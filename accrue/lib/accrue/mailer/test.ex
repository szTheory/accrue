defmodule Accrue.Mailer.Test do
  @moduledoc """
  Test adapter for `Accrue.Mailer` (D6-05). Replaces `Accrue.Mailer.Default`
  at the behaviour layer — intercepts `Accrue.Mailer.deliver/2` BEFORE
  Oban enqueue. Sends the intent tuple to the calling test pid and
  returns immediately.

  Wired via `config :accrue, :mailer, Accrue.Mailer.Test` in test env.
  Mirrors `Accrue.PDF.Test` (Phase 1 D-34) — every Accrue test adapter
  sends a 3-tuple starting with a `:*_rendered`/`:*_delivered` atom.

  For tests that need a rendered `%Swoosh.Email{}` body (subject / HTML
  assertions), swap this adapter for `Accrue.Mailer.Default` plus
  `Swoosh.Adapters.Test` in that specific test module.
  """

  @behaviour Accrue.Mailer

  @impl true
  def deliver(type, assigns) when is_atom(type) and is_map(assigns) do
    send(self(), {:accrue_email_delivered, type, assigns})
    {:ok, :test}
  end
end
