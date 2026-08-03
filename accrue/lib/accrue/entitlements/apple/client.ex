defmodule Accrue.Entitlements.Apple.Client do
  @moduledoc false

  @callback subscription_statuses(term(), binary(), :production | :sandbox) ::
              {:ok, [map()]} | {:error, term()}
  @callback transaction_history(term(), binary(), map(), String.t() | nil, :production | :sandbox) ::
              {:ok, map()} | {:error, term()}
  @callback notification_history(term(), map(), :production | :sandbox) ::
              {:ok, map()} | {:error, term()}
  @callback set_app_account_token(term(), binary(), binary(), :production | :sandbox) ::
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

  def subscription_statuses(%{__struct__: module} = client, lineage, environment)
      when module != Fake, do: module.subscription_statuses(client, lineage, environment)

  def subscription_statuses(module, lineage, environment) when is_atom(module),
    do: module.subscription_statuses(nil, lineage, environment)

  def subscription_statuses(_, _, _), do: {:error, :config_invalid}

  def transaction_history(%Fake{history: pages}, _lineage, _filters, revision, _environment) do
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

  def transaction_history(%{__struct__: module} = client, lineage, filters, revision, environment)
      when module != Fake,
      do: module.transaction_history(client, lineage, filters, revision, environment)

  def transaction_history(module, lineage, filters, revision, environment) when is_atom(module),
    do: module.transaction_history(nil, lineage, filters, revision, environment)

  def transaction_history(_, _, _, _, _), do: {:error, :config_invalid}

  def notification_history(%Fake{notification_history: [result | _]}, _filters, _environment),
    do: result

  def notification_history(%Fake{}, _filters, _environment), do: {:ok, %{notifications: []}}

  def notification_history(%{__struct__: module} = client, filters, environment)
      when module != Fake, do: module.notification_history(client, filters, environment)

  def notification_history(module, filters, environment) when is_atom(module),
    do: module.notification_history(nil, filters, environment)

  def notification_history(_, _, _), do: {:error, :config_invalid}

  def set_app_account_token(%Fake{token_result: result}, _lineage, _token, _environment),
    do: result

  def set_app_account_token(%{__struct__: module} = client, lineage, token, environment)
      when module != Fake, do: module.set_app_account_token(client, lineage, token, environment)

  def set_app_account_token(module, lineage, token, environment) when is_atom(module),
    do: module.set_app_account_token(nil, lineage, token, environment)

  def set_app_account_token(_, _, _, _), do: {:error, :config_invalid}

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

defmodule Accrue.Entitlements.Apple.Client.Production do
  @moduledoc """
  Private App Store Server API adapter. It uses OTP's `:httpc`; hosts provide
  a short-lived bearer token, so Accrue neither adds an HTTP dependency nor
  retains Apple private keys.
  """
  @behaviour Accrue.Entitlements.Apple.Client

  @production_base_url "https://api.storekit.itunes.apple.com"
  @sandbox_base_url "https://api.storekit-sandbox.itunes.apple.com"
  # Apple may send an HTTP-date Retry-After. We intentionally use the bounded
  # default for date-form and malformed values because reconciliation needs a
  # deterministic delay without trusting provider wall-clock data.
  @default_retry_after_seconds 60
  @max_retry_after_seconds 6 * 60 * 60

  defstruct [
    :authorization,
    production_base_url: @production_base_url,
    sandbox_base_url: @sandbox_base_url,
    timeout: 15_000,
    transport: &:httpc.request/4
  ]

  def new(opts), do: struct!(__MODULE__, opts)

  @impl true
  def subscription_statuses(%__MODULE__{} = client, lineage, environment),
    do: get(client, environment, "/inApps/v1/subscriptions/#{URI.encode(lineage)}", [], &statuses/1)

  @impl true
  def transaction_history(%__MODULE__{} = client, lineage, filters, revision, environment) do
    query =
      filters
      |> Map.take([:sort, :product_types])
      |> Enum.flat_map(fn
        {:product_types, values} when is_list(values) -> Enum.map(values, &{"productType", &1})
        {key, value} -> [{Atom.to_string(key), value}]
      end)
      |> then(fn pairs -> if revision, do: [{"revision", revision} | pairs], else: pairs end)

    get(client, environment, "/inApps/v2/history/#{URI.encode(lineage)}", query, &history/1)
  end

  @impl true
  def notification_history(_, _, _), do: {:error, :unsupported}

  @impl true
  def set_app_account_token(_, _, _, _), do: {:error, :unsupported}

  defp get(%__MODULE__{authorization: authorization, transport: transport} = client, environment, path, query, decode)
       when is_binary(authorization) and byte_size(authorization) > 0 do
    url = base_url(client, environment) <> path <> if(query == [], do: "", else: "?" <> URI.encode_query(query))

    headers = [
      {~c"authorization", String.to_charlist("Bearer " <> authorization)},
      {~c"accept", ~c"application/json"}
    ]

    case transport.(:get, {String.to_charlist(url), headers}, [timeout: client.timeout],
           body_format: :binary
         ) do
      {:ok, {{_, 200, _}, _, body}} -> decode.(body)
      {:ok, {{_, 401, _}, _, _}} -> {:error, :unauthorized}
      {:ok, {{_, 429, _}, headers, _}} -> {:error, {:rate_limited, retry_after(headers)}}
      {:ok, {{_, status, _}, _, _}} when status >= 500 -> {:error, :provider_unavailable}
      {:ok, _} -> {:error, :provider_rejected}
      {:error, _} -> {:error, :provider_unavailable}
    end
  end

  defp get(_, _, _, _, _), do: {:error, :config_invalid}

  defp base_url(%__MODULE__{production_base_url: url}, :production) when is_binary(url), do: url
  defp base_url(%__MODULE__{sandbox_base_url: url}, :sandbox) when is_binary(url), do: url
  defp base_url(_, _), do: @production_base_url
  defp statuses(body), do: with({:ok, %{"data" => data}} <- Jason.decode(body), do: {:ok, data})

  defp history(body),
    do:
      with(
        {:ok, data} when is_map(data) <- Jason.decode(body),
        do:
          {:ok,
           %{
             signed_transactions: Map.get(data, "signedTransactions", []),
             revision: Map.get(data, "revision"),
             has_more: Map.get(data, "hasMore", false)
           }}
      )

  defp retry_after(headers),
    do:
      headers
      |> Enum.find_value(@default_retry_after_seconds, fn {key, value} ->
        if String.downcase(to_string(key)) == "retry-after",
          do: parse_retry_after(value)
      end)

  defp parse_retry_after(value) do
    case Integer.parse(to_string(value)) do
      {seconds, ""} when seconds >= 0 -> min(seconds, @max_retry_after_seconds)
      _ -> @default_retry_after_seconds
    end
  end
end
