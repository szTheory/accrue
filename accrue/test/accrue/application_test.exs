defmodule Accrue.ApplicationTest do
  @moduledoc """
  Verifies Plan 01-06 Task 1: Accrue.Application boot wiring, empty-supervisor
  pattern (D-05), boot-time Auth refuse-to-boot (D-40, T-FND-07), Pitfall #4
  (no ChromicPDF/Oban/Finch children — D-33, D-42), brand.css presence
  (FND-07), and Config.validate_at_boot! plumbing.
  """
  use ExUnit.Case, async: false

  describe "OTP application wiring" do
    test "Accrue.Application is configured as the :mod entry point" do
      assert {:ok, {Accrue.Application, []}} = :application.get_key(:accrue, :mod)
    end

    test "Application.ensure_all_started/1 boots :accrue and supervisor is alive" do
      {:ok, _} = Application.ensure_all_started(:accrue)
      assert is_pid(Process.whereis(Accrue.Supervisor))
    end
  end

  describe "Config.validate_at_boot!/0" do
    test "returns :ok with current test config" do
      assert :ok = Accrue.Config.validate_at_boot!()
    end
  end

  describe "boot-time auth refusal (T-FND-07 integration)" do
    test "Accrue.Auth.Default.do_boot_check!(:prod) raises when adapter is default" do
      assert_raise Accrue.ConfigError, ~r/dev-only and refuses to run in :prod/, fn ->
        Accrue.Auth.Default.do_boot_check!(:prod)
      end
    end
  end

  describe "Pitfall #4 — no host-owned deps started by Accrue.Application" do
    test "application.ex does not reference ChromicPDF, Oban, or Finch start/child-spec" do
      source = File.read!("lib/accrue/application.ex")

      # Strip @moduledoc before scanning so documentation references don't
      # trip the test (same pattern as Plan 05's PDF facade-lockdown test).
      code = Regex.replace(~r/@moduledoc\s+"""[\s\S]*?"""/m, source, "@moduledoc false")

      refute code =~ "ChromicPDF"
      refute code =~ "Oban.start"
      refute code =~ "Finch"
    end
  end

  describe "brand.css (FND-07)" do
    test "brand.css is shipped under priv/static and contains 7 --accrue- variables" do
      priv = :code.priv_dir(:accrue)
      path = Path.join([priv, "static", "brand.css"])
      assert File.exists?(path)

      contents = File.read!(path)

      for name <- ~w(ink slate fog paper moss cobalt amber) do
        assert contents =~ "--accrue-#{name}:", "missing --accrue-#{name} variable"
      end

      # Count token definitions as a sanity check (exactly 7).
      count =
        Regex.scan(~r/^\s*--accrue-[a-z]+:/m, contents)
        |> length()

      assert count == 7, "expected 7 --accrue-* variables, got #{count}"
    end

    test "brand.css is discoverable via :code.priv_dir/1" do
      priv = :code.priv_dir(:accrue)
      assert is_list(priv) or is_binary(priv)
      assert File.exists?(Path.join([to_string(priv), "static", "brand.css"]))
    end
  end
end
