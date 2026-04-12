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
  # Customer — update (D2-07, D2-09)
  # ---------------------------------------------------------------------------

  @doc """
  Updates a `Customer` with the given attributes.

  Uses `Ecto.Multi` to atomically update the customer and record a
  `"customer.updated"` event (EVT-04). Metadata is validated per D2-07
  (flat string map, max 50 keys, etc.). Optimistic locking via
  `lock_version` prevents torn writes (D2-09).

  ## Examples

      {:ok, customer} = Accrue.Billing.update_customer(customer, %{metadata: %{"tier" => "pro"}})
  """
  @spec update_customer(%Customer{}, map()) :: {:ok, Customer.t()} | {:error, term()}
  def update_customer(%Customer{} = customer, attrs) when is_map(attrs) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:customer, Customer.changeset(customer, attrs))
      |> Ecto.Multi.run(:event, fn _repo, %{customer: updated} ->
        Events.record(%{
          type: "customer.updated",
          subject_type: "Customer",
          subject_id: updated.id,
          data: %{changes: Map.take(attrs, [:metadata, :name, :email, "metadata", "name", "email"])}
        })
      end)

    case Repo.transaction(multi) do
      {:ok, %{customer: customer}} -> {:ok, customer}
      {:error, :customer, changeset, _changes} -> {:error, changeset}
      {:error, :event, reason, _changes} -> {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # Data operations (D2-08)
  # ---------------------------------------------------------------------------

  @doc """
  Fully replaces the `data` jsonb column on a billing record (D2-08).

  Used by webhook reconcile paths that receive the whole object (e.g.
  `customer.updated`). Applies optimistic locking via `lock_version`.

  ## Examples

      {:ok, updated} = Accrue.Billing.put_data(customer, %{"balance" => 0})
  """
  @spec put_data(Ecto.Schema.t(), map()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def put_data(%{__struct__: _schema} = record, new_data) when is_map(new_data) do
    record
    |> Ecto.Changeset.change(data: new_data)
    |> Ecto.Changeset.optimistic_lock(:lock_version)
    |> Repo.update()
  end

  @doc """
  Shallow-merges `partial_data` into the existing `data` column (D2-08).

  Used when a partial event carries only a delta. Applies optimistic
  locking via `lock_version`.

  ## Examples

      {:ok, patched} = Accrue.Billing.patch_data(customer, %{"balance" => 100})
  """
  @spec patch_data(Ecto.Schema.t(), map()) :: {:ok, Ecto.Schema.t()} | {:error, term()}
  def patch_data(%{__struct__: _schema} = record, partial_data) when is_map(partial_data) do
    merged = Map.merge(record.data || %{}, partial_data)
    put_data(record, merged)
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
