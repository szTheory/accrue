defmodule Accrue.Application do
  @moduledoc """
  OTP Application module for Accrue — manages boot-time validation and
  the supervision tree.

  ## What this is

  Accrue follows an empty-supervisor pattern: it is a library, not a
  service. The supervisor starts with no children. Accrue does **not**
  start host-owned processes such as your Repo, Oban, ChromicPDF pool, or
  Finch pool — your application's supervision tree owns those.

  ## What happens at boot

  Before the (empty) supervisor starts, Accrue runs several validations:

    1. **Config schema check** — `Accrue.Config.validate_at_boot!/0`
       validates the `:accrue` application environment against the
       NimbleOptions schema. Misconfiguration fails loudly at startup,
       before any state is touched.

    2. **Auth adapter safety check** — `Accrue.Auth.Default.boot_check!/0`
       refuses to start in `:prod` when `:auth_adapter` still points at
       the dev-permissive default adapter.

    3. **PDF adapter availability check** — warns at boot if
       `Accrue.PDF.ChromicPDF` is configured but no ChromicPDF supervisor
       child is running in the host app's supervision tree.

    4. **Oban queue / PDF pool size check** — warns if the `:accrue_mailers`
       Oban queue concurrency exceeds the ChromicPDF pool size, which can
       cause back-pressure on invoice email rendering.

    5. **Connect webhook secret collision check** — warns when a Connect
       endpoint's webhook signing secret is byte-identical to a platform
       endpoint secret. Stripe issues a separate signing secret for Connect
       endpoints in the Dashboard; mixing them causes silent signature
       verification failures. See `guides/connect.md`.

    6. **Company address / locale check** — warns when customers have
       EU/CA preferred locales but `:branding[:company_address]` is unset.
       CAN-SPAM/CASL require a physical postal address in transactional
       emails for those locales.

  ## Host app integration

  `Accrue.Application` is started automatically by OTP when `:accrue` is
  listed as a dependency — host applications do **not** start it manually.
  Ensure your `config/runtime.exs` is complete before the application
  starts, as validation runs during `start/2`.
  """

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    :ok = Accrue.Config.validate_at_boot!()
    :ok = Accrue.Auth.Default.boot_check!()
    :ok = warn_on_secret_collision()
    :ok = warn_pdf_adapter_unavailable()
    :ok = warn_oban_queue_vs_pdf_pool()
    :ok = warn_company_address_locale_mismatch()

    children = []

    Supervisor.start_link(children, strategy: :one_for_one, name: Accrue.Supervisor)
  end

  @doc false
  # Emit a boot-time warning when the configured PDF adapter is
  # `Accrue.PDF.ChromicPDF` but the host app has NOT started a ChromicPDF
  # supervisor child. Accrue does not start ChromicPDF itself — the host
  # app's supervision tree owns it. The mailer worker's PDF attachment
  # branch treats `:chromic_pdf_not_started` as a terminal error and falls
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
        supervisor child is running. Accrue does not start ChromicPDF —
        add it to your host application's supervision tree.
        Invoice emails will fall through to the hosted_invoice_url note
        instead of attaching a rendered PDF until this is fixed.
        Add `{ChromicPDF, on_demand: true}` (dev) or a persistent pool
        (prod) to your host application's supervision tree.
        """)

        :ok
    end
  end

  @doc false
  # Emit a boot-time warning when the `:accrue_mailers` Oban queue is
  # configured with a concurrency greater than the declared ChromicPDF pool
  # size. Without this guard the mailer queue can starve the PDF pool and
  # back-pressure the entire billing email path.
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
      size or bump :chromic_pdf_pool_size. See guides/email.md.
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
  # Emit a boot-time warning when the Connect endpoint secret byte-equals
  # any non-Connect (platform) endpoint secret. Non-fatal — hosts may
  # intentionally set identical secrets in dev/test fixtures — but a
  # warning surfaces the footgun before hitting a silent signature
  # verification failure in production.
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
          "Stripe issues a separate signing secret per Connect endpoint in the " <>
          "Stripe Dashboard. Mixing them causes silent verification failures. " <>
          "See guides/connect.md for the correct setup."
      )
    end

    :ok
  end
end
