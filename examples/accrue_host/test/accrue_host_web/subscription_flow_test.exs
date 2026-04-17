defmodule AccrueHostWeb.SubscriptionFlowTest do
  use AccrueHost.HostFlowProofCase, async: false

  import Ecto.Query
  import ExUnit.CaptureLog
  import Phoenix.LiveViewTest

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias AccrueHost.Repo

  @moduletag :phase10

  setup :register_and_log_in_user

  test "signed-in user can reach billing, start price_basic, and cancel it", %{
    conn: conn,
    user: user
  } do
    organization = AccrueHost.AccountsFixtures.organization_fixture(%{owner: user})
    conn = log_in_user(conn, user, active_organization_id: organization.id)

    home_conn = get(conn, ~p"/")
    home_html = html_response(home_conn, 200)

    assert home_html =~ ~p"/app/billing"
    assert home_html =~ "Go to billing"

    assert Repo.one(
             from(customer in Customer,
               where:
                 customer.owner_type == "Organization" and customer.owner_id == ^organization.id
             )
           ) == nil

    {:ok, view, html} = live(conn, ~p"/app/billing")

    assert html =~ "Active organization"
    assert html =~ "Start organization subscription"
    assert html =~ "price_basic"

    view
    |> form("#tax-location-form", %{
      "tax_location" => %{
        "line1" => "27 Fredrick Ave",
        "city" => "Albany",
        "state" => "NY",
        "postal_code" => "12207",
        "country" => "US"
      }
    })
    |> render_submit()

    assert render(view) =~ "Tax location saved."

    start_log =
      capture_log(fn ->
        view
        |> element("[data-plan-id='price_basic'] button", "Start organization subscription")
        |> render_click()
      end)

    refute start_log =~ "no operation_id"

    customer =
      Repo.one!(
        from(customer in Customer,
          where: customer.owner_type == "Organization" and customer.owner_id == ^organization.id
        )
      )

    started_subscription =
      customer
      |> latest_subscription!()
      |> Repo.preload(:subscription_items)

    assert started_subscription.customer_id == customer.id
    assert started_subscription.processor == "fake"
    assert [item] = started_subscription.subscription_items
    assert item.price_id == "price_basic"

    assert render(view) =~ "Current subscription"
    assert render(view) =~ "price_basic"

    view
    |> element("button", "Cancel organization subscription")
    |> render_click()

    assert render(view) =~
             "Cancel organization subscription: Confirm cancellation before ending organization access."

    cancel_log =
      capture_log(fn ->
        view
        |> element("button", "Confirm cancellation")
        |> render_click()
      end)

    refute cancel_log =~ "no operation_id"

    {:ok, canceled_subscription} = Billing.get_subscription(started_subscription.id)

    assert Subscription.canceled?(canceled_subscription) or
             Subscription.canceling?(canceled_subscription)

    assert render(view) =~ "Subscription canceled."
  end

  defp latest_subscription!(%Customer{id: customer_id}) do
    Repo.one!(
      from(subscription in Subscription,
        where: subscription.customer_id == ^customer_id,
        order_by: [desc: subscription.inserted_at],
        limit: 1
      )
    )
  end
end
