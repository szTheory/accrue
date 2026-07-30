defmodule Accrue.Entitlements.StripeSyncRefreshWorkerTest do
  @moduledoc """
  Phase 213 Plan 02 — thin Oban wrapper for advisory Stripe-native refresh.
  """

  use Accrue.BillingCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  alias Accrue.Billing.EntitlementSummary
  alias Accrue.Entitlements.StripeSync.RefreshWorker

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "stripe",
        processor_id: "cus_fake_worker",
        email: "stripe-sync-worker@example.test"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  describe "job shape" do
    test "uses the existing webhooks queue with scalar JSON-safe customer_id args", %{
      customer: customer
    } do
      assert %Ecto.Changeset{valid?: true} =
               changeset = RefreshWorker.new(%{"customer_id" => customer.id})

      job = Ecto.Changeset.apply_changes(changeset)

      assert job.queue == "accrue_webhooks"
      assert job.max_attempts == 25
      assert job.args == %{"customer_id" => customer.id}
    end
  end

  describe "perform/1" do
    test "loads the customer and delegates once to StripeSync.refresh/1", %{customer: customer} do
      enable_sync()

      Fake.put_entitlements(customer.processor_id, [
        %{
          "id" => "ent_worker_alpha",
          "object" => "entitlements.active_entitlement",
          "feature" => "feat_alpha",
          "lookup_key" => "alpha",
          "livemode" => false
        }
      ])

      assert {:ok, %EntitlementSummary{} = summary} =
               perform_job(RefreshWorker, %{"customer_id" => customer.id})

      assert summary.customer_id == customer.id
      assert [%{"lookup_key" => "alpha"}] = summary.data["entitlements"]["data"]
      assert Fake.call_count(:list_active_entitlements) == 1
    end

    test "disabled refresh completes without calling the processor", %{customer: customer} do
      disable_sync()

      assert :ok = perform_job(RefreshWorker, %{"customer_id" => customer.id})
      assert Fake.call_count(:list_active_entitlements) == 0
      assert Repo.aggregate(EntitlementSummary, :count) == 0
    end

    test "missing customer cancels deterministically" do
      assert {:cancel, :customer_not_found} =
               perform_job(RefreshWorker, %{"customer_id" => Ecto.UUID.generate()})
    end

    test "refresh errors are returned for Oban retry semantics", %{customer: customer} do
      enable_sync()

      error = %Accrue.APIError{message: "processor unavailable", code: "processor_unavailable"}
      Fake.scripted_response(:list_active_entitlements, {:error, error})

      assert {:error, ^error} = perform_job(RefreshWorker, %{"customer_id" => customer.id})
      assert Fake.call_count(:list_active_entitlements) == 1
    end
  end

  defp enable_sync do
    put_sync_mode(:advisory)
  end

  defp disable_sync do
    put_sync_mode(:disabled)
  end

  defp put_sync_mode(mode) do
    previous = Application.get_env(:accrue, :entitlements)

    Application.put_env(
      :accrue,
      :entitlements,
      Keyword.put(previous || [], :stripe_native_sync, mode)
    )

    ExUnit.Callbacks.on_exit(fn ->
      if previous do
        Application.put_env(:accrue, :entitlements, previous)
      else
        Application.delete_env(:accrue, :entitlements)
      end
    end)
  end
end
