defmodule Accrue.Entitlements.Apple.Client do
  @moduledoc false

  @callback subscription_statuses(binary(), :production | :sandbox, keyword()) ::
              {:ok, [map()]} | {:error, term()}
  @callback transaction_history(binary(), map(), String.t() | nil, keyword()) ::
              {:ok, map()} | {:error, term()}
  @callback notification_history(map(), :production | :sandbox, keyword()) ::
              {:ok, map()} | {:error, term()}
  @callback set_app_account_token(binary(), binary(), :production | :sandbox, keyword()) ::
              :ok | {:error, term()}

  # The Fake is deliberately value based: every scripted history response is addressed by
  # the prior revision, so a replay cannot accidentally consume a different page.
  defmodule Fake do
    @moduledoc false
    defstruct statuses: [], history: [], notification_history: [], token_result: :ok
    def new(opts \\ []), do: struct(__MODULE__, opts)
  end

  def subscription_statuses(%Fake{statuses: [result | _]}, _lineage, _environment), do: result
  def subscription_statuses(%Fake{}, _lineage, _environment), do: {:ok, []}
  def subscription_statuses(_client, _lineage, _environment), do: {:error, :config_invalid}

  def transaction_history(%Fake{history: pages}, _lineage, _filters, revision) do
    pages
    |> Enum.find(fn
      {:ok, %{revision: next_revision}} -> prior_revision(next_revision, pages) == revision
      _ -> revision == nil
    end)
    |> case do
      nil -> {:ok, %{signed_transactions: [], revision: revision, has_more: false}}
      result -> result
    end
  end

  def transaction_history(_client, _lineage, _filters, _revision), do: {:error, :config_invalid}

  def notification_history(%Fake{notification_history: [result | _]}, _filters, _environment),
    do: result

  def notification_history(%Fake{}, _filters, _environment), do: {:ok, %{notifications: []}}
  def notification_history(_client, _filters, _environment), do: {:error, :config_invalid}

  def set_app_account_token(%Fake{token_result: result}, _lineage, _token, _environment),
    do: result

  def set_app_account_token(_client, _lineage, _token, _environment),
    do: {:error, :config_invalid}

  # Production transport belongs to the host. Calling this adapter without a host-supplied
  # client is configuration failure, never a silent network request or grant.
  defp prior_revision(next_revision, pages) do
    pages
    |> Enum.take_while(fn
      {:ok, %{revision: revision}} -> revision != next_revision
      _ -> true
    end)
    |> List.last()
    |> case do
      {:ok, %{revision: revision}} -> revision
      _ -> nil
    end
  end
end
