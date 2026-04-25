defmodule Accrue.Mailer do
  @moduledoc """
  Behaviour + facade for the Accrue transactional email pipeline.

  ## Semantic API

  Callers invoke `Accrue.Mailer.deliver/2` with an email **type atom** and a
  plain **assigns map**. The configured adapter (`Accrue.Mailer.Default` by
  default) is responsible for turning the type + assigns into a rendered email
  and delivering it. Callers never construct a `%Swoosh.Email{}` directly —
  that is the adapter's job, keeping call sites decoupled from the email
  rendering pipeline.

  ## Per-type kill switch

  Set `config :accrue, :emails, [<type>: false]` to disable a specific
  transactional email type. When a type is disabled, `deliver/2` returns
  `{:ok, :skipped}` immediately without enqueueing a job or rendering
  anything. The `:emails` config schema is defined by `Accrue.Config`.

  ## Telemetry

  Every `deliver/2` call emits `[:accrue, :mailer, :deliver, :start | :stop |
  :exception]` with `%{email_type: atom, customer_id: binary | nil}` metadata.
  Raw assigns and rendered email bodies are NEVER placed in metadata — they
  may carry PII.
  """

  @type email_type :: atom()
  @type assigns :: map()

  @callback deliver(email_type(), assigns()) :: {:ok, term()} | {:error, term()}

  @doc """
  Delivers a transactional email by type + assigns. Delegates to the
  configured adapter (default `Accrue.Mailer.Default`).

  Returns `{:ok, :skipped}` when the email type is disabled via the
  `:emails` kill switch. Otherwise returns whatever the adapter returns
  (typically `{:ok, %Oban.Job{}}` for async enqueue).
  """
  @spec deliver(email_type(), assigns()) :: {:ok, term()} | {:error, term()}
  def deliver(type, assigns) when is_atom(type) and is_map(assigns) do
    metadata = %{email_type: type, customer_id: assigns[:customer_id] || assigns["customer_id"]}

    Accrue.Telemetry.span([:accrue, :mailer, :deliver], metadata, fn ->
      if enabled?(type) do
        impl().deliver(type, assigns)
      else
        {:ok, :skipped}
      end
    end)
  end

  @doc """
  Returns `true` if the given email type is not disabled via the
  `:emails` kill switch.
  """
  @spec enabled?(email_type()) :: boolean()
  def enabled?(type) when is_atom(type) do
    case Keyword.fetch(Application.get_env(:accrue, :emails, []), type) do
      {:ok, false} -> false
      _ -> true
    end
  end

  @doc false
  def impl, do: Application.get_env(:accrue, :mailer, Accrue.Mailer.Default)
end
