# Standalone script, NOT part of the ExUnit suite. Run as a child OS process
# by test/accrue/release_boot_regression_test.exs via `elixir -pa ... this_file`.
#
# Purpose: prove that Accrue's auth boot path survives in a VM where the
# build-tool module is genuinely undefined — the shape of a real OTP release,
# where the build tool application is not present at all. This cannot be
# proven inside the ExUnit VM itself, because the build tool module is
# loaded there.
#
# Any unexpected raise must escape (non-zero exit) so a regression fails
# loudly in CI logs. Only the expected Accrue.ConfigError branch is rescued
# explicitly; everything else re-raises.

# 1. Make the build-tool module genuinely undefined.
mix_ebin_dir = :filename.dirname(:code.which(Mix))
:code.del_path(mix_ebin_dir)
:code.purge(Mix)
:code.delete(Mix)
:code.purge(Mix)

if Code.ensure_loaded?(Mix) do
  IO.puts(:stderr, "ABORT: Mix is still loaded after removal — probe cannot prove anything")
  System.halt(1)
end

IO.puts("MARKER_MIX_UNDEFINED_OK")

# 2. Accrue.Env.mix_env/0 returns :prod without raising.
:prod = Accrue.Env.mix_env()
IO.puts("MARKER_ENV_MIX_ENV_OK")

# 3. Accrue.Env.current/0 returns :prod when :env is unset, without raising.
Application.delete_env(:accrue, :env)
:prod = Accrue.Env.current()
IO.puts("MARKER_ENV_CURRENT_UNSET_OK")

# 4. With :env set to :dev, the full auth surface works without raising.
Application.put_env(:accrue, :env, :dev)

:ok = Accrue.Auth.Default.boot_check!()
IO.puts("MARKER_BOOT_CHECK_DEV_OK")

dev_user = Accrue.Auth.Default.current_user(%{})

if dev_user.role != :admin do
  IO.puts(:stderr, "ABORT: expected dev stub user, got #{inspect(dev_user)}")
  System.halt(1)
end

IO.puts("MARKER_CURRENT_USER_DEV_OK")

plug = Accrue.Auth.Default.require_admin_plug()
:some_conn = plug.(:some_conn, [])
IO.puts("MARKER_REQUIRE_ADMIN_PLUG_DEV_OK")

challenge = Accrue.Auth.Default.step_up_challenge(dev_user, :some_action)

if challenge.kind != :auto do
  IO.puts(:stderr, "ABORT: expected auto-approval challenge, got #{inspect(challenge)}")
  System.halt(1)
end

IO.puts("MARKER_STEP_UP_CHALLENGE_DEV_OK")

:ok = Accrue.Auth.Default.verify_step_up(dev_user, %{}, :some_action)
IO.puts("MARKER_VERIFY_STEP_UP_DEV_OK")

:ok = Accrue.Auth.Mock.put_current_user(dev_user)
:ok = Accrue.Auth.Mock.clear_current_user()
IO.puts("MARKER_MOCK_PUT_CLEAR_DEV_OK")

# 5. With :env unset, boot_check!/0 raises Accrue.ConfigError (the intended
#    prod refuse-to-boot guard), and NOT UndefinedFunctionError. This
#    distinction is the heart of the test.
Application.delete_env(:accrue, :env)

try do
  Accrue.Auth.Default.boot_check!()

  IO.puts(
    :stderr,
    "ABORT: expected boot_check!/0 to raise Accrue.ConfigError, it returned normally"
  )

  System.halt(1)
rescue
  e in Accrue.ConfigError ->
    _ = e
    IO.puts("MARKER_BOOT_CHECK_RAISES_CONFIG_ERROR_OK")
end

IO.puts("ALL_OK")
