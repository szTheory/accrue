defmodule Accrue.Entitlements.AppleLineagePropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Entitlements.Apple.Lineage

  property "a mismatched account token can never claim an unbound lineage" do
    check all token <- string(:alphanumeric, min_length: 1), account <- string(:alphanumeric, min_length: 1) do
      lineage = %Lineage{account_id: nil, binding_state: :unbound}
      assert {:ownership_conflict, _} = Lineage.claim(Accrue.TestRepo, lineage, account, token <> "x")
    end
  end
end
