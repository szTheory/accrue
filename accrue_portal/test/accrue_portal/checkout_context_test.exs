defmodule AccruePortal.CheckoutContextTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Checkout.LocalSession
  alias Accrue.Billing.Customer
  alias AccruePortal.TestRepo

  defmodule Organization do
    use Ecto.Schema
    use Accrue.Billable

    @primary_key {:id, :string, autogenerate: false}
    schema "portal_test_organizations" do
    end
  end

  defmodule ActionAdapter do
    alias AccruePortal.CheckoutContextTest.Organization

    def resolve(_actor, %{source: source, values: values}) when source in [:session, :pin] do
      id = Map.get(values, "active_billable_id") || Map.get(values, "owner_id")

      if is_binary(id) and String.starts_with?(id, "org-") do
        {:ok,
         %{
           billable: %Organization{id: id},
           display_name: "Checkout Organization",
           switch_path: "/accounts"
         }}
      else
        {:error, :unavailable}
      end
    end

    def authorize(_actor, context, :read, _target) do
      if MapSet.member?(
           :persistent_term.get({__MODULE__, :revoked}, MapSet.new()),
           context.owner_id
         ),
         do: {:error, :forbidden},
         else: :ok
    end

    def authorize(_actor, context, action, _target) do
      if action in Map.get(:persistent_term.get({__MODULE__, :grants}, %{}), context.owner_id, []),
        do: :ok,
        else: {:error, :forbidden}
    end

    def grant(owner_id, actions) do
      grants = :persistent_term.get({__MODULE__, :grants}, %{})
      :persistent_term.put({__MODULE__, :grants}, Map.put(grants, owner_id, actions))
    end

    def clear_grants do
      :persistent_term.erase({__MODULE__, :grants})
      :persistent_term.erase({__MODULE__, :revoked})
    end
  end

  defmodule TokenCounter do
    use Agent

    def start_link, do: Agent.start_link(fn -> 0 end, name: __MODULE__)
    def reset, do: Agent.update(__MODULE__, fn _ -> 0 end)
    def count, do: Agent.get(__MODULE__, & &1)
    def bump, do: Agent.update(__MODULE__, &(&1 + 1))
  end

  defmodule CountingTokenGenerator do
    def generate(%{customer_id: _id}) do
      AccruePortal.CheckoutContextTest.TokenCounter.bump()
      {:ok, "counted-client-token"}
    end
  end

  defmodule SubscriptionGatewayStub do
    def create(params, _opts) do
      if pid = Application.get_env(:accrue_portal, :checkout_context_test_pid) do
        send(pid, {:gateway_create, params, Accrue.Actor.current()})
      end

      {:ok,
       struct!(Braintree.Subscription,
         id: "sub_bt_checkout_context",
         plan_id: params[:plan_id],
         payment_method_token: params[:payment_method_token],
         status: "Active",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-01T00:00:00Z"
       )}
    end
  end

  defmodule CustomRouter do
    use Phoenix.Router
    import Phoenix.ConnTest, except: [get: 3, post: 3]
    import Accrue.Portal.Router

    accrue_portal("/org-billing",
      session_keys: [:user_token, :active_billable_id],
      context_adapter: ActionAdapter
    )
  end

  defmodule CustomEndpoint do
    use Phoenix.Endpoint, otp_app: :accrue_portal

    socket("/live", Phoenix.LiveView.Socket)

    plug(Plug.Session,
      store: :cookie,
      key: "_accrue_portal_checkout_context_key",
      signing_salt: "accrue-portal-context-post"
    )

    plug(CustomRouter)
  end

  @endpoint CustomEndpoint

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    previous_generator = Application.get_env(:accrue, :braintree_client_token_generator)
    previous_processor = Application.get_env(:accrue, :processor)
    previous_gateway = Application.get_env(:accrue, :braintree_subscription_gateway)
    previous_test_pid = Application.get_env(:accrue_portal, :checkout_context_test_pid)
    Application.put_env(:accrue, :auth_adapter, AccruePortal.Fixtures.AuthAdapter)
    Application.put_env(:accrue, :braintree_client_token_generator, CountingTokenGenerator)
    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :braintree_subscription_gateway, SubscriptionGatewayStub)
    Application.put_env(:accrue_portal, :checkout_context_test_pid, self())
    ActionAdapter.clear_grants()

    Application.put_env(:accrue_portal, CustomEndpoint,
      secret_key_base: String.duplicate("abcd1234", 8),
      server: false,
      url: [host: "localhost"],
      live_view: [signing_salt: "accrue-portal-context-post"],
      render_errors: [formats: [html: &Phoenix.Controller.status_message_from_template/1]]
    )

    case CustomEndpoint.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    case TokenCounter.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> TokenCounter.reset()
    end

    on_exit(fn ->
      if previous_auth,
        do: Application.put_env(:accrue, :auth_adapter, previous_auth),
        else: Application.delete_env(:accrue, :auth_adapter)

      if previous_generator,
        do: Application.put_env(:accrue, :braintree_client_token_generator, previous_generator),
        else: Application.delete_env(:accrue, :braintree_client_token_generator)

      if previous_processor,
        do: Application.put_env(:accrue, :processor, previous_processor),
        else: Application.delete_env(:accrue, :processor)

      if previous_gateway,
        do: Application.put_env(:accrue, :braintree_subscription_gateway, previous_gateway),
        else: Application.delete_env(:accrue, :braintree_subscription_gateway)

      if previous_test_pid,
        do: Application.put_env(:accrue_portal, :checkout_context_test_pid, previous_test_pid),
        else: Application.delete_env(:accrue_portal, :checkout_context_test_pid)

      ActionAdapter.clear_grants()
    end)

    :ok
  end

  test "read-only checkout mount never issues a client token or renders Hosted Fields", %{
    conn: conn
  } do
    session = checkout_fixture("org-checkout-read-only")
    conn = sign_in_org(conn, "org-checkout-read-only")
    ActionAdapter.grant("org-checkout-read-only", [])
    TokenCounter.reset()

    assert {:ok, _view, html} = live(conn, "/org-billing/checkout/#{session.session_token}")

    assert TokenCounter.count() == 0
    refute html =~ ~s(data-portal-hosted-fields="checkout")
    assert html =~ "Checkout access is unavailable"
  end

  test "rendered checkout form pins and completes the same context through the LiveView event", %{
    conn: conn
  } do
    session = checkout_fixture("org-checkout-allowed")
    conn = sign_in_org(conn, "org-checkout-allowed")
    ActionAdapter.grant("org-checkout-allowed", [:checkout_complete])

    TokenCounter.reset()

    assert {:ok, view, html} = live(conn, "/org-billing/checkout/#{session.session_token}")

    assert html =~ ~s(id="checkout-form")
    assert html =~ ~s(name="context_pin" value=)
    assert TokenCounter.count() > 0

    [[pin]] = Regex.scan(~r/name="context_pin" value="([^"]+)"/, html, capture: :all_but_first)

    assert {:error, {:redirect, %{to: "https://app.example.test/billing/success"}}} =
             render_hook(view, "checkout_tokenized", %{
               "nonce" => "fake-valid-nonce",
               "context_pin" => pin
             })

    assert LocalSession.by_id(session.id).status == "completed"

    assert_received {:gateway_create, %{payment_method_token: "fake-valid-nonce"},
                     %{type: :user, id: _}}
  end

  defp checkout_fixture(owner_id) do
    customer =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: Organization.__accrue__(:billable_type),
        owner_id: owner_id,
        email: "#{owner_id}@example.com",
        name: "Checkout Organization",
        processor: "braintree",
        processor_id: "cus_checkout_context_#{System.unique_integer([:positive])}"
      })
      |> TestRepo.insert!()

    {:ok, session} =
      LocalSession.create_or_reuse(customer, %{
        processor: "braintree",
        mode: "subscription",
        ui_mode: "hosted",
        status: "open",
        price_id: "price_checkout_context",
        line_items: [%{"price" => "price_checkout_context", "amount" => "49.00"}],
        success_url: "https://app.example.test/billing/success",
        cancel_url: "https://app.example.test/billing/cancel",
        operation_id: "checkout-context-#{System.unique_integer([:positive])}"
      })

    session
  end

  defp sign_in_org(conn, owner_id) do
    Plug.Test.init_test_session(conn, %{
      "user_token" => "customer:00000000-0000-0000-0000-000000000123",
      "active_billable_id" => owner_id
    })
  end
end
