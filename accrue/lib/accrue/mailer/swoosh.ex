defmodule Accrue.Mailer.Swoosh do
  @moduledoc """
  Swoosh-backed delivery module for Accrue's transactional emails.

  This module is NOT the `Accrue.Mailer` behaviour adapter — it is the
  thin Swoosh shim used by `Accrue.Workers.Mailer` to actually deliver
  a `%Swoosh.Email{}` after the template pipeline has built it. The
  env-specific Swoosh adapter (Local in dev, Test in test, SMTP/SendGrid
  in prod) is wired via `config :accrue, Accrue.Mailer.Swoosh, adapter: ...`
  in the host application's config.
  """

  use Swoosh.Mailer, otp_app: :accrue
end
