---
phase: 126
slug: admin-surface-docs-jtbd-spine
status: verified
threats_open: 0
asvs_level: 2
block_on: high
register_origin: authored-at-plan-time
created: 2026-05-24
---

# Phase 126 — admin-surface-docs-jtbd-spine — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> **Disposition: SECURED — 14/14 threats closed (11 mitigate verified + 3 accept upheld).**
>
> NOTE: This file is the per-phase security audit record. It is intentionally
> separate from the repo-root `SECURITY.md` (the public vulnerability-disclosure
> policy), which was not modified.

**Register origin:** authored at plan time (4 PLAN.md `<threat_model>` blocks) → verification-only; no new register constructed.

## Verdict

Every declared mitigation has a corresponding grep/Read match in the implemented
code at the cited location, and all three `accept` dispositions were verified to
actually hold in code (not merely asserted). The merge-blocking doc verifier
exits 0 and its Elixir wrapper passes 8/0; the Plan 01 seam contract passes 9/0.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Operator browser → accrue_admin LiveView | Only untrusted input is the `tab` query param; allowlisted by `normalize_tab/1` against `@tabs`. | Tab string (validated) |
| accrue_admin LiveView → accrue core | Admin holds an already-owner-scoped `%Customer{}` from mount; calls `Accrue.Entitlements.Admin.resolve_for_customer/1`. No bypass of `Customers.detail/2`. | Owner-validated `%Customer{}` |
| Public package API surface | The diagnostic seam must NOT leak into the published `Accrue.*` gate API — `@doc false` + separate internal module keep it off the docs surface. | (internal-only) |
| Published docs → reader | Guide prose teaches developers how to gate access; fail-open guidance would propagate an anti-pattern to every host. | Gating guidance |
| Public vs internal docs | `jobs_to_be_done.md`/README/quickstart/entitlements.md are PUBLIC (HexDocs); JTBD-FRONTIER.md/PROJECT.md are INTERNAL. Deferred roadmap stays internal. | Roadmap honesty |
| CI verifier → merge gate | The package-doc verifier is merge-blocking; a needle referencing an unseeded/absent file would false-fail or false-pass. | Doc needles (SSOT-mirrored) |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Status | Evidence (file:line) |
|-----------|----------|-----------|-------------|--------|----------------------|
| T-126-01 | Elevation of Privilege | New public `Accrue.*` fn misused as fail-open gate (D-07 trap) | mitigate | closed | `accrue/lib/accrue/entitlements/admin.ex:1-50` — separate internal module; moduledoc (2-10) states "NOT a public gate API"; `resolve_for_customer/1` (47-49) returns `{resolved, unmapped_price_ids}`, never a boolean. `entitlements.ex` still has exactly 4 public defs (entitled?/has_active_plan?/features_for/entitlement_quantity at :62/:99/:135/:154) — no new gate fn. Both LocalMap seam helpers carry `@doc false` (`local_map.ex:99,113`). |
| T-126-02 | Tampering | Divergent resolver fold drifting from SSOT | mitigate | closed | `accrue/lib/accrue/entitlements/resolver/local_map.ex:100` — `fold_for_customer/1` literally calls `fold_active(customer)` (single SSOT fold, defined :125). No second fold copy. |
| T-126-03 | Information Disclosure | Resolved entitlement map containing PII | accept | closed | Resolved-map shape `@empty` (`local_map.ex:53-61`) = `plan` atom\|nil + 5 MapSets of atoms + `quantities` `%{atom=>int}`. No email/name/owner_id/Stripe secret. Seam returns fold + `[String.t()]` price_id list, never `%Customer{}` (`admin.ex:48`). |
| T-126-04 | Info Disclosure / Elevation | Cross-tenant entitlement view | mitigate | closed | `customer_live.ex:38` — mount calls `Customers.detail(customer_id, current_owner_scope)`; out-of-scope → redirect (39-45). Tab reuses the same owner-validated `@customer` (no new route; `@tabs` :32 adds a query value only). Seam queries by validated `customer` (:527-528, :546-548). |
| T-126-05 | Information Disclosure | PII leak in resolved-map JsonViewer render | mitigate | closed | `customer_live.ex:440` — JsonViewer `payload={entitlements_display_map(resolved)}`. Helper (:556-566) builds a fresh map of plan/feature atoms (MapSet→sorted) + `quantities`; never includes `%Customer{}`. |
| T-126-06 | Tampering (operational misread) | "Unmapped plan" drift badge misread as enforcement | mitigate | closed | Entitlements `case` clause (`customer_live.ex:361-442`) is display-only. All 5 `handle_event` clauses (:80,:93,:112,:131,:135) are payment-method ops — none grant/revoke/edit entitlements. Self-explaining hint copy (`copy/entitlements.ex:26-27`). |
| T-126-07 | Input Validation | Crafted `tab` query param value | accept | closed | `customer_live.ex:807-808` — `normalize_tab(tab) when tab in @tabs` / fallthrough → `"subscriptions"`. `@tabs` (:32) includes `entitlements`. `String.to_existing_atom` (:507) applied only to `@tabs` members — cannot raise on attacker input. |
| T-126-08 | Repudiation / Misleading guidance | entitlements.md teaching a fail-open pattern | mitigate | closed | `accrue/guides/entitlements.md:21-35` — Getting Started LEADS with the fail-closed easy path and states "there is no fail-open branch anywhere in the gate path." No fail-open snippet present. |
| T-126-09 | Information Disclosure | Over-claiming deferred sync as shipped / leaking internal roadmap | mitigate | closed | `accrue/guides/jobs_to_be_done.md:383-385,401` — honest "*optional* Stripe-native sync … deferred, off-by-default (Phase 127)". Deferred detail lives in internal `.planning/research/JTBD-FRONTIER.md` only. |
| T-126-10 | Tampering | Doc truth-table / provider matrix drifting from SSOT | mitigate | closed | `entitlements.md:91,205` link `lifecycle_semantics.md#lifecycle--entitlement-truth-table` (summarize-and-link, no re-derived table); `:222` provider honesty is prose + `Accrue.Processor.Capabilities` link (not the internal `.planning` matrix). |
| T-126-11 | Tampering | Verifier needle references unseeded/absent file | mitigate | closed | `accrue/test/accrue/docs/package_docs_verifier_test.exs:262,264` — `seed_tmp_dir!` copies `entitlements.md` + `jobs_to_be_done.md`. Verifier test runs 8/0 (no "No such file"). |
| T-126-12 | Spoofing / drift slip-through | Flip-guard regex defeated by historical Update-log line | mitigate | closed | `scripts/ci/verify_package_docs.sh:123` — `require_absent_regex … 'on the table\*\* is \*\*entitlements'` scoped to the unique scope-prose phrase (not "headline gap"). Phrase confirmed ABSENT in `jobs_to_be_done.md` (grep exit 1). |
| T-126-13 | Tampering | Positive needle not byte-matching authored doc string | mitigate | closed | `verify_package_docs.sh:118-124` needles byte-match on-disk docs: README `:19`, entitlements.md (`entitled?`, `Accrue.Plug.RequireEntitlement`, `[:accrue, :entitlements, :check]`), quickstart `:30`, JTBD marker `entitlements ✅ shipped` at `jobs_to_be_done.md:398`. Live verifier exits 0. |
| T-126-SC | Tampering (supply-chain) | npm/pip/cargo installs | accept | closed | `git diff d23bde1~1..a8f4056 -- **/mix.exs` is EMPTY — zero new dependency declared. Only `accrue_admin/mix.lock` reconciled; every package name appears on BOTH `-`/`+` sides (version reconcile, no net-new package). |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Verification the acceptance is sound | Accepted By | Date |
|---------|------------|-----------|--------------------------------------|-------------|------|
| AR-126-01 | T-126-03 | Admin diagnostic returns resolved entitlement state; non-sensitive — no PII. | Resolved-map keys are plan/feature atoms + integer quantities only (`local_map.ex:53-61`); seam never returns `%Customer{}` (`admin.ex:48`). | gsd-security-auditor | 2026-05-24 |
| AR-126-02 | T-126-07 | `tab` query param is attacker-controlled; accepted because allowlisted + safe atom conversion. | `normalize_tab/1` allowlists `@tabs`, defaults "subscriptions"; `String.to_existing_atom` only sees `@tabs` members (`customer_live.ex:32,507,807-808`). | gsd-security-auditor | 2026-05-24 |
| AR-126-03 | T-126-SC | No supply-chain review needed — phase installs no new packages. | No `mix.exs` diff across the phase; `mix.lock` change is a reconcile of existing pins (no net-new package). | gsd-security-auditor | 2026-05-24 |

*Accepted risks do not resurface in future audit runs.*

---

## Unregistered Flags

None. No SUMMARY.md in this phase contains a `## Threat Flags` section, and no new
public attack surface (route, endpoint, public gate fn, dependency) was introduced
outside the declared register. The entitlements tab adds a query-param value to an
existing owner-scoped LiveView (no new route/auth surface), and the seam is a
`@doc false` / separate-internal-module addition that does not widen the public API.

---

## Operational Evidence (re-run at audit time)

- `bash scripts/ci/verify_package_docs.sh` → exit 0 ("package docs verified for accrue 1.1.2, accrue_admin 1.1.2, and accrue_portal 1.1.2").
- `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` → 8 tests, 0 failures.
- `cd accrue && mix test test/accrue/entitlements/admin_test.exs` → 9 tests, 0 failures (seam contract).
- One-way dependency check: `grep -rn 'Entitlements.Admin' lib/accrue/billing/ lib/accrue/entitlements/resolver/` → no match (no reverse reference).

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | ASVS | Run By |
|------------|---------------|--------|------|------|--------|
| 2026-05-24 | 14 | 14 | 0 | 2 | gsd-security-auditor (verify-mitigations mode) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24
