defmodule AccrueAdmin.SubscriptionAreaTapFormatter do
  use GenServer

  def init(_opts), do: {:ok, []}

  def handle_cast({:test_finished, test}, results), do: {:noreply, [test | results]}

  def handle_cast({:suite_finished, _times}, results) do
    tests = Enum.reverse(results)
    IO.puts("TAP version 13")

    tests
    |> Enum.with_index(1)
    |> Enum.each(fn {test, index} ->
      name = "#{inspect(test.module)}::#{test.name}" |> String.replace(~r/[\r\n]+/u, " ")

      case test.state do
        nil ->
          IO.puts("ok #{index} - #{name}")

        {:skipped, _reason} ->
          IO.puts("ok #{index} - #{name} # SKIP")

        {:failed, failures} ->
          IO.puts("not ok #{index} - #{name}")

          Enum.each(failures, fn failure ->
            failure
            |> inspect(pretty: false, limit: :infinity)
            |> String.split("\n")
            |> Enum.each(&IO.puts("# " <> &1))
          end)

        _ ->
          IO.puts("not ok #{index} - #{name}")
      end
    end)

    IO.puts("1..#{length(tests)}")
    {:noreply, []}
  end

  def handle_cast(_event, results), do: {:noreply, results}
end

ExUnit.start(formatters: [AccrueAdmin.SubscriptionAreaTapFormatter])

defmodule AccrueAdmin.SubscriptionAreaTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Accrue.Processor.Fake
  alias AccrueAdmin.Components.Detail
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Live.SubscriptionLive
  alias AccrueAdmin.Storybook.SubscriptionScenarios

  @fixed_now ~U[2026-10-25 12:00:00Z]

  setup do
    previous_env = Application.get_env(:accrue, :env, :unset)
    previous_locale = Application.get_env(:localize, :default_locale, :unset)
    Application.put_env(:accrue, :env, :test)
    Application.put_env(:localize, :default_locale, :en)
    {:ok, _started} = Application.ensure_all_started(:localize)

    case Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Fake.reset()
    :ok = Fake.advance(DateTime.diff(@fixed_now, Fake.current_time(), :second))

    on_exit(fn ->
      :ok = Fake.reset()

      case previous_env do
        :unset -> Application.delete_env(:accrue, :env)
        value -> Application.put_env(:accrue, :env, value)
      end

      case previous_locale do
        :unset -> Application.delete_env(:localize, :default_locale)
        value -> Application.put_env(:localize, :default_locale, value)
      end
    end)

    :ok
  end

  test "summary action links and buttons expose the complete context exactly once" do
    plan_context =
      Copy.action_hidden_context("Change",
        resource: "plan",
        object: "subscription sub_plan_example"
      )

    renewal_context =
      Copy.action_hidden_context("Change",
        resource: "renewal",
        object: "subscription sub_renewal_example"
      )

    rows = [
      %{
        label: "Plan / price",
        value: "pro_monthly",
        action_label: "Change",
        action_context: plan_context,
        action_href: "/billing/plans?org=cadence-demo"
      },
      %{
        label: "Renews / ends",
        value: "Renews Nov 24, 2026",
        action_label: "Change",
        action_context: renewal_context,
        action_event: "open_action_drawer",
        action_value: "cancel_at_period_end",
        action_target: "#subscription-page"
      }
    ]

    html = render_component(&Detail.summary_list/1, rows: rows)
    document = Floki.parse_document!(html)
    [link] = Floki.find(document, "a.ax-summary-list-action")
    [button] = Floki.find(document, "button.ax-summary-list-action")

    assert Floki.attribute(link, "aria-label") == [plan_context]
    assert Floki.attribute(button, "aria-label") == [renewal_context]
    assert Floki.text(Floki.find(link, "span:not(.ax-visually-hidden)")) == "Change"
    assert Floki.text(Floki.find(button, "span:not(.ax-visually-hidden)")) == "Change"
    assert Floki.attribute(Floki.find(link, ".ax-visually-hidden"), "aria-hidden") == ["true"]
    assert Floki.attribute(Floki.find(button, ".ax-visually-hidden"), "aria-hidden") == ["true"]
    assert Floki.attribute(link, "href") == ["/billing/plans?org=cadence-demo"]
    assert Floki.attribute(button, "phx-click") == ["open_action_drawer"]
    assert Floki.attribute(button, "phx-target") == ["#subscription-page"]
    assert Floki.attribute(button, "phx-value-action_type") == ["cancel_at_period_end"]

    assigns = SubscriptionScenarios.assigns!(:active)
    production_html = render_component(&SubscriptionLive.subscription_area/1, assigns)

    production_document = Floki.parse_document!(production_html)
    plan_row = summary_row(production_document, "Plan / price")
    renewal_row = summary_row(production_document, "Renews / ends")

    assert Floki.attribute(Floki.find(plan_row, "button.ax-summary-list-action"), "aria-label") ==
             ["Change plan for subscription sub_cadence_active"]

    assert Floki.attribute(Floki.find(renewal_row, "button.ax-summary-list-action"), "aria-label") ==
             ["Change renewal for subscription sub_cadence_active"]
  end

  test "a generic summary action without context keeps its visible accessible name" do
    html =
      render_component(&Detail.summary_list/1,
        rows: [
          %{
            label: "Customer",
            value: "Acme",
            action_label: "View",
            action_href: "/billing/customers/cus_1"
          }
        ]
      )

    document = Floki.parse_document!(html)
    [link] = Floki.find(document, "a.ax-summary-list-action")

    assert Floki.attribute(link, "aria-label") == []
    assert Floki.find(link, ".ax-visually-hidden") == []
    assert Floki.text(link) == "View"
    assert Floki.attribute(link, "href") == ["/billing/customers/cus_1"]
  end

  test "the production area retains the semantic hierarchy and full copied ID" do
    assigns = SubscriptionScenarios.assigns!(:active)
    html = render_component(&SubscriptionLive.subscription_area/1, assigns)

    document = Floki.parse_document!(html)

    assert length(Floki.find(document, "h1")) == 1
    assert Floki.text(Floki.find(document, "h1")) == "Acme Research"
    assert Floki.text(Floki.find(document, "h2")) == "Subscription actions"
    assert Floki.find(document, "dl dt") != []
    assert Floki.find(document, "dl dd") != []
    assert Floki.attribute(Floki.find(document, "#subscription-summary-id"), "type") == ["button"]

    assert Floki.attribute(Floki.find(document, "#subscription-summary-id"), "aria-label") == [
             "Copy subscription ID"
           ]

    assert Floki.attribute(
             Floki.find(document, "#subscription-summary-id"),
             "data-clipboard-text"
           ) ==
             ["sub_cadence_active"]

    assert length(Floki.find(document, "[data-ax-action-band]")) == 1
  end

  test "scheduled cancellation renders its effective timestamp and only eligible renewal actions" do
    facts = CadenceSubscriptionFacts.fetch!(:scheduled_cancellation)
    assigns = SubscriptionScenarios.assigns!(facts)
    html = render_component(&SubscriptionLive.subscription_area/1, assigns)
    document = Floki.parse_document!(html)
    cancellation = summary_row(document, "Cancellation")
    renewal = summary_row(document, "Renews / ends")
    period_end = DateTime.to_iso8601(assigns.subscription.current_period_end)

    assert Floki.text(cancellation) =~ "Scheduled for"
    assert Floki.attribute(Floki.find(cancellation, "time"), "datetime") == [period_end]
    assert Floki.text(renewal) =~ "Ends"

    assert Floki.attribute(Floki.find(renewal, "button.ax-summary-list-action"), "aria-label") ==
             ["Change renewal for subscription sub_cadence_active"]

    assert Floki.attribute(
             Floki.find(renewal, "button.ax-summary-list-action"),
             "phx-value-action_type"
           ) ==
             ["resume"]

    refute Floki.text(Floki.find(document, "[data-ax-action-band]")) =~ "Cancel renewal"

    assert Floki.text(Floki.find(document, "[role=menuitem][phx-value-action_type=resume]")) =~
             "Resume subscription"

    refute "cancel_at_period_end" in Floki.attribute(
             Floki.find(document, "button[data-ax-primary-action]"),
             "phx-value-action_type"
           )
  end

  test "scheduled cancellation without a projected date uses production fallback copy" do
    facts =
      CadenceSubscriptionFacts.fetch!(:scheduled_cancellation)
      |> put_in([:subscription, :current_period_end], nil)

    assigns = SubscriptionScenarios.assigns!(facts)

    document =
      render_component(&SubscriptionLive.subscription_area/1, assigns) |> Floki.parse_document!()

    assert summary_value(document, "Cancellation") == "Scheduled; effective date not shown"
    assert summary_value(document, "Renews / ends") == "End date unavailable"

    assert Floki.find(summary_row(document, "Renews / ends"), "button.ax-summary-list-action") !=
             []
  end

  test "incomplete evidence preserves status and exact production caveat order" do
    assigns = SubscriptionScenarios.assigns!(:incomplete_evidence)

    document =
      render_component(&SubscriptionLive.subscription_area/1, assigns) |> Floki.parse_document!()

    assert Floki.text(Floki.find(document, "h1")) == "Acme Research"
    assert summary_value(document, "Lifecycle state") == "Active"

    assert summary_value(document, "Billing evidence") ==
             "Renewal date unavailable, Price unavailable, Charge amount unavailable"

    assert summary_value(document, "Plan / price") == "Price unavailable"
    assert summary_value(document, "Current period") == "Current period unavailable"
    assert summary_value(document, "Renews / ends") == "Renewal date unavailable"
    assert summary_value(document, "Amount (MRR)") == "Unavailable"
    assert summary_value(document, "Seats / quantity") == "12"
    assert summary_row(document, "Dunning") == nil
  end

  test "optional caveats cover zero, one, and many missing projections without an empty subscription" do
    active = render_facts(CadenceSubscriptionFacts.fetch!(:active))

    one_missing =
      CadenceSubscriptionFacts.fetch!(:active)
      |> put_in([:subscription, :current_period_end], nil)

    one_missing = render_facts(one_missing)
    incomplete = render_facts(CadenceSubscriptionFacts.fetch!(:incomplete_evidence))

    assert summary_value(active, "Billing evidence") == "Charge amount unavailable"

    assert summary_value(one_missing, "Billing evidence") ==
             "Renewal date unavailable, Charge amount unavailable"

    assert summary_value(incomplete, "Billing evidence") ==
             "Renewal date unavailable, Price unavailable, Charge amount unavailable"

    assert Floki.find(active, "[data-ax-summary-list] dt") != []
  end

  test "optional seats and dunning rows follow real item and lifecycle evidence" do
    active = render_facts(CadenceSubscriptionFacts.fetch!(:active))
    dunning = render_facts(CadenceSubscriptionFacts.fetch!(:dunning_active))

    assert summary_value(active, "Seats / quantity") == "12"
    assert summary_row(active, "Dunning") == nil
    assert summary_row(dunning, "Dunning") != nil

    multi_item_facts =
      CadenceSubscriptionFacts.fetch!(:active)
      |> update_in([:subscription, :items], fn [item | _] ->
        [
          item,
          %{
            item
            | id: "4e0deebc-9567-44ac-b779-7ce6bfb7aa08",
              processor_id: "si_cadence_active_2",
              quantity: 3
          }
        ]
      end)

    multi_item = render_facts(multi_item_facts)
    assert summary_row(multi_item, "Seats / quantity") == nil
  end

  test "provider-pruned empty action groups are omitted for a valid Braintree subscription" do
    assigns = SubscriptionScenarios.assigns!(:braintree_pruned)

    document =
      render_component(&SubscriptionLive.subscription_area/1, assigns) |> Floki.parse_document!()

    groups = Floki.find(document, "[data-ax-action-overflow-menu] [role=group]")

    assert Enum.map(groups, &Floki.attribute(&1, "aria-label")) == [["Danger zone"]]
    assert Enum.all?(groups, &(Floki.find(&1, "[role=menuitem]") != []))
  end

  defp summary_row(document, label) do
    Enum.find(Floki.find(document, "[data-ax-summary-list] .ax-summary-list-row"), fn row ->
      Floki.text(Floki.find(row, "dt")) == label
    end)
  end

  defp summary_value(document, label) do
    document
    |> summary_row(label)
    |> Floki.find("dd.ax-summary-list-value")
    |> Floki.text()
    |> String.trim()
  end

  defp render_facts(facts) do
    facts
    |> SubscriptionScenarios.assigns!()
    |> then(fn assigns -> render_component(&SubscriptionLive.subscription_area/1, assigns) end)
    |> Floki.parse_document!()
  end
end
