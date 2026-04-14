defmodule Accrue.Billing.MeterEvent do
  @moduledoc """
  Ecto schema for `accrue_meter_events` — the metered billing audit
  ledger and transactional outbox (D4-03).

  One row per `Accrue.Billing.report_usage/3` call. Lifecycle:

    * `pending` — inserted inside `Repo.transact/2`, committed before
      Stripe is ever called.
    * `reported` — set after a successful
      `LatticeStripe.Billing.MeterEvent.create/3` (or Fake equivalent).
      `reported_at` is stamped.
    * `failed` — set either synchronously (when the first Stripe call
      returns `{:error, _}`) or asynchronously (when Stripe emits a
      `v1.billing.meter.error_report_triggered` webhook).

  The partial index `accrue_meter_events_failed_idx` on
  `stripe_status = 'failed'` gives ops a free DLQ view.

  Only derived error shapes are stored in `stripe_error :map` — never
  the raw Stripe payload (threat model T-04-02-03).
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_meter_events" do
    belongs_to :customer, Accrue.Billing.Customer, type: :binary_id
    field :stripe_customer_id, :string
    field :event_name, :string
    field :value, :integer
    field :identifier, :string
    field :occurred_at, :utc_datetime_usec
    field :reported_at, :utc_datetime_usec
    field :stripe_status, :string, default: "pending"
    field :stripe_error, :map
    field :operation_id, :string

    timestamps(type: :utc_datetime_usec)
  end

  @pending_cast ~w[customer_id stripe_customer_id event_name value identifier occurred_at operation_id]a
  @pending_required ~w[stripe_customer_id event_name value identifier occurred_at]a

  @doc """
  Builds a changeset for inserting a `pending` meter-event row.
  """
  @spec pending_changeset(map()) :: Ecto.Changeset.t()
  def pending_changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> cast(attrs, @pending_cast)
    |> validate_required(@pending_required)
    |> validate_number(:value, greater_than_or_equal_to: 0)
    |> put_change(:stripe_status, "pending")
    |> unique_constraint(:identifier)
  end

  @doc """
  Flips a committed `pending` row to `reported`, stamping `reported_at`.
  The Stripe event struct is accepted for symmetry but no fields are
  pulled from it — the row already has everything we need.
  """
  @spec reported_changeset(t(), map()) :: Ecto.Changeset.t()
  def reported_changeset(%__MODULE__{} = row, _stripe_event) do
    change(row, %{
      stripe_status: "reported",
      reported_at: DateTime.utc_now(),
      stripe_error: nil
    })
  end

  @doc """
  Flips a row to `failed`, storing a sanitized error map in
  `stripe_error`. Never stores the raw Stripe payload.
  """
  @spec failed_changeset(t(), term()) :: Ecto.Changeset.t()
  def failed_changeset(%__MODULE__{} = row, err) do
    change(row, %{
      stripe_status: "failed",
      stripe_error: normalize_error(err)
    })
  end

  defp normalize_error(nil), do: %{}

  defp normalize_error(%{__struct__: struct} = s) do
    s
    |> Map.from_struct()
    |> normalize_error()
    |> Map.put("__struct__", inspect(struct))
  end

  defp normalize_error(m) when is_map(m) do
    for {k, v} <- m, into: %{}, do: {to_string(k), scalarize(v)}
  end

  defp normalize_error(other), do: %{"raw" => inspect(other)}

  defp scalarize(v) when is_binary(v) or is_number(v) or is_boolean(v) or is_nil(v), do: v
  defp scalarize(v) when is_atom(v), do: Atom.to_string(v)
  defp scalarize(v), do: inspect(v)
end
