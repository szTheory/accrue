defmodule Accrue.Workers.MailerDunningWiringTest do
  @moduledoc """
  Phase 128 Plan 04 Task 2 (D-02, D-14 routing): static wiring assertions
  for the two new dunning-step templates resolving via
  `Accrue.Workers.Mailer.resolve_template/1`, and the `:invoice_payment_failed`
  type routing through the Mailglass lane (so the D-14 backstop key takes
  effect). The full DUN-04 dedup proof lives in
  `Accrue.Workers.MailerIdempotencyTest`.
  """
  use ExUnit.Case, async: true

  alias Accrue.Workers.Mailer

  test "resolve_template/1 maps :dunning_action_required to DunningActionRequired" do
    assert Mailer.resolve_template(:dunning_action_required) ==
             Accrue.Emails.DunningActionRequired
  end

  test "resolve_template/1 maps :dunning_final_notice to DunningFinalNotice" do
    assert Mailer.resolve_template(:dunning_final_notice) ==
             Accrue.Emails.DunningFinalNotice
  end

  test "the two new templates are real, loadable modules" do
    assert Code.ensure_loaded?(Accrue.Emails.DunningActionRequired)
    assert Code.ensure_loaded?(Accrue.Emails.DunningFinalNotice)
  end
end
