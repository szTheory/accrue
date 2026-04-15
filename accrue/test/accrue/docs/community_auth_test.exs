defmodule Accrue.Docs.CommunityAuthTest do
  use ExUnit.Case, async: true

  @guide "guides/auth_adapters.md"

  test "community auth guide documents supported adapter paths" do
    guide = File.read!(@guide)

    assert guide =~ "PhxGenAuth"
    assert guide =~ "Pow"
    assert guide =~ "Assent"
    assert guide =~ "Sigra"
    assert guide =~ "Accrue.Auth.Default"
  end

  test "community auth guide documents every required auth callback" do
    guide = File.read!(@guide)

    assert guide =~ "current_user/1"
    assert guide =~ "require_admin_plug/0"
    assert guide =~ "user_schema/0"
    assert guide =~ "log_audit/2"
    assert guide =~ "actor_id/1"
    assert guide =~ "step_up_challenge/2"
    assert guide =~ "verify_step_up/3"
  end
end
