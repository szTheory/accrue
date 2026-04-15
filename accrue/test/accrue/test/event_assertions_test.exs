defmodule Accrue.Test.EventAssertionsTest do
  use Accrue.RepoCase, async: false

  setup do
    {:ok, event} =
      Accrue.Events.record(%{
        type: "subscription.created",
        subject_type: "Subscription",
        subject_id: "sub_fake_00001",
        actor_type: "system",
        data: %{
          "customer_id" => "cus_fake_00001",
          "status" => "active",
          "metadata" => %{"plan" => "pro"}
        }
      })

    %{event: event}
  end

  test "assert_event_recorded/1 supports keyword filters" do
    assert_event("""
    import Accrue.Test.EventAssertions
    assert_event_recorded(type: "subscription.created", subject_id: "sub_fake_00001")
    """)
  end

  test "assert_event_recorded/1 supports struct subject matching", %{event: event} do
    assert_event("""
    import Accrue.Test.EventAssertions
    subject = %{__struct__: Accrue.Billing.Subscription, id: "sub_fake_00001"}
    assert_event_recorded(subject: subject, type: #{inspect(event.type)})
    """)
  end

  test "assert_event_recorded/1 supports partial map matching" do
    assert_event("""
    import Accrue.Test.EventAssertions
    assert_event_recorded(data: %{"customer_id" => "cus_fake_00001"})
    """)
  end

  test "assert_event_recorded/1 supports one-arity predicate functions" do
    assert_event("""
    import Accrue.Test.EventAssertions
    assert_event_recorded(fn event -> event.type == "subscription.created" end)
    """)
  end

  test "refute/no-op companions support absent event assertions" do
    assert_event("""
    import Accrue.Test.EventAssertions
    refute_event_recorded(type: "subscription.deleted")
    assert_no_events_recorded(type: "invoice.voided")
    """)
  end

  defp assert_event(source) do
    assert {_, _binding} = Code.eval_string(source)
  end
end
