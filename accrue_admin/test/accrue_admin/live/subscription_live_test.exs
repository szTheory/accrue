defmodule AccrueAdmin.SubscriptionLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Subscription}
  alias Accrue.Events
  alias Accrue.Events.Event
  alias Accrue.Repo
  alias Accrue.Test.Factory
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Subscriptions
  alias AccrueAdmin.TestRepo

  import Ecto.Query

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def current_user(_session), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(user), do: user[:id]

    @impl Accrue.Auth
    def step_up_challenge(_user, _action), do: %{kind: :totp, message: "Verify admin action"}

    @impl Accrue.Auth
    def verify_step_up(_user, %{"code" => "123456"}, action) do
      case Application.get_env(:accrue_admin, :expected_step_up_subject_id) do
        nil -> :ok
        expected when action.subject_id == expected -> :ok
        _expected -> {:error, :wrong_subject_id}
      end
    end

    def verify_step_up(_user, _params, _action), do: {:error, :invalid_code}
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, prior)
      Application.delete_env(:accrue_admin, :expected_step_up_subject_id)
    end)

    %{subscription: subscription} =
      Factory.active_subscription(%{owner_id: "subscription-detail"})

    subscription =
      subscription
      |> Subscription.changeset(%{automatic_tax_disabled_reason: "requires_location_inputs"})
      |> TestRepo.update!()

    {:ok, source_event} =
      Events.record(%{
        type: "invoice.payment_failed",
        subject_type: "Subscription",
        subject_id: subscription.id,
        actor_type: "system"
      })

    {:ok,
     subscription: Repo.preload(subscription, [:customer, :subscription_items]),
     source_event: source_event}
  end

  test "renders canonical predicate summary and subscription timeline", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert html =~ "Canonical predicates"
    assert html =~ "active"
    assert html =~ "invoice.payment_failed"
    assert html =~ "Automatic tax is currently disabled"
    assert html =~ "Local reason: Requires Location Inputs."

    assert html =~
             "Update the customer tax location in the host app, then retry recurring tax on this subscription."
  end

  test "cancel now requires step-up and records admin audit linkage", %{
    conn: conn,
    subscription: subscription,
    source_event: source_event
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, subscription.id)

    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    html =
      render_submit(
        element(view, "[data-role='cancel-now-form']"),
        %{"action_type" => "cancel_now", "source_event_id" => Integer.to_string(source_event.id)}
      )

    assert html =~ "Confirm action"

    html = render_click(element(view, "[data-role='confirm-action']"))
    assert html =~ "Step-up required"

    html =
      render_submit(element(view, "form[phx-submit='step_up_submit']"), %{"code" => "123456"})

    assert html =~ "Subscription action recorded."

    audit_event =
      TestRepo.one!(
        from(event in Event,
          where:
            event.type == "admin.subscription.action.completed" and
              event.caused_by_event_id == ^source_event.id
        )
      )

    assert audit_event.actor_type == "admin"

    canceled = TestRepo.get!(Subscription, subscription.id)
    assert Accrue.Billing.Subscription.canceled?(canceled)
  end

  test "subscription loader denies rows outside the active organization" do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
    allowed_subscription = insert_subscription(allowed_customer)
    denied_subscription = insert_subscription(denied_customer)
    allowed_subscription_id = allowed_subscription.id

    owner_scope = organization_owner_scope("org_allowed")

    assert {:ok, %{id: ^allowed_subscription_id}} =
             Subscriptions.detail(allowed_subscription.id, owner_scope)

    assert :not_found = Subscriptions.detail(denied_subscription.id, owner_scope)
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "fake",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      preferred_locale: "en",
      metadata: %{},
      data: %{}
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_subscription(customer) do
    %Subscription{}
    |> Subscription.changeset(%{
      customer_id: customer.id,
      processor: "fake",
      processor_id: "sub_" <> Integer.to_string(System.unique_integer([:positive])),
      status: :active,
      currency: "usd"
    })
    |> TestRepo.insert!()
  end

  defp organization_owner_scope(organization_id) do
    %OwnerScope{
      mode: :organization,
      current_admin: %{id: "admin_1", role: :admin},
      organization_id: organization_id,
      organization_slug: "allowed-org",
      platform_admin?: false,
      admin_org_ids: [organization_id],
      active_organization_id: organization_id,
      active_organization_slug: "allowed-org"
    }
  end
end
