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

ExUnit.start(formatters: [AccrueAdmin.Test.TapFormatter])

repo_root = Path.expand("../../../../", __DIR__)

unless Code.ensure_loaded?(AccrueAdmin.Storybook.Components.SubscriptionDetail) do
  Code.require_file(Path.join(repo_root, "storybook/components/subscription_detail.story.exs"))
end

defmodule AccrueAdmin.SubscriptionStorySliceTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Live.SubscriptionLive
  alias AccrueAdmin.Storybook.Components.SubscriptionDetail
  alias Accrue.Processor.Fake
  alias PhoenixStorybook.Stories.Variation

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
    assert text =~ "No cancellation scheduled"
    assert text =~ "Unavailable"

    assert Floki.attribute(
             Floki.find(document, "#subscription-summary-id"),
             "data-clipboard-text"
           ) ==
             ["sub_cadence_active"]

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

    assert Floki.attribute(
             Floki.find(document, "button[data-ax-primary-action]"),
             "phx-value-action_type"
           ) ==
             ["swap_plan", "cancel_at_period_end"]
  end

  test "absent, malformed, or unrecognized story input is rejected" do
    assert_raise ArgumentError, fn ->
      AccrueAdmin.Storybook.SubscriptionScenarios.assigns!(%{})
    end

    assert_raise ArgumentError, fn ->
      AccrueAdmin.Storybook.SubscriptionScenarios.assigns!(%{scenario: :unknown})
    end

    assert_raise ArgumentError, fn ->
      AccrueAdmin.Storybook.SubscriptionScenarios.assigns!(%{
        scenario: :active,
        subscription: %{status: nil}
      })
    end
  end

  test "canonical lifecycle variation IDs sit beside preserved compatibility IDs" do
    ids = Enum.map(SubscriptionDetail.variations(), & &1.id)

    assert ids == [
             :active,
             :scheduled_cancellation,
             :incomplete_evidence,
             :populated,
             :braintree_pruned,
             :dunning_active
           ]
  end

  test "all canonical lifecycle variations delegate to the shared production area" do
    for id <- [:active, :scheduled_cancellation, :incomplete_evidence] do
      variation = Enum.find(SubscriptionDetail.variations(), &(&1.id == id))

      assert %Variation{} = variation
      assert variation.attributes.scenario == id

      assigns = AccrueAdmin.Storybook.SubscriptionScenarios.assigns!(variation.attributes)
      story_html = render_component(SubscriptionDetail.function(), variation.attributes)
      production_html = render_component(&SubscriptionLive.subscription_area/1, assigns)

      assert story_html == production_html
      assert Process.whereis(AccrueAdmin.TestRepo) == nil
    end
  end
end
