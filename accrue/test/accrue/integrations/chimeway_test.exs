defmodule Accrue.Integrations.ChimewayTest do
  @moduledoc """
  Phase 131 Plan 01 Task 2: Verify the Chimeway conditional-compile scaffold (DUN-03, D-04).

  Contract:
    * When :chimeway is NOT loaded, Accrue.Integrations.Chimeway is NEVER
      defined — Code.ensure_loaded/1 returns {:error, :nofile}.
    * When :chimeway IS loaded, the module is defined and implements
      Accrue.Dunning.Engine with both callbacks exported.
    * In BOTH matrices, mix compile --warnings-as-errors passes.

  This test accepts either outcome — the sanity check is that asking for the
  module does not raise, and when it IS loaded the behaviour surface is correct.

  Test 2 ("source uses the 4-pattern conditional compile") is RED until
  lib/accrue/integrations/chimeway.ex exists (Plan 04).
  """

  use ExUnit.Case, async: true

  describe "conditional compile" do
    test "Accrue.Integrations.Chimeway is either loaded OR :nofile — never a crash" do
      case Code.ensure_loaded(Accrue.Integrations.Chimeway) do
        {:module, Accrue.Integrations.Chimeway} ->
          # Chimeway-present matrix — assert behaviour surface
          assert function_exported?(Accrue.Integrations.Chimeway, :start_campaign, 3)
          assert function_exported?(Accrue.Integrations.Chimeway, :cancel_campaign, 3)

          behaviours =
            Accrue.Integrations.Chimeway.module_info(:attributes)
            |> Keyword.get_values(:behaviour)
            |> List.flatten()

          assert Accrue.Dunning.Engine in behaviours

        {:error, :nofile} ->
          # Chimeway-absent matrix (the current default) — module must not
          # exist, and merely asking for it must not raise.
          refute Code.ensure_loaded?(Chimeway)
      end
    end

    test "source file exists and uses the 4-pattern conditional compile" do
      source = File.read!("lib/accrue/integrations/chimeway.ex")

      # Pattern 1 — Code.ensure_loaded? gate around the defmodule.
      assert source =~ "Code.ensure_loaded?(Chimeway)"

      # Pattern 2 — @compile {:no_warn_undefined, ...} inside the defmodule
      # so warnings-as-errors passes when Chimeway.* references resolve at
      # runtime instead of compile time.
      assert source =~ "@compile {:no_warn_undefined"

      # Pattern 3 — behaviour declaration.
      assert source =~ "@behaviour Accrue.Dunning.Engine"
    end
  end
end
