defmodule Accrue.Emails.MailglassCleanupTest do
  use ExUnit.Case, async: true

  test "legacy preview helpers are gone" do
    refute function_exported?(Accrue.Workers.Mailer, :template_for, 1)
  end

  test "mix no longer declares MJML dependencies" do
    mix_exs = File.read!("mix.exs")

    refute mix_exs =~ "mjml_eex"
    refute mix_exs =~ "phoenix_swoosh"
  end

  test "legacy MJML template files are deleted" do
    refute File.exists?("lib/accrue/emails/html_bridge.ex")
    refute File.exists?("lib/mix/tasks/accrue.mail.preview.ex")
    refute File.exists?("test/accrue/emails/html_bridge_test.exs")
    refute File.exists?("priv/accrue/templates/emails/payment_succeeded.mjml.eex")
    refute File.exists?("priv/accrue/templates/emails/payment_succeeded.text.eex")
  end
end
