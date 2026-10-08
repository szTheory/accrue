defmodule Accrue.Checkout.LocalSession do
  @moduledoc """
  Persisted local checkout sessions used by processors that route checkout
  through a first-party Accrue portal.
  """

  use Accrue.Schema

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

  @processors ["braintree"]

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(session, attrs \\ %{}) do
    session
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:processor, @processors, message: "must be braintree")
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
          nil -> insert_or_reuse_after_conflict(customer, attrs, op_id)
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

  @doc "Looks up one Braintree checkout operation within the supplied Customer boundary."
  @spec for_customer_operation(Customer.t(), String.t()) :: t() | nil
  def for_customer_operation(%Customer{id: customer_id}, operation_id)
      when is_binary(operation_id) and byte_size(operation_id) > 0 and
             byte_size(operation_id) <= 255 do
    Repo.one(
      from(session in __MODULE__,
        where:
          session.customer_id == ^customer_id and session.processor == "braintree" and
            session.operation_id == ^operation_id,
        limit: 1
      )
    )
  end

  def for_customer_operation(_, _), do: nil

  @doc "Whether a persisted checkout may be acted on at the supplied instant."
  @spec actionable?(t(), DateTime.t()) :: boolean()
  def actionable?(
        %__MODULE__{status: "open", expires_at: %DateTime{} = expires_at},
        %DateTime{} = now
      ),
      do: DateTime.compare(expires_at, now) == :gt

  def actionable?(%__MODULE__{}, %DateTime{}), do: false

  @spec mark_completed(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def mark_completed(%__MODULE__{} = session) do
    update_claimed_status(session, "completed")
  end

  @doc "Atomically claims an open, unexpired session for one provider operation."
  @spec claim(t(), DateTime.t()) :: {:ok, t()} | {:error, :unavailable}
  def claim(%__MODULE__{} = session, %DateTime{} = now) do
    query =
      from(checkout in __MODULE__,
        where:
          checkout.id == ^session.id and checkout.status == "open" and
            checkout.expires_at > ^now
      )

    case Repo.update_all(query, set: [status: "processing", updated_at: now]) do
      {1, _} -> {:ok, by_id(session.id)}
      _ -> {:error, :unavailable}
    end
  end

  @doc "Records a provider operation whose result is not yet authoritative."
  @spec mark_uncertain(t()) :: {:ok, t()} | {:error, term()}
  def mark_uncertain(%__MODULE__{} = session), do: update_claimed_status(session, "uncertain")

  @doc "Releases a claim only after a definite provider rejection."
  @spec release_claim(t()) :: {:ok, t()} | {:error, term()}
  def release_claim(%__MODULE__{} = session), do: update_claimed_status(session, "open")

  defp update_claimed_status(%__MODULE__{} = session, status) do
    query =
      from(checkout in __MODULE__,
        where: checkout.id == ^session.id and checkout.status == "processing"
      )

    case Repo.update_all(query, set: [status: status, updated_at: DateTime.utc_now()]) do
      {1, _} -> {:ok, by_id(session.id)}
      _ -> {:error, :not_claimed}
    end
  end

  defp by_operation_id(%Customer{id: customer_id}, operation_id) do
    Repo.one(
      from(session in __MODULE__,
        where: session.customer_id == ^customer_id and session.operation_id == ^operation_id,
        limit: 1
      )
    )
  end

  defp insert_or_reuse_after_conflict(%Customer{} = customer, attrs, operation_id) do
    case insert_session(customer, attrs) do
      {:ok, _session} = inserted ->
        inserted

      {:error, %Ecto.Changeset{errors: errors}} = error ->
        if Keyword.has_key?(errors, :operation_id) do
          case by_operation_id(customer, operation_id) do
            %__MODULE__{} = existing -> {:ok, existing}
            nil -> error
          end
        else
          error
        end
    end
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
