Code.require_file(Path.expand("../../../../dev_support/phase252_tap_formatter.ex", __DIR__))
ExUnit.start(formatters: [Accrue.Test.Phase252TapFormatter])

unless Code.ensure_loaded?(CadenceSubscriptionFacts) do
  Code.require_file(
    Path.expand("../../../../dev_support/ui_scenarios/cadence_subscriptions.exs", __DIR__)
  )
end

defmodule AccrueAdmin.SubscriptionPageSliceTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Live.SubscriptionLive
  alias AccrueAdmin.Storybook.Pages.Subscription
  alias AccrueAdmin.Storybook.SubscriptionPageScenarios
  alias PhoenixStorybook.Stories.Variation

  setup do
    {:ok, _started} = Application.ensure_all_started(:localize)
    Application.put_env(:localize, :default_locale, :en)
    :ok
  end

  test "the production owner exposes the shared whole subscription page renderer" do
    assert {:module, SubscriptionLive} = Code.ensure_loaded(SubscriptionLive)
    assert function_exported?(SubscriptionLive, :subscription_page, 1)
  end

  test "the active page variation is byte-identical to the production renderer and preserves its whole composition" do
    assert Process.whereis(AccrueAdmin.TestRepo) == nil

    variation = Enum.find(Subscription.variations(), &(&1.id == :active))
    assert %Variation{} = variation

    assigns = SubscriptionPageScenarios.assigns!(variation.attributes)
    story_html = render_component(Subscription.function(), variation.attributes)
    page_html = render_component(&SubscriptionLive.subscription_page/1, assigns)
    routed_html = render_component(&SubscriptionLive.render/1, assigns)

    assert story_html == page_html
    assert routed_html == page_html

    document = Floki.parse_document!(page_html)
    assert length(Floki.find(document, "#accrue-admin-shell")) == 1
    assert length(Floki.find(document, ".ax-subscription-detail-page")) == 1
    assert length(Floki.find(document, ".ax-subscription-detail-page h1")) == 1
    assert Floki.text(Floki.find(document, ".ax-subscription-detail-page h1")) =~ "Acme Research"

    assert Floki.find(document, "[data-ax-summary-list] dt")
           |> Enum.map(&Floki.text/1) == [
             "Lifecycle state",
             "Billing evidence",
             "Customer",
             "Plan / price",
             "Current period",
             "Cancellation",
             "Renews / ends",
             "Amount (MRR)",
             "Seats / quantity"
           ]

    assert Floki.attribute(Floki.find(document, "dl a"), "href") == [
             "/billing/events?org=cadence-demo&subject_id=ea26f232-b276-42bb-b862-d5c1b7d9d457&subject_type=Subscription",
             "/billing/customers/3a632d30-37d1-4c08-a5bf-2b14f2862520?org=cadence-demo"
           ]

    assert Floki.attribute(Floki.find(document, "button[data-ax-primary-action]"), "phx-click") ==
             ["open_action_drawer", "open_action_drawer"]

    assert Floki.attribute(
             Floki.find(document, "button[data-ax-primary-action]"),
             "phx-value-action_type"
           ) == ["swap_plan", "cancel_at_period_end"]

    drawer_assigns = Map.merge(assigns, %{drawer_action_type: "swap_plan", step_up_pending: true})
    drawer_html = render_component(&SubscriptionLive.subscription_page/1, drawer_assigns)

    markers = [
      "class=\"ax-breadcrumbs\"",
      "class=\"ax-detail-back-link\"",
      "data-ax-summary-list",
      "data-ax-action-band",
      "data-ax-related-resources",
      "data-ax-drill-section=\"billing-items\"",
      "data-ax-drill-section=\"dunning-recovery\"",
      "data-ax-drill-section=\"tax-compliance\"",
      "data-ax-lazy-activity",
      "data-ax-lazy-json",
      "id=\"subscription-action-drawer\"",
      "id=\"accrue-admin-step-up-dialog\""
    ]

    positions =
      Enum.map(markers, fn marker ->
        {position, _length} = :binary.match(drawer_html, marker)
        position
      end)

    assert positions == Enum.sort(positions)
    assert length(Floki.find(document, "[data-ax-lazy-activity][phx-click='load_activity']")) == 1
    assert length(Floki.find(document, "[data-ax-lazy-json][phx-click='load_raw_json']")) == 1
    drawer_document = Floki.parse_document!(drawer_html)
    assert length(Floki.find(drawer_document, "#subscription-action-drawer")) == 1
    assert length(Floki.find(drawer_document, "#accrue-admin-step-up-dialog")) == 1
    assert function_exported?(SubscriptionLive, :handle_event, 3)
    assert Process.whereis(AccrueAdmin.TestRepo) == nil
  end

  test "canonical whole-page variations retain the active cancellation and incomplete facts" do
    ids = Enum.map(Subscription.variations(), & &1.id)
    assert ids == [:active, :scheduled_cancellation, :incomplete_evidence]

    rendered =
      Enum.map(ids, fn id ->
        variation = Enum.find(Subscription.variations(), &(&1.id == id))
        assigns = SubscriptionPageScenarios.assigns!(variation.attributes)

        {id, render_component(Subscription.function(), variation.attributes),
         assigns.subscription}
      end)

    assert Process.whereis(AccrueAdmin.TestRepo) == nil

    {_id, active_html, active} = Enum.find(rendered, &(elem(&1, 0) == :active))

    {_id, scheduled_html, scheduled} =
      Enum.find(rendered, &(elem(&1, 0) == :scheduled_cancellation))

    {_id, incomplete_html, incomplete} =
      Enum.find(rendered, &(elem(&1, 0) == :incomplete_evidence))

    assert active.processor_id == "sub_cadence_active"
    assert scheduled.cancel_at_period_end
    assert scheduled_html =~ "Scheduled for"
    assert incomplete.current_period_start == nil
    assert incomplete.current_period_end == nil
    assert incomplete_html =~ "Renewal date unavailable"
    assert incomplete_html =~ "Price unavailable"
    assert incomplete_html =~ "Charge amount unavailable"
    assert active_html =~ "Subscription actions"
    assert Process.whereis(AccrueAdmin.TestRepo) == nil
  end
end
