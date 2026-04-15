defmodule Accrue.Application do
  @moduledoc """
  OTP Application entry point for Accrue (FND-05, D-05).

  Empty-supervisor pattern: Accrue is a library, not a service. It does
  NOT start host-owned components (host Repo, Oban, host ChromicPDF pool,
  host Finch pool) — the host application's supervision tree owns those
  (D-33, D-42, Pitfall #4).

  Before the supervisor starts we run three boot-time validations:

    1. `Accrue.Config.validate_at_boot!/0` — validates the current
       `:accrue` application env against the NimbleOptions schema.
       Misconfig fails loud, before any state is touched.

    2. `Accrue.Auth.Default.boot_check!/0` — refuses to boot in `:prod`
       when `:auth_adapter` still points at the dev-permissive default
       (D-40, T-FND-07 mitigation).

    3. `warn_on_secret_collision/0` — emits a `Logger.warning/1` (not
       fatal) when the configured Connect webhook endpoint secret is
       byte-identical to the platform endpoint secret. Stripe issues a
       SEPARATE signing secret per Connect endpoint in the Stripe
       Dashboard; mixing them causes silent signature verification
       failures (Phase 5 Pitfall 5; `guides/connect.md`).
  """

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    :ok = Accrue.Config.validate_at_boot!()
    :ok = Accrue.Auth.Default.boot_check!()
    :ok = warn_on_secret_collision()

    children = []

    Supervisor.start_link(children, strategy: :one_for_one, name: Accrue.Supervisor)
  end

  @doc false
  # Pitfall 5 (Phase 5): emit a boot-time warning when the Connect
  # endpoint secret byte-equals any non-Connect (platform) endpoint
  # secret. Non-fatal — hosts may intentionally set identical secrets
  # in dev/test fixtures — but a warning surfaces the footgun before
  # the host hits a silent signature verification failure in prod.
  @spec warn_on_secret_collision() :: :ok
  def warn_on_secret_collision do
    endpoints =
      try do
        Accrue.Config.webhook_endpoints()
      rescue
        _ -> []
      end

    {connect_entries, other_entries} =
      Enum.split_with(endpoints, fn {_name, cfg} ->
        Keyword.get(cfg || [], :mode) == :connect
      end)

    connect_secrets =
      connect_entries
      |> Enum.map(fn {name, cfg} -> {name, Keyword.get(cfg || [], :secret)} end)
      |> Enum.reject(fn {_n, s} -> is_nil(s) or s == "" end)

    other_secrets =
      other_entries
      |> Enum.map(fn {name, cfg} -> {name, Keyword.get(cfg || [], :secret)} end)
      |> Enum.reject(fn {_n, s} -> is_nil(s) or s == "" end)

    for {cname, csecret} <- connect_secrets,
        {pname, psecret} <- other_secrets,
        csecret == psecret do
      Logger.warning(
        "[Accrue] :#{cname} and :#{pname} webhook secrets are byte-identical. " <>
          "Stripe issues a SEPARATE signing secret per Connect endpoint in the " <>
          "Stripe Dashboard. Mixing them causes silent verification failures. " <>
          "(Pitfall 5; see guides/connect.md)"
      )
    end

    :ok
  end
end
