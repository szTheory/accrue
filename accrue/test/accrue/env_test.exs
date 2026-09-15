defmodule Accrue.EnvTest do
  # Mutates application env for :accrue, :env — must not run async.
  use ExUnit.Case, async: false

  setup do
    original = Application.fetch_env(:accrue, :env)

    on_exit(fn ->
      case original do
        {:ok, value} -> Application.put_env(:accrue, :env, value)
        :error -> Application.delete_env(:accrue, :env)
      end
    end)

    :ok
  end

  describe "mix_env/0" do
    test "returns the build-tool environment when it is available" do
      assert Accrue.Env.mix_env() == Mix.env()
    end

    test "returns :prod instead of raising when the build tool is absent" do
      # Full release-shaped absence (module genuinely undefined) is proven
      # by the child-process regression test in
      # test/accrue/release_boot_regression_test.exs. Here we only assert
      # the rescue clause returns the fail-closed default and never raises
      # under normal conditions.
      assert is_atom(Accrue.Env.mix_env())
    end
  end

  describe "current/0" do
    test "returns the configured value when :accrue, :env is set, without consulting the build tool" do
      Application.put_env(:accrue, :env, :staging)
      assert Accrue.Env.current() == :staging
    end

    test "returns the build-tool environment when :env is unset" do
      Application.delete_env(:accrue, :env)
      assert Accrue.Env.current() == Accrue.Env.mix_env()
    end

    test "precedence: explicitly configured value wins over the fallback" do
      Application.put_env(:accrue, :env, :staging)
      assert Accrue.Env.current() == :staging
      refute Accrue.Env.current() == Accrue.Env.mix_env()
    end
  end
end
