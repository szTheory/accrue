defmodule Accrue.Processor.BehaviourTest do
  use ExUnit.Case, async: true

  describe "Accrue.Processor behaviour" do
    test "defines the Phase 1 callbacks" do
      callbacks = Accrue.Processor.behaviour_info(:callbacks)
      assert {:create_customer, 2} in callbacks
      assert {:retrieve_customer, 2} in callbacks
      assert {:update_customer, 3} in callbacks
    end

    test "Accrue.ProcessorMock is defined by the Mox harness" do
      # Plan 01's Accrue.MoxSetup.define_mocks/0 guards on
      # Code.ensure_loaded?(Accrue.Processor). Now that this plan's
      # behaviour compiles, the mock must exist.
      assert Code.ensure_loaded?(Accrue.ProcessorMock)
      assert function_exported?(Accrue.ProcessorMock, :create_customer, 2)
      assert function_exported?(Accrue.ProcessorMock, :retrieve_customer, 2)
      assert function_exported?(Accrue.ProcessorMock, :update_customer, 3)
    end

    test "default impl resolves to Accrue.Processor.Fake when unset" do
      prior = Application.get_env(:accrue, :processor)

      try do
        Application.delete_env(:accrue, :processor)
        # Private impl/0 is exercised indirectly — the behaviour module's
        # moduledoc documents Accrue.Processor.Fake as the default.
        assert Accrue.Processor.__impl__() == Accrue.Processor.Fake
      after
        if prior, do: Application.put_env(:accrue, :processor, prior)
      end
    end
  end
end
