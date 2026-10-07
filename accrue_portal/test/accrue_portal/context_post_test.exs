defmodule AccruePortal.ContextPostTest do
  use AccruePortal.ConnCase, async: false

  defmodule Organization do
    use Ecto.Schema
    use Accrue.Billable

    @primary_key {:id, :string, autogenerate: false}
    schema "portal_test_organizations" do
    end
  end

  defmodule ActionAdapter do
    alias AccruePortal.ContextPostTest.Organization

    def resolve(_actor, %{source: source, values: values}) when source in [:session, :pin] do
      id = Map.get(values, "active_billable_id") || Map.get(values, "owner_id")

      if is_binary(id) and String.starts_with?(id, "org-") do
        {:ok,
         %{
           billable: %Organization{id: id},
           display_name: "Test Organization",
           display_detail: "Organization billing",
           switch_path: "/accounts"
         }}
      else
        {:error, :unavailable}
      end
    end

    def authorize(_actor, context, :read, _target), do: if(context.billable, do: :ok)

    def authorize(_actor, context, action, _target) do
      if action in Map.get(:persistent_term.get({__MODULE__, :grants}, %{}), context.owner_id, []),
        do: :ok,
        else: {:error, :forbidden}
    end

    def grant(owner_id, actions) do
      grants = :persistent_term.get({__MODULE__, :grants}, %{})
      :persistent_term.put({__MODULE__, :grants}, Map.put(grants, owner_id, actions))
    end

    def clear_grants, do: :persistent_term.erase({__MODULE__, :grants})
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
      AccruePortal.ContextPostTest.TokenCounter.bump()
      {:ok, "counted-client-token"}
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
      key: "_accrue_portal_context_post_key",
      signing_salt: "accrue-portal-context-post"
    )

    plug(CustomRouter)
  end

  alias Accrue.Billing.PaymentMethod
  alias AccruePortal.TestRepo

  import AccruePortal.Fixtures

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AccruePortal.Fixtures.AuthAdapter)
    ActionAdapter.clear_grants()

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, previous_auth)
      ActionAdapter.clear_grants()
    end)

    :ok
  end

  test "rendered default and delete forms carry a context pin accepted by their POSTs", %{
    conn: conn
  } do
    %{
      user: user,
      customer: customer,
      payment_method: default_method,
      foreign_payment_method: foreign_method
    } = dashboard_fixture!()

    other_method =
      payment_method_fixture!(customer, %{
        processor_id: "pm_context_pin_other",
        card_brand: "visa",
        card_last4: "1111",
        card_exp_month: 12,
        card_exp_year: 2031,
        exp_month: 12,
        exp_year: 2031
      })

    conn = sign_in_conn(conn, user)
    assert {:ok, _view, html} = live_payment_methods(conn)

    pins = Regex.scan(~r/name="context_pin" value="([^"]+)"/, html, capture: :all_but_first)
    assert length(pins) >= 2
    [pin] = pins |> Enum.map(&hd/1) |> Enum.uniq()

    default_calls_before = Accrue.Processor.Fake.call_count(:set_default_payment_method)

    default_response =
      post(conn, "/billing/payment-methods/#{other_method.id}/default", %{
        "context_pin" => pin
      })

    assert redirected_to(default_response) == "/billing/payment-methods"

    assert Accrue.Processor.Fake.call_count(:set_default_payment_method) ==
             default_calls_before + 1

    assert TestRepo.get!(Accrue.Billing.Customer, customer.id).default_payment_method_id ==
             other_method.id

    detach_calls_before = Accrue.Processor.Fake.call_count(:detach_payment_method)

    foreign_response =
      post(conn, "/billing/payment-methods/#{foreign_method.id}/delete", %{"context_pin" => pin})

    assert foreign_response.status == 404
    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == detach_calls_before

    delete_calls_before = Accrue.Processor.Fake.call_count(:detach_payment_method)

    delete_response =
      post(conn, "/billing/payment-methods/#{default_method.id}/delete", %{
        "context_pin" => pin
      })

    assert redirected_to(delete_response) == "/billing/payment-methods"
    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == delete_calls_before + 1
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, default_method.id)
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, other_method.id)
  end

  test "missing and forged pins block payment method writes", %{conn: conn} do
    %{user: user, customer: customer, payment_method: payment_method} = dashboard_fixture!()
    conn = sign_in_conn(conn, user)
    detach_calls_before = Accrue.Processor.Fake.call_count(:detach_payment_method)

    response = post(conn, "/billing/payment-methods/#{payment_method.id}/delete", %{})
    assert redirected_to(response) == "/billing/blocked"
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, payment_method.id)
    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == detach_calls_before

    response =
      post(conn, "/billing/payment-methods/#{payment_method.id}/delete", %{
        "context_pin" => "forged-pin"
      })

    assert redirected_to(response) == "/billing/blocked"
    assert TestRepo.get(Accrue.Billing.Customer, customer.id)
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, payment_method.id)
    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == detach_calls_before
  end

  defp live_payment_methods(conn) do
    case live(conn, "/billing/payment-methods") do
      {:ok, _view, _html} = success -> success
      {:error, {:live_redirect, %{to: path}}} -> live(conn, path)
    end
  end
end

defmodule AccruePortal.ContextPinPolicyTest do
  use AccruePortal.ConnCase, async: false

  alias AccruePortal.ContextPostTest.ActionAdapter
  alias AccruePortal.ContextPostTest.CountingTokenGenerator
  alias AccruePortal.ContextPostTest.Organization
  alias AccruePortal.ContextPostTest.TokenCounter

  @endpoint AccruePortal.ContextPostTest.CustomEndpoint

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    previous_generator = Application.get_env(:accrue, :braintree_client_token_generator)
    Application.put_env(:accrue, :auth_adapter, AccruePortal.Fixtures.AuthAdapter)
    Application.put_env(:accrue, :braintree_client_token_generator, CountingTokenGenerator)
    ActionAdapter.clear_grants()

    Application.put_env(:accrue_portal, AccruePortal.ContextPostTest.CustomEndpoint,
      secret_key_base: String.duplicate("abcd1234", 8),
      server: false,
      url: [host: "localhost"],
      live_view: [signing_salt: "accrue-portal-context-post"],
      render_errors: [formats: [html: &Phoenix.Controller.status_message_from_template/1]]
    )

    case AccruePortal.ContextPostTest.CustomEndpoint.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    case TokenCounter.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> TokenCounter.reset()
    end

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, previous_auth)

      if previous_generator,
        do: Application.put_env(:accrue, :braintree_client_token_generator, previous_generator),
        else: Application.delete_env(:accrue, :braintree_client_token_generator)

      ActionAdapter.clear_grants()
    end)

    :ok
  end

  test "read-only organization cannot receive a Braintree client token or Hosted Fields", %{
    conn: conn
  } do
    owner_id = "org-create-denied"

    Accrue.Test.Factory.active_subscription(%{
      owner_type: Organization.__accrue__(:billable_type),
      owner_id: owner_id,
      email: "#{owner_id}@example.com",
      name: "Test Organization"
    })

    ActionAdapter.grant(owner_id, [])
    TokenCounter.reset()

    conn =
      Plug.Test.init_test_session(conn, %{
        "user_token" => "customer:00000000-0000-0000-0000-000000000123",
        "active_billable_id" => owner_id
      })

    assert {:ok, _view, html} = live(conn, "/org-billing/payment-methods/new")

    assert TokenCounter.count() == 0
    refute html =~ ~s(data-portal-hosted-fields="payment-method")
  end

  test "rendered add-card form posts its original pin through create authorization", %{conn: conn} do
    owner_id = "org-create-allowed"

    %{customer: customer} =
      Accrue.Test.Factory.active_subscription(%{
        owner_type: Organization.__accrue__(:billable_type),
        owner_id: owner_id,
        email: "#{owner_id}@example.com",
        name: "Test Organization"
      })

    ActionAdapter.grant(owner_id, [:payment_method_create])
    TokenCounter.reset()

    conn =
      Plug.Test.init_test_session(conn, %{
        "user_token" => "customer:00000000-0000-0000-0000-000000000123",
        "active_billable_id" => owner_id
      })

    assert {:ok, _view, methods_html} = live(conn, "/org-billing/payment-methods")

    [_, encoded_pin] =
      Regex.run(~r/href="\/org-billing\/payment-methods\/new\?context_pin=([^"]+)"/, methods_html)

    pin = URI.decode_www_form(encoded_pin)
    add_path = "/org-billing/payment-methods/new?context_pin=" <> encoded_pin
    assert {:ok, _view, add_html} = live(conn, add_path)

    assert add_html =~ ~s(name="context_pin" value="#{pin}")
    assert TokenCounter.count() > 0

    calls_before = Accrue.Processor.Fake.call_count(:create_payment_method)

    response =
      post(conn, "/org-billing/payment-methods", %{
        "context_pin" => pin,
        "payment_method_nonce" => "fake-valid-nonce"
      })

    assert redirected_to(response) == "/org-billing/payment-methods"
    assert Accrue.Processor.Fake.call_count(:create_payment_method) == calls_before + 1
    assert AccruePortal.TestRepo.get_by(Accrue.Billing.PaymentMethod, customer_id: customer.id)
  end
end
