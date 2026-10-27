Code.require_file(Path.expand("../../../../dev_support/phase252_tap_formatter.ex", __DIR__))

if System.get_env("PHASE252_TAP_REPORT") == "1" do
  ExUnit.start(formatters: [Accrue.Test.Phase252TapFormatter])
else
  ExUnit.start()
end

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
    canonical_variations = Enum.take(Subscription.variations(), 3)
    ids = Enum.map(canonical_variations, & &1.id)
    assert ids == [:active, :scheduled_cancellation, :incomplete_evidence]

    rendered =
      Enum.map(ids, fn id ->
        variation = Enum.find(canonical_variations, &(&1.id == id))
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

  test "the compiled page story declares supported review and result snapshots" do
    assert Enum.map(Subscription.variations(), & &1.id) == [
             :active,
             :scheduled_cancellation,
             :incomplete_evidence,
             :review_cancel_now,
             :awaiting_step_up,
             :dispatching,
             :result_confirmed,
             :result_pending,
             :result_failed
           ]
  end

  test "review, step-up, dispatch and results retain production copy and safe status semantics" do
    variations = Subscription.variations()

    html_by_id =
      Map.new(variations, fn variation ->
        {variation.id, render_component(Subscription.function(), variation.attributes)}
      end)

    review = Floki.parse_document!(html_by_id.review_cancel_now)
    awaiting = Floki.parse_document!(html_by_id.awaiting_step_up)
    dispatching = Floki.parse_document!(html_by_id.dispatching)
    confirmed = Floki.parse_document!(html_by_id.result_confirmed)
    pending = Floki.parse_document!(html_by_id.result_pending)
    failed = Floki.parse_document!(html_by_id.result_failed)

    expected_review_copy =
      AccrueAdmin.Copy.subscription_confirm_workflow_message("cancel_now",
        subscription_id: "sub_cadence_active",
        customer_id: "Acme Research",
        source_event_id: nil
      ) <> " This cancels the subscription immediately."

    assert Floki.text(Floki.find(review, "[data-role='confirm-panel']")) =~ expected_review_copy
    assert Floki.attribute(Floki.find(review, "[data-role='confirm-action']"), "disabled") == []

    assert Floki.attribute(
             Floki.find(review, "#subscription-action-drawer"),
             "data-focus-trap-close-event"
           ) ==
             ["cancel_pending_action"]

    assert Floki.text(Floki.find(review, "#subscription-action-drawer")) =~ "Back to subscription"

    assert Floki.text(Floki.find(awaiting, "#accrue-admin-step-up-dialog")) =~
             "Verify admin action"

    awaiting_buttons = Floki.find(awaiting, "[data-role='confirm-action']")
    assert awaiting_buttons != []
    assert Enum.all?(awaiting_buttons, &(Floki.attribute(&1, "disabled") != []))

    assert Floki.attribute(
             Floki.find(awaiting, "#accrue-admin-step-up-dialog"),
             "data-focus-trap-close-event"
           ) ==
             ["step_up_dismiss"]

    dispatching_buttons = Floki.find(dispatching, "[data-role='confirm-action']")
    assert dispatching_buttons != []
    assert Enum.all?(dispatching_buttons, &(Floki.attribute(&1, "disabled") != []))

    for {document, kind} <- [
          {confirmed, :confirmed},
          {pending, :pending},
          {failed, :failed}
        ] do
      [result] = Floki.find(document, "[data-role='subscription-action-result']")
      assert Floki.attribute(result, "role") == ["status"]
      assert Floki.attribute(result, "aria-live") == ["polite"]
      assert Floki.text(result) =~ SubscriptionLive.action_result_message(kind)
      assert Floki.find(result, "a") != []
    end

    assert Floki.text(pending) =~ "A completed subscription change is not confirmed"

    assert Floki.attribute(
             Floki.find(pending, "[data-role='subscription-action-result'] a"),
             "href"
           ) ==
             [
               "/billing/events?org=cadence-demo&subject_id=ea26f232-b276-42bb-b862-d5c1b7d9d457&subject_type=Subscription"
             ]

    refute Floki.text(failed) =~ "completed"
    assert Process.whereis(AccrueAdmin.TestRepo) == nil
  end

  test "lazy disclosures and zero, one, and many related/item groups follow production omission rules" do
    assigns = SubscriptionPageScenarios.assigns!(:active)
    unloaded = Map.merge(assigns, %{timeline_events_loaded?: false, raw_json_loaded?: false})

    loaded =
      Map.merge(assigns, %{
        timeline_events: [],
        timeline_events_loaded?: true,
        raw_json_loaded?: true
      })

    unloaded_document =
      render_component(&SubscriptionLive.subscription_page/1, unloaded) |> Floki.parse_document!()

    loaded_document =
      render_component(&SubscriptionLive.subscription_page/1, loaded) |> Floki.parse_document!()

    assert Floki.text(unloaded_document) =~ "Open this section to load subscription activity."

    assert Floki.text(unloaded_document) =~
             "Open this section to load the escaped subscription payload."

    assert Floki.find(unloaded_document, "#subscription-data") == []
    assert length(Floki.find(loaded_document, "#subscription-data")) == 1
    refute Floki.text(loaded_document) =~ "payment_method_token"
    refute Floki.text(loaded_document) =~ "secret_token_value"

    resources = assigns.related_items

    for {items, expected_count} <- [
          {[], 0},
          {Enum.take(resources, 1), 1},
          {resources, length(resources)}
        ] do
      related_assigns = Map.put(assigns, :related_items, items)
      related_html = render_component(&SubscriptionLive.subscription_page/1, related_assigns)
      document = Floki.parse_document!(related_html)

      assert length(Floki.find(document, ".ax-related-resources .ax-related-item")) ==
               expected_count

      assert length(Floki.find(document, ".ax-related-resources")) ==
               if(expected_count == 0, do: 0, else: 1)
    end

    subscription = assigns.subscription
    [item] = subscription.subscription_items

    second_item =
      item
      |> Map.put(:id, "a3d78ad0-0315-4b28-90db-3b68519f00aa")
      |> Map.put(:processor_id, "si_cadence_active_secondary")
      |> Map.put(:quantity, 2)

    item_cases = [
      {[], "-", false},
      {[item], "12", true},
      {[item, second_item], "14", false}
    ]

    for {items, quantity, has_single_quantity_summary?} <- item_cases do
      page_subscription = Map.put(subscription, :subscription_items, items)
      item_assigns = Map.put(assigns, :subscription, page_subscription)
      item_html = render_component(&SubscriptionLive.subscription_page/1, item_assigns)
      document = Floki.parse_document!(item_html)

      fields = Floki.find(document, "[data-ax-drill-section='billing-items'] .ax-field")
      quantity_field = Enum.find(fields, &(Floki.text(Floki.find(&1, "dt")) == "Quantity"))
      assert Floki.text(Floki.find(quantity_field, "dd")) == quantity

      summary_labels =
        Floki.find(document, "[data-ax-summary-list] dt") |> Enum.map(&Floki.text/1)

      assert "Seats / quantity" in summary_labels == has_single_quantity_summary?
    end

    assert Process.whereis(AccrueAdmin.TestRepo) == nil
  end
end
