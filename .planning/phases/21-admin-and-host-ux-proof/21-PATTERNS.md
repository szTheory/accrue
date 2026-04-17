# Phase 21 — Pattern Map

Analogs for new work (read before editing).

---

## Admin org-scoped links and shell

- **`accrue_admin/lib/accrue_admin/components/app_shell.ex`** — builds `?org=` suffix for nav links; extend for **visible** active-org chrome (CONTEXT D-02).
- **Phase 20 list links:** `customers_live.ex`, `subscriptions_live.ex` — `mount_path <> suffix <> "?org=" <> URI.encode_www_form(slug)` pattern.

---

## Denial and flash copy (do not drift)

- **`accrue_admin/lib/accrue_admin/live/customer_live.ex`**, **`subscription_live.ex`** — exact flash: `You don't have access to billing for this organization.`
- **`webhook_live.ex`** — ambiguous replay messaging from Phase 20.

---

## Host billing facade

- **`examples/accrue_host/lib/accrue_host/billing.ex`** — public entry points for subscribe / org resolution; extend tests through this module only.

---

## Playwright fixture spine

- **`examples/accrue_host/e2e/global-setup.js`** — invokes seed script.
- **`examples/accrue_host/e2e/phase13-canonical-demo.spec.js`** — `readFixture`, `reseedFixture`, `login`, `waitForLiveView`, a11y axe pattern.

---

## Seed script

- **`scripts/ci/accrue_host_seed_e2e.exs`** — `write_fixture!/2` map; add keys without removing `password`, `normal_email`, `admin_email`, `webhook_id`, etc.

---

## PATTERN MAPPING COMPLETE
