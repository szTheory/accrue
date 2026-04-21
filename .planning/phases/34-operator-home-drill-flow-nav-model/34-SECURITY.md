---
phase: 34
slug: operator-home-drill-flow-nav-model
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-21
---

# Phase 34 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.  
> Source threat models: `34-01-PLAN.md`, `34-02-PLAN.md`, `34-03-PLAN.md`.  
> Plan summaries did not define a separate `## Threat Flags` section; disposition below follows code review + verification (`34-VERIFICATION.md`).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Operator browser ↔ mounted admin | Authenticated operator uses LiveView UI over HTTPS (host responsibility). | Session-backed `OwnerScope`; no new PII stores in this phase. |
| Admin UI ↔ tenant scope | `?org=` and `OwnerScope` determine which rows/links are valid. | Org slug in URLs must match resolved scope, not raw untrusted concatenation. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-nav-01 | Tampering / broken authz (URL) | `AccrueAdmin.ScopedPath`, dashboard links | mitigate | `ScopedPath.build/4` matches prior `scoped_mount_path/4` clauses; `scoped_path_test.exs` covers global, org, and query params. | closed |
| T-nav-02 | Information disclosure (confusing targets) | `DashboardLive` KPI `href`s | mitigate | Four KPIs map to distinct index paths only (`/customers`, `/subscriptions`, `/invoices`, `/webhooks`) with no status query. | closed |
| T-ui-01 | Repudiation / a11y gap | `KpiCard` linked mode | mitigate | When `href` set, root is `<a>`; `DashboardLive` passes `aria_label` per card; `.ax-kpi-card--linked` focus styles in CSS. | closed |
| T-idor-01 | Elevation / IDOR (cross-tenant href) | `CustomerLive` invoices tab, `InvoiceLive` breadcrumbs | mitigate | New `href`s use `ScopedPath.build(@admin_mount_path, ..., @current_owner_scope)` only; no raw `?org=` from `params`. | closed |
| T-nav-03 | Tampering (nav state desync) | `InvoiceLive` shell assigns | mitigate | Breadcrumb `href`s only changed; `assign(:current_path, admin_path(admin, "/invoices"))` unchanged—sidebar active state unchanged by design. | closed |
| T-conf-01 | Tampering (wrong tenant links) | `AccrueAdmin.Nav` | mitigate | `nav_href/3` and `org_slug/1` moved verbatim from `AppShell` into `Nav`; `app_shell_test` org preservation still applies. | closed |
| T-doc-01 | Maintenance / drift | `accrue_admin/README.md` | mitigate | **Admin routes** table lists every shipping `live/3` path from `router.ex` plus dev-only table; explicit pointer to `AccrueAdmin.Router.accrue_admin/2`. | closed |

*Status: open · closed*  
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-21 | 7 | 7 | 0 | gsd-secure-phase (inline; no `gsd-security-auditor` spawn — all threats pre-closed from plan mitigations + `34-VERIFICATION.md`) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-21
