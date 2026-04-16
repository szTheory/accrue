defmodule Accrue.Jobs.DunningSweeperTest do
  @moduledoc """
  Phase 4 Plan 04 — BILL-15 DunningSweeper (D4-02 hybrid).

  Verifies the thin grace-period overlay:

    * Scans candidate subs older than grace_days with no prior sweep attempt.
    * Calls `Processor.update_subscription/3` to flip the Stripe row.
    * Stamps `dunning_sweep_attempted_at` AFTER a successful Stripe call.
    * NEVER flips local `subscription.status` (D2-29 — Stripe is canonical).
    * Records a `dunning.terminal_action_requested` audit event.
    * Disabled mode short-circuits.
    * Stripe errors do NOT stamp sweep_attempted_at (so next tick retries).
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias Accrue.Jobs.DunningSweeper

  @default_policy [
    mode: :stripe_smart_retries,
    grace_days: 14,
    terminal_action: :unpaid,
    telemetry_prefix: [:accrue, :ops]
  ]

  setup do
    # Pin a known dunning policy for this test module — other test
    # modules may delete or override the :dunning app env.
    prior = Application.get_env(:accrue, :dunning, :__unset__)
    Application.put_env(:accrue, :dunning, @default_policy)

    on_exit(fn ->
      case prior do
        :__unset__ -> Application.delete_env(:accrue, :dunning)
        v -> Application.put_env(:accrue, :dunning, v)
      end
    end)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_dunning",
        email: "dunning@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  defp seed_sub(customer, attrs) do
    # Seed Fake with a subscription. The Fake assigns its own
    # processor_id; we mirror it in the local projection so the
    # sweeper's update_subscription(processor_id, ...) call lands on
    # the same row.
    {:ok, fake_sub} =
      Accrue.Processor.Fake.create_subscription(
        %{customer: customer.processor_id, items: [%{price: "price_basic"}]},
        []
      )

    row_attrs =
      attrs
      |> Map.put_new(:status, :past_due)
      |> Map.put(:processor_id, fake_sub.id)

    {:ok, sub} =
      %Subscription{customer_id: customer.id, processor: "fake"}
      |> Subscription.force_status_changeset(row_attrs)
      |> Repo.insert()

    sub
  end

  describe "sweep/0 — no candidates" do
    test "returns {:ok, 0} when nothing is past_due", %{customer: _cus} do
      assert {:ok, 0} = DunningSweeper.sweep()
    end
  end

  describe "sweep/0 — disabled mode" do
    test "short-circuits when mode is :disabled", %{customer: cus} do
      _sub =
        seed_sub(cus, %{
          past_due_since: DateTime.add(Accrue.Clock.utc_now(), -30 * 86_400, :second),
          dunning_sweep_attempted_at: nil
        })

      prior = Application.get_env(:accrue, :dunning, [])

      Application.put_env(
        :accrue,
        :dunning,
        Keyword.merge(prior, mode: :disabled, grace_days: 14, terminal_action: :unpaid)
      )

      try do
        assert {:ok, 0} = DunningSweeper.sweep()
      after
        Application.put_env(:accrue, :dunning, prior)
      end
    end
  end

  describe "sweep/0 — happy path" do
    test "calls Stripe, stamps sweep_attempted_at, records event, does NOT flip local status",
         %{customer: cus} do
      sub =
        seed_sub(cus, %{
          past_due_since: DateTime.add(Accrue.Clock.utc_now(), -30 * 86_400, :second),
          dunning_sweep_attempted_at: nil
        })

      assert {:ok, 1} = DunningSweeper.sweep()

      reloaded = Repo.reload!(sub)

      # Local status is NOT flipped — Stripe (via webhook) is canonical.
      assert reloaded.status == :past_due
      assert %DateTime{} = reloaded.dunning_sweep_attempted_at

      # Audit event recorded.
      event =
        Repo.one!(
          from(e in "accrue_events",
            where: e.type == "dunning.terminal_action_requested",
            select: %{type: e.type, subject_id: e.subject_id}
          )
        )

      assert event.type == "dunning.terminal_action_requested"
    end

    test "skips rows where dunning_sweep_attempted_at is already set", %{customer: cus} do
      _sub =
        seed_sub(cus, %{
          past_due_since: DateTime.add(Accrue.Clock.utc_now(), -30 * 86_400, :second),
          dunning_sweep_attempted_at: DateTime.add(Accrue.Clock.utc_now(), -3600, :second)
        })

      # Candidates query filters these out, so sweep returns {:ok, 0}.
      assert {:ok, 0} = DunningSweeper.sweep()
    end

    test "skips rows inside grace window", %{customer: cus} do
      _sub =
        seed_sub(cus, %{
          past_due_since: DateTime.add(Accrue.Clock.utc_now(), -2 * 86_400, :second),
          dunning_sweep_attempted_at: nil
        })

      assert {:ok, 0} = DunningSweeper.sweep()
    end
  end

  describe "sweep/0 — Stripe errors" do
    test "does NOT stamp sweep_attempted_at when Stripe returns error", %{customer: cus} do
      sub =
        seed_sub(cus, %{
          past_due_since: DateTime.add(Accrue.Clock.utc_now(), -30 * 86_400, :second),
          dunning_sweep_attempted_at: nil
        })

      err = %Accrue.APIError{code: "lock_timeout", http_status: 500, message: "stripe 500"}
      :ok = Accrue.Processor.Fake.scripted_response(:update_subscription, {:error, err})

      assert {:ok, 0} = DunningSweeper.sweep()

      reloaded = Repo.reload!(sub)
      assert is_nil(reloaded.dunning_sweep_attempted_at)
      assert reloaded.status == :past_due
    end
  end

  describe "worker wiring" do
    test "queue is :accrue_dunning" do
      assert DunningSweeper.__opts__()[:queue] == :accrue_dunning
    end
  end
end
