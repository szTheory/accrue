defmodule Accrue.Checkout.LocalSession do
  @moduledoc """
  Persisted local checkout sessions used by processors that route checkout
  through a first-party Accrue portal.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Accrue.Billing.Customer
  alias Accrue.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "accrue_checkout_sessions" do
    belongs_to(:customer, Customer)

    field(:processor, :string)
    field(:session_token, :string)
    field(:mode, :string)
    field(:ui_mode, :string)
    field(:status, :string, default: "open")
    field(:price_id, :string)
    field(:line_items, {:array, :map}, default: [])
    field(:success_url, :string)
    field(:cancel_url, :string)
    field(:return_url, :string)
    field(:operation_id, :string)
    field(:expires_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})
    field(:data, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    customer_id processor session_token mode ui_mode status
    price_id line_items success_url cancel_url return_url
    operation_id expires_at metadata data
  ]a

  @required_fields ~w[
    customer_id processor session_token mode ui_mode
    status price_id
  ]a

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(session, attrs \\ %{}) do
    session
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:customer_id)
    |> unique_constraint(:session_token)
    |> unique_constraint(:operation_id)
  end

  @spec create_or_reuse(Customer.t(), map()) :: {:ok, t()} | {:error, term()}
  def create_or_reuse(%Customer{} = customer, attrs) when is_map(attrs) do
    case Map.get(attrs, :operation_id) || Map.get(attrs, "operation_id") do
      op_id when is_binary(op_id) and op_id != "" ->
        case by_operation_id(customer, op_id) do
          %__MODULE__{} = existing -> {:ok, existing}
          nil -> insert_session(customer, attrs)
        end

      _ ->
        insert_session(customer, attrs)
    end
  end

  @spec by_id(String.t()) :: t() | nil
  def by_id(id) when is_binary(id), do: Repo.get(__MODULE__, id)

  @spec by_token(String.t()) :: t() | nil
  def by_token(token) when is_binary(token) do
    Repo.get_by(__MODULE__, session_token: token)
  end

  @spec mark_completed(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def mark_completed(%__MODULE__{} = session) do
    session
    |> changeset(%{status: "completed"})
    |> Repo.update()
  end

  defp by_operation_id(%Customer{id: customer_id}, operation_id) do
    Repo.one(
      from(session in __MODULE__,
        where: session.customer_id == ^customer_id and session.operation_id == ^operation_id,
        limit: 1
      )
    )
  end

  defp insert_session(%Customer{} = customer, attrs) do
    payload =
      attrs
      |> Map.new()
      |> Map.put(:customer_id, customer.id)
      |> Map.put_new(:session_token, generate_token())
      |> Map.put_new(:status, "open")
      |> Map.put_new(:expires_at, DateTime.add(DateTime.utc_now(), 1_800, :second))

    %__MODULE__{}
    |> changeset(payload)
    |> Repo.insert()
  end

  defp generate_token do
    "chk_local_" <> Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)
  end
end
