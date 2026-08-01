defmodule Accrue.Entitlements.Source.Registry do
  @moduledoc "Deterministic entitlement-source inspection registry; intentionally processor-free."

  alias Accrue.Entitlements.Source
  alias Accrue.Entitlements.Source.{CapabilityError, Outcome}

  @sources [:stripe, :apple, :host_fake]
  @apple_url "https://apps.apple.com/account/subscriptions"

  @spec sources() :: [Source.source()]
  def sources, do: @sources

  @spec capabilities() :: [Source.capability()]
  def capabilities, do: Source.capabilities()

  @spec validate(term()) :: {:ok, [Source.source()]} | {:error, CapabilityError.t()}
  def validate(sources) when is_list(sources) and sources != [] do
    if Enum.all?(sources, &(&1 in @sources)) and length(sources) == length(Enum.uniq(sources)) do
      {:ok, sources}
    else
      invalid_registry_error()
    end
  end

  def validate(_sources), do: invalid_registry_error()

  @spec inspect(Source.source()) :: {:ok, [Outcome.t()]} | {:error, CapabilityError.t()}
  def inspect(source) when source in @sources do
    {:ok,
     Enum.map(capabilities(), fn capability ->
       inspection_outcome(source, capability)
     end)}
  end

  def inspect(source), do: unknown_source_error(source)

  @spec outcome(Source.source(), Source.capability()) ::
          {:ok, Outcome.t()} | {:error, CapabilityError.t()}
  def outcome(source, capability) when source in @sources do
    if capability in Source.capabilities() do
      case declaration(source, capability) do
        {:ok, state, guidance} ->
          {:ok,
           %Outcome{source: source, capability: capability, state: state, guidance: guidance}}

        {:error, code, next_action} ->
          {:error,
           %CapabilityError{
             source: source,
             capability: capability,
             code: code,
             next_action: next_action
           }}
      end
    else
      {:error,
       %CapabilityError{
         source: source,
         capability: capability,
         code: :unknown_capability,
         next_action: :inspect_source_contract
       }}
    end
  end

  def outcome(source, capability) when source not in @sources,
    do: unknown_source_error(source, capability)

  defp declaration(:apple, :management),
    do:
      {:ok, :externally_managed,
       guidance(
         :manage_apple_subscription,
         "Manage this subscription in Apple.",
         "Manage subscription",
         @apple_url
       )}

  defp declaration(:apple, :control), do: {:error, :operation_unavailable, :manage_in_apple}

  defp declaration(:apple, :offline),
    do:
      {:ok, :feasibility_blocked,
       guidance(
         :apple_offline_feasibility,
         "Offline entitlement issuance needs the later Apple feasibility proof.",
         "Review feasibility"
       )}

  defp declaration(:apple, capability)
       when capability in [:observation, :restore, :reconciliation],
       do:
         {:ok, :supported,
          guidance(
            :apple_server_evidence,
            "Use verified Apple evidence for this operation.",
            "Review Apple evidence"
          )}

  defp declaration(:stripe, _capability),
    do:
      {:ok, :supported,
       guidance(
         :stripe_source_inspection,
         "This capability is available from the Stripe entitlement source.",
         "Review source contract"
       )}

  defp declaration(:host_fake, :management),
    do:
      {:ok, :host_owned,
       guidance(
         :host_fake_management,
         "Your host owns this proof-rail operation.",
         "Review host configuration"
       )}

  defp declaration(:host_fake, _capability),
    do:
      {:ok, :supported,
       guidance(
         :host_fake_source_inspection,
         "This capability is available in the deterministic host proof rail.",
         "Review source contract"
       )}

  defp inspection_outcome(:apple, :control) do
    %Outcome{
      source: :apple,
      capability: :control,
      state: :unavailable,
      guidance:
        guidance(
          :manage_apple_subscription,
          "Apple manages subscription changes.",
          "Manage subscription",
          @apple_url
        )
    }
  end

  defp inspection_outcome(source, capability) do
    {:ok, state, guidance} = declaration(source, capability)
    %Outcome{source: source, capability: capability, state: state, guidance: guidance}
  end

  defp guidance(key, text, action_label, url \\ nil) do
    %{key: key, text: text, action_label: action_label} |> maybe_put_url(url)
  end

  defp maybe_put_url(guidance, nil), do: guidance
  defp maybe_put_url(guidance, url), do: Map.put(guidance, :url, url)

  defp invalid_registry_error,
    do:
      {:error,
       %CapabilityError{
         source: nil,
         capability: nil,
         code: :invalid_source_registry,
         next_action: :configure_distinct_known_sources
       }}

  defp unknown_source_error(source, capability \\ nil),
    do:
      {:error,
       %CapabilityError{
         source: source,
         capability: capability,
         code: :unknown_source,
         next_action: :inspect_source_contract
       }}
end
