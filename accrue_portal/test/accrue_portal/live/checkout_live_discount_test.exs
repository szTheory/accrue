defmodule AccruePortal.CheckoutLiveDiscountTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Checkout.LocalSession
  alias AccruePortal.BraintreeMox
  alias AccruePortal.TestRepo

  @discount_mappings_table Accrue.Migration.qualified_table(:accrue_discount_mappings)

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
    def current_user(%{"user_token" => "customer-token", "user_id" => user_id}) do
      %AccruePortal.CheckoutLiveDiscountTest.TestUser{id: user_id}
    end

    def current_user(_), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(%{id: id}), do: id
  end

  defmodule SubscriptionGatewayStub do
    def create(params, _opts) do
      if pid = Application.get_env(:accrue_portal, :checkout_discount_test_pid) do
        send(pid, {:gateway_create, params})
      end

      {:ok,
       struct!(Braintree.Subscription,
         id: "sub_bt_checkout_discount_123",
         plan_id: params[:plan_id],
         payment_method_token: params[:payment_method_token],
         status: "Active",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-01T00:00:00Z",
         discounts: [%{id: "bt_discount_25", inherited_from_id: "bt_discount_25"}]
       )}
    end
  end

  setup do
    previous_processor = Application.get_env(:accrue, :processor)
    previous_gateway = Application.get_env(:accrue, :braintree_subscription_gateway)
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    previous_test_pid = Application.get_env(:accrue_portal, :checkout_discount_test_pid)

    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, SubscriptionGatewayStub)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    Application.put_env(:accrue_portal, :checkout_discount_test_pid, self())
    BraintreeMox.stub_client_token("portal-client-token")

    user = %TestUser{id: Ecto.UUID.generate()}
    customer = build_customer(%{owner_id: user.id, owner_type: "TestUser"})

    on_exit(fn ->
      if previous_processor do
        Application.put_env(:accrue, :processor, previous_processor)
      else
        Application.delete_env(:accrue, :processor)
      end

      if previous_gateway do
        Application.put_env(:accrue, :braintree_subscription_gateway, previous_gateway)
      else
        Application.delete_env(:accrue, :braintree_subscription_gateway)
      end

      if previous_auth do
        Application.put_env(:accrue, :auth_adapter, previous_auth)
      else
        Application.delete_env(:accrue, :auth_adapter)
      end

      if previous_test_pid do
        Application.put_env(:accrue_portal, :checkout_discount_test_pid, previous_test_pid)
      else
        Application.delete_env(:accrue_portal, :checkout_discount_test_pid)
      end
    end)

    {:ok, user: user, customer: customer}
  end

  test "valid promo preview updates the CTA, total, and aria-live status with provisional copy",
       %{
         conn: conn,
         user: user,
         customer: customer
       } do
    session =
      checkout_fixture(customer, line_items: [%{"price" => "price_pro", "amount" => "49.00"}])

    assert {:ok, _mapping} =
             Billing.upsert_discount_mapping("SPRING25", %{
               discount_id: "bt_discount_25",
               amount_off_minor: 2_500,
               currency: "USD"
             })

    conn = sign_in_customer(conn, user)

    assert {:ok, view, html} = live(conn, "/billing/checkout/#{session.session_token}")
    assert html =~ "Pay $49.00"

    html =
      view
      |> form("#promo-code-form", promo: %{code: "spring25"})
      |> render_change()

    assert html =~ "Discount ready."
    assert html =~ "Estimated total: $24.00"
    assert html =~ "Pay $24.00"
    assert html =~ ~s(aria-live="polite")

    assert {:error, {:redirect, %{to: "https://app.example.test/billing/success"}}} =
             render_hook(view, "checkout_tokenized", %{"nonce" => "fake-valid-nonce"})

    assert_received {:gateway_create,
                     %{
                       payment_method_token: "fake-valid-nonce",
                       plan_id: "price_fixture",
                       discounts: %{add: [%{inherited_from_id: "bt_discount_25"}]}
                     }}

    assert LocalSession.by_id(session.id).status == "completed"
  end

  test "invalid promo preview keeps failure copy in the customer domain", %{
    conn: conn,
    user: user,
    customer: customer
  } do
    session = checkout_fixture(customer)
    conn = sign_in_customer(conn, user)

    assert {:ok, view, _html} = live(conn, "/billing/checkout/#{session.session_token}")

    html =
      view
      |> form("#promo-code-form", promo: %{code: "missing"})
      |> render_change()

    assert html =~ "This code is unavailable. Check the code and try again."
    refute html =~ "discount_mapping_invalid"
    refute html =~ "missing discount"
    assert html =~ "Pay $49.00"
  end

  test "submit-time drift revalidation shows safe customer copy and blocks subscription creation",
       %{
         conn: conn,
         user: user,
         customer: customer
       } do
    session = checkout_fixture(customer)

    assert {:ok, mapping} =
             Billing.upsert_discount_mapping("DRIFTED", %{
               discount_id: "bt_discount_drifted",
               amount_off_minor: 500,
               currency: "USD"
             })

    conn = sign_in_customer(conn, user)

    assert {:ok, view, _html} = live(conn, "/billing/checkout/#{session.session_token}")

    preview_html =
      view
      |> form("#promo-code-form", promo: %{code: "DRIFTED"})
      |> render_change()

    assert preview_html =~ "Discount ready."
    assert preview_html =~ "Pay $44.00"

    assert {:ok, _} =
             Ecto.Adapters.SQL.query(
               AccruePortal.TestRepo,
               """
               UPDATE #{@discount_mappings_table}
               SET discount_id = '', updated_at = $2
               WHERE id = $1
               """,
               [Ecto.UUID.dump!(mapping.id), DateTime.utc_now() |> DateTime.truncate(:second)]
             )

    submit_html = render_hook(view, "checkout_tokenized", %{"nonce" => "fake-valid-nonce"})

    assert submit_html =~ "This promotion is temporarily unavailable."
    assert LocalSession.by_id(session.id).status == "open"
    refute_received {:gateway_create, _}
  end

  defp checkout_fixture(%Customer{} = customer, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})

    attrs =
      Map.merge(
        %{
          processor: "braintree",
          mode: "subscription",
          ui_mode: "hosted",
          status: "open",
          price_id: "price_fixture",
          line_items: [%{"price" => "price_fixture", "amount" => "49.00"}],
          success_url: "https://app.example.test/billing/success",
          cancel_url: "https://app.example.test/billing/cancel",
          return_url: "https://app.example.test/settings/billing",
          operation_id:
            "checkout-discount-fixture-" <> Integer.to_string(System.unique_integer([:positive])),
          metadata: %{"source" => "fixture"},
          data: %{"local_portal" => true}
        },
        attrs
      )

    {:ok, session} = LocalSession.create_or_reuse(customer, attrs)
    session
  end

  defp build_customer(attrs) do
    attrs =
      Map.merge(
        %{
          owner_type: "User",
          owner_id: Ecto.UUID.generate(),
          processor: "braintree",
          processor_id:
            "cus_bt_discount_fixture_" <> Integer.to_string(System.unique_integer([:positive])),
          email: "portal-discount-fixture@example.com"
        },
        attrs
      )

    %Customer{}
    |> Customer.changeset(attrs)
    |> TestRepo.insert!()
  end

  defp sign_in_customer(conn, %TestUser{id: id}) do
    Plug.Test.init_test_session(conn, %{
      "user_token" => "customer-token",
      "user_id" => id
    })
  end
end
