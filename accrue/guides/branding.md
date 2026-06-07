# Branding

Accrue's branding config drives visual customization of transactional
emails and invoice PDFs. This guide covers the full schema and the logo
strategy across HTTPS vs PDF rendering contexts.

Use the nested `:branding` keyword list (see below); it is the supported schema.

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

Emails and PDFs have different logo constraints, and the PDF posture depends on
which renderer you chose:

| Format | Preferred source | Why |
|--------|------------------|-----|
| HTML email | `logo_url` (HTTPS) | Email clients load the configured logo URL directly |
| PDF (Rendro) | `logo_url` (HTTPS) or no logo | The current invoice renderer reads `logo_url`; if the render environment cannot reach that URL, verify the fallback text posture instead of assuming an embedded-logo config exists |
| PDF (ChromicPDF) | `logo_url` (HTTPS) | Chromium can fetch HTTPS assets at render time on the explicit compatibility path, but the host still owns network reachability and timeout behavior |
| PDF (restricted/offline) | no logo or text fallback | Accrue does not currently expose a separate embedded-logo branding key for offline PDF rendering |

## Renderer-specific constraints

Rendro and ChromicPDF do not have the same asset and font behavior:

| Renderer | Assets | Fonts | Operational note |
|----------|--------|-------|------------------|
| Rendro | Uses the configured `logo_url` when present, otherwise falls back to text | Validate glyph coverage up front and verify logo reachability in the actual render environment | Best fit for deterministic invoice rendering without Chrome, but it does not add a separate offline logo embedding contract today |
| ChromicPDF | Uses the configured `logo_url` over HTTPS on the explicit compatibility path | Browser-like CSS and webfont behavior exist, but remote fetch timing can still fail | Only applies when the host explicitly opts into `Accrue.InvoiceRenderer.ChromicPDF` |

If you care about air-gapped deploys, reproducible CI output, or environments
where outbound fetches are restricted, verify the no-logo/text fallback output
explicitly. Accrue does not currently expose a dedicated embedded-logo setting
for PDF rendering.

## Per-template override

Host apps can inject branding overrides on a per-type basis via the
rung-3 override ladder (see `guides/email.md`). The default templates
read branding via `@context.branding` — pass an overridden map via
the mailer assigns pipeline.

## Connect note

Stripe Connect platform branding always wins over per-connected-account
overrides today. Accrue does not ship first-class per-account branding;
use a rung-3 template override (see `guides/email.md`) that dispatches on
the Connect account id at render time if you need it.

## Admin chrome override

`branding` remains the customer-facing billing identity for emails, PDFs, and
the mounted customer portal. If the mounted operator UI should keep a separate
admin identity, set `:admin_branding`:

```elixir
config :accrue,
  branding: [
    business_name: "Acme",
    from_email: "billing@acme.example",
    support_email: "support@acme.example",
    accent_color: "#26785F"
  ],
  admin_branding: [
    app_name: "Accrue Admin",
    accent_color: "#5D79F6"
  ]
```

When `:admin_branding` is unset, Accrue Admin derives its label, logo, and accent
from `branding` for backwards compatibility.
