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

    def authorize(_actor, context, :read, _target) do
      revoked = :persistent_term.get({__MODULE__, :revoked}, MapSet.new())
      if MapSet.member?(revoked, context.owner_id), do: {:error, :forbidden}, else: :ok
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

    def revoke(owner_id) do
      revoked = :persistent_term.get({__MODULE__, :revoked}, MapSet.new())
      :persistent_term.put({__MODULE__, :revoked}, MapSet.put(revoked, owner_id))
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
  alias AccruePortal.Copy
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

    assert_context_redirect(default_response, "/billing/payment-methods", pin)

    assert Phoenix.Flash.get(default_response.assigns.flash, :info) ==
             Copy.payment_methods_default_success()

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

    assert_context_redirect(delete_response, "/billing/payment-methods", pin)

    assert Phoenix.Flash.get(delete_response.assigns.flash, :error) ==
             Copy.payment_methods_delete_error()

    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == delete_calls_before + 1
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, default_method.id)
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, other_method.id)
  end

  test "failed default changes announce failure without changing the customer default", %{
    conn: conn
  } do
    %{user: user, customer: customer, payment_method: payment_method} = dashboard_fixture!()

    TestRepo.update!(
      Accrue.Billing.Customer.changeset(customer, %{default_payment_method_id: payment_method.id})
    )

    target = payment_method_fixture!(customer, %{processor_id: "pm_failed_default_target"})
    conn = sign_in_conn(conn, user)
    assert {:ok, _view, html} = live_payment_methods(conn)

    [[pin] | _] =
      Regex.scan(~r/name="context_pin" value="([^"]+)"/, html, capture: :all_but_first)

    Accrue.Processor.Fake.stub(:set_default_payment_method, fn _customer_id, _params, _opts ->
      {:error, :offline}
    end)

    on_exit(fn -> Accrue.Processor.Fake.unstub(:set_default_payment_method) end)

    response =
      post(conn, "/billing/payment-methods/#{target.id}/default", %{
        "context_pin" => pin
      })

    assert_context_redirect(response, "/billing/payment-methods", pin)

    assert Phoenix.Flash.get(response.assigns.flash, :error) ==
             Copy.payment_methods_default_error()

    assert TestRepo.get!(Accrue.Billing.Customer, customer.id).default_payment_method_id ==
             payment_method.id
  end

  test "failed card saves announce the processor result and create no card", %{conn: conn} do
    %{user: user, customer: customer} = dashboard_fixture!()
    conn = sign_in_conn(conn, user)
    assert {:ok, _view, html} = live_payment_methods(conn)

    [[pin] | _] =
      Regex.scan(~r/name="context_pin" value="([^"]+)"/, html, capture: :all_but_first)

    payment_method_ids_before =
      TestRepo.all(PaymentMethod) |> Enum.map(& &1.id) |> MapSet.new()

    Accrue.Processor.Fake.stub(:create_payment_method, fn _params, _opts ->
      {:error, :offline}
    end)

    on_exit(fn -> Accrue.Processor.Fake.unstub(:create_payment_method) end)

    response =
      post(conn, "/billing/payment-methods", %{
        "context_pin" => pin,
        "payment_method_nonce" => "fake-valid-nonce"
      })

    assert_context_redirect(response, "/billing/payment-methods", pin)

    assert Phoenix.Flash.get(response.assigns.flash, :error) ==
             Copy.add_payment_method_save_error()

    assert TestRepo.all(PaymentMethod) |> Enum.map(& &1.id) |> MapSet.new() ==
             payment_method_ids_before

    assert TestRepo.get(Accrue.Billing.Customer, customer.id)
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

  test "expired pins and a changed processor identity block payment method writes", %{conn: conn} do
    %{user: user, customer: customer, payment_method: payment_method} = dashboard_fixture!()
    conn = sign_in_conn(conn, user)
    assert {:ok, _view, html} = live_payment_methods(conn)

    [[pin] | _] =
      Regex.scan(~r/name="context_pin" value="([^"]+)"/, html, capture: :all_but_first)

    expired_pin =
      Phoenix.Token.sign(
        AccruePortal.TestEndpoint,
        "accrue-portal-payment-flow-v1",
        %{
          "owner_type" => customer.owner_type,
          "owner_id" => customer.owner_id,
          "processor" => customer.processor,
          "customer_id" => customer.id
        },
        signed_at: System.system_time(:second) - 1_201
      )

    calls_before = Accrue.Processor.Fake.call_count(:detach_payment_method)

    expired_response =
      post(conn, "/billing/payment-methods/#{payment_method.id}/delete", %{
        "context_pin" => expired_pin
      })

    assert redirected_to(expired_response) == "/billing/blocked"
    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == calls_before

    TestRepo.update!(Ecto.Changeset.change(customer, processor: "other-processor"))

    mismatched_response =
      post(conn, "/billing/payment-methods/#{payment_method.id}/delete", %{"context_pin" => pin})

    assert redirected_to(mismatched_response) == "/billing/blocked"
    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == calls_before
    assert %PaymentMethod{} = TestRepo.get(PaymentMethod, payment_method.id)
  end

  defp live_payment_methods(conn) do
    case live(conn, "/billing/payment-methods") do
      {:ok, _view, _html} = success -> success
      {:error, {:live_redirect, %{to: path}}} -> live(conn, path)
    end
  end

  defp assert_context_redirect(response, expected_path, expected_pin) do
    redirect = redirected_to(response)
    uri = URI.parse(redirect)

    assert uri.path == expected_path
    assert URI.decode_query(uri.query || "")["context_pin"] == expected_pin
  end
end

defmodule AccruePortal.ContextPinPolicyTest do
  use AccruePortal.ConnCase, async: false

  alias AccruePortal.ContextPostTest.ActionAdapter
  alias AccruePortal.ContextPostTest.CountingTokenGenerator
  alias AccruePortal.ContextPostTest.Organization
  alias AccruePortal.ContextPostTest.TokenCounter
  alias AccruePortal.Copy

  import AccruePortal.Fixtures

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
      {:ok, pid} -> Process.unlink(pid)
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

  test "payment method actions appear only when the selected owner grants them", %{conn: conn} do
    owner_id = "org-payment-method-capabilities"

    %{customer: customer} =
      Accrue.Test.Factory.active_subscription(%{
        owner_type: Organization.__accrue__(:billable_type),
        owner_id: owner_id,
        email: "#{owner_id}@example.com",
        name: "Capability Organization"
      })

    default_method =
      payment_method_fixture!(customer, %{
        processor_id: "pm_capability_default",
        card_brand: "visa",
        card_last4: "4242",
        is_default: true
      })

    additional_method =
      payment_method_fixture!(customer, %{
        processor_id: "pm_capability_additional",
        card_brand: "mastercard",
        card_last4: "5555"
      })

    AccruePortal.TestRepo.update!(
      Accrue.Billing.Customer.changeset(customer, %{default_payment_method_id: default_method.id})
    )

    conn =
      Plug.Test.init_test_session(conn, %{
        "user_token" => "customer:00000000-0000-0000-0000-000000000123",
        "active_billable_id" => owner_id
      })

    ActionAdapter.grant(owner_id, [])
    assert {:ok, _view, read_only_html} = live(conn, "/org-billing/payment-methods")
    refute read_only_html =~ "/org-billing/payment-methods/new?"
    refute read_only_html =~ "/org-billing/payment-methods/#{additional_method.id}/default"
    refute read_only_html =~ "/org-billing/payment-methods/#{additional_method.id}/delete"

    ActionAdapter.grant(owner_id, [:payment_method_default])
    assert {:ok, _view, default_only_html} = live(conn, "/org-billing/payment-methods")
    assert default_only_html =~ "/org-billing/payment-methods/#{additional_method.id}/default"

    assert default_only_html =~
             "Set mastercard ending in 5555 as the default payment method for Test Organization?"

    refute default_only_html =~ "/org-billing/payment-methods/#{additional_method.id}/delete"
    refute default_only_html =~ "/org-billing/payment-methods/new?"

    ActionAdapter.grant(owner_id, [:payment_method_delete])
    assert {:ok, _view, delete_only_html} = live(conn, "/org-billing/payment-methods")
    assert delete_only_html =~ "/org-billing/payment-methods/#{additional_method.id}/delete"
    refute delete_only_html =~ "/org-billing/payment-methods/#{default_method.id}/delete"
    assert delete_only_html =~ Copy.payment_methods_default_removal_blocked()

    assert delete_only_html =~
             "Remove mastercard ending in 5555 from the saved payment methods for Test Organization?"
  end

  test "default and delete pins remain bound to organization A after selecting B", %{conn: conn} do
    owner_a = "org-payment-actions-a"
    owner_b = "org-payment-actions-b"

    %{customer: customer_a} =
      Accrue.Test.Factory.active_subscription(%{
        owner_type: Organization.__accrue__(:billable_type),
        owner_id: owner_a,
        email: "#{owner_a}@example.com",
        name: "Organization A"
      })

    %{customer: customer_b} =
      Accrue.Test.Factory.active_subscription(%{
        owner_type: Organization.__accrue__(:billable_type),
        owner_id: owner_b,
        email: "#{owner_b}@example.com",
        name: "Organization B"
      })

    old_default =
      payment_method_fixture!(customer_a, %{processor_id: "pm_org_a_default", is_default: true})

    new_default = payment_method_fixture!(customer_a, %{processor_id: "pm_org_a_new"})

    other_default =
      payment_method_fixture!(customer_b, %{processor_id: "pm_org_b_default", is_default: true})

    AccruePortal.TestRepo.update!(
      Accrue.Billing.Customer.changeset(customer_a, %{default_payment_method_id: old_default.id})
    )

    AccruePortal.TestRepo.update!(
      Accrue.Billing.Customer.changeset(customer_b, %{default_payment_method_id: other_default.id})
    )

    ActionAdapter.grant(owner_a, [:payment_method_default, :payment_method_delete])
    ActionAdapter.grant(owner_b, [:payment_method_default, :payment_method_delete])

    conn =
      Plug.Test.init_test_session(conn, %{
        "user_token" => "customer:00000000-0000-0000-0000-000000000123",
        "active_billable_id" => owner_a
      })

    assert {:ok, _view, html} = live(conn, "/org-billing/payment-methods")

    [[pin] | _] =
      Regex.scan(~r/name="context_pin" value="([^"]+)"/, html, capture: :all_but_first)

    switched_conn =
      Plug.Test.init_test_session(conn, %{
        "user_token" => "customer:00000000-0000-0000-0000-000000000123",
        "active_billable_id" => owner_b
      })

    default_calls_before = Accrue.Processor.Fake.call_count(:set_default_payment_method)

    default_response =
      post(switched_conn, "/org-billing/payment-methods/#{new_default.id}/default", %{
        "context_pin" => pin
      })

    assert_context_redirect(default_response, "/org-billing/payment-methods", pin)

    assert Accrue.Processor.Fake.call_count(:set_default_payment_method) ==
             default_calls_before + 1

    assert AccruePortal.TestRepo.get!(Accrue.Billing.Customer, customer_a.id).default_payment_method_id ==
             new_default.id

    assert AccruePortal.TestRepo.get!(Accrue.Billing.Customer, customer_b.id).default_payment_method_id ==
             other_default.id

    delete_calls_before = Accrue.Processor.Fake.call_count(:detach_payment_method)

    delete_response =
      post(switched_conn, "/org-billing/payment-methods/#{old_default.id}/delete", %{
        "context_pin" => pin
      })

    assert_context_redirect(delete_response, "/org-billing/payment-methods", pin)

    assert Accrue.Processor.Fake.call_count(:detach_payment_method) == delete_calls_before + 1

    assert %Accrue.Billing.PaymentMethod{} =
             AccruePortal.TestRepo.get(Accrue.Billing.PaymentMethod, old_default.id)
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

    other_owner_id = "org-create-switched"

    %{customer: other_customer} =
      Accrue.Test.Factory.active_subscription(%{
        owner_type: Organization.__accrue__(:billable_type),
        owner_id: other_owner_id,
        email: "#{other_owner_id}@example.com",
        name: "Other Organization"
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

    switched_conn =
      Plug.Test.init_test_session(conn, %{
        "user_token" => "customer:00000000-0000-0000-0000-000000000123",
        "active_billable_id" => other_owner_id
      })

    response =
      post(switched_conn, "/org-billing/payment-methods", %{
        "context_pin" => pin,
        "payment_method_nonce" => "fake-valid-nonce"
      })

    assert_context_redirect(response, "/org-billing/payment-methods", pin)

    assert Phoenix.Flash.get(response.assigns.flash, :info) ==
             Copy.add_payment_method_save_success()

    assert Accrue.Processor.Fake.call_count(:create_payment_method) == calls_before + 1

    assert %Accrue.Billing.PaymentMethod{id: payment_method_id} =
             AccruePortal.TestRepo.get_by(Accrue.Billing.PaymentMethod, customer_id: customer.id)

    assert %Accrue.Events.Event{
             actor_type: "user",
             actor_id: "00000000-0000-0000-0000-000000000123"
           } =
             AccruePortal.TestRepo.get_by(Accrue.Events.Event,
               type: "payment_method.added",
               subject_id: payment_method_id
             )

    refute AccruePortal.TestRepo.get_by(Accrue.Billing.PaymentMethod,
             customer_id: other_customer.id
           )
  end

  defp assert_context_redirect(response, expected_path, expected_pin) do
    redirect = redirected_to(response)
    uri = URI.parse(redirect)

    assert uri.path == expected_path
    assert URI.decode_query(uri.query || "")["context_pin"] == expected_pin
  end

  test "revoked original billable pin does not fall through to the newly selected billable", %{
    conn: conn
  } do
    original_owner = "org-revoked-original"
    new_owner = "org-new-selection"

    Accrue.Test.Factory.active_subscription(%{
      owner_type: Organization.__accrue__(:billable_type),
      owner_id: original_owner,
      email: "#{original_owner}@example.com",
      name: "Original Organization"
    })

    %{customer: new_customer} =
      Accrue.Test.Factory.active_subscription(%{
        owner_type: Organization.__accrue__(:billable_type),
        owner_id: new_owner,
        email: "#{new_owner}@example.com",
        name: "New Organization"
      })

    ActionAdapter.grant(original_owner, [:payment_method_create])
    ActionAdapter.grant(new_owner, [:payment_method_create])

    conn =
      Plug.Test.init_test_session(conn, %{
        "user_token" => "customer:00000000-0000-0000-0000-000000000123",
        "active_billable_id" => original_owner
      })

    assert {:ok, _view, html} = live(conn, "/org-billing/payment-methods")

    [_, encoded_pin] =
      Regex.run(~r/href="\/org-billing\/payment-methods\/new\?context_pin=([^"]+)"/, html)

    pin = URI.decode_www_form(encoded_pin)
    ActionAdapter.revoke(original_owner)
    calls_before = Accrue.Processor.Fake.call_count(:create_payment_method)

    switched_conn =
      Plug.Test.init_test_session(conn, %{
        "user_token" => "customer:00000000-0000-0000-0000-000000000123",
        "active_billable_id" => new_owner
      })

    response =
      post(switched_conn, "/org-billing/payment-methods", %{
        "context_pin" => pin,
        "payment_method_nonce" => "fake-valid-nonce"
      })

    assert redirected_to(response) == "/org-billing/blocked"
    assert Accrue.Processor.Fake.call_count(:create_payment_method) == calls_before

    refute AccruePortal.TestRepo.get_by(Accrue.Billing.PaymentMethod,
             customer_id: new_customer.id
           )
  end
end
