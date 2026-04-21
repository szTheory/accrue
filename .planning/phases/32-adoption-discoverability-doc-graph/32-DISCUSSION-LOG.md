# Phase 32: Adoption discoverability + doc graph - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `32-CONTEXT.md`.

**Date:** 2026-04-21  
**Phase:** 32 — Adoption discoverability + doc graph  
**Areas discussed:** Root README hops (ADOPT-01); Host README IA (ADOPT-02); Cross-guide SSOT (ADOPT-03); Playwright/npm naming (coherence)  
**Mode:** User selected **all** gray areas; research via parallel subagents; decisions synthesized one-shot into CONTEXT.

---

## 1. Root README → VERIFY-01 path (ADOPT-01)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Host README only | Thin root; all proof on host | |
| B — Lanes table on root | Fake / CI / deep architecture routing | Partial (optional thin cues only) |
| C — Explicit VERIFY block on root | Named section + commands + deep link | ✓ (hybrid) |
| D — Guides hub second hop | Root → guides index → proof | |
| E — Hybrid | Root summary + host long-form SSOT | ✓ |

**User's choice:** Synthesized **D-01** — named root block (Fake-first, exact `cd`, merge-blocking command, single anchor to host authoritative H2); host owns runnable depth (Hex idiom + evaluator 60-second expectation).

**Notes:** Research cited Rails Pay / Laravel Cashier / Jumpstart patterns: one blessed path, CI/README naming parity; footgun = duplicate tutorials that drift.

---

## 2. Host README authoritative subsection (ADOPT-02)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Single “Proof & CI” H2 | Subheads for mix / VERIFY-01 / Playwright / links | ✓ |
| B — Start here box + deep links | Short box; authority elsewhere | |
| C — Merge VERIFY-01 into Verification modes | Modes parent, VERIFY-01 child | ✓ (combined with A) |
| D — Quickstart vs reference layers | Two layers | Partial (quickstart stays short) |

**User's choice:** **D-02** — One H2 Proof & verification (stable title); internal H3s; opening SSOT paragraph for `host-integration` ↔ `mix verify.full` vs `mix verify`; visuals non-blocking.

**Notes:** Phoenix example-app idiom: prerequisites → quickstart → single testing chapter → docs map.

---

## 3. Cross-guide SSOT (ADOPT-03)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Single hub doc | One matrix for all lanes | ✓ (split executable vs philosophy) |
| B — One-liner + link | Same sentence everywhere | ✓ |
| C — Glossary/matrix table | Rows for lanes + CI | ✓ (matrix in host/docs, not duplicated) |
| D — Tier badges | Fake / Stripe / live vocabulary | ✓ (in prose, aligned with CI) |

**User's choice:** **D-03** — Executable SSOT = host §; philosophy = `accrue/guides/testing.md` + Stripe guide; identical merge-blocking one-liner; extend doc contract scripts.

**Notes:** Stripe docs / Cashier / Pay lesson: quickstart vs full suite; stable job **id** not display name; footgun = `mix test` implied as PR-equivalent.

---

## 4. Playwright / npm entry naming

| Option | Description | Selected |
|--------|-------------|----------|
| A — Always qualify `cd` | Every out-of-host mention | ✓ |
| B — Prefixed prose (“host: …”) | Disambiguate script names | ✓ (optional after first mention) |
| C — Matrix table | Lane × Mix × npm × role | ✓ (in host Proof section) |
| D — Umbrella terms | VERIFY-01 browser vs trust visuals | ✓ |

**User's choice:** **D-04** — cwd discipline; umbrella vocabulary; matrix under host; Windows `npx` escape hatch centralized.

**Notes:** Monorepo footgun = `npm run` from wrong package root; visual suites mistaken for merge-blocking proof.

---

## Claude's Discretion

- Exact host H2 title and anchor slug (within D-02 constraints).
- Root section title wording.
- Size of summary table on host vs matrix-only doc.

## Deferred Ideas

- Phase 33 installer + CI clarity; Phases 34–35 admin/summary/copy work.
