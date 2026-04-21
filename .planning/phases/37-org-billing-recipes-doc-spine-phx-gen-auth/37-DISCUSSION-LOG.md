# Phase 37: Org billing recipes — doc spine + phx.gen.auth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `37-CONTEXT.md`.

**Date:** 2026-04-21  
**Phase:** 37 — Org billing recipes — doc spine + phx.gen.auth  
**Areas discussed:** Doc spine shape; Not-using-Sigra entry points; phx.gen.auth recipe concreteness; ORG-03 depth; examples/accrue_host anchoring  
**Method:** User requested **all** gray areas; five parallel `generalPurpose` research subagents; parent synthesized into locked decisions.

---

## Doc spine shape

| Option | Description | Selected |
|--------|-------------|----------|
| A | New dedicated guide as ORG-05 hub | ✓ (as primary spine) |
| B | Expand only `auth_adapters.md` | |
| C | README / installer index only | |
| D | Hybrid hub + deep links | ✓ (combined with A + short README pointer) |

**User's choice:** All areas explored; **locked:** new dedicated guide + deep links + minimal README (or quickstart) pointer; do not merge full org narrative into `auth_adapters.md`.

**Notes:** Ecto/Phoenix/Oban patterns favor scoped guides; Cashier single-page discoverability emulated via **TOC inside spine**, not one mega-file.

---

## “Not using Sigra” entry points

| Option | Description | Selected |
|--------|-------------|----------|
| A | Top callout on `sigra_integration.md` | ✓ |
| B | New/expanded section at top of `auth_adapters.md` | ✓ (SSOT positioning) |
| C | Installer one-line pointer when not Sigra | ✓ |
| D | Combination | ✓ (A+B+C with one canonical sentence + mirrors) |

**User's choice:** Combination with duplication discipline — hub owns positioning; Sigra page fixes misroutes; installer reaches non-doc readers.

**Notes:** Avoid circular links and Sigra-first tone in hub ordering; avoid implying `Accrue.Auth.Default` is production-complete.

---

## phx.gen.auth recipe concreteness

| Option | Description | Selected |
|--------|-------------|----------|
| A | User billable first, org later | |
| B | Organization billable + membership + active org | ✓ (mainline) |
| C | Two full parallel tracks | |

**User's choice:** **Org-first mainline** with **personal org bootstrap**; **bounded aside** for User billable only (Cashier acknowledgment + migration intent); Pow/custom deferred to Phase 38.

**Notes:** Membership validation on every sensitive resolution; forward link for replay/export depth.

---

## ORG-03 depth in Phase 37

| Option | Description | Selected |
|--------|-------------|----------|
| A | Minimal + link only | |
| B | Full inline copy of v1.3 | |
| C | Normative paragraph + checklist + deep links | ✓ |

**User's choice:** Checklist aligned to **public / admin / webhook replay / export** + link to `.planning/milestones/v1.3-REQUIREMENTS.md` + forward to Phase 38 ORG-08.

---

## examples/accrue_host anchoring

| Option | Description | Selected |
|--------|-------------|----------|
| A | Concrete paths only | |
| B | Generator-agnostic only | |
| C | Hybrid abstract spine + concrete annex | ✓ |

**User's choice:** Placeholders in narrative; **Reference wiring** annex citing real `AccrueHost` modules (repo has both User and Organization billables).

---

## Claude's Discretion

- Exact new guide filename and ExDoc group placement (see CONTEXT).

## Deferred Ideas

- Phase 38–39 scope items recorded in `37-CONTEXT.md` deferred section.
