defmodule Accrue.Docs.EntitlementsGuideTest do
  use ExUnit.Case, async: true

  @guide "guides/entitlements.md"

  test "guide preserves Apple observer boundaries and Phase 216 exclusions" do
    guide = File.read!(@guide)

    for required <- [
          "Apple is an entitlement source/observer",
          "Apple does not implement `Accrue.Processor`",
          "Phase 216 does not verify Apple signed material",
          "Phase 216 does not mutate the Apple subscription lifecycle",
          "rail/environment/product tuple",
          "accrue_entitlement_accounts",
          "accrue_entitlement_observations",
          "accrue_entitlement_grants",
          "accrue_entitlement_devices"
        ] do
      assert guide =~ required, "expected entitlement guide to include #{inspect(required)}"
    end

    for forbidden <- [
          "Apple is a processor",
          "Apple is gateway authority",
          "Phase 216 verifies Apple signed material",
          "Phase 216 mutates the Apple subscription lifecycle"
        ] do
      refute guide =~ forbidden, "expected entitlement guide to avoid #{inspect(forbidden)}"
    end
  end
end
