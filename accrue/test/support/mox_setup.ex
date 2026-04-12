defmodule Accrue.MoxSetup do
  @moduledoc false

  # Wave 0 Mox bootstrap. Each Mox.defmock/2 call is guarded by
  # Code.ensure_loaded?/1 so the harness compiles and runs green before the
  # corresponding behaviour modules exist (they land in Wave 1 plans 04/05).
  # Once each behaviour compiles, the matching mock is registered
  # automatically at `mix test` startup — no test_helper.exs edits required.

  @pairs [
    {Accrue.ProcessorMock, Accrue.Processor},
    {Accrue.MailerMock, Accrue.Mailer},
    {Accrue.PDFMock, Accrue.PDF},
    {Accrue.AuthMock, Accrue.Auth}
  ]

  def define_mocks do
    for {mock, behaviour} <- @pairs do
      if Code.ensure_loaded?(behaviour) and
           function_exported?(behaviour, :behaviour_info, 1) do
        Mox.defmock(mock, for: behaviour)
      end
    end

    :ok
  end
end
