defmodule AccruePortal.ContextLiveTest do
  use AccruePortal.ConnCase, async: false
  @endpoint AccruePortal.ContextLiveTest.Endpoint

  alias Accrue.Billing.{Customer, Invoice, Subscription}
  alias Accrue.Portal.{Context, CustomerSession}
  alias AccruePortal.TestRepo

  import AccruePortal.Fixtures
  import Ecto.Query

  defmodule Organization do
    use Ecto.Schema
    use Accrue.Billable

    @primary_key {:id, :string, autogenerate: false}
    schema "portal_test_organizations" do
    end
  end

  defmodule Adapter do
    alias AccruePortal.ContextLiveTest.Organization

    def resolve(_actor, %{source: source, values: values}) when source in [:session, :pin] do
      id = Map.get(values, "active_billable_id") || Map.get(values, "owner_id")

      if id in ["org-a", "org-b"],
        do: {:ok, %{billable: %Organization{id: id}, display_name: "Org #{id}"}},
        else: {:error, :unavailable}
    end

    def authorize(actor, context, action, target) do
      :persistent_term.put({__MODULE__, :last_authorization}, {actor, context, action, target})
      revoked = :persistent_term.get({__MODULE__, :revoked}, MapSet.new())
      grants = :persistent_term.get({__MODULE__, :grants}, %{})

      if MapSet.member?(revoked, context.owner_id) or
           (action != :read and action not in Map.get(grants, context.owner_id, [])),
         do: {:error, :forbidden},
         else: :ok
    end

    def grant(id, actions) do
      grants = :persistent_term.get({__MODULE__, :grants}, %{})
      :persistent_term.put({__MODULE__, :grants}, Map.put(grants, id, actions))
    end

    def revoke(id) do
      revoked = :persistent_term.get({__MODULE__, :revoked}, MapSet.new())
      :persistent_term.put({__MODULE__, :revoked}, MapSet.put(revoked, id))
    end

    def clear do
      for key <- [:last_authorization, :revoked, :grants],
          do: :persistent_term.erase({__MODULE__, key})
    end
  end

  defmodule Router do
    use Phoenix.Router
    import Phoenix.ConnTest, except: [get: 3, post: 3]
    import Accrue.Portal.Router

    accrue_portal("/org-billing",
      session_keys: [:user_token, :active_billable_id],
      context_adapter: Adapter
    )
  end

  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :accrue_portal
    socket("/live", Phoenix.LiveView.Socket)

    plug(Plug.Session,
      store: :cookie,
      key: "_accrue_portal_context_live",
      signing_salt: "context-live"
    )

    plug(Router)
  end

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AccruePortal.Fixtures.AuthAdapter)
    Adapter.clear()

    Application.put_env(:accrue_portal, Endpoint,
      secret_key_base: String.duplicate("abcd1234", 8),
      server: false,
      url: [host: "localhost"],
      live_view: [signing_salt: "context-live-test"],
      render_errors: [formats: [html: &Phoenix.Controller.status_message_from_template/1]]
    )

    if Process.whereis(Endpoint) == nil, do: start_supervised!(Endpoint)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, previous_auth)
      Adapter.clear()
    end)

    :ok
  end

  test "home and subscription routes keep the selected billed identity and signed navigation pin",
       %{conn: conn} do
    %{user: actor, customer: personal_customer} = subscription_bundle_fixture!()
    personal_subscription = insert_subscription!(personal_customer, "sub-personal-#{actor.id}")
    {customer, subscription, invoice} = organization_records!("org-a")

    conn =
      sign_in_conn(conn, actor)
      |> Plug.Test.init_test_session(%{
        "user_token" => "customer:" <> actor.id,
        "active_billable_id" => "org-a"
      })

    assert {:ok, _view, home} = live_context(conn, "/org-billing/", actor, "org-a")
    assert home =~ "Org org-a"
    assert home =~ subscription.processor_id
    refute home =~ personal_subscription.processor_id

    assert [_, encoded_pin] =
             Regex.run(~r{href="/org-billing/subscriptions\?context_pin=([^"]+)"}, home)

    assert {:ok, _view, list} =
             live(conn, "/org-billing/subscriptions?context_pin=" <> encoded_pin)

    assert list =~ subscription.processor_id
    refute list =~ personal_subscription.processor_id
    assert list =~ "Org org-a"

    assert {:ok, _view, detail} =
             live(
               conn,
               "/org-billing/subscriptions/#{subscription.id}?context_pin=" <> encoded_pin
             )

    assert detail =~ subscription.processor_id
    refute detail =~ invoice.number
    assert customer.owner_id == "org-a"
  end

  test "revoked subscription cancellation clears confirmation and performs no provider mutation",
       %{conn: conn} do
    actor = user_fixture()
    {customer, subscription, _invoice} = organization_records!("org-a")
    Adapter.grant("org-a", [:subscription_cancel])
    conn = signed_context(conn, actor, "org-a")

    assert {:ok, view, html} =
             live_context(conn, "/org-billing/subscriptions/#{subscription.id}", actor, "org-a")

    assert html =~ "Org org-a"
    view |> element("button[phx-click='toggle_cancel_confirmation']") |> render_click()
    assert has_element?(view, "button", "Keep subscription")
    Adapter.revoke("org-a")
    before = Accrue.Processor.Fake.call_count(:update_subscription)

    html = view |> element("button[phx-click='cancel']") |> render_click()

    refute html =~ "Keep subscription"
    assert html =~ "not submitted"
    refute TestRepo.get!(Subscription, subscription.id).cancel_at_period_end
    assert Accrue.Processor.Fake.call_count(:update_subscription) == before
    assert customer.id == subscription.customer_id
  end

  test "a forged foreign subscription event cannot mutate another customer's subscription", %{
    conn: conn
  } do
    actor = user_fixture()
    {_customer, subscription, _invoice} = organization_records!("org-a")
    foreign = subscription_bundle_fixture!()
    Adapter.grant("org-a", [:subscription_cancel])
    conn = signed_context(conn, actor, "org-a")

    assert {:ok, view, _html} =
             live_context(conn, "/org-billing/subscriptions/#{subscription.id}", actor, "org-a")

    before = Accrue.Processor.Fake.call_count(:update_subscription)

    render_click(view, "cancel", %{"id" => foreign.subscription.id})

    refute TestRepo.get!(Subscription, subscription.id).cancel_at_period_end
    refute TestRepo.get!(Subscription, foreign.subscription.id).cancel_at_period_end
    assert Accrue.Processor.Fake.call_count(:update_subscription) == before
  end

  test "an authorized subscription cancellation records the signed-in human actor", %{conn: conn} do
    actor = user_fixture()

    %{subscription: subscription} =
      Accrue.Test.Factory.active_subscription(%{
        owner_type: Organization.__accrue__(:billable_type),
        owner_id: "org-a",
        email: "org-a-actor-test@example.test"
      })

    Adapter.grant("org-a", [:subscription_cancel])
    conn = signed_context(conn, actor, "org-a")

    assert {:ok, view, _html} =
             live_context(conn, "/org-billing/subscriptions/#{subscription.id}", actor, "org-a")

    view |> element("button[phx-click='toggle_cancel_confirmation']") |> render_click()
    render_click(view, "cancel", %{})

    event =
      Accrue.Events.Event
      |> where(
        [event],
        event.type == "subscription.canceled" and event.subject_id == ^subscription.id
      )
      |> TestRepo.one!()

    assert event.actor_type == "user"
    assert event.actor_id == actor.id
  end

  test "invoices are loaded for the selected organization and a revoked pinned reconnect is blocked",
       %{conn: conn} do
    actor = user_fixture()
    {_customer, _subscription, invoice} = organization_records!("org-a")
    {_foreign_customer, _foreign_subscription, foreign_invoice} = organization_records!("org-b")
    Adapter.grant("org-a", [])
    conn = signed_context(conn, actor, "org-a")
    pin = context_pin!(actor, "org-a")

    assert {:ok, _view, html} = live(conn, "/org-billing/invoices?context_pin=#{pin}")
    assert html =~ invoice.number
    refute html =~ foreign_invoice.number
    assert html =~ "Org org-a"
    Adapter.revoke("org-a")

    assert {:error, {:redirect, %{to: "/org-billing/blocked"}}} =
             live(conn, "/org-billing/invoices?context_pin=#{pin}")
  end

  test "an invoice route pins its initial selection into the browser URL for reconnect", %{
    conn: conn
  } do
    actor = user_fixture()
    {_customer, _subscription, invoice} = organization_records!("org-a")
    {_foreign_customer, _foreign_subscription, foreign_invoice} = organization_records!("org-b")
    Adapter.grant("org-a", [])
    Adapter.grant("org-b", [])
    conn = signed_context(conn, actor, "org-a")

    assert {:error, {:live_redirect, %{to: pinned_path}}} = live(conn, "/org-billing/invoices")
    assert pinned_path =~ "/org-billing/invoices?context_pin="
    assert {:ok, _view, html} = live(conn, pinned_path)
    assert html =~ invoice.number
    refute html =~ foreign_invoice.number

    switched_conn = signed_context(build_conn(), actor, "org-b")

    assert {:ok, _view, old_tab_html} =
             live(switched_conn, pinned_path)

    assert old_tab_html =~ invoice.number
    refute old_tab_html =~ foreign_invoice.number
  end

  defp context_pin!(actor, organization_id) do
    session = %{
      "user_token" => "customer:" <> actor.id,
      "active_billable_id" => organization_id,
      "accrue_portal" => %{
        "context_adapter" => Adapter,
        "context_session_keys" => ["active_billable_id"],
        "mount_path" => "/org-billing"
      }
    }

    assert {:ok, context} =
             CustomerSession.resolve(session,
               context_adapter: Adapter,
               session_keys: ["active_billable_id"],
               mount_path: "/org-billing",
               create?: false
             )

    assert {:ok, pin} = Context.mint_pin(context, Endpoint)
    pin
  end

  defp live_context(conn, path, actor, organization_id) do
    live(conn, path <> "?context_pin=" <> context_pin!(actor, organization_id))
  end

  defp signed_context(conn, actor, organization_id) do
    conn
    |> sign_in_conn(actor)
    |> Plug.Test.init_test_session(%{
      "user_token" => "customer:" <> actor.id,
      "active_billable_id" => organization_id
    })
  end

  defp organization_records!(organization_id) do
    customer =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: Organization.__accrue__(:billable_type),
        owner_id: organization_id,
        processor: Accrue.Processor.name(),
        processor_id: "cus-#{organization_id}",
        email: "#{organization_id}@example.test",
        metadata: %{},
        data: %{}
      })
      |> TestRepo.insert!()

    subscription = insert_subscription!(customer, "sub-#{organization_id}")

    invoice =
      %Invoice{}
      |> Invoice.changeset(%{
        customer_id: customer.id,
        subscription_id: subscription.id,
        processor: customer.processor,
        processor_id: "in-#{organization_id}",
        number: "INV-#{organization_id}",
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
      })
      |> TestRepo.insert!()

    {customer, subscription, invoice}
  end

  defp insert_subscription!(customer, processor_id) do
    %Subscription{}
    |> Subscription.changeset(%{
      customer_id: customer.id,
      processor: customer.processor,
      processor_id: processor_id,
      status: :active,
      currency: "usd",
      current_period_start: DateTime.add(DateTime.utc_now(), -86_400, :second),
      current_period_end: DateTime.add(DateTime.utc_now(), 2_592_000, :second)
    })
    |> TestRepo.insert!()
  end
end
