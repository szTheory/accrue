defmodule AccrueAdmin.MixProject do
  use Mix.Project

  @version "1.5.0"
  @source_url "https://github.com/szTheory/accrue"

  def project do
    [
      app: :accrue_admin,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      description: "Admin LiveView UI for Accrue billing.",
      source_url: @source_url,
      docs: docs(),
      test_coverage: [summary: [threshold: 80]],
      dialyzer: [plt_local_path: "priv/plts", plt_add_apps: [:mix, :ex_unit]]
    ]
  end

  def application do
    [
      mod: {AccrueAdmin.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "storybook/_support"]
  defp elixirc_paths(:test), do: ["lib", "storybook/_support", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  def cli do
    [preferred_envs: [test: :test]]
  end

  defp deps do
    [
      accrue_dep(),
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.2"},
      {:mailglass_admin, "~> 1.0", only: [:dev, :test]},
      {:phoenix_storybook, "~> 1.2", only: [:dev, :test]},
      {:plug_cowboy, "~> 2.7", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{},
      files: ~w(lib config guides priv/static mix.exs README* LICENSE* CHANGELOG*)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "accrue_admin-v#{@version}",
      extras: [
        "README.md",
        "guides/admin_ui.md",
        "guides/local_demo.md",
        "guides/core-admin-parity.md",
        "guides/theme-exceptions.md",
        "guides/motion.md",
        "guides/spec-overview.md",
        "guides/spec-list.md",
        "guides/spec-detail.md"
      ],
      groups_for_extras: [
        Guides: [
          "guides/admin_ui.md",
          "guides/local_demo.md",
          "guides/core-admin-parity.md",
          "guides/theme-exceptions.md",
          "guides/motion.md",
          "guides/spec-overview.md",
          "guides/spec-list.md",
          "guides/spec-detail.md"
        ]
      ],
      # `AccrueAdmin.Copy` defdelegates and README route tables mention implementation/hidden
      # modules (`@moduledoc false`). Skipping autolink avoids ExDoc --warnings-as-errors.
      skip_code_autolink_to: fn term ->
        is_binary(term) and
          (term =~
             ~r/^AccrueAdmin\.Copy\.(BillingEvent|Connect|Coupon|CustomerPaymentMethods|Dunning|Entitlements|Invoice|PromotionCode|Subscription)\b/ or
             term =~ ~r/^AccrueAdmin\.Live\./ or
             term =~ ~r/^AccrueAdmin\.Dev\./)
      end,
      # ExDoc resolves relative markdown links in guides; the
      # `.planning/milestones/...` paths sit outside the package tarball but
      # add operator-discoverable context for repo readers. Skip the warning
      # rather than break the link or duplicate the SSOT inside the package.
      skip_undefined_reference_warnings_on: [
        "guides/admin_ui.md",
        "guides/local_demo.md",
        "guides/core-admin-parity.md",
        "guides/motion.md",
        "guides/spec-overview.md",
        "guides/spec-list.md",
        "guides/spec-detail.md"
      ]
    ]
  end

  defp accrue_dep do
    if System.get_env("ACCRUE_ADMIN_HEX_RELEASE") == "1" do
      {:accrue, "~> #{@version}"}
    else
      {:accrue, path: "../accrue"}
    end
  end
end
