defmodule AccrueAdmin.Test.TapFormatter do
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
        nil -> IO.puts("ok #{index} - #{name}")
        {:skipped, _reason} -> IO.puts("ok #{index} - #{name} # SKIP")
        _ -> IO.puts("not ok #{index} - #{name}")
      end
    end)

    IO.puts("1..#{length(tests)}")
    {:noreply, []}
  end

  def handle_cast(_event, results), do: {:noreply, results}
end

ExUnit.start(formatters: [AccrueAdmin.Test.TapFormatter])

repo_root = Path.expand("../../../../", __DIR__)
Code.require_file(Path.join(repo_root, "storybook/components/subscription_detail.story.exs"))

defmodule AccrueAdmin.SubscriptionStorySliceTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Live.SubscriptionLive
  alias AccrueAdmin.Storybook.Components.SubscriptionDetail
  alias PhoenixStorybook.Stories.Variation

  test "the declared active variation renders the production area from real facts without Repo" do
    assert Process.whereis(AccrueAdmin.TestRepo) == nil

    variation =
      SubscriptionDetail.variations()
      |> Enum.find(&(&1.id == :active))

    assert %Variation{} = variation

    assigns = AccrueAdmin.Storybook.SubscriptionScenarios.assigns!(variation.attributes)
    story_html = render_component(SubscriptionDetail.function(), variation.attributes)
    production_html = render_component(&SubscriptionLive.subscription_area/1, assigns)

    assert story_html == production_html

    document = Floki.parse_document!(story_html)
    text = Floki.text(document)

    assert Floki.text(Floki.find(document, "h1")) =~ "Acme"
    assert text =~ "Active"
    assert text =~ "Lifecycle state"
    assert text =~ "Customer"
    assert text =~ "Plan / price"
    assert text =~ "Current period"
    assert text =~ "Subscription actions"
    assert Floki.attribute(Floki.find(document, "dl a"), "href") == [
             "/billing/customers/3a632d30-37d1-4c08-a5bf-2b14f2862520?org=cadence-demo"
           ]

    assert Floki.attribute(Floki.find(document, "button[phx-click='open_action_drawer']"), "phx-value-action_type") ==
             ["swap_plan", "cancel_at_period_end"]
  end
end
