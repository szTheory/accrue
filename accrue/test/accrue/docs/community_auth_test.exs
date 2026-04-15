defmodule Accrue.Docs.CommunityAuthTest do
  use ExUnit.Case, async: true

  @guide "guides/auth_adapters.md"

  test "community auth guide documents supported adapter paths" do
    guide = File.read!(@guide)

    assert guide =~ "MyApp.Auth.PhxGenAuth"
    assert guide =~ "MyApp.Auth.Pow"
    assert guide =~ "MyApp.Auth.Assent"
    assert guide =~ "Sigra"
    assert guide =~ "config :accrue, :auth_adapter, Accrue.Integrations.Sigra"
    assert guide =~ "Accrue.Auth.Default"
  end

  test "community auth guide documents every required auth callback" do
    guide = File.read!(@guide)

    for callback <- [
          "current_user/1",
          "require_admin_plug/0",
          "user_schema/0",
          "log_audit/2",
          "actor_id/1",
          "step_up_challenge/2",
          "verify_step_up/3"
        ] do
      assert guide =~ callback
    end
  end

  test "community auth guide keeps release docs out of scope" do
    guide = File.read!(@guide)

    refute guide =~ "quickstart"
    refute guide =~ "upgrade guide"
    refute guide =~ "SECURITY.md"
    refute guide =~ "CONTRIBUTING"
  end
end
