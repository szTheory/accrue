defmodule Accrue.Auth.MockTest do
  use ExUnit.Case, async: false

  describe "named test adapters" do
    test "loads the auth, mailer, and PDF test adapters" do
      assert Code.ensure_loaded?(Accrue.Auth.Mock)
      assert Code.ensure_loaded?(Accrue.Mailer.Test)
      assert Code.ensure_loaded?(Accrue.PDF.Test)
    end

    test "exports the auth mock helper and behaviour functions" do
      Code.ensure_loaded!(Accrue.Auth.Mock)

      assert function_exported?(Accrue.Auth.Mock, :put_current_user, 1)
      assert function_exported?(Accrue.Auth.Mock, :clear_current_user, 0)
      assert function_exported?(Accrue.Auth.Mock, :current_user, 1)
      assert function_exported?(Accrue.Auth.Mock, :require_admin_plug, 0)
      assert function_exported?(Accrue.Auth.Mock, :user_schema, 0)
      assert function_exported?(Accrue.Auth.Mock, :log_audit, 2)
      assert function_exported?(Accrue.Auth.Mock, :actor_id, 1)
      assert function_exported?(Accrue.Auth.Mock, :step_up_challenge, 2)
      assert function_exported?(Accrue.Auth.Mock, :verify_step_up, 3)
    end
  end

  describe "process-local auth state" do
    setup do
      Accrue.Auth.Mock.clear_current_user()

      on_exit(fn ->
        Accrue.Auth.Mock.clear_current_user()
      end)

      :ok
    end

    test "put_current_user/1 makes current_user/1 return that user" do
      user = %{id: "admin_1", role: :admin}

      assert :ok = Accrue.Auth.Mock.put_current_user(user)
      assert Accrue.Auth.Mock.current_user(%{}) == user
      assert Accrue.Auth.Mock.actor_id(user) == "admin_1"
    end

    test "require_admin_plug/0 passes an admin user through" do
      user = %{id: "admin_1", role: :admin}
      conn = %{assigns: %{current_user: user}}
      plug = Accrue.Auth.Mock.require_admin_plug()

      assert plug.(conn, []) == conn
    end

    test "clear_current_user/0 resets current_user/1 to nil" do
      assert :ok = Accrue.Auth.Mock.put_current_user(%{id: "admin_1", role: :admin})
      assert :ok = Accrue.Auth.Mock.clear_current_user()
      assert Accrue.Auth.Mock.current_user(%{}) == nil
    end
  end

  describe "production safety" do
    test "current_user/1 refuses to run in :prod" do
      original_env = Application.get_env(:accrue, :env, Mix.env())

      try do
        Application.put_env(:accrue, :env, :prod)

        assert_raise Accrue.ConfigError, ~r/Accrue.Auth.Mock is test-only/, fn ->
          Accrue.Auth.Mock.current_user(%{})
        end
      after
        Application.put_env(:accrue, :env, original_env)
      end
    end
  end
end
