defmodule AccrueHostWeb.DevBanner do
  @moduledoc false
  # Native-dev launch banner: logs the same routes + demo logins as the host-side
  # `bin/dev-banner.sh`, but for `mix phx.server` running directly on the host
  # (http://localhost:4000). Best-effort and dev-only — never raises, never runs
  # under Docker (the host-side banner already covers that path and binds 0.0.0.0
  # on an ephemeral port, so `localhost:4000` would be wrong).

  require Logger

  @doc """
  Prints the native-dev banner when appropriate.

  Gated on BOTH:
    * `:dev_routes` config truthy (dev only), AND
    * `PGHOST != "db"` (suppressed inside Docker).

  Wrapped best-effort so a printing failure can never affect application boot.
  """
  @spec maybe_print() :: :ok
  def maybe_print do
    if Application.get_env(:accrue_host, :dev_routes) == true and System.get_env("PGHOST") != "db" do
      try do
        print()
      catch
        _, _ -> :ok
      end
    end

    :ok
  end

  defp print do
    Logger.info("""

    ==============================================================================
    Accrue admin-UI demo is up:

      http://localhost:4000

    Key routes:
      /admin                  mounted Accrue Admin UI
      /billing                mounted billing portal
      /app/billing            host billing screen
      /app/reports/advanced   entitlement-gated reports
      /users/log-in           sign in
      /dev/mailbox            sent-email preview

    Seeded demo logins (password for ALL: accrue-demo-password):
      OPERATOR (billing-admin — use this to open /admin):
        admin@example.com        billing_admin, no subscription — /admin only

      CUSTOMERS (tenant-facing /app/billing + /billing portal — NOT admin):
        healthy@example.com      clean, subscribed (no dunning banner)
        past-due@example.com     past_due, dunning campaign active
        canceled@example.com     canceled subscription
        enterprise@example.com   premium plan + JPY invoice showcase
        trialing@example.com     trialing subscription
    ==============================================================================
    """)
  end
end
