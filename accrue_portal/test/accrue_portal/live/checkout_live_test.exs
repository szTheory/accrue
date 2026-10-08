defmodule AccruePortal.CheckoutLiveTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing.Customer
  alias Accrue.Checkout.LocalSession
  alias AccruePortal.BraintreeMox
  alias AccruePortal.TestRepo

  @client_sri "sha384-rNv6rxT4CpVv9Kb8luV4l/GpBwbhHTmZxWbI74/LX+ShrJzh/b9AL7nynSmHDpRC"
  @hosted_fields_sri "sha384-QAzc9uX3XQPGzTESbnMNOUn9hY9jVL/L10Eq3Gxt4NKXIZZWzGlhnEscA3iGj8Jp"

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
      %AccruePortal.CheckoutLiveTest.TestUser{id: user_id}
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
      {:ok,
       struct!(Elixir.Braintree.Subscription,
         id: "sub_bt_checkout_123",
         plan_id: params[:plan_id],
         payment_method_token: params[:payment_method_token],
         status: "Active",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-01T00:00:00Z"
       )}
    end
  end

  setup do
    previous_processor = Application.get_env(:accrue, :processor)
    previous_gateway = Application.get_env(:accrue, :braintree_subscription_gateway)
    previous_auth = Application.get_env(:accrue, :auth_adapter)

    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, SubscriptionGatewayStub)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
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
    end)

    {:ok, user: user, customer: customer}
  end

  test "renders Hosted Fields checkout with locked CTAs and SRI-pinned Braintree assets", %{
    conn: conn,
    user: user,
    customer: customer
  } do
    session =
      checkout_fixture(customer,
        price_id: "price_pro",
        line_items: [
          %{"price" => "price_pro", "quantity" => 1, "amount" => "49.00", "amount_minor" => 4900}
        ]
      )

    conn = sign_in_customer(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/checkout/#{session.session_token}")
    assert html =~ ~s(phx-hook="BraintreeHostedFields")
    assert html =~ ~s(data-braintree-field="number")
    assert html =~ ~s(data-braintree-field="expirationDate")
    assert html =~ ~s(data-braintree-field="cvv")
    assert html =~ "Pay $49.00"
    assert html =~ "Studio"
    assert html =~ "USD $49.00 / per month"
    assert html =~ "Billed to"
    assert html =~ "Leave checkout"
    assert html =~ ~s(src="https://js.braintreegateway.com/web/3.132.0/js/client.min.js")
    assert html =~ ~s(integrity="#{@client_sri}")
    assert html =~ ~s(src="https://js.braintreegateway.com/web/3.132.0/js/hosted-fields.min.js")
    assert html =~ ~s(integrity="#{@hosted_fields_sri}")
    assert html =~ ~s(crossorigin="anonymous")
  end

  test "an explicit trusted zero remains visible as zero", %{
    conn: conn,
    user: user,
    customer: customer
  } do
    session =
      checkout_fixture(customer,
        line_items: [
          %{"price" => "price_fixture", "quantity" => 1, "amount" => "0.00", "amount_minor" => 0}
        ],
        metadata: checkout_metadata(%{"amount_minor" => 0})
      )

    assert {:ok, _view, html} =
             live(sign_in_customer(conn, user), "/billing/checkout/#{session.session_token}")

    assert html =~ "USD $0.00 / per month"
    assert html =~ "Pay $0.00"
    assert html =~ ~s(id="checkout-form")
  end

  test "incomplete or inconsistent terms disable payment and offer safe recovery", %{
    conn: conn,
    user: user,
    customer: customer
  } do
    invalid_sessions = [
      checkout_fixture(customer, metadata: %{"source" => "missing terms"}),
      checkout_fixture(customer, line_items: [], metadata: checkout_metadata()),
      checkout_fixture(customer,
        line_items: [%{"price" => "price_fixture", "amount" => "49.001", "amount_minor" => 4900}],
        metadata: checkout_metadata()
      ),
      checkout_fixture(customer,
        line_items: [%{"price" => "price_fixture", "amount" => "-1.00", "amount_minor" => 4900}],
        metadata: checkout_metadata()
      ),
      checkout_fixture(customer, metadata: checkout_metadata(%{"currency" => "US"})),
      checkout_fixture(customer, metadata: checkout_metadata(%{"interval" => ""})),
      checkout_fixture(customer,
        line_items: [
          %{
            "price" => "price_fixture",
            "quantity" => 1,
            "amount" => "49.00",
            "amount_minor" => 4900
          },
          %{"price" => "second", "quantity" => 1, "amount" => "1.00", "amount_minor" => 100}
        ],
        metadata: checkout_metadata()
      )
    ]

    for session <- invalid_sessions do
      assert {:ok, _view, html} =
               live(sign_in_customer(conn, user), "/billing/checkout/#{session.session_token}")

      assert html =~ "Plan details are unavailable"
      assert html =~ "Return to billing"
      refute html =~ ~s(id="checkout-form")
      refute html =~ ~s(id="promo-code-form")
    end
  end

  test "long Unicode plan labels render as escaped trusted data", %{
    conn: conn,
    user: user,
    customer: customer
  } do
    long_name = String.duplicate("航🚀", 80)
    session = checkout_fixture(customer, metadata: checkout_metadata(%{"plan_name" => long_name}))

    assert {:ok, _view, html} =
             live(sign_in_customer(conn, user), "/billing/checkout/#{session.session_token}")

    assert html =~ long_name
    refute html =~ "price_fixture</strong>"
  end

  test "checkout hook returns the nonce and rendered context pin, never card fields" do
    js = File.read!(Path.expand("../../../priv/static/accrue_portal.js", __DIR__))

    assert js =~ ~s|pushEvent("checkout_tokenized", {|
    assert js =~ "context_pin: contextPin"
    assert js =~ "nonce: payload.nonce"
    refute js =~ ~s|pushEvent("checkout_tokenized", { number:|
    refute js =~ ~s|pushEvent("checkout_tokenized", { cvv:|
    refute js =~ "payment_method_nonce"
  end

  test "submitting a nonce completes checkout without exposing card fields in the LiveView", %{
    conn: conn,
    user: user,
    customer: customer
  } do
    session = checkout_fixture(customer, price_id: "price_basic")
    conn = sign_in_customer(conn, user)

    assert {:ok, view, html} = live(conn, "/billing/checkout/#{session.session_token}")

    [[pin] | _] =
      Regex.scan(~r/name="context_pin" value="([^"]+)"/, html, capture: :all_but_first)

    assert {:error, {:redirect, %{to: "https://app.example.test/billing/success"}}} =
             render_hook(view, "checkout_tokenized", %{
               "nonce" => "fake-valid-nonce",
               "context_pin" => pin,
               "number" => "4111111111111111",
               "cvv" => "123"
             })

    assert LocalSession.by_id(session.id).status == "completed"
  end

  test "expired and missing checkout sessions fail closed in the LiveView surface", %{
    conn: conn,
    user: user,
    customer: customer
  } do
    expired =
      checkout_fixture(customer,
        expires_at: DateTime.add(DateTime.utc_now(), -300, :second)
      )

    conn = sign_in_customer(conn, user)

    assert {:ok, expired_view, expired_html} =
             live(conn, "/billing/checkout/#{expired.session_token}")

    [[pinned_path]] =
      Regex.scan(~r/href="([^"]*context_pin=[^"]+)"/, expired_html, capture: :all_but_first)

    pin =
      pinned_path
      |> URI.parse()
      |> Map.get(:query)
      |> URI.decode_query()
      |> Map.fetch!("context_pin")

    assert expired_html =~ "This checkout link has expired"
    assert expired_html =~ "Leave checkout"

    assert expired_html_after =
             render_hook(expired_view, "checkout_tokenized", %{
               "nonce" => "fake-valid-nonce",
               "context_pin" => pin
             })

    assert expired_html_after =~ "This checkout link has expired"
    assert expired_html_after =~ "Return to your account and start a new subscription."
    assert LocalSession.by_id(expired.id).status == "open"

    assert {:error, {:redirect, %{to: "/billing"}}} =
             live(conn, "/billing/checkout/missing-token")
  end

  test "inline tokenize errors stay on the checkout LiveView", %{
    conn: conn,
    user: user,
    customer: customer
  } do
    session = checkout_fixture(customer)
    conn = sign_in_customer(conn, user)

    assert {:ok, view, _html} = live(conn, "/billing/checkout/#{session.session_token}")

    html =
      render_hook(view, "checkout_failed", %{
        "message" => "Card verification failed."
      })

    assert html =~ "We couldn&#39;t process that card. Card verification failed."
    assert html =~ "Check the card number, expiration, and CVV, then try again."
    assert LocalSession.by_id(session.id).status == "open"
  end

  defp checkout_fixture(%Customer{} = customer, attrs \\ %{}) do
    provided = Enum.into(attrs, %{})

    attrs =
      Map.merge(
        %{
          processor: "braintree",
          mode: "subscription",
          ui_mode: "hosted",
          status: "open",
          price_id: "price_fixture",
          line_items: [
            %{
              "price" => "price_fixture",
              "quantity" => 1,
              "amount" => "49.00",
              "amount_minor" => 4900
            }
          ],
          success_url: "https://app.example.test/billing/success",
          cancel_url: "https://app.example.test/billing/cancel",
          return_url: "https://app.example.test/settings/billing",
          operation_id:
            "checkout-fixture-" <> Integer.to_string(System.unique_integer([:positive])),
          metadata: checkout_metadata(),
          data: %{"local_portal" => true}
        },
        provided
      )

    price_id =
      Map.get(provided, :price_id) ||
        case Map.get(provided, :line_items) do
          [%{"price" => item_price} | _] -> item_price
          _ -> attrs.price_id
        end

    line_items =
      if Map.has_key?(provided, :line_items) do
        provided.line_items
      else
        [%{"price" => price_id, "quantity" => 1, "amount" => "49.00", "amount_minor" => 4900}]
      end

    attrs = Map.merge(attrs, %{price_id: price_id, line_items: line_items})

    {:ok, session} = LocalSession.create_or_reuse(customer, attrs)
    session
  end

  defp checkout_metadata(overrides \\ %{}) do
    Map.merge(
      %{
        "plan_name" => "Studio",
        "amount_minor" => 4900,
        "currency" => "USD",
        "interval" => "month",
        "interval_count" => 1,
        "billable_type" => "User",
        "billable_id" => "fixture-billable",
        "billable_name" => "Fixture account",
        "processor" => "braintree"
      },
      overrides
    )
  end

  defp build_customer(attrs) do
    attrs =
      Map.merge(
        %{
          owner_type: "User",
          owner_id: Ecto.UUID.generate(),
          processor: "braintree",
          processor_id:
            "cus_bt_fixture_" <> Integer.to_string(System.unique_integer([:positive])),
          email: "portal-fixture@example.com"
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
