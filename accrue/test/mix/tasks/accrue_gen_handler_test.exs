defmodule Mix.Tasks.Accrue.Gen.HandlerTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Accrue.Test.InstallFixture

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
    :ok
  end

  test "generates a webhook handler module with the public handler behaviour" do
    app = InstallFixture.tmp_app!(:gen_handler)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}"
    ])

    run_generator(app, ["MyApp.BillingHandler"])

    assert InstallFixture.assert_contains!(
             app,
             "lib/my_app/billing_handler.ex",
             "use Accrue.Webhook.Handler"
           )

    assert InstallFixture.assert_contains!(
             app,
             "lib/my_app/billing_handler.ex",
             "def handle_event(type, event, ctx)"
           )
  end

  test "never overwrite a user-edited handler" do
    app = InstallFixture.tmp_app!(:gen_handler_no_clobber)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}"
    ])

    InstallFixture.write!(app, "lib/my_app/billing_handler.ex", """
    defmodule MyApp.BillingHandler do
      # user-edited
    end
    """)

    output = run_generator(app, ["MyApp.BillingHandler"])

    assert output =~ "never overwrite"
    assert output =~ "user-edited"
    assert InstallFixture.assert_contains!(app, "lib/my_app/billing_handler.ex", "# user-edited")
  end

  defp run_generator(app, argv) do
    Mix.Task.clear()

    capture_io(fn ->
      File.cd!(app, fn ->
        apply(Mix.Tasks.Accrue.Gen.Handler, :run, [argv])
      end)
    end)
  end
end
