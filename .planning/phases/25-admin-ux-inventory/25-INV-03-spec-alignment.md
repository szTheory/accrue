# INV-03 — Spec alignment

**Snapshot:** 2026-04-20 @ 052a784  
**Production method:** Manual mapping from `20-UI-SPEC.md` / `21-UI-SPEC.md` headings to existing `accrue_admin` LiveView tests, `examples/accrue_host/e2e` specs, and `25-INV-01` / `25-INV-02` inventories.

## Surface rollup (secondary index)

| Surface | Governing spec pointers | Worst status | Link to clauses |
|---------|-------------------------|--------------|-----------------|
| Dashboard | `21-UI-SPEC.md` — Interaction #1 (KPI context); `20-UI-SPEC.md` — Accessibility | Partial | C-06, C-08 |
| Money indexes | `21-UI-SPEC.md` — Interaction #1; Copywriting (empty index, tenant chrome) | Partial | C-01, C-02 |
| Detail pages | `20-UI-SPEC.md` — Customer / Subscription detail; `21-UI-SPEC.md` — Interaction #2 | Partial | C-03, C-04, C-05; **26-02** (single `ax-page` on money details) |
| Webhooks | `20-UI-SPEC.md` — Webhook detail + ambiguous ownership | Aligned | C-04, C-05; **26-03** (`webhooks_live.ex` / `webhook_live.ex` typography parity) |
| Step-up | `20-UI-SPEC.md` — Interaction rules (staged confirm); subscription detail staging | Aligned | C-07 |

## Clause rows (primary index)

| ID | Spec pointer | Status | Scope tags | Evidence | Owner | Gap + target phase (if Partial) |
|----|--------------|--------|------------|----------|-------|----------------------------------|
| C-01 | `21-UI-SPEC.md` — `## Interaction Contract` — §1 Money-relevant indexes | Partial | `admin`, `desktop` | `accrue_admin/lib/accrue_admin/live/customers_live.ex`, `subscriptions_live.ex`, `invoices_live.ex`, `charges_live.ex` (list shells + `ax-chip ax-label` billing signals, 2026-04-20 **Phase 26** plan **26-01**); `accrue_admin/test/accrue_admin/live/customers_live_test.exs`, `subscriptions_live_test.exs`, `invoices_live_test.exs`, `charges_live_test.exs`; `examples/accrue_host/e2e/verify01-admin-mounted.spec.js` (customers only); **2026-04-20 Phase 27 plan `27-01`:** `accrue_admin/lib/accrue_admin/copy.ex` (money index empty copy SSOT), same four `*_live.ex` index files + four live tests for Copy-backed empty states | maintainer | UX-01 list-row signals aligned in **Phase 26**; Playwright still does not walk every money index URL — **Phase 29** |
| C-02 | `21-UI-SPEC.md` — `## Copywriting Contract` (locked strings + tenant chrome table) | Aligned | `admin`, `copy` | `accrue_admin/test/accrue_admin/live/customers_live_test.exs`, `webhooks_live_test.exs`; `examples/accrue_host/e2e/verify01-admin-denial.spec.js`; **2026-04-20 Phase 27 plan `27-02`:** money detail surfaces — `copy.ex`, `copy/locked.ex`, `subscription_live.ex`, `invoice_live.ex`, `charge_live.ex`, matching `*_test.exs` | maintainer | — |
| C-03 | `20-UI-SPEC.md` — `## Admin Owner-Scoped Contract` — `### Common behavior` | Aligned | `admin` | `examples/accrue_host/e2e/verify01-admin-denial.spec.js`; `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` | maintainer | — |
| C-04 | `20-UI-SPEC.md` — `### Webhook detail and bulk replay` | Aligned | `admin`, `webhooks` | `accrue_admin/lib/accrue_admin/live/webhook_live.ex` (2026-04-20 **26-03**: nested `ax-page` removed from replay confirm + forensic stack); `accrue_admin/test/accrue_admin/live/webhook_live_test.exs`, `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs`; `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` | maintainer | — |
| C-05 | `20-UI-SPEC.md` — `### Ambiguous ownership behavior` | Aligned | `admin`, `webhooks` | `accrue_admin/lib/accrue_admin/live/webhook_live.ex`; `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` (**26-03** `ax-kpi-grid` / single-`ax-page` checks) | maintainer | — |
| C-06 | `21-UI-SPEC.md` — `## Interaction Contract` — §3 `?org=` preservation | Partial | `admin`, `host-mount` | `examples/accrue_host/e2e/verify01-admin-mounted.spec.js`, `verify01-admin-denial.spec.js` | maintainer | Not every `push_patch` / `link` path has an automated guard — **Phase 26** hierarchy + link audit |
| C-07 | `20-UI-SPEC.md` — `## Admin Owner-Scoped Contract` — `### Subscription detail` (staged confirmations) | Aligned | `admin`, `step-up` | `accrue_admin/lib/accrue_admin/live/subscription_live.ex` (2026-04-20 **26-02** nested `ax-page` removed); `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` | maintainer | — |
| C-08 | `20-UI-SPEC.md` — `## Accessibility and Responsive Contract` | Partial | `admin`, `@mobile` | `accrue_admin/test/accrue_admin/live/dashboard_live_test.exs` (smoke); no dedicated a11y suite in package | maintainer | Screen-reader / focus-trap proofs — **Phase 28** |
| C-09 | `20-UI-SPEC.md` — `### Customer detail` | Partial | `admin` | `accrue_admin/lib/accrue_admin/live/customer_live.ex`; `accrue_admin/test/accrue_admin/live/customer_live_test.exs` (2026-04-20 **26-02** single-`ax-page` regression); **2026-04-20 Phase 27 plan `27-02`:** `copy.ex` / `copy/locked.ex`, `customer_live.ex`, `customer_live_test.exs` (Copy-backed empty invoices line) | maintainer | Tax ownership card still lacks isolated component tests — optional follow-up |
| C-10 | `21-UI-SPEC.md` — `## Interaction Contract` — §4 Playwright desktop/mobile matrix | Partial | `admin`, `ci` | `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` | maintainer | Full desktop matrix + `@mobile` tagging per `21-CONTEXT.md` — **Phase 29** |
| C-11 | `20-UI-SPEC.md` — `## Visual Constraints` | N/A | `library` | `—` (inherits Phoenix theme tokens; no separate automated gate) | maintainer | N/A — tracked qualitatively in design reviews |

### Legend

- **Status:** `Aligned` = obligations met with cited automated coverage; `Partial` = known gaps; `N/A` = obligation not machine-testable at library boundary.
- **Owner:** `maintainer` unless noted.
