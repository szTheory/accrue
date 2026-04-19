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
    :ok = warn_deprecated_branding()
    :ok = warn_pdf_adapter_unavailable()
    :ok = warn_oban_queue_vs_pdf_pool()
    :ok = warn_company_address_locale_mismatch()

    children = []

    Supervisor.start_link(children, strategy: :one_for_one, name: Accrue.Supervisor)
  end

  @doc false
  # Pitfall guard: emit a boot-time warning when the configured
  # PDF adapter is `Accrue.PDF.ChromicPDF` but the host app has NOT
  # started a ChromicPDF supervisor child. Accrue does not start
  # ChromicPDF itself (D-33). The mailer worker's PDF attachment branch
  # treats `:chromic_pdf_not_started` as a terminal error and falls
  # through to the hosted-invoice-url note — this warning surfaces the
  # misconfig at boot instead of waiting for the first invoice email.
  @spec warn_pdf_adapter_unavailable() :: :ok
  def warn_pdf_adapter_unavailable do
    key = :accrue_pdf_adapter_unavailable_warned?
    adapter = Application.get_env(:accrue, :pdf_adapter, Accrue.PDF.ChromicPDF)
    env = safe_mix_env()

    cond do
      adapter != Accrue.PDF.ChromicPDF ->
        :ok

      env != :prod ->
        :ok

      Process.whereis(ChromicPDF) != nil ->
        :ok

      :persistent_term.get(key, false) ->
        :ok

      true ->
        :persistent_term.put(key, true)

        Logger.warning("""
        [Accrue] :pdf_adapter is Accrue.PDF.ChromicPDF but no ChromicPDF
        supervisor child is running. Accrue does NOT start ChromicPDF
        (D-33). Invoice emails will fall through to the hosted_invoice_url
        note instead of attaching a rendered PDF.
        Add `{ChromicPDF, on_demand: true}` (dev) or a persistent pool
        (prod) to your host application's supervision tree.
        """)

        :ok
    end
  end

  @doc false
  # Pitfall guard: emit a boot-time warning when the
  # `:accrue_mailers` Oban queue is configured with a concurrency
  # greater than the declared ChromicPDF pool size. Without this guard
  # the mailer queue can starve the PDF pool and back-pressure the
  # entire billing email path.
  @spec warn_oban_queue_vs_pdf_pool() :: :ok
  def warn_oban_queue_vs_pdf_pool do
    key = :accrue_oban_queue_vs_pdf_pool_warned?

    with false <- :persistent_term.get(key, false),
         true <- Application.get_env(:accrue, :attach_invoice_pdf, true),
         queue_concurrency when is_integer(queue_concurrency) <- mailer_queue_concurrency(),
         pool_size when is_integer(pool_size) and queue_concurrency > pool_size <-
           Application.get_env(:accrue, :chromic_pdf_pool_size, 3) do
      :persistent_term.put(key, true)

      Logger.warning("""
      [Accrue] :accrue_mailers Oban queue concurrency (#{queue_concurrency}) exceeds
      :chromic_pdf_pool_size (#{pool_size}). Invoice email rendering may
      back-pressure the ChromicPDF pool — set queue concurrency ≤ pool
      size or bump :chromic_pdf_pool_size. See guides/email.md Pitfall 4.
      """)

      :ok
    else
      _ -> :ok
    end
  end

  @doc false
  # Emit a boot-time warning when the customer base includes EU/CA locales
  # but `:branding[:company_address]` is unset. Transactional exemptions under
  # CAN-SPAM/CASL require a physical postal address for EU/CA senders. The
  # query samples grouped counts only — no customer_id, email, or name leaks
  # into the log.
  @spec warn_company_address_locale_mismatch() :: :ok
  def warn_company_address_locale_mismatch do
    key = :accrue_company_address_locale_warned?

    cond do
      safe_mix_env() == :test ->
        :ok

      :persistent_term.get(key, false) ->
        :ok

      branding_has_company_address?() ->
        :ok

      true ->
        case sample_customer_locales() do
          {:ok, locales} ->
            eu_ca = Enum.filter(locales, &eu_ca_locale?/1)

            if eu_ca != [] do
              :persistent_term.put(key, true)

              Logger.warning("""
              [Accrue] Customers have preferred_locale in #{inspect(eu_ca)} but
              :branding[:company_address] is not set. EU/CA transactional
              exemptions under CAN-SPAM/CASL/GDPR require a physical
              postal address in transactional emails. Set
              `config :accrue, :branding, company_address: "..."`.
              See guides/email.md.
              """)
            end

            :ok

          :error ->
            :ok
        end
    end
  end

  defp branding_has_company_address? do
    branding = Application.get_env(:accrue, :branding, [])
    addr = Keyword.get(branding, :company_address)
    is_binary(addr) and addr != ""
  end

  defp mailer_queue_concurrency do
    oban_cfg = Application.get_env(:accrue, Oban, [])
    queues = Keyword.get(oban_cfg, :queues, [])
    # Queues can be [{queue, limit}] or keyword list.
    case Enum.find(queues, fn
           {:accrue_mailers, _} -> true
           _ -> false
         end) do
      {:accrue_mailers, limit} when is_integer(limit) -> limit
      {:accrue_mailers, opts} when is_list(opts) -> Keyword.get(opts, :limit)
      _ -> nil
    end
  end

  defp sample_customer_locales do
    import Ecto.Query, only: [from: 2]

    try do
      repo = Accrue.Repo

      locales =
        from(c in "accrue_customers",
          where: not is_nil(c.preferred_locale),
          group_by: c.preferred_locale,
          limit: 100,
          select: c.preferred_locale
        )
        |> repo.all()

      {:ok, locales}
    rescue
      _ -> :error
    catch
      _, _ -> :error
    end
  end

  defp eu_ca_locale?(locale) when is_binary(locale) do
    cond do
      String.starts_with?(locale, "fr") -> true
      String.starts_with?(locale, "de") -> true
      String.starts_with?(locale, "nl") -> true
      locale in ["en-GB", "en-CA", "en_GB", "en_CA"] -> true
      true -> false
    end
  end

  defp eu_ca_locale?(_), do: false

  defp safe_mix_env do
    try do
      Mix.env()
    rescue
      _ -> :prod
    end
  end

  @doc false
  # Emit a boot-time warning when any of the six deprecated flat branding keys
  # are set AND the nested `:branding` config key is empty. The flat keys are
  # a deprecation shim; migrate to nested `:branding`. `:persistent_term`
  # dedupe ensures the warning fires at most once per BEAM boot.
  #
  # The log message includes only key names, never values — email values never
  # leak into log output.
  @spec warn_deprecated_branding() :: :ok
  def warn_deprecated_branding do
    key = :accrue_deprecated_branding_warned?
    flat = Accrue.Config.deprecated_flat_branding_keys()
    any_flat_set? = Enum.any?(flat, fn k -> Application.get_env(:accrue, k) != nil end)
    nested_empty? = Application.get_env(:accrue, :branding, []) == []

    if any_flat_set? and nested_empty? and :persistent_term.get(key, false) == false do
      :persistent_term.put(key, true)

      affected =
        Enum.filter(flat, fn k -> Application.get_env(:accrue, k) != nil end)

      Logger.warning("""
      [Accrue] Flat branding keys are DEPRECATED.
      Migrate to the nested :branding keyword list. See guides/branding.md.
      Affected keys: #{inspect(affected)}
      """)
    end

    :ok
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
