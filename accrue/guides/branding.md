# Branding

Accrue's branding config drives visual customization of transactional
emails and invoice PDFs. This guide covers the full schema, migration
from Phase 1 flat keys, and the logo strategy across HTTPS vs PDF
rendering contexts.

Phase 6 shipping schema — v1.0.

## Quickstart

```elixir
# config/config.exs
config :accrue, :branding,
  business_name: "Acme Corp",
  from_name: "Acme Billing",
  from_email: "billing@acme.example",
  support_email: "support@acme.example",
  company_address: "123 Main St, San Francisco, CA 94103",
  logo_url: "https://cdn.acme.example/logo.png",
  logo_base64: nil,
  accent_color: "#1F6FEB",
  secondary_color: "#6B7280",
  font_stack: "-apple-system, BlinkMacSystemFont, sans-serif",
  footer_html: nil,
  footer_text: nil,
  currency_symbol_override: nil,
  list_unsubscribe_url: nil
```

All keys validate via `nimble_options` at boot — misconfig fails
loud via `Accrue.ConfigError`.

## Schema reference

| Key | Type | Default | Required | Purpose |
|-----|------|---------|----------|---------|
| `business_name` | `string` | `"Acme"` | no | Rendered as the sender name + used in `{business}` template interpolation |
| `from_name` | `string` | `business_name` | no | `From:` display name on Swoosh emails |
| `from_email` | `string` | `"noreply@example.com"` | yes (prod) | `From:` address |
| `support_email` | `string` | nil | no | Rendered in `Contact support at` footer line |
| `company_address` | `string` | nil | conditional | Physical postal address shown in email footer. **Required** for EU/CA audiences per CAN-SPAM/CASL transactional exemptions — see guides/email.md |
| `logo_url` | `string (HTTPS)` | nil | no | HTTPS-accessible logo. Used in email `<img>` src + PDF URL mode |
| `logo_base64` | `string (data URL)` | nil | no | Base64-embedded logo. Use when PDFs must render offline / air-gapped. Email clients prefer `logo_url` |
| `accent_color` | `hex color (#RRGGBB)` | `"#1F6FEB"` | no | Primary CTA button + link color |
| `secondary_color` | `hex color (#RRGGBB)` | `"#6B7280"` | no | Muted text + borders |
| `font_stack` | `string` | `"-apple-system, BlinkMacSystemFont, sans-serif"` | no | CSS font-family. Web-safe stack recommended |
| `footer_html` | `string (HTML)` | nil | no | HTML footer appended below the standard Accrue footer |
| `footer_text` | `string` | nil | no | Plain-text version of `footer_html` for text/plain email parts |
| `currency_symbol_override` | `string` | nil | no | Overrides the CLDR-derived currency symbol. Usually leave nil |
| `list_unsubscribe_url` | `string` | nil | no | Opt-in RFC 8058 `List-Unsubscribe` header URL. See guides/email.md "RFC 8058 opt-in" |

## Hex color validation

`accent_color` and `secondary_color` accept the following formats:

- `#RGB` — 3-digit shorthand (`#1F6`)
- `#RRGGBB` — 6-digit (`#1F6FEB`)
- `#RRGGBBAA` — 8-digit with alpha (`#1F6FEBFF`)

Case-insensitive. Invalid values fail at boot with `Accrue.ConfigError`
identifying the offending key.

## Logo strategy

Emails and PDFs have different logo constraints:

| Format | Preferred source | Why |
|--------|------------------|-----|
| HTML email | `logo_url` (HTTPS) | Email clients cache remote images; reduces email size |
| PDF (ChromicPDF) | `logo_url` (HTTPS) OR `logo_base64` | Chromium fetches HTTPS at render time. Base64 avoids network dependency for air-gapped renders |
| PDF (offline) | `logo_base64` | Required — no outbound HTTP |

When both are set, `logo_base64` takes precedence for PDF and
`logo_url` takes precedence for email. See `guides/pdf.md` for the
ChromicPDF font + image loading strategy.

## Per-template override

Host apps can inject branding overrides on a per-type basis via the
rung-3 override ladder (see `guides/email.md`). The default templates
read branding via `@context.branding` — pass an overridden map via
the mailer assigns pipeline.

## Deprecated flat keys

Phase 1 exposed six flat branding keys directly on `:accrue`:

- `:from_name`
- `:from_email`
- `:business_name`
- `:support_email`
- `:logo_url`
- `:accent_color`

These are DEPRECATED and will be removed before v1.0. Migrate to the
nested `:branding` keyword list. Accrue emits a boot-time branding warning
listing every
affected flat key.

### Migration example

```elixir
# Before (Phase 1 — DEPRECATED)
config :accrue,
  from_name: "Acme Billing",
  from_email: "billing@acme.example",
  business_name: "Acme Corp",
  support_email: "support@acme.example",
  logo_url: "https://cdn.acme.example/logo.png",
  accent_color: "#1F6FEB"

# After (Phase 6 — RECOMMENDED)
config :accrue, :branding,
  business_name: "Acme Corp",
  from_name: "Acme Billing",
  from_email: "billing@acme.example",
  support_email: "support@acme.example",
  logo_url: "https://cdn.acme.example/logo.png",
  accent_color: "#1F6FEB"
```

The deprecated flat keys continue to work for one minor release —
they are removed in the v1.0 release. Do not rely on them in new
code.

## Connect note

Stripe Connect platform branding always wins over per-connected-
account overrides in v1.0 (D6-02). Phase 5 Connect plans do not
introduce per-account branding customization — that lands in v1.1.
Platforms that need per-account branding should implement a rung-3
atom override that dispatches on the Connect account ID at render
time.
