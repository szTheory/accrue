defmodule Accrue.AuthTest do
  @moduledoc """
  Plan 05 Task 3 — Accrue.Auth behaviour + Accrue.Auth.Default
  (dev-permissive, prod-refuse-to-boot).

  Tests exercise the `:prod` branch via the `do_boot_check!/1` helper
  directly (not by mutating `Application.put_env(:accrue, :env, :prod)`),
  which would bleed between async tests.
  """

  use ExUnit.Case, async: true

  describe "Accrue.Auth facade" do
    test "delegates current_user/1 to the configured adapter" do
      user = Accrue.Auth.current_user(%{})
      assert user.id == "dev"
      assert user.email == "dev@localhost"
      assert user.role == :admin
    end

    test "actor_id/1 reads :id from the adapter-returned user" do
      assert Accrue.Auth.actor_id(%{id: "u_1"}) == "u_1"
    end
  end

  describe "Accrue.Auth.Default.current_user/1" do
    test "returns stubbed dev user in :test env" do
      assert %{id: "dev", email: "dev@localhost", role: :admin} =
               Accrue.Auth.Default.current_user(nil)
    end
  end

  describe "Accrue.Auth.Default.boot_check!/0 — public API" do
    test "returns :ok in :test env" do
      assert :ok = Accrue.Auth.Default.boot_check!()
    end
  end

  describe "Accrue.Auth.Default.do_boot_check!/1 — testable helper" do
    test ":dev returns :ok" do
      assert :ok = Accrue.Auth.Default.do_boot_check!(:dev)
    end

    test ":test returns :ok" do
      assert :ok = Accrue.Auth.Default.do_boot_check!(:test)
    end

    test ":prod raises Accrue.ConfigError when :auth_adapter is still Default" do
      # Default adapter is the Plan 01 default — no env tampering needed.
      error = assert_raise Accrue.ConfigError, fn -> Accrue.Auth.Default.do_boot_check!(:prod) end
      assert error.diagnostic.code == "ACCRUE-DX-AUTH-ADAPTER"
      assert Exception.message(error) =~ "/guides/troubleshooting.html#accrue-dx-auth-adapter"
    end

    test ":prod returns :ok when a custom :auth_adapter is configured" do
      prior = Application.get_env(:accrue, :auth_adapter, Accrue.Auth.Default)

      try do
        Application.put_env(:accrue, :auth_adapter, Accrue.AuthTest.CustomStub)
        assert :ok = Accrue.Auth.Default.do_boot_check!(:prod)
      after
        Application.put_env(:accrue, :auth_adapter, prior)
      end
    end
  end

  describe "Accrue.Auth.Default.require_admin_plug/0" do
    test "returns a pass-through plug in dev/test" do
      plug = Accrue.Auth.Default.require_admin_plug()
      conn = %{halted: false}
      assert plug.(conn, []) == conn
    end

    test "fails closed with a shared diagnostic outside dev/test" do
      prior = Application.get_env(:accrue, :env)

      try do
        Application.put_env(:accrue, :env, :prod)
        plug = Accrue.Auth.Default.require_admin_plug()

        error = assert_raise Accrue.ConfigError, fn -> plug.(%{}, []) end
        assert error.diagnostic.code == "ACCRUE-DX-AUTH-ADAPTER"
      after
        if is_nil(prior),
          do: Application.delete_env(:accrue, :env),
          else: Application.put_env(:accrue, :env, prior)
      end
    end
  end

  describe "Accrue.Auth.Default misc callbacks" do
    test "user_schema/0 returns nil" do
      assert Accrue.Auth.Default.user_schema() == nil
    end

    test "log_audit/2 is a no-op returning :ok" do
      assert :ok = Accrue.Auth.Default.log_audit(%{id: "u"}, %{type: :login})
    end

    test "actor_id/1 handles atom-keyed maps" do
      assert Accrue.Auth.Default.actor_id(%{id: "u_1"}) == "u_1"
    end

    test "actor_id/1 handles string-keyed maps" do
      assert Accrue.Auth.Default.actor_id(%{"id" => "u_2"}) == "u_2"
    end

    test "actor_id/1 returns nil for non-maps" do
      assert Accrue.Auth.Default.actor_id(nil) == nil
    end
  end
end
