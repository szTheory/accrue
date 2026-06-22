---
quick_id: 260622-fql
verified: 2026-06-22T15:35:00Z
verdict: PASS
score: 7/7 checkpoints verified
verifier: Claude (independent goal-backward re-run)
---

# Verification: 260622-fql — Admin page-header microcopy, one consistent JTBD voice

**Goal:** Every admin section page has `h1.ax-display` + `p.ax-body.ax-page-copy` subtitle in one
consistent JTBD voice modeled on /admin/customers; Recovery (which had none) now has a subtitle.
Copy-only + tiny markup; no CSS/JS; bundles untouched.

## VERDICT: PASS

All 7 checkpoints (A–G) verified independently against the codebase and a fresh test run. No genuine
regressions. The two noted items (refund/invoice-actions "billing facade" strings; webhooks table
caption) are out of scope per the plan and confirmed not in page-header copy.

| Checkpoint | Status | Evidence |
| ---------- | ------ | -------- |
| A. Approved strings live | ✓ PASS | All Copy helpers return exact approved strings incl. em-dashes |
| B. LiveViews wired | ✓ PASS | 3 inline LVs now call Copy; Recovery subtitle placed correctly; customers/dashboard unchanged |
| C. Recovery renders subtitle | ✓ PASS | recovery_live_test:64 asserts `Copy.recovery_index_subtitle()`; test green |
| D. No jargon in headers | ✓ PASS | All 10 jargon phrases absent from page-header copy helpers |
| E. Tests | ✓ PASS | compile clean; 350 tests, 0 failures; all 5 must-update assertions fixed |
| F. No-bundle / guardrails | ✓ PASS | No asset/bundle/.planning/host changes; exactly 3 code commits |
| G. Consistency (the point) | ✓ PASS | All 11 headers share plain-noun h1 + two-part subtitle shape and voice |

---

## Checkpoint A — Approved strings are live

Read each Copy source directly (not the SUMMARY):

- `copy/billing_event.ex:59,61` — `billing_events_heading_organization`/`_global` both = **"Event log"** ✓
- `copy/billing_event.ex:63-69` — both new append-only subtitles match approved (org "in this organization", global "across all organizations") ✓
- `copy/invoice.ex:24` headline = **"Invoices"**; `:26-28` body = "Open and uncollectible invoices first **—** your collections queue. Switch status or search by customer to widen the view." ✓ (em-dash present)
- `copy/coupon.ex:8` headline = **"Coupons"**; `:10-12` body matches ✓
- `copy/promotion_code.ex:8` headline = **"Promotion codes"**; `:10-12` body matches ✓
- `copy/connect.ex:12` headline = **"Connected accounts"**; `:14-16` body matches ✓
- `copy.ex:523-545` — 4 NEW helpers present and exact:
  - `subscriptions_index_heading` = "Subscriptions" + subtitle ✓
  - `charges_index_heading` = "Payments" + subtitle ✓
  - `webhooks_index_heading` = "Webhooks" + subtitle ✓
  - `recovery_index_heading` = **"Revenue Recovery"** + subtitle with em-dash ("at risk of churn **—** how many recover…") ✓

Customers reference (`copy.ex:497-501`) UNCHANGED — verified.

## Checkpoint B — LiveViews wired

- `subscriptions_live.ex:102-103` → `Copy.subscriptions_index_heading()` / `_subtitle()` — no inline literal ✓
- `charges_live.ex:78-79` → `Copy.charges_index_heading()` / `_subtitle()` ✓
- `webhooks_live.ex:139-140` → `Copy.webhooks_index_heading()` / `_subtitle()` ✓ (the line-159 `data-role="webhooks-retry-helper"` paragraph is a separate retry helper, not the header)
- `analytics/recovery_live.ex:104` h1 → `Copy.recovery_index_heading()`; **NEW** `:114` `<p class="ax-body ax-page-copy"><%= Copy.recovery_index_subtitle() %></p>` placed AFTER the `.ax-heading-row` (closes :113) and BEFORE `WindowSelector` (:115) — exactly as specified ✓
- Customers LV (`customers_live.ex:95-96`) + dashboard headers UNCHANGED — git diff of those files across the 3 commits is empty ✓

## Checkpoint C — Recovery actually renders a subtitle now

`recovery_live_test.exs:58-64` mounts `/billing/analytics/recovery` and asserts both
`html =~ Copy.recovery_index_heading()` and `html =~ Copy.recovery_index_subtitle()`. Test is green
in the full run. The user's headline complaint (Recovery had no subtitle) is fixed and test-covered.

## Checkpoint D — No jargon in page-header copy

Grepped all 10 forbidden phrases against `copy.ex` + `copy/`. Three matches found, all confirmed
OUT of scope of page headers:

- `copy.ex:586` `charge_refund_created_info` — refund flash/info message ("…from the billing facade.") — not a page header.
- `copy/invoice.ex:120` `invoice_actions_body` — invoice **actions panel** body on the detail page — not a section page header.
- `copy.ex:3` — moduledoc comment ("admin surfaces") — not user-facing copy.

NONE of the `*_index_*` / `*_headline` / `*_body` / `billing_events_*` page-header helpers contain
any jargon phrase. The `webhooks_index_table_caption` (copy.ex:753, "Replay, inspect, and trace
webhook delivery") is the explicitly out-of-scope table `<caption>` — noted, not failed.

## Checkpoint E — Tests

- `mix compile --warnings-as-errors` → **EXIT 0**, clean.
- `mix test` (full accrue_admin suite) → **350 tests, 0 failures**.
- `mix test copy_test.exs assets_test.exs` → **7 tests, 0 failures** (CPY-03 token-check + asset md5 green).
- All 5 must-update assertions fixed to `Copy.<fn>()` (commit beef8722 diff):
  - subscriptions_live_test ("Lifecycle-safe subscription search" → Copy fns) ✓
  - charges_live_test ("Payment and refund review" → Copy fns) ✓
  - webhooks_live_test ("Replay, inspect, and trace webhook delivery" → Copy fns) ✓
  - connect_accounts_live_test ("Connected accounts and payout readiness" → Copy fns) ✓
  - events_live_test:173 ("Billing activity for the active organization" → `Copy.billing_events_copy_organization()`) ✓ — the blocker the first plan grep missed
- Recovery subtitle assertion ADDED ✓
- Stay-green tests (invoices/coupons/promotion) assert via `Copy.<headline>()` — remain valid ✓

## Checkpoint F — No-bundle / guardrails

- `git diff --name-only 68fb8bc5~1 beef8722` = 16 files: 6 copy + 4 live + 6 test. NO
  `priv/static/*`, `assets/*`, `app.css`, `app.js`, `mix.lock`, `ROADMAP`, `.planning`, StatusBadge,
  CSP, or examples/host files.
- `assets_test.exs` pins committed bundle md5 (`AccrueAdmin.Assets.{css,js,brand}_hash` == md5 of
  `priv/static/*`) and is green WITHOUT a rebuild → bundles confirmed untouched. Working tree has no
  asset changes.
- Exactly **3 code commits**: `68fb8bc5` feat(copy), `b3709f8f` refactor, `beef8722` test. None
  touch `.planning/` (verified via per-commit `--stat`).

## Checkpoint G — Consistency (the actual point)

All 11 section headers now share the shape: plain-noun h1 (matches nav label) + two-part
"[what it is]. [how to act — search/filter/open]" subtitle, brand voice, no implementation jargon:

Customers · Subscriptions · Invoices · Payments · Webhooks · Event log (org) · Event log (global) ·
Coupons · Promotion codes · Connected accounts · Revenue Recovery.

Each subtitle leads with a domain description and closes with a navigate/act instruction
(search/filter/open/replay), matching the /admin/customers reference voice. No page reads off-voice.

**Minor note (accepted, not a fault):** "Revenue Recovery" is the only title-case two-word h1 (the
nav label is "Recovery"). This is the user-approved exact string per the plan's copy table — an
intentional, approved deviation, not an inconsistency to flag.

---

## Accepted deviations vs. regressions

- "billing facade" in `charge_refund_created_info` and `invoice_actions_body` — pre-existing, NOT
  page-header copy, explicitly out of Checkpoint D scope. Accepted.
- `webhooks_index_table_caption` reusing the old phrase — explicitly OUT OF SCOPE per plan. Accepted.
- "Revenue Recovery" title-case h1 — user-approved exact string. Accepted.

No genuine regressions found.

---

_Verified independently: 2026-06-22_
