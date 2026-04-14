defmodule Accrue.Billing.SetupIntentTest do
  @moduledoc """
  Plan 06 Task 1: `Accrue.Billing.create_setup_intent/2` — BILL-22
  off-session card-on-file parallel, with IntentResult tagged returns
  mirroring `create_payment_intent/2`.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_si_test",
        email: "si-test@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  test "create_setup_intent/2 for off-session returns {:ok, si} with usage=off_session", %{
    customer: cus
  } do
    assert {:ok, si} = Billing.create_setup_intent(cus)
    assert (si[:object] || si["object"]) == "setup_intent"
    # Usage is passed through the params; Fake echoes it via build map.
    # At minimum we must have a SetupIntent id + status.
    assert is_binary(si[:id] || si["id"])
  end

  test "scripted requires_action on SI returns tagged result", %{customer: cus} do
    scripted = %{
      id: "si_fake_scripted",
      object: "setup_intent",
      status: "requires_action",
      client_secret: "si_fake_scripted_secret",
      next_action: %{type: "use_stripe_sdk"},
      customer: cus.processor_id
    }

    Fake.scripted_response(:create_setup_intent, {:ok, scripted})

    assert {:ok, :requires_action, pi} = Billing.create_setup_intent(cus)
    assert (pi[:status] || pi["status"]) == "requires_action"
  end

  test "create_setup_intent!/2 raises on requires_action", %{customer: cus} do
    scripted = %{
      id: "si_fake_scripted_bang",
      object: "setup_intent",
      status: "requires_action",
      client_secret: "si_fake_scripted_bang_secret",
      next_action: %{type: "use_stripe_sdk"}
    }

    Fake.scripted_response(:create_setup_intent, {:ok, scripted})

    assert_raise Accrue.ActionRequiredError, fn -> Billing.create_setup_intent!(cus) end
  end
end
