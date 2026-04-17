defmodule Accrue.SetupDiagnostic do
  @moduledoc """
  Shared setup-diagnostic carrier for first-hour host misconfiguration.
  """

  @enforce_keys [:code, :summary, :fix, :docs_path]
  defexception [:code, :summary, :fix, :docs_path, :details]

  @type t :: %__MODULE__{
          code: String.t(),
          summary: String.t(),
          fix: String.t(),
          docs_path: String.t(),
          details: term()
        }

  @repo_config_anchor "/guides/troubleshooting.html#accrue-dx-repo-config"
  @migrations_pending_anchor "/guides/troubleshooting.html#accrue-dx-migrations-pending"
  @oban_not_configured_anchor "/guides/troubleshooting.html#accrue-dx-oban-not-configured"
  @oban_not_supervised_anchor "/guides/troubleshooting.html#accrue-dx-oban-not-supervised"
  @webhook_secret_missing_anchor "/guides/troubleshooting.html#accrue-dx-webhook-secret-missing"
  @webhook_route_missing_anchor "/guides/troubleshooting.html#accrue-dx-webhook-route-missing"
  @webhook_raw_body_anchor "/guides/troubleshooting.html#accrue-dx-webhook-raw-body"
  @webhook_pipeline_anchor "/guides/troubleshooting.html#accrue-dx-webhook-pipeline"
  @auth_adapter_anchor "/guides/troubleshooting.html#accrue-dx-auth-adapter"
  @admin_mount_missing_anchor "/guides/troubleshooting.html#accrue-dx-admin-mount-missing"

  @impl true
  def message(diagnostic), do: format(diagnostic)

  @spec repo_config(keyword()) :: t()
  def repo_config(opts \\ []) do
    build(
      "ACCRUE-DX-REPO-CONFIG",
      "Accrue cannot find a host Repo configuration.",
      "Set `config :accrue, :repo, MyApp.Repo` and make sure the module uses `Ecto.Repo`.",
      @repo_config_anchor,
      Keyword.get(opts, :details)
    )
  end

  @spec migrations_pending(keyword()) :: t()
  def migrations_pending(opts \\ []) do
    build(
      "ACCRUE-DX-MIGRATIONS-PENDING",
      "Accrue migrations are pending for the configured Repo.",
      "Run `mix ecto.migrate` in the host app, then retry boot or the installer check.",
      @migrations_pending_anchor,
      Keyword.get(opts, :details)
    )
  end

  @spec oban_not_configured(keyword()) :: t()
  def oban_not_configured(opts \\ []) do
    build(
      "ACCRUE-DX-OBAN-NOT-CONFIGURED",
      "Accrue could not find the expected Oban queue configuration.",
      "Add the host Oban config with `:accrue_webhooks` and `:accrue_mailers`, then rerun the check.",
      @oban_not_configured_anchor,
      Keyword.get(opts, :details)
    )
  end

  @spec oban_not_supervised(keyword()) :: t()
  def oban_not_supervised(opts \\ []) do
    build(
      "ACCRUE-DX-OBAN-NOT-SUPERVISED",
      "Oban is configured but no running Oban supervisor was detected.",
      "Start `{Oban, ...}` in the host supervision tree before using Accrue async paths.",
      @oban_not_supervised_anchor,
      Keyword.get(opts, :details)
    )
  end

  @spec webhook_secret_missing(keyword()) :: t()
  def webhook_secret_missing(opts \\ []) do
    build(
      "ACCRUE-DX-WEBHOOK-SECRET-MISSING",
      "Accrue cannot verify webhook signatures because the signing secret is missing.",
      "Set the webhook signing secret in runtime config and keep the value out of source control.",
      @webhook_secret_missing_anchor,
      Keyword.get(opts, :details)
    )
  end

  @spec webhook_route_missing(keyword()) :: t()
  def webhook_route_missing(opts \\ []) do
    build(
      "ACCRUE-DX-WEBHOOK-ROUTE-MISSING",
      "The host router is missing the Accrue webhook mount.",
      "Mount `accrue_webhook \"/stripe\", :stripe` inside the webhook scope or rerun `mix accrue.install --check`.",
      @webhook_route_missing_anchor,
      Keyword.get(opts, :details)
    )
  end

  @spec webhook_raw_body(keyword()) :: t()
  def webhook_raw_body(opts \\ []) do
    build(
      "ACCRUE-DX-WEBHOOK-RAW-BODY",
      "The webhook request did not include the preserved raw request body.",
      "Use `Accrue.Webhook.CachingBodyReader` in a route-scoped `Plug.Parsers` pipeline before the webhook mount.",
      @webhook_raw_body_anchor,
      Keyword.get(opts, :details)
    )
  end

  @spec webhook_pipeline(keyword()) :: t()
  def webhook_pipeline(opts \\ []) do
    build(
      "ACCRUE-DX-WEBHOOK-PIPELINE",
      "The webhook route is running behind a browser, CSRF, or auth-oriented pipeline.",
      "Move the webhook route into a dedicated raw-body pipeline that only parses JSON and preserves the raw bytes.",
      @webhook_pipeline_anchor,
      Keyword.get(opts, :details)
    )
  end

  @spec auth_adapter(keyword()) :: t()
  def auth_adapter(opts \\ []) do
    build(
      "ACCRUE-DX-AUTH-ADAPTER",
      "The default Accrue auth adapter is active where a real host adapter is required.",
      "Configure `config :accrue, :auth_adapter, MyApp.Auth` or a supported integration before production use.",
      @auth_adapter_anchor,
      Keyword.get(opts, :details)
    )
  end

  @spec admin_mount_missing(keyword()) :: t()
  def admin_mount_missing(opts \\ []) do
    build(
      "ACCRUE-DX-ADMIN-MOUNT-MISSING",
      "The host router is missing the Accrue admin mount.",
      "Mount `accrue_admin \"/billing\"` and protect it with the host admin/auth boundary.",
      @admin_mount_missing_anchor,
      Keyword.get(opts, :details)
    )
  end

  @spec format(t()) :: String.t()
  def format(%__MODULE__{} = diagnostic) do
    [
      diagnostic.code,
      diagnostic.summary,
      "Fix: " <> diagnostic.fix,
      "Docs: " <> diagnostic.docs_path,
      format_details(diagnostic.details)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
    |> redact()
  end

  @spec redact(term()) :: String.t()
  def redact(value) do
    value = stringify(value)

    Enum.reduce(secret_patterns(), value, fn {pattern, replacement}, acc ->
      String.replace(acc, pattern, replacement)
    end)
  end

  # Regex literals cannot live in module attributes on all OTP/Elixir pairs (OTP 28
  # rejects injecting the compiled #Reference into escaped attribute storage).
  defp secret_patterns do
    [
      {~r/sk_(test|live)_[A-Za-z0-9_=-]+/, "sk_\\1_[REDACTED]"},
      {~r/whsec_[A-Za-z0-9_=-]+/, "whsec_[REDACTED]"},
      {~r/([A-Z0-9_]*(?:SECRET|KEY)[A-Z0-9_]*=)[^\s,}]+/, "\\1[REDACTED]"}
    ]
  end

  defp build(code, summary, fix, docs_path, details) do
    %__MODULE__{code: code, summary: summary, fix: fix, docs_path: docs_path, details: details}
  end

  defp format_details(nil), do: nil
  defp format_details(details), do: "Details: " <> redact(details)

  defp stringify(value) when is_binary(value), do: value
  defp stringify(value), do: inspect(value, pretty: true, limit: :infinity)
end
