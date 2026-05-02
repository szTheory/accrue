defmodule AccruePortal.Fixtures do
  @moduledoc false

  alias Accrue.Billing.{Customer, Invoice, PaymentMethod, Subscription}
  alias Accrue.Test.Factory
  alias AccruePortal.TestRepo

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable

    @primary_key {:id, :binary_id, autogenerate: false}
    schema "portal_test_users" do
    end
  end

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"user_token" => "customer:" <> user_id}) do
      %AccruePortal.Fixtures.TestUser{id: user_id}
    end

    def current_user(_session), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(%{id: id}), do: id
  end

  @spec dashboard_fixture!() :: map()
  def dashboard_fixture! do
    current = subscription_bundle_fixture!()

    payment_method =
      payment_method_fixture!(current.customer, %{
        processor_id: "pm_current_dashboard",
        card_brand: "visa",
        card_last4: "4242",
        card_exp_month: 12,
        card_exp_year: 2030,
        exp_month: 12,
        exp_year: 2030,
        is_default: true
      })

    invoice =
      invoice_fixture!(current.customer, current.subscription, %{
        processor_id: "in_current_dashboard",
        status: :open,
        total_minor: 4_900,
        amount_due_minor: 4_900,
        amount_remaining_minor: 4_900,
        number: "INV-CURRENT-001"
      })

    foreign = subscription_bundle_fixture!()

    foreign_payment_method =
      payment_method_fixture!(foreign.customer, %{
        processor_id: "pm_foreign_dashboard",
        card_brand: "mastercard",
        card_last4: "4444",
        card_exp_month: 1,
        card_exp_year: 2031,
        exp_month: 1,
        exp_year: 2031
      })

    foreign_invoice =
      invoice_fixture!(foreign.customer, foreign.subscription, %{
        processor_id: "in_foreign_dashboard",
        status: :open,
        total_minor: 9_900,
        amount_due_minor: 9_900,
        amount_paid_minor: 0,
        amount_remaining_minor: 9_900,
        number: "INV-FOREIGN-001"
      })

    Map.merge(current, %{
      payment_method: payment_method,
      invoice: invoice,
      foreign_user: foreign.user,
      foreign_customer: foreign.customer,
      foreign_subscription: foreign.subscription,
      foreign_payment_method: foreign_payment_method,
      foreign_invoice: foreign_invoice
    })
  end

  @spec subscription_bundle_fixture!(map()) :: map()
  def subscription_bundle_fixture!(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    user = user_fixture(Map.get(attrs, :user_attrs, %{}))

    %{customer: customer, subscription: subscription} =
      Factory.active_subscription(%{
        owner_type: TestUser.__accrue__(:billable_type),
        owner_id: user.id,
        email: Map.get(attrs, :email, "portal-#{user.id}@example.com"),
        name: Map.get(attrs, :name, "Portal #{String.slice(user.id, 0, 8)}")
      })

    %{user: user, customer: customer, subscription: subscription}
  end

  @spec foreign_subscription_fixture!(non_neg_integer()) :: map()
  def foreign_subscription_fixture!(index) when is_integer(index) and index >= 0 do
    foreign = subscription_bundle_fixture!(%{email: "wrong-tenant-#{index}@example.com"})
    subscription = read_only_subscription_fixture!(foreign.customer, %{index: index})
    %{user: foreign.user, customer: foreign.customer, subscription: subscription}
  end

  @spec user_fixture(map()) :: TestUser.t()
  def user_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    struct!(TestUser, Map.merge(%{id: Ecto.UUID.generate()}, attrs))
  end

  @spec payment_method_fixture!(Customer.t(), map()) :: PaymentMethod.t()
  def payment_method_fixture!(%Customer{} = customer, attrs \\ %{}) do
    defaults = %{
      customer_id: customer.id,
      processor: customer.processor || "fake",
      processor_id: "pm_" <> Integer.to_string(System.unique_integer([:positive])),
      type: "card",
      is_default: false,
      fingerprint: Ecto.UUID.generate(),
      metadata: %{},
      data: %{}
    }

    %PaymentMethod{}
    |> PaymentMethod.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  @spec invoice_fixture!(Customer.t(), Subscription.t(), map()) :: Invoice.t()
  def invoice_fixture!(%Customer{} = customer, %Subscription{} = subscription, attrs \\ %{}) do
    defaults = %{
      customer_id: customer.id,
      subscription_id: subscription.id,
      processor: customer.processor || "fake",
      processor_id: "in_" <> Integer.to_string(System.unique_integer([:positive])),
      status: :open,
      currency: "usd",
      collection_method: "charge_automatically",
      total_minor: 0,
      amount_due_minor: 0,
      amount_paid_minor: 0,
      amount_remaining_minor: 0,
      subtotal_minor: 0,
      tax_minor: 0,
      total_discount_amounts: %{},
      metadata: %{},
      data: %{}
    }

    %Invoice{}
    |> Invoice.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  @spec read_only_subscription_fixture!(Customer.t(), map()) :: Subscription.t()
  def read_only_subscription_fixture!(%Customer{} = customer, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    index = Map.get(attrs, :index, System.unique_integer([:positive]))

    defaults = %{
      customer_id: customer.id,
      processor: customer.processor || "fake",
      processor_id: "sub_read_only_" <> Integer.to_string(index),
      status: :active,
      current_period_start: DateTime.add(DateTime.utc_now(), -86_400, :second),
      current_period_end: DateTime.add(DateTime.utc_now(), 2_592_000, :second),
      cancel_at_period_end: false,
      metadata: %{},
      data: %{}
    }

    %Subscription{}
    |> Subscription.changeset(Map.merge(defaults, Map.drop(attrs, [:index])))
    |> TestRepo.insert!()
  end

  @spec sign_in_conn(Plug.Conn.t(), TestUser.t()) :: Plug.Conn.t()
  def sign_in_conn(conn, %TestUser{id: id}) do
    Plug.Test.init_test_session(conn, %{"user_token" => "customer:" <> id})
  end
end
