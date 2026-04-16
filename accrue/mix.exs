defmodule Accrue.MixProject do
  use Mix.Project

  @version "0.1.2"
  @source_url "https://github.com/szTheory/accrue"

  def project do
    [
      app: :accrue,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      description: "Billing state, modeled clearly.",
      source_url: @source_url,
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit, :credo]
      ],
      docs: docs()
    ]
  end

  # Custom CLI aliases must declare their preferred env explicitly —
  # `mix test.live` and `mix test.all` both run in :test.
  def cli do
    [preferred_envs: ["test.live": :test, "test.all": :test]]
  end

  # Configuration for the OTP application.
  #
  # Plan 01-06 wires `Accrue.Application` as the OTP entry point (FND-05).
  # The application runs two boot-time validations (config schema + Auth
  # refuse-to-boot) and then starts an empty supervisor — Accrue is a
  # library, so Repo/Oban/ChromicPDF/Finch remain host-owned (D-33, D-42,
  # Pitfall #4).
  def application do
    [
      extra_applications: [:logger],
      mod: {Accrue.Application, []}
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "credo_checks"]
  defp elixirc_paths(:test), do: ["lib", "credo_checks", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core required deps — versions locked per CLAUDE.md §Technology Stack and
      # re-verified in .planning/phases/01-foundations/01-RESEARCH.md (2026-04-11).
      {:ecto, "~> 3.13"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.22"},
      {:ex_money, "~> 5.24"},
      {:lattice_stripe, "~> 1.1"},
      {:oban, "~> 2.21"},
      {:swoosh, "~> 1.25"},
      {:phoenix_swoosh, "~> 1.2"},
      {:mjml_eex, "~> 0.13"},
      {:chromic_pdf, "~> 1.17"},
      {:nimble_options, "~> 1.1"},
      {:telemetry, "~> 1.3"},
      {:jason, "~> 1.4"},
      {:decimal, "~> 2.0"},
      {:plug, "~> 1.16"},
      {:plug_crypto, "~> 2.1"},
      {:igniter, "~> 0.7.9", runtime: false},

      # Optional deps — conditionally compiled; see CLAUDE.md §Conditional Compilation.
      #
      # Phoenix is optional for core accrue — the Router macro uses
      # Phoenix.Router.forward/3 when Phoenix is loaded, but the webhook
      # plug works without Phoenix (plain Plug.Router).
      {:phoenix, "~> 1.8", optional: true},
      # Phase 6 Plan 03: Phoenix.Component + ~H sigil for the shared invoice
      # component library (`Accrue.Invoices.Components`) used by both email
      # (via HtmlBridge + <mj-raw>) and PDF (via Layouts.print_shell). Loaded
      # for compile + runtime because the components live in lib/, not test/.
      {:phoenix_live_view, "~> 1.1"},
      #
      # NOTE on :sigra — not yet published to Hex. Per D-41 the
      # Accrue.Integrations.Sigra adapter is conditionally compiled via
      # `Code.ensure_loaded?/1` + `@compile {:no_warn_undefined, _}` guards, so
      # Accrue does not need to declare :sigra in deps for the detection
      # pattern to work. Once :sigra publishes, this list should grow a
      # `{:sigra, "~> 0.1", optional: true}` line. Tracked as a Wave-0
      # deviation (Rule 3) in 01-01-bootstrap-SUMMARY.md.
      {:opentelemetry, "~> 1.7", optional: true},
      {:telemetry_metrics, "~> 1.1", optional: true},

      # Dev / test
      {:mox, "~> 1.2", only: :test},
      {:stream_data, "~> 1.3", only: [:dev, :test]},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      "test.all": [
        "format --check-formatted",
        "credo --strict",
        "compile --warnings-as-errors",
        "test"
      ],
      # Opt-in live-Stripe fidelity suite. Gated on the `:live_stripe` tag,
      # which is excluded by default in `test/test_helper.exs`. Individual
      # test modules in `test/live_stripe/` are expected to skip cleanly in
      # `setup_all` when `STRIPE_TEST_SECRET_KEY` is unset.
      "test.live": ["test --only live_stripe"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{},
      files: ~w(lib priv guides mix.exs README* LICENSE* CHANGELOG*)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "accrue-v#{@version}",
      extras: ["README.md" | Path.wildcard("guides/*.md")],
      groups_for_extras: [Guides: Path.wildcard("guides/*.md")],
      skip_undefined_reference_warnings_on: &skip_undefined_reference_warning?/1
    ]
  end

  # Pre-v1 API docs still contain internal cross-links to schema types and
  # hidden lifecycle functions that are not public ExDoc nodes yet. Keep guide
  # warnings active while allowing the docs build to fail only on new
  # actionable guide or external references.
  defp skip_undefined_reference_warning?(reference) do
    is_binary(reference) and String.starts_with?(reference, "lib/")
  end
end
