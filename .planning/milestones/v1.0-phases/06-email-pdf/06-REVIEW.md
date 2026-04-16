---
phase: 06-email-pdf
reviewed: 2026-04-15T00:00:00Z
depth: standard
files_reviewed: 36
files_reviewed_list:
  - accrue/lib/accrue/application.ex
  - accrue/lib/accrue/billing.ex
  - accrue/lib/accrue/billing/customer.ex
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/emails/card_expiring_soon.ex
  - accrue/lib/accrue/emails/coupon_applied.ex
  - accrue/lib/accrue/emails/fixtures.ex
  - accrue/lib/accrue/emails/html_bridge.ex
  - accrue/lib/accrue/emails/invoice_finalized.ex
  - accrue/lib/accrue/emails/invoice_paid.ex
  - accrue/lib/accrue/emails/invoice_payment_failed.ex
  - accrue/lib/accrue/emails/payment_failed.ex
  - accrue/lib/accrue/emails/receipt.ex
  - accrue/lib/accrue/emails/refund_issued.ex
  - accrue/lib/accrue/emails/subscription_canceled.ex
  - accrue/lib/accrue/emails/subscription_paused.ex
  - accrue/lib/accrue/emails/subscription_resumed.ex
  - accrue/lib/accrue/emails/trial_ended.ex
  - accrue/lib/accrue/emails/trial_ending.ex
  - accrue/lib/accrue/errors.ex
  - accrue/lib/accrue/invoices.ex
  - accrue/lib/accrue/invoices/components.ex
  - accrue/lib/accrue/invoices/layouts.ex
  - accrue/lib/accrue/invoices/render.ex
  - accrue/lib/accrue/invoices/render_context.ex
  - accrue/lib/accrue/invoices/styles.ex
  - accrue/lib/accrue/mailer/test.ex
  - accrue/lib/accrue/pdf/null.ex
  - accrue/lib/accrue/storage.ex
  - accrue/lib/accrue/storage/null.ex
  - accrue/lib/accrue/test/mailer_assertions.ex
  - accrue/lib/accrue/test/pdf_assertions.ex
  - accrue/lib/accrue/webhook/default_handler.ex
  - accrue/lib/accrue/workers/mailer.ex
  - accrue/lib/mix/tasks/accrue.mail.preview.ex
  - ./CLAUDE.md
findings:
  critical: 1
  warning: 6
  info: 5
  total: 12
status: issues_found
---

# Phase 6: Code Review Report

**Reviewed:** 2026-04-15
**Depth:** standard
**Files Reviewed:** 36
**Status:** issues_found

## Summary

Phase 6 delivers the Email + PDF subsystem: a nested `:branding` config, a HEEx-to-MJML bridge, 13 transactional email modules, an invoice PDF facade, an Oban mailer worker with PDF attachment handling, dispatching from the default webhook handler, and a preview Mix task.

Overall architecture is sound — the `RenderContext` freeze-point pattern (Pitfall 8), the three-tier PDF adapter fallback chain (Null → ChromicPDF-not-started → RenderFailed retry), the locale/timezone precedence ladder, and the signature-preserving telemetry events are all well-designed and consistently implemented. Security hygiene in logs is good (no PII in `warn_company_address_locale_mismatch`, telemetry metadata is sanitized, `String.to_existing_atom` is used correctly throughout).

One critical bug was found: the mailer worker does not read the new nested `:branding` config when setting the `From:` header, so any host that migrates to `:branding[:from_email]` / `:branding[:from_name]` will silently send mail from the wrong address. Six additional warnings cover a `cond` clause with no fallthrough, an unescaped URL interpolated into HTML, missing `reply_to_email` wiring, a crash-on-missing-recipient in the worker, a subject-line data exposure, and filesystem I/O on every email render. Info items cover code duplication, error swallowing, and minor polish.

## Critical Issues

### CR-01: Mailer worker ignores `:branding` config for `From:` header

**File:** `accrue/lib/accrue/workers/mailer.ex:68-71`
**Issue:** The worker reads the `From:` name and address from the **deprecated flat** keys `:from_name` / `:from_email`:

```elixir
|> Swoosh.Email.from(
  {Application.get_env(:accrue, :from_name, "Accrue"),
   Application.get_env(:accrue, :from_email, "noreply@example.com")}
)
```

`Accrue.Config.branding/0` is the documented single source of truth (D6-02), and the `:branding` schema declares `:from_email` as `required: true`. Any host that correctly uses the new nested config (`config :accrue, :branding, from_email: "billing@acme.com"`) will have their outgoing email silently sent from `"noreply@example.com"` — the default flat-key fallback. This also defeats the deprecation shim in `Accrue.Config.branding/0`, which only takes effect when callers read through that function. `Accrue.Application.warn_deprecated_branding/0` warns about flat keys, but the warning is vacuous because the worker *requires* them to send mail correctly.

The `Accrue.Emails.*` subject builders already read from `%{context: %{branding: b}}`, so the convention exists elsewhere — the worker is the outlier.

**Fix:**
```elixir
|> Swoosh.Email.from(
  {Accrue.Config.branding(:from_name), Accrue.Config.branding(:from_email)}
)
|> maybe_reply_to(Accrue.Config.branding(:reply_to_email))
```

where `maybe_reply_to/2` no-ops on `nil`. Also consider freezing branding onto `assigns` in `enrich/2` rather than re-reading from `Accrue.Config` inside the hot path, to honor Pitfall 8 (branding freeze) end-to-end.

## Warnings

### WR-01: `Config.branding/0` `cond` has no fallthrough clause

**File:** `accrue/lib/accrue/config.ex:468-479`
**Issue:** The `cond` has only two clauses (`is_list(raw) and raw == []` and `is_list(raw)`). If `get!(:branding)` ever returns a non-list value — possible if a host misconfigures `:branding` as a map during a migration, or if the schema is bypassed via `Application.put_env/3` in tests — `cond` raises `CondClauseError`, which is far less informative than the validator's `NimbleOptions.ValidationError`. Boot-time validation normally catches this, but `Application.put_env/3` in tests bypasses boot validation entirely.

**Fix:**
```elixir
cond do
  is_list(raw) and raw == [] ->
    branding_from_flat_keys()

  is_list(raw) ->
    merge_with_defaults(raw)

  true ->
    raise Accrue.ConfigError,
      key: :branding,
      message: "expected :branding to be a keyword list, got: #{inspect(raw)}"
end
```

### WR-02: Unescaped URL interpolation into HTML body

**File:** `accrue/lib/accrue/workers/mailer.ex:204-205`
**Issue:** `append_hosted_url_note/3` interpolates `url` directly into an HTML string without escaping:

```elixir
new_html =
  (email.html_body || "") <>
    ~s(<p><a href="#{url}">View your invoice online</a></p>)
```

The URL is sourced from `obj.hosted_invoice_url` (Stripe canonical fetch), so under normal flow it's trusted. However: (1) defense-in-depth — this is a library, a host might inject `hosted_invoice_url` from a different code path (spoofed webhook, test fixtures with malformed data, Stripe Connect account with attacker-controlled display settings); (2) if the URL contains a `"` character it breaks the HTML attribute quoting even without a hostile actor; (3) Swoosh's `html_body/2` does not re-encode, so the bytes land in the customer's inbox as-is. The existing validation (`is_binary(url) and url != ""`) does not sanitize.

**Fix:** Escape the URL via `Phoenix.HTML` when interpolating:

```elixir
alias Phoenix.HTML

safe_url =
  url
  |> HTML.html_escape()
  |> HTML.safe_to_string()

new_html =
  (email.html_body || "") <>
    ~s(<p><a href="#{safe_url}">View your invoice online</a></p>)
```

Or better, build the snippet via `Phoenix.HTML.Tag.content_tag/3` so both the attribute and the text are encoded.

### WR-03: `Swoosh.Email.to/2` called with `nil` when recipient is missing

**File:** `accrue/lib/accrue/workers/mailer.ex:67`
**Issue:** `Swoosh.Email.to(atomized[:to] || enriched["to"])` — if neither key is set (possible when dispatch comes from `default_handler.ex` `safe_deliver/2` with only `customer_id` assigns, and `enrich/2` does not fill in `:to`), this calls `Swoosh.Email.to(nil)` which raises `FunctionClauseError` inside the Oban worker. The job will retry on every attempt and eventually land in the DLQ. `enrich/2` hydrates `customer` but never copies `customer.email` into `:to`.

Cross-reference: `default_handler.ex` lines 1028-1035, 1053-1067, 1070-1081 all build assigns without `:to` — they rely on `:customer_id` to resolve recipient later, but that resolution never happens.

**Fix:** Resolve `:to` from the hydrated customer in `enrich/2`:

```elixir
to =
  Map.get(assigns, :to) || Map.get(assigns, "to") ||
    (customer && customer.email)

assigns
|> Map.put(:to, to)
# ...
```

And in `perform/1`, fail loudly with a non-retriable error if `:to` is still nil — a missing address is a terminal config error, not a transient failure.

### WR-04: `:reply_to_email` branding key is never applied to outgoing mail

**File:** `accrue/lib/accrue/workers/mailer.ex:66-74` (and `config.ex:238`)
**Issue:** The schema declares `branding.reply_to_email` (config.ex:238) and documents it in the module doc, but `Workers.Mailer.perform/1` never calls `Swoosh.Email.reply_to/2`. Hosts that set `reply_to_email: "billing-replies@acme.com"` will have it silently ignored — customer replies go to the `From:` address instead.

**Fix:** Add a `maybe_reply_to/2` helper after the `from/2` call:

```elixir
defp maybe_reply_to(email, nil), do: email
defp maybe_reply_to(email, reply_to) when is_binary(reply_to),
  do: Swoosh.Email.reply_to(email, reply_to)
```

Wire it into the pipeline alongside the `from/2` fix in CR-01.

### WR-05: Stripe charge ID exposed in email subject line

**File:** `accrue/lib/accrue/emails/refund_issued.ex:16-17`
**Issue:**
```elixir
def subject(%{context: %{charge: %{id: id}}}) when is_binary(id),
  do: "Refund issued for charge #{id}"
```

The Stripe charge id (`ch_3P...`) is a stable, user-identifying reference. Email subject lines are visible in notification popups, saved in email logs by third-party forwarders, indexed by inbox providers, and shown in plaintext to anyone with screen access. Leaking `ch_...` IDs here does not give an attacker direct API access (charge IDs aren't secrets), but it is a PII-adjacent footgun: it connects a customer's email address to a specific processor charge in a channel the library cannot audit. None of the other 12 email subject builders include raw processor IDs. CLAUDE.md security constraint: "Sensitive Stripe fields never logged."

**Fix:** Replace the processor id with the invoice number or a human-readable amount:

```elixir
def subject(%{context: %{refund: %{formatted_amount: amt}}}) when is_binary(amt),
  do: "Refund issued: #{amt}"

def subject(%{context: %{branding: b}}),
  do: "Refund issued by #{b[:business_name]}"
```

### WR-06: `EEx.eval_file/2` re-reads text templates on every email

**File:** All 13 email modules, e.g. `accrue/lib/accrue/emails/receipt.ex:23-29`
**Issue:** `render_text/1` calls `EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))` on every delivery. Beyond the performance cost (out of v1 scope), this is also a **correctness** concern: `EEx.eval_file/2` reads from disk at runtime via `:code.priv_dir(:accrue)`. In a release, `priv` is bundled but a misconfigured release (missing priv files, overlay failure, read-only FS permission error) surfaces as a runtime crash *only when the first email is attempted* — long after boot validation. Emails then fail in the Oban queue and block unrelated jobs.

This also means every runtime evaluation parses the `.text.eex` source on every call — no compile-time safety net for template syntax errors.

**Fix:** Use `EEx.function_from_file/5` at compile time so the template is parsed once and bundled into the beam:

```elixir
require EEx

EEx.function_from_file(
  :def,
  :render_text,
  Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/receipt.text.eex"),
  [:assigns]
)
```

Note this requires the path to exist at compile time — which it does for library code. Bonus: eliminates the 13-module `to_keyword/1` duplication since `@assigns` is addressed as a keyword inside EEx naturally.

## Info

### IN-01: Duplicated `to_keyword/1` and `text_template_path/0` across 13 email modules

**File:** All `accrue/lib/accrue/emails/*.ex` (except `fixtures.ex`, `html_bridge.ex`)
**Issue:** Every email module copies the same ~15-line `to_keyword/1` implementation and a near-identical `text_template_path/0`. 13 copies of the same `String.to_existing_atom` reducer. Any future bug fix or refactor (e.g., the WR-06 compile-time-EEx fix) needs 13 identical edits.

**Fix:** Extract to a `use Accrue.Emails.Template` macro module that injects the shared helpers, or collapse into a single behaviour module. The `mjml_template` path and `render_text/1` module name can be derived from `__MODULE__`.

### IN-02: `maybe_load_customer/1` swallows all errors as `nil`

**File:** `accrue/lib/accrue/workers/mailer.ex:278-292`
**Issue:** DB errors, schema mismatches, and bad ids all collapse into `nil`, which then cascades into "customer has no preferred locale" → application default. In dev this hides real bugs (e.g., `preferred_locale` column removed, `Accrue.Repo` misconfigured). The docstring says "best-effort" but there's no telemetry event on the rescue branch, so operators have no signal the hydration failed.

**Fix:** Add `:telemetry.execute([:accrue, :email, :customer_hydration_failed], %{count: 1}, %{customer_id: customer_id})` in both `rescue` and `catch` arms.

### IN-03: `safe_render/3` in mix task rescues `FunctionClauseError` / `KeyError`

**File:** `accrue/lib/mix/tasks/accrue.mail.preview.ex:119-126`
**Issue:** The rescue masks real template bugs during preview generation — a developer who introduces a template assigns mismatch won't see a clear error, just a fallback render against `fixture.context`. The comment says this is intentional (two-shape support), but the two shapes should be made explicit rather than branch-via-exception.

**Fix:** Check arity / shape via `function_exported?/3` + pattern match on the fixture keys, and let genuine exceptions propagate to the shell so template bugs surface loudly.

### IN-04: `import Ecto.Query` inside a `try` block in boot warning

**File:** `accrue/lib/accrue/application.ex:185`
**Issue:** `import` inside a function body (let alone inside a `try`) works but is unconventional. Move it to a module-level `import Ecto.Query, only: [from: 2]` at the top of `Accrue.Application`, or factor the sample query into a private helper module where the import is scoped normally.

### IN-05: `render_invoice_pdf/2` error tuple for `%Accrue.Error.PdfDisabled{}` vs `{:error, :chromic_pdf_not_started}` shape asymmetry

**File:** `accrue/lib/accrue/invoices.ex:73-92`
**Issue:** `{:error, %Accrue.Error.PdfDisabled{}}` wraps a struct, while `{:error, :chromic_pdf_not_started}` is a bare atom. Both are terminal, but callers have to pattern-match two different shapes. Consider unifying — either wrap the atom as `%Accrue.Error.PdfAdapterUnavailable{}` for symmetry, or document clearly why the two shapes differ. Low impact: the mailer worker already handles both branches, but downstream consumers (admin UI, custom handlers) will repeat the pattern.

**Fix:** Decide on one convention and document it on `@spec` and in `@moduledoc`.

---

_Reviewed: 2026-04-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
