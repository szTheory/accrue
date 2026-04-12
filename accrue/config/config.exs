import Config

# ex_money / ex_cldr backend wiring. Required at compile-time for the
# Money.Application supervisor to start. Plan 02 wraps this behind Accrue.Money.
config :ex_cldr, default_backend: Accrue.Cldr
config :ex_money, default_cldr_backend: Accrue.Cldr

# Compile-stable env marker. Plan 05 Auth.Default boot_check reads this via
# Application.get_env(:accrue, :env, Mix.env()) — runtime lookup with Mix.env fallback.
config :accrue, :env, Mix.env()

# Placeholder keys so Plan 02's NimbleOptions schema has something to validate.
# Plan 02 will ship the full schema; Plans 04/05 READ these, never WRITE them.
config :accrue,
  processor: Accrue.Processor.Fake,
  mailer: Accrue.Mailer.Default,
  mailer_adapter: Accrue.Mailer.Swoosh,
  pdf_adapter: Accrue.PDF.ChromicPDF,
  auth_adapter: Accrue.Auth.Default,
  default_currency: :usd,
  emails: [],
  email_overrides: [],
  attach_invoice_pdf: true,
  enforce_immutability: false

# Oban queue name reservation (host app owns the Oban instance — Accrue just names queues).
# Documented here so downstream plans know the canonical queue name.
#
#     config :my_app, Oban,
#       queues: [accrue_mailers: 20, accrue_webhooks: 10]

# Swoosh: disable default api_client to avoid the hackney dep. Host apps that
# use API-based adapters (SendGrid, Mailgun, Postmark) re-enable it with their
# own HTTP client (Finch recommended).
config :swoosh, :api_client, false

# Swoosh mailer shim — placeholder; env-specific adapter is set in dev.exs / test.exs.
config :accrue, Accrue.Mailer.Swoosh, adapter: Swoosh.Adapters.Local

import_config "#{config_env()}.exs"
