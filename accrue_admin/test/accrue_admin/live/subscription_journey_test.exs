defmodule AccrueAdmin.SubscriptionJourneyTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Subscription, SubscriptionItem}
  alias Accrue.Events.Event
  alias Accrue.Processor.Fake
  alias Accrue.Test.Factory
  alias AccrueAdmin.Copy
  alias AccrueAdmin.TestRepo

  import Ecto.Query

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}),
      do: %{id: Application.get_env(:accrue_admin, :test_actor_id, "admin_1"), role: :admin}

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
      Application.delete_env(:accrue_admin, :test_actor_id)
    end)

    :ok
  end

  test "scoped list to reviewed cancellation returns with filters after two inert dismissals", %{
    conn: conn
  } do
    owner_id = Ecto.UUID.generate()
    org_slug = "phase253-journey-#{System.unique_integer([:positive])}"
    token = "phase253-journey-#{System.unique_integer([:positive])}"
    target_email = "#{token}-target@example.test"

    %{subscription: subscription, customer: customer} =
      Factory.active_subscription(%{
        owner_type: "Organization",
        owner_id: owner_id,
        email: target_email
      })

    neighbor =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "fake",
        processor_id: "sub_#{token}_neighbor",
        status: :active,
        currency: "usd"
      })
      |> TestRepo.insert!()

    subscription_time = ~U[2026-10-27 12:00:00.000000Z]
    neighbor_time = ~U[2026-10-26 12:00:00.000000Z]
    TestRepo.update!(Ecto.Changeset.change(subscription, inserted_at: subscription_time))
    TestRepo.update!(Ecto.Changeset.change(neighbor, inserted_at: neighbor_time))

    {:ok, source_event} =
      Accrue.Events.record(%{
        type: "invoice.payment_failed",
        subject_type: "Subscription",
        subject_id: subscription.id,
        actor_type: "system"
      })

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: owner_id,
        active_organization_slug: org_slug,
        admin_organization_ids: [owner_id]
      )

    list_path =
      "/billing/subscriptions?" <>
        URI.encode_query(%{
          "org" => org_slug,
          "view" => "all",
          "status" => "active",
          "q" => token
        })

    assert {:ok, list_view, list_html} = live(conn, list_path)
    assert has_element?(list_view, "[name='q'][value='#{token}']")
    assert has_element?(list_view, "[data-row-id='#{subscription.id}']")
    assert has_element?(list_view, "[data-row-id='#{neighbor.id}']")

    row_ids =
      list_html
      |> Floki.parse_document!()
      |> Floki.find("tbody > tr[data-row-id]")
      |> Enum.map(&(Floki.attribute(&1, "data-row-id") |> hd()))

    assert row_ids == [to_string(subscription.id), to_string(neighbor.id)]

    detail_href =
      list_html
      |> Floki.parse_document!()
      |> Floki.find("tr[data-row-id='#{subscription.id}'] a.ax-link")
      |> Floki.attribute("href")
      |> hd()

    parsed_detail = URI.parse(detail_href)
    assert parsed_detail.path == "/billing/subscriptions/#{subscription.id}"
    detail_params = URI.decode_query(parsed_detail.query)
    assert detail_params["org"] == org_slug
    assert detail_params["return_to"]

    return_to = detail_params["return_to"]
    return_params = URI.decode_query(URI.parse(return_to).query)
    assert URI.parse(return_to).path == "/billing/subscriptions"

    assert return_params == %{
             "org" => org_slug,
             "view" => "all",
             "status" => "active",
             "q" => token
           }

    assert {:ok, view, detail_html} = live(conn, detail_href)
    assert detail_html =~ "Back to subscriptions"

    render_click(element(view, "button[role='menuitem']", Copy.subscription_action_cancel_now()))

    review =
      render_submit(
        element(
          view,
          "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
        ),
        %{"action_type" => "cancel_now", "source_event_id" => Integer.to_string(source_event.id)}
      )

    assert review =~ "Subscription ID: #{subscription.id}"
    assert review =~ "Processor subscription ID: #{subscription.processor_id}"
    assert review =~ "Customer ID: #{customer.id}"
    assert review =~ "Customer owner: Organization #{owner_id}"
    assert review =~ org_slug
    assert review =~ Copy.subscription_action_cancel_now()
    assert review =~ Copy.subscription_action_back_to_subscription()
    assert Fake.call_count(:cancel_subscription) == 0
    calls_before_dismissals = Fake.calls()

    render_click(view, "cancel_pending_action", %{})
    refute has_element?(view, "[data-role='confirm-panel']")
    assert_no_cancellation_effects(subscription.id, calls_before_dismissals)

    render_click(element(view, "button[role='menuitem']", Copy.subscription_action_cancel_now()))

    render_submit(
      element(
        view,
        "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
      ),
      %{"action_type" => "cancel_now"}
    )

    assert render_click(element(view, "[data-role='confirm-action']")) =~ "Step-up required"
    assert has_element?(view, "[data-role='step-up-test-mirror']")
    render_click(view, "step_up_dismiss", %{})
    refute has_element?(view, "[data-role='step-up-test-mirror']")
    assert has_element?(view, "[data-role='confirm-action']")
    render_click(view, "cancel_pending_action", %{})
    refute has_element?(view, "[data-role='confirm-panel']")
    assert_no_cancellation_effects(subscription.id, calls_before_dismissals)

    Application.put_env(:accrue_admin, :expected_step_up_subject_id, subscription.id)
    render_click(element(view, "button[role='menuitem']", Copy.subscription_action_cancel_now()))

    render_submit(
      element(
        view,
        "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
      ),
      %{"action_type" => "cancel_now", "source_event_id" => Integer.to_string(source_event.id)}
    )

    assert render_click(element(view, "[data-role='confirm-action']")) =~ "Step-up required"
    result = render_submit(view, "step_up_submit", %{"code" => "123456"})
    assert result =~ Copy.subscription_action_recorded_info()
    assert Fake.call_count(:cancel_subscription) == 1

    assert [{:cancel_subscription, [processor_id, _opts]}] =
             Enum.filter(Fake.calls(), fn {operation, _args} ->
               operation == :cancel_subscription
             end)

    assert processor_id == subscription.processor_id
    assert Accrue.Billing.Subscription.canceled?(TestRepo.get!(Subscription, subscription.id))

    assert length(
             TestRepo.all(
               from(event in Event,
                 where:
                   event.type == "subscription.canceled" and event.subject_id == ^subscription.id
               )
             )
           ) == 1

    audit_event =
      TestRepo.one!(
        from(event in Event,
          where:
            event.type == "admin.subscription.action.completed" and
              event.subject_id == ^subscription.id and
              event.caused_by_event_id == ^source_event.id
        )
      )

    assert audit_event.actor_type == "admin"

    return_href =
      view
      |> element("a", "Back to subscriptions")
      |> render()
      |> Floki.parse_document!()
      |> Floki.find("a")
      |> Floki.attribute("href")
      |> hd()

    assert URI.parse(return_href).path == "/billing/subscriptions"
    assert URI.decode_query(URI.parse(return_href).query) == return_params
    assert {:ok, returned_view, returned_html} = live(conn, return_href)
    assert has_element?(returned_view, "[name='q'][value='#{token}']")
    assert has_element?(returned_view, "[data-row-id='#{neighbor.id}']")
    refute has_element?(returned_view, "[data-row-id='#{subscription.id}']")

    returned_ids =
      returned_html
      |> Floki.parse_document!()
      |> Floki.find("tbody > tr[data-row-id]")
      |> Enum.map(&(Floki.attribute(&1, "data-row-id") |> hd()))

    assert returned_ids == [to_string(neighbor.id)]
  end

  defp assert_no_cancellation_effects(subscription_id, original_fake_calls) do
    assert Fake.calls() == original_fake_calls
    refute TestRepo.get_by(Event, type: "subscription.canceled", subject_id: subscription_id)

    refute TestRepo.get_by(Event,
             type: "admin.subscription.action.completed",
             subject_id: subscription_id
           )

    assert not Accrue.Billing.Subscription.canceled?(TestRepo.get!(Subscription, subscription_id))

    assert TestRepo.aggregate(
             from(item in SubscriptionItem, where: item.subscription_id == ^subscription_id),
             :count
           ) > 0
  end
end
