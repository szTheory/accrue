defmodule Accrue.Integrations.SigraTest do
  @moduledoc """
  Plan 01-06 Task 2: verify the Sigra conditional-compile scaffold.

  The contract (per CLAUDE.md §Conditional Compilation and plan
  `must_haves.truths`) is:

    * When `:sigra` is NOT loaded at compile time, the
      `Accrue.Integrations.Sigra` module is NEVER defined —
      `Code.ensure_loaded/1` returns `{:error, :nofile}`.
    * When `:sigra` IS loaded, the module is defined and implements the
      `Accrue.Auth` behaviour with all five callbacks exported.
    * In BOTH matrices, `mix compile --warnings-as-errors` passes (this
      is asserted at the `mix compile` level in CI, not in this test).

  This test therefore accepts either outcome — the sanity check is that
  asking for the module does not raise, and when it IS loaded the
  behaviour surface is correct.
  """

  use ExUnit.Case, async: true

  describe "conditional compile" do
    test "Accrue.Integrations.Sigra is either loaded OR :nofile — never a crash" do
      case Code.ensure_loaded(Accrue.Integrations.Sigra) do
        {:module, Accrue.Integrations.Sigra} ->
          # Sigra present matrix — assert behaviour surface
          assert function_exported?(Accrue.Integrations.Sigra, :current_user, 1)
          assert function_exported?(Accrue.Integrations.Sigra, :require_admin_plug, 0)
          assert function_exported?(Accrue.Integrations.Sigra, :user_schema, 0)
          assert function_exported?(Accrue.Integrations.Sigra, :log_audit, 2)
          assert function_exported?(Accrue.Integrations.Sigra, :actor_id, 1)

          behaviours =
            Accrue.Integrations.Sigra.module_info(:attributes)
            |> Keyword.get_values(:behaviour)
            |> List.flatten()

          assert Accrue.Auth in behaviours

        {:error, :nofile} ->
          # Sigra-absent matrix (the current default) — module must not
          # exist, and merely asking for it must not raise.
          refute Code.ensure_loaded?(Sigra)
      end
    end

    test "source file exists and uses the 4-pattern conditional compile" do
      source = File.read!("lib/accrue/integrations/sigra.ex")

      # Pattern 1 — Code.ensure_loaded? gate around the defmodule.
      assert source =~ "Code.ensure_loaded?(Sigra)"

      # Pattern 2 — @compile {:no_warn_undefined, ...} inside the defmodule
      # so warnings-as-errors passes when `Sigra.*` references resolve at
      # runtime instead of compile time.
      assert source =~ "@compile {:no_warn_undefined"

      # Pattern 3 — behaviour declaration.
      assert source =~ "@behaviour Accrue.Auth"
    end
  end
end
