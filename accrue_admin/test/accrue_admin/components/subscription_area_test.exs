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
      name = test.name |> to_string() |> String.replace(~r/[\r\n]+/u, " ")

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

  alias AccrueAdmin.Components.Detail
  alias AccrueAdmin.Live.SubscriptionLive
  alias AccrueAdmin.Storybook.SubscriptionScenarios
  alias AccrueAdmin.Copy

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

  defp summary_row(document, label) do
    Enum.find(Floki.find(document, "[data-ax-summary-list] .ax-summary-list-row"), fn row ->
      Floki.text(Floki.find(row, "dt")) == label
    end)
  end
end
