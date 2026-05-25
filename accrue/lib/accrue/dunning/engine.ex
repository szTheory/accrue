defmodule Accrue.Dunning.Engine do
  @moduledoc """
  Behaviour for dunning campaign orchestration engines (DUN-03, D-01).

  Engines control **which orchestration system** is invoked at campaign
  boundaries. DB state (`dunning_campaign_started_at` on
  `accrue_subscriptions`) is managed by Accrue regardless of engine choice —
  the engine only decides how the resulting Oban jobs or external workflows
  are enqueued and cancelled.

  ## Built-in engine

  `Accrue.Dunning.Engine.Oban` is always-on and requires no additional
  configuration. It wraps the existing Oban-backed `DunningStep` worker.

  ## Optional Chimeway engine

  `Accrue.Integrations.Chimeway` is off by default and conditionally compiled
  when the optional `:chimeway` dependency is present. To opt in:

      # config/config.exs
      config :accrue, dunning: [engine: Accrue.Integrations.Chimeway]

  The `:chimeway` dep must also be added to the host `mix.exs`:

      {:chimeway, "~> 1.0"}

  ## Dispatch

  The engine is invoked directly via `Config.dunning_engine().start_campaign(...)`.
  This module is behaviour-only — no facade delegation functions are defined
  here, unlike `Accrue.Auth`.
  """

  @callback start_campaign(
              subscription :: Accrue.Billing.Subscription.t(),
              anchor_at :: DateTime.t(),
              opts :: keyword()
            ) :: :ok | {:error, term()}

  @callback cancel_campaign(
              subscription :: Accrue.Billing.Subscription.t(),
              iso_anchor :: String.t(),
              opts :: keyword()
            ) :: :ok | {:error, term()}
end
