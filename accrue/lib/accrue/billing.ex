defmodule Accrue.Billing do
  @moduledoc """
  Primary context module for Accrue billing operations.

  All write operations for billable entities live here, following
  Phoenix context conventions (D2-05). Host schemas gain access to
  these operations via `use Accrue.Billable`, which injects a
  convenience `customer/1` that delegates here.

  ## Customer lifecycle

    * `customer/1` — lazy fetch-or-create (D2-06). First call
      auto-creates an `accrue_customers` row via the configured
      processor; subsequent calls return the cached row.
    * `create_customer/1` — explicit create, always hits the processor.
    * `customer!/1` and `create_customer!/1` — raising variants per
      Phase 1 D-05 dual API pattern.

  All writes use `Ecto.Multi` to ensure the customer row and the
  corresponding `accrue_events` entry are committed atomically
  (EVT-04 invariant).
  """

  alias Accrue.Billing.Customer
  alias Accrue.Events
  alias Accrue.Processor
  alias Accrue.Repo

  import Ecto.Query, only: [from: 2]

  # ---------------------------------------------------------------------------
  # Customer — lazy fetch-or-create (D2-06)
  # ---------------------------------------------------------------------------

  @doc """
  Lazily fetches or creates a `Customer` for the given billable struct.

  If a customer row already exists for the billable's `owner_type` and
  `owner_id`, returns it. Otherwise, creates one via the configured
  processor and persists it atomically with an event record.

  ## Examples

      {:ok, customer} = Accrue.Billing.customer(user)
      {:ok, ^customer} = Accrue.Billing.customer(user)  # same row
  """
  @spec customer(struct()) :: {:ok, Customer.t()} | {:error, term()}
  def customer(%{__struct__: mod, id: id} = billable) do
    billable_type = mod.__accrue__(:billable_type)
    owner_id = to_string(id)

    query =
      from(c in Customer,
        where: c.owner_type == ^billable_type and c.owner_id == ^owner_id,
        limit: 1
      )

    case Repo.one(query) do
      %Customer{} = existing -> {:ok, existing}
      nil -> create_customer(billable)
    end
  end

  @doc """
  Raising variant of `customer/1`. Returns the `Customer` directly or
  raises on error.
  """
  @spec customer!(struct()) :: Customer.t()
  def customer!(billable) do
    case customer(billable) do
      {:ok, customer} -> customer
      {:error, reason} -> raise "Failed to fetch or create customer: #{inspect(reason)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Customer — explicit create (D2-05)
  # ---------------------------------------------------------------------------

  @doc """
  Explicitly creates a `Customer` for the given billable struct.

  Uses `Ecto.Multi` to atomically:

    1. Create the customer on the processor side (Fake or Stripe)
    2. Insert the `accrue_customers` row with the processor-assigned ID
    3. Record a `"customer.created"` event (EVT-04)

  Returns `{:ok, %Customer{}}` on success or `{:error, reason}` on
  failure. The entire transaction rolls back if any step fails.

  ## Examples

      {:ok, customer} = Accrue.Billing.create_customer(user)
      customer.processor_id  #=> "cus_fake_00001"
  """
  @spec create_customer(struct()) :: {:ok, Customer.t()} | {:error, term()}
  def create_customer(%{__struct__: mod, id: id} = billable) do
    billable_type = mod.__accrue__(:billable_type)
    owner_id = to_string(id)
    processor_name = processor_name()

    params = build_processor_params(billable)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:processor, fn _repo, _changes ->
        Processor.create_customer(params)
      end)
      |> Ecto.Multi.insert(:customer, fn %{processor: processor_result} ->
        Customer.changeset(%Customer{}, %{
          owner_type: billable_type,
          owner_id: owner_id,
          processor: processor_name,
          processor_id: Map.get(processor_result, :id),
          name: Map.get(processor_result, :name),
          email: Map.get(processor_result, :email),
          metadata: Map.get(processor_result, :metadata, %{}),
          data: processor_result
        })
      end)
      |> Ecto.Multi.run(:event, fn _repo, %{customer: customer} ->
        Events.record(%{
          type: "customer.created",
          subject_type: "Customer",
          subject_id: customer.id,
          data: %{
            owner_type: billable_type,
            owner_id: owner_id,
            processor: processor_name,
            processor_id: customer.processor_id
          }
        })
      end)

    case Repo.transaction(multi) do
      {:ok, %{customer: customer}} -> {:ok, customer}
      {:error, :processor, reason, _changes} -> {:error, reason}
      {:error, :customer, changeset, _changes} -> {:error, changeset}
      {:error, :event, reason, _changes} -> {:error, reason}
    end
  end

  @doc """
  Raising variant of `create_customer/1`. Returns the `Customer`
  directly or raises on error.
  """
  @spec create_customer!(struct()) :: Customer.t()
  def create_customer!(billable) do
    case create_customer(billable) do
      {:ok, customer} -> customer
      {:error, reason} -> raise "Failed to create customer: #{inspect(reason)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  defp processor_name do
    adapter = Processor.__impl__()

    case adapter do
      Accrue.Processor.Fake -> "fake"
      Accrue.Processor.Stripe -> "stripe"
      other -> other |> Module.split() |> List.last() |> String.downcase()
    end
  end

  defp build_processor_params(%{__struct__: _mod} = billable) do
    params = %{}

    params =
      if function_exported?(billable.__struct__, :__schema__, 1) do
        fields = billable.__struct__.__schema__(:fields)

        params
        |> maybe_put(:name, billable, fields)
        |> maybe_put(:email, billable, fields)
      else
        params
      end

    params
  end

  defp maybe_put(params, field, struct, fields) do
    if field in fields do
      case Map.get(struct, field) do
        nil -> params
        value -> Map.put(params, field, value)
      end
    else
      params
    end
  end
end
