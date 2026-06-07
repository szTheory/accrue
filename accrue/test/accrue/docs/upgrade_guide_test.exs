defmodule Accrue.Docs.UpgradeGuideTest do
  use ExUnit.Case, async: true

  @guide "guides/upgrade.md"

  test "upgrade guide preserves existing public-schema opt-out guidance" do
    guide = File.read!(@guide)

    assert guide =~ ~s(config :accrue, :billing_schema, "public")
    assert guide =~ "before recompiling the dependency"

    assert guide =~ "Moving an existing production install"
    assert guide =~ "from `public` to `billing` is host-owned data migration work"
  end
end
