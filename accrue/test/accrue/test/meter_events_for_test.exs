defmodule Accrue.Test.MeterEventsForTest do
  @moduledoc false
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.Customer
  alias Accrue.Processor.Stripe

  test "meter_events_for/1 raises when processor is not Fake" do
    prior = Application.get_env(:accrue, :processor)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_meter_guard",
        email: "guard@example.com"
      })
      |> Repo.insert()

    Application.put_env(:accrue, :processor, Stripe)

    on_exit(fn ->
      if prior != nil do
        Application.put_env(:accrue, :processor, prior)
      else
        Application.delete_env(:accrue, :processor)
      end
    end)

    assert_raise ArgumentError, fn ->
      Accrue.Test.meter_events_for(customer)
    end
  end
end
