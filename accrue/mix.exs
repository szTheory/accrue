defmodule Accrue.MixProject do
  use Mix.Project

  @version "1.4.0"
  @source_url "https://github.com/szTheory/accrue"

  def project do
    [
      app: :accrue,
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      description: "Billing state, modeled clearly.",
      source_url: @source_url,
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit, :credo],
        ignore_warnings: ".dialyzer_ignore.exs"
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
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
  # `Accrue.Application` runs boot-time validations (config schema + auth)
  # and starts an empty supervisor — Accrue is a library, so Repo/Oban/
  # ChromicPDF/Finch remain host-owned.
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
      # re-verified against the project stack documentation.
      {:ecto, "~> 3.13"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.22"},
      {:ex_money, "~> 5.24"},
      {:lattice_stripe, "~> 2.0"},
      {:braintree, "~> 0.16"},
      {:oban, "~> 2.21"},
      {:swoosh, "~> 1.25"},
      {:mailglass, "~> 1.0"},
      {:rendro, "~> 1.0"},
      {:chromic_pdf, "~> 1.17"},
      {:nimble_options, "~> 1.1"},
      {:telemetry, "~> 1.3"},
      {:jason, "~> 1.4"},
      {:jose, "~> 1.11"},
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
      # REQUIRED (non-optional) core dep — NOT optional. Ships Phoenix.Component +
      # the ~H sigil for the email + invoice render spine (the components live in
      # lib/, not test/, so it is loaded for compile + runtime), AND backs the
      # conditionally-compiled Accrue.Live.Entitlements on_mount guard.
      # Core stays LiveView-runtime-free: no LiveView socket runtime
      # (Phoenix.LiveView / on_mount / Socket) in always-compiled code, and
      # phoenix_live_view never appears in extra_applications (see
      # application/0 — [:logger] only).
      {:phoenix_live_view, "~> 1.1"},
      #
      # NOTE on :sigra — optional integration; when not published to Hex the
      # Accrue.Integrations.Sigra adapter is conditionally compiled via
      # `Code.ensure_loaded?/1` + `@compile {:no_warn_undefined, _}` guards, so
      # Accrue does not need to declare :sigra in deps for the detection
      # pattern to work. Once :sigra publishes, this list should grow a
      # `{:sigra, "~> 0.1", optional: true}` line.
      {:opentelemetry, "~> 1.7", optional: true},
      {:telemetry_metrics, "~> 1.1", optional: true},
      # Optional Chimeway dunning engine (DUN-03) — conditionally compiled via
      # Code.ensure_loaded?(Chimeway); absent by default; host opts in by adding
      # {:chimeway, "~> 1.0"} to their own deps and setting
      # `config :accrue, dunning: [engine: Accrue.Integrations.Chimeway]`.
      # Cross-repo dev: CHIMEWAY_PATH=/path/to/chimeway mix deps.get
      chimeway_dep(),

      # Dev / test
      {:excoveralls, "~> 0.18", only: :test},
      {:mox, "~> 1.2", only: :test},
      {:stream_data, "~> 1.3", only: [:dev, :test]},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp chimeway_dep do
    case System.get_env("CHIMEWAY_PATH") do
      nil -> {:chimeway, "~> 1.0", optional: true}
      path -> {:chimeway, path: path, optional: true}
    end
  end

  defp aliases do
    [
      "test.all": [
        "format --check-formatted",
        "cmd mix credo --strict",
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
      logo: "priv/ex_doc/accrue-mark.svg",
      favicon: "priv/ex_doc/favicon.svg",
      extras: ["README.md" | Path.wildcard("guides/*.md")],
      groups_for_extras: [Guides: Path.wildcard("guides/*.md")],
      before_closing_body_tag: &before_closing_body_tag/1,
      skip_undefined_reference_warnings_on: &skip_undefined_reference_warning?/1
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <style>
      .accrue-mermaid {
        --accrue-diagram-ring: rgba(15, 23, 42, 0.08);
        margin: 1.5rem 0;
        overflow-x: auto;
        padding: 1rem;
        border-radius: 0.75rem;
        background: transparent;
        box-shadow:
          0 0 0 1px var(--accrue-diagram-ring),
          0 1px 2px -1px rgba(15, 23, 42, 0.08),
          0 2px 6px rgba(15, 23, 42, 0.04);
        color: inherit;
        text-align: center;
      }

      body.dark .accrue-mermaid {
        --accrue-diagram-ring: rgba(255, 255, 255, 0.1);
        box-shadow: 0 0 0 1px var(--accrue-diagram-ring);
      }

      .accrue-mermaid svg {
        display: block;
        width: 100%;
        min-width: 42rem;
        max-width: none;
        height: auto;
        margin: 0 auto;
      }

      @media (min-width: 48rem) {
        .accrue-mermaid svg {
          min-width: 0;
          max-width: 100%;
        }
      }
    </style>
    <script type="module">
      const mermaidSource =
        "https://cdn.jsdelivr.net/npm/mermaid@11.16.0/dist/mermaid.esm.min.mjs";
      let mermaidPromise;
      let renderSequence = 0;
      let renderQueue = Promise.resolve();
      let warned = false;

      const warnOnce = (error) => {
        if (warned) return;
        warned = true;
        console.warn("Accrue docs could not render a Mermaid diagram; showing source instead.", error);
      };

      const loadMermaid = () => {
        mermaidPromise ||= import(mermaidSource).then(({ default: mermaid }) => mermaid);

        return mermaidPromise;
      };

      const docsTheme = () =>
        document.body.classList.contains("dark") ? "dark" : "default";

      const renderExistingDiagram = async (mermaid, wrapper, theme) => {
        if (
          wrapper.dataset.mermaidTheme === theme ||
          wrapper.dataset.mermaidRendering === "true"
        ) {
          return;
        }

        wrapper.dataset.mermaidRendering = "true";

        try {
          const diagramId = `accrue-mermaid-${++renderSequence}`;
          const { svg, bindFunctions } =
            await mermaid.render(diagramId, wrapper.dataset.mermaidSource);
          const rendered = document.createElement("div");
          rendered.innerHTML = svg;
          wrapper.replaceChildren(...rendered.childNodes);
          wrapper.dataset.mermaidTheme = theme;

          if (typeof bindFunctions === "function") bindFunctions(wrapper);
        } catch (error) {
          warnOnce(error);
        } finally {
          delete wrapper.dataset.mermaidRendering;
        }
      };

      const renderSourceDiagram = async (mermaid, code, theme) => {
        const pre = code.parentElement;
        if (!pre || code.dataset.mermaidRendering === "true") return;

        code.dataset.mermaidRendering = "true";

        try {
          const source = code.textContent;
          const diagramId = `accrue-mermaid-${++renderSequence}`;
          const { svg, bindFunctions } = await mermaid.render(diagramId, source);
          const wrapper = document.createElement("div");
          wrapper.className = "accrue-mermaid";
          wrapper.dataset.mermaidSource = source;
          wrapper.dataset.mermaidTheme = theme;
          wrapper.innerHTML = svg;

          if (typeof bindFunctions === "function") bindFunctions(wrapper);

          pre.replaceWith(wrapper);
        } catch (error) {
          delete code.dataset.mermaidRendering;
          warnOnce(error);
        }
      };

      const renderMermaid = async () => {
        const blocks = document.querySelectorAll("pre > code.mermaid");
        const diagrams = document.querySelectorAll(".accrue-mermaid[data-mermaid-source]");
        if (blocks.length === 0 && diagrams.length === 0) return;

        let mermaid;

        try {
          mermaid = await loadMermaid();
        } catch (error) {
          mermaidPromise = undefined;
          warnOnce(error);
          return;
        }

        const theme = docsTheme();
        mermaid.initialize({ startOnLoad: false, securityLevel: "strict", theme });

        for (const wrapper of diagrams) {
          await renderExistingDiagram(mermaid, wrapper, theme);
        }

        for (const code of blocks) {
          await renderSourceDiagram(mermaid, code, theme);
        }
      };

      const scheduleMermaidRender = () => {
        renderQueue = renderQueue.then(renderMermaid).catch(warnOnce);
      };

      new MutationObserver(scheduleMermaidRender).observe(document.body, {
        attributes: true,
        attributeFilter: ["class"]
      });

      window.addEventListener("exdoc:loaded", scheduleMermaidRender);

      if (document.readyState === "loading") {
        window.addEventListener("DOMContentLoaded", scheduleMermaidRender, { once: true });
      } else {
        scheduleMermaidRender();
      }
    </script>
    """
  end

  defp before_closing_body_tag(_format), do: ""

  # Pre-v1 API docs still contain internal cross-links to schema types and
  # hidden lifecycle functions that are not public ExDoc nodes yet. Keep guide
  # warnings active while allowing the docs build to fail only on new
  # actionable guide or external references.
  defp skip_undefined_reference_warning?(reference) do
    is_binary(reference) and String.starts_with?(reference, "lib/")
  end
end
