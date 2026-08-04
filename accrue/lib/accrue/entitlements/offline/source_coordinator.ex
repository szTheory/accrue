defmodule Accrue.Entitlements.Offline.SourceCoordinator do
  @moduledoc false

  alias Accrue.Entitlements.Source.Registry

  defmodule SourceStatus do
    @enforce_keys [:source, :environment, :due, :state, :next_action]
    defstruct [:source, :environment, :due, :state, :retry_after, :next_action]
  end

  @type state :: :resolved | :pending | :needs_repair
  @callback due_sources(Accrue.Entitlements.Account.t(), DateTime.t(), keyword()) ::
              {:ok, [SourceStatus.t()]} | {:error, atom()}
  @callback refresh(Accrue.Entitlements.Account.t(), SourceStatus.t(), DateTime.t(), keyword()) ::
              {:ok, SourceStatus.t()} | {:error, atom()}
  @callback enqueue_repair(
              Accrue.Entitlements.Account.t(),
              SourceStatus.t(),
              DateTime.t(),
              keyword()
            ) ::
              :ok | {:error, atom()}

  @spec validate([SourceStatus.t()]) :: :ok | {:error, :invalid_source_status}
  def validate(statuses) when is_list(statuses) do
    with {:ok, _} <- Registry.validate(Enum.map(statuses, & &1.source)),
         true <- Enum.all?(statuses, &valid_status?/1),
         do: :ok,
         else: (_ -> {:error, :invalid_source_status})
  end

  def validate(_), do: {:error, :invalid_source_status}

  defp valid_status?(%SourceStatus{
         source: source,
         environment: environment,
         due: due,
         state: state,
         next_action: action
       }) do
    source in Registry.sources() and environment in [:production, :sandbox] and is_boolean(due) and
      state in [:resolved, :pending, :needs_repair] and is_atom(action)
  end

  defp valid_status?(_), do: false
end
