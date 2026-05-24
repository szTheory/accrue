defmodule Accrue.ConfigDunningCampaignTest do
  @moduledoc """
  DUN-01 — config-driven multi-step dunning cadence validation.

  Covers the intra-list `{:custom}` validator (`validate_dunning_campaign/1`),
  the cross-field boot raise (`validate_dunning_campaign_grace!/1` via
  `validate_at_boot!/0`), the default-journey accessors, and stream_data
  property invariants for strictly-increasing/unique steps.

  Mutates the `:accrue` app env (`:dunning`) and exercises the boot
  validation path, so this case MUST be `async: false` (mirrors
  `test/accrue/config_entitlements_test.exs`).
  """
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Accrue.Config

  setup do
    prev = Application.get_env(:accrue, :dunning, :__unset__)

    on_exit(fn ->
      case prev do
        :__unset__ -> Application.delete_env(:accrue, :dunning)
        value -> Application.put_env(:accrue, :dunning, value)
      end
    end)

    :ok
  end

  # --- intra-list validator: validate_dunning_campaign/1 (DUN-01, D-04/D-05) ---

  describe "validate_dunning_campaign/1 — valid cadences (DUN-01)" do
    test "accepts a strictly-increasing, unique-key step list -> {:ok, normalized}" do
      steps = [
        [after_days: 0, key: :reminder, template: Accrue.Emails.InvoicePaymentFailed],
        [after_days: 5, key: :action_required, template: Accrue.Emails.DunningActionRequired],
        [after_days: 12, key: :final_notice, template: Accrue.Emails.DunningFinalNotice]
      ]

      assert {:ok, [enabled: true, steps: normalized]} =
               Config.validate_dunning_campaign(enabled: true, steps: steps)

      assert Enum.map(normalized, &Keyword.fetch!(&1, :after_days)) == [0, 5, 12]
      assert Enum.map(normalized, &Keyword.fetch!(&1, :key)) ==
               [:reminder, :action_required, :final_notice]
    end

    test "accepts a single-step cadence" do
      steps = [[after_days: 0, key: :only, template: Accrue.Emails.InvoicePaymentFailed]]
      assert {:ok, [enabled: true, steps: ^steps]} =
               Config.validate_dunning_campaign(enabled: true, steps: steps)
    end
  end

  describe "validate_dunning_campaign/1 — invalid cadences (DUN-01, D-04)" do
    test "non-increasing after_days -> {:error, _}" do
      steps = [
        [after_days: 5, key: :a, template: M],
        [after_days: 1, key: :b, template: N]
      ]

      assert {:error, msg} = Config.validate_dunning_campaign(enabled: true, steps: steps)
      assert msg =~ "increasing"
    end

    test "duplicate after_days -> {:error, _}" do
      steps = [
        [after_days: 0, key: :a, template: M],
        [after_days: 0, key: :b, template: N]
      ]

      assert {:error, msg} = Config.validate_dunning_campaign(enabled: true, steps: steps)
      assert msg =~ "after_days"
    end

    test "duplicate key -> {:error, _}" do
      steps = [
        [after_days: 0, key: :dup, template: M],
        [after_days: 5, key: :dup, template: N]
      ]

      assert {:error, msg} = Config.validate_dunning_campaign(enabled: true, steps: steps)
      assert msg =~ "key"
    end

    test "a step missing a required field (per @step_schema) -> {:error, _}" do
      steps = [[after_days: 0, key: :a]]
      assert {:error, _} = Config.validate_dunning_campaign(enabled: true, steps: steps)
    end

    test "a non-list/non-false value -> {:error, _}" do
      assert {:error, _} = Config.validate_dunning_campaign(:nonsense)
    end
  end

  describe "validate_dunning_campaign/1 — opt-out normalization (DUN-01, D-05)" do
    test "campaign: false normalizes to [enabled: false, steps: []]" do
      assert {:ok, [enabled: false, steps: []]} = Config.validate_dunning_campaign(false)
    end

    test "enabled: false with steps still normalizes (steps preserved when valid)" do
      steps = [[after_days: 0, key: :a, template: M]]
      assert {:ok, [enabled: false, steps: ^steps]} =
               Config.validate_dunning_campaign(enabled: false, steps: steps)
    end

    test "enabled: true with steps: [] is a LOUD error (not a silent disable)" do
      assert {:error, msg} = Config.validate_dunning_campaign(enabled: true, steps: [])
      assert msg =~ "empty"
    end
  end

  # --- default journey accessors (DUN-01, D-01/D-07) --------------------------

  describe "default journey accessors (DUN-01, D-01/D-07)" do
    test "no host override: dunning_campaign_steps/0 yields offsets [0, 5, 12] with the right keys/templates" do
      Application.delete_env(:accrue, :dunning)

      steps = Config.dunning_campaign_steps()

      assert Enum.map(steps, &Keyword.fetch!(&1, :after_days)) == [0, 5, 12]
      assert Enum.map(steps, &Keyword.fetch!(&1, :key)) ==
               [:reminder, :action_required, :final_notice]

      assert Enum.map(steps, &Keyword.fetch!(&1, :template)) == [
               Accrue.Emails.InvoicePaymentFailed,
               Accrue.Emails.DunningActionRequired,
               Accrue.Emails.DunningFinalNotice
             ]
    end

    test "dunning_campaign_enabled?/0 is true by default (opt-out, not opt-in)" do
      Application.delete_env(:accrue, :dunning)
      assert Config.dunning_campaign_enabled?() == true
    end

    test "dunning_campaign_steps/0 returns [] when disabled" do
      Application.put_env(:accrue, :dunning,
        grace_days: 14,
        campaign: [enabled: false, steps: []]
      )

      assert Config.dunning_campaign_steps() == []
      assert Config.dunning_campaign_enabled?() == false
    end
  end

  # --- cross-field boot raise (DUN-01, D-06, T-128-01) ------------------------

  describe "boot validation cross-field grace guard (DUN-01, D-06)" do
    test "last_step.after_days <= grace_days passes (:ok)" do
      Application.put_env(:accrue, :dunning,
        grace_days: 14,
        campaign: [
          enabled: true,
          steps: [
            [after_days: 0, key: :reminder, template: Accrue.Emails.InvoicePaymentFailed],
            [after_days: 12, key: :final_notice, template: Accrue.Emails.DunningFinalNotice]
          ]
        ]
      )

      assert Config.validate_at_boot!() == :ok
    end

    test "last_step.after_days == grace_days passes (boundary, :ok)" do
      Application.put_env(:accrue, :dunning,
        grace_days: 12,
        campaign: [
          enabled: true,
          steps: [[after_days: 12, key: :final_notice, template: M]]
        ]
      )

      assert Config.validate_at_boot!() == :ok
    end

    test "last_step.after_days > grace_days raises Accrue.ConfigError (cross-field boot raise)" do
      Application.put_env(:accrue, :dunning,
        grace_days: 10,
        campaign: [
          enabled: true,
          steps: [
            [after_days: 0, key: :reminder, template: M],
            [after_days: 12, key: :final_notice, template: N]
          ]
        ]
      )

      error =
        assert_raise Accrue.ConfigError, fn ->
          Config.validate_at_boot!()
        end

      message = Exception.message(error)
      assert message =~ "after_days"
      assert message =~ "grace_days"
    end

    test "the grace guard does not fire when the campaign is disabled" do
      Application.put_env(:accrue, :dunning,
        grace_days: 1,
        campaign: false
      )

      assert Config.validate_at_boot!() == :ok
    end

    test "the default journey (no override) validates clean at boot (12 <= 14)" do
      Application.delete_env(:accrue, :dunning)
      assert Config.validate_at_boot!() == :ok
    end
  end

  # --- property invariants (DUN-01) ------------------------------------------

  # Generator for a strictly-increasing, unique-after_days, unique-key step
  # list. Composed from a strictly-increasing offset list (cumulative sum of
  # positive deltas) so the invariant holds by construction.
  defp valid_steps_gen do
    StreamData.bind(StreamData.integer(1..6), fn n ->
      StreamData.map(
        StreamData.list_of(StreamData.integer(1..30), length: n),
        fn deltas ->
          {offsets, _} =
            Enum.map_reduce([0 | deltas] |> Enum.take(n), 0, fn d, acc ->
              next = acc + d
              {next, next}
            end)

          offsets
          |> Enum.with_index()
          |> Enum.map(fn {after_days, idx} ->
            [after_days: after_days, key: :"step_#{idx}", template: Accrue.Emails.InvoicePaymentFailed]
          end)
        end
      )
    end)
  end

  property "validate_dunning_campaign/1 returns {:ok, _} over strictly-increasing unique-key step lists" do
    check all(steps <- valid_steps_gen(), max_runs: 200) do
      assert {:ok, [enabled: true, steps: ^steps]} =
               Config.validate_dunning_campaign(enabled: true, steps: steps)
    end
  end

  property "validate_dunning_campaign/1 returns {:error, _} when after_days are non-increasing (shuffled into a violation)" do
    check all(
            steps <- valid_steps_gen(),
            steps != [],
            length(steps) >= 2,
            max_runs: 200
          ) do
      # Reverse a multi-step strictly-increasing list -> strictly-decreasing,
      # which violates the strictly-increasing invariant. (Two distinct
      # offsets guarantee a real ordering violation, never an equal pair.)
      reversed = Enum.reverse(steps)

      assert {:error, _} =
               Config.validate_dunning_campaign(enabled: true, steps: reversed)
    end
  end
end
