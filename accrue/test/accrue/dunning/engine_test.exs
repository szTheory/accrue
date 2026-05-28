defmodule Accrue.Dunning.EngineTest do
  @moduledoc """
  Phase 131 Plan 01 Task 1: Verify the Accrue.Dunning.Engine behaviour contract.

  Wave-0 test scaffold — all tests are RED until Plan 02 creates the behaviour
  module and Plan 03 creates Engine.Oban. Expected failure:
  `UndefinedFunctionError` / "module Accrue.Dunning.Engine is not available".

  Contract asserted:
    * `Accrue.Dunning.Engine` declares `start_campaign/3` and `cancel_campaign/3`
      as behaviour callbacks.
    * `Accrue.Dunning.Engine.Oban` implements the behaviour (`:behaviour`
      attribute contains `Accrue.Dunning.Engine`).
    * `Engine.Oban` exports both `start_campaign/3` and `cancel_campaign/3`.
  """

  use ExUnit.Case, async: true

  describe "behaviour contract" do
    test "defines start_campaign/3 callback" do
      callbacks = Accrue.Dunning.Engine.behaviour_info(:callbacks)
      assert {:start_campaign, 3} in callbacks
    end

    test "defines cancel_campaign/3 callback" do
      callbacks = Accrue.Dunning.Engine.behaviour_info(:callbacks)
      assert {:cancel_campaign, 3} in callbacks
    end

    test "Engine.Oban implements the behaviour" do
      behaviours =
        Accrue.Dunning.Engine.Oban.module_info(:attributes)
        |> Keyword.get_values(:behaviour)
        |> List.flatten()

      assert Accrue.Dunning.Engine in behaviours
    end

    test "Engine.Oban exports start_campaign/3" do
      Code.ensure_loaded?(Accrue.Dunning.Engine.Oban)
      assert function_exported?(Accrue.Dunning.Engine.Oban, :start_campaign, 3)
    end

    test "Engine.Oban exports cancel_campaign/3" do
      Code.ensure_loaded?(Accrue.Dunning.Engine.Oban)
      assert function_exported?(Accrue.Dunning.Engine.Oban, :cancel_campaign, 3)
    end
  end
end
