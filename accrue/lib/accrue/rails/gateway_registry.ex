defmodule Accrue.Rails.GatewayRegistry do
  @moduledoc """
  Closed dispatch boundary for already-persisted gateway resources.

  Creation deliberately remains configured-processor driven.  A resource which
  already exists, however, must always use the processor recorded with that
  resource so a concurrent configuration change cannot redirect a mutation.
  """

  defmodule Error do
    @moduledoc "Typed, stable failure returned when persisted gateway provenance is unusable."
    @enforce_keys [:processor, :code, :next_action]
    defstruct [:processor, :code, :next_action]

    @type t :: %__MODULE__{
            processor: String.t() | atom() | nil,
            code: :missing_processor | :unknown_processor,
            next_action: :inspect_resource_provenance
          }
  end

  @adapters %{
    "fake" => Accrue.Processor.Fake,
    "stripe" => Accrue.Processor.Stripe,
    "braintree" => Accrue.Processor.Braintree
  }

  @spec resolve(String.t() | atom() | nil) :: {:ok, module()} | {:error, Error.t()}
  def resolve(nil), do: missing_processor_error(nil)
  def resolve(""), do: missing_processor_error("")

  def resolve(processor) when is_atom(processor), do: resolve(Atom.to_string(processor))

  def resolve(processor) when is_binary(processor) do
    case Map.fetch(@adapters, String.downcase(processor)) do
      {:ok, adapter} -> {:ok, adapter}
      :error -> unknown_processor_error(processor)
    end
  end

  def resolve(processor), do: unknown_processor_error(processor)

  defp missing_processor_error(processor) do
    {:error,
     %Error{
       processor: processor,
       code: :missing_processor,
       next_action: :inspect_resource_provenance
     }}
  end

  defp unknown_processor_error(processor) do
    {:error,
     %Error{
       processor: processor,
       code: :unknown_processor,
       next_action: :inspect_resource_provenance
     }}
  end
end
