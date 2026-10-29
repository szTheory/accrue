if System.get_env("PHASE252_TAP_REPORT") == "1" do
  Code.require_file(Path.expand("../../../dev_support/phase252_tap_formatter.ex", __DIR__))
  ExUnit.start(formatters: [Accrue.Test.Phase252TapFormatter])
else
  ExUnit.start()
end

Ecto.Adapters.SQL.Sandbox.mode(AccrueHost.Repo, :manual)
