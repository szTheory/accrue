defmodule AccrueHost.Demo.CommandManifest do
  @moduledoc false

  @manifest %{
    first_run: %{
      label: "First run",
      boundary: :public,
      audience: :local_evaluation,
      commands: [
        "cd examples/accrue_host",
        "mix setup",
        "mix phx.server",
        "Create a Fake-backed subscription through AccrueHost.Billing",
        "POST one signed /webhooks/stripe event",
        "Inspect /billing",
        "mix verify"
      ]
    },
    seeded_history: %{
      label: "Seeded history",
      boundary: :seeded,
      audience: :browser_smoke,
      commands: [
        "cd examples/accrue_host",
        "mix setup",
        "mix verify.full",
        "Seed deterministic replay/history state for browser smoke"
      ]
    },
    command_modes: [
      %{label: "Fake-backed local evaluation", command: "mix setup", boundary: :public},
      %{label: "Focused tutorial proof suite", command: "mix verify", boundary: :public},
      %{label: "CI-equivalent validation", command: "mix verify.full", boundary: :seeded},
      %{
        label: "Repo-root CI wrapper",
        command: "bash scripts/ci/accrue_host_uat.sh",
        boundary: :seeded
      },
      %{label: "Hex smoke", command: "bash scripts/ci/accrue_host_hex_smoke.sh", boundary: :seeded},
      %{label: "Production setup", command: "mix accrue.install", boundary: :public}
    ],
    story_artifacts: [
      "customer.subscription.created",
      "/billing",
      "/webhooks/stripe"
    ]
  }

  def manifest, do: @manifest

  def command_labels do
    Enum.map(@manifest.command_modes, & &1.command)
  end
end
