# Phase 47: Post-release docs & planning continuity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `47-CONTEXT.md` — this log preserves alternatives considered.

**Date:** 2026-04-22  
**Phase:** 47 — Post-release docs & planning continuity  
**Areas discussed:** `RELEASING.md` structure (REL-03); install snippets (DOC-01); planning SSOT / PR strategy (HYG-01); verifier scope (DOC-02)  
**Mode:** User selected **all** areas; research delegated to parallel subagents; principal agent synthesized into locked decisions.

---

## 1 — `RELEASING.md` structure (REL-03)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Routine-first + bootstrap appendix | Recurring Release Please path leads; 1.0.0 story at end or linked | ✓ |
| B — Parallel equal weight | Both narratives prominent | |
| C — Split files | Tiny `RELEASING.md` + separate bootstrap doc | |

**User's choice:** Research synthesis + agent consolidation → **A** (with optional linked bootstrap doc; single obvious entry point).  
**Notes:** Cross-ecosystem pattern (Pay/Cashier/npm/Rust) favors **low-ceremony recurring spine**; Elixir/Hex culture treats **release PR + changelog** as rhythm. Anti-pattern: leading with bootstrap so the 5th `0.x` ship feels like the wrong doc.

---

## 2 — Primary install snippets (DOC-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Exact `==` pair | Maximum reproducibility | |
| Three-part `~> X.Y.Z` both packages | Matches Mix pre-1.0 semantics + lockstep; CI-synced from `@version` | ✓ |
| Wide `~> 0.M` | Simple-looking range | |

**User's choice:** **Three-part `~>`** identical for `accrue` and `accrue_admin`, synced to shipped `@version`, plus short prose on pre-1.0 + lockstep.  
**Notes:** `~> 0.3` allows up to `< 1.0.0` — footgun for tutorials. `path:`/`github:` deferred to non-primary docs.

---

## 3 — Planning hygiene PR strategy (HYG-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Same PR / same merge train as release | PROJECT / MILESTONES / STATE Hex lines with doc + verifier | ✓ |
| Separate fast-follow PR | Cleaner diff; drift window | |

**User's choice:** **Same merged unit** as release (default); **documented exceptions** for urgency, large re-roadmap, or branch policy.  
**Notes:** Analogous to **changelog + tag atomicity**; small-team dominant failure mode is “forgot the hygiene PR.”

---

## 4 — Verifier scope vs manual checks (DOC-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Verifier + ExUnit + existing `mix docs` CI | Mechanical contracts + API doc warnings | ✓ |
| + Mandatory badge / README HTTP checks | Broader, brittle | |

**User's choice:** **Mandatory:** `verify_package_docs.sh` + `package_docs_verifier_test.exs`; **existing** `mix docs --warnings-as-errors` in CI is part of the bar. **Optional:** short maintainer glance at Hex/README optics.  
**Notes:** Stripe-like “pin integration surface to supported version” maps to automated version gates + versioned narrative; badges excluded from merge-blocking evidence.

---

## Claude's Discretion

- Appendix title / split-bootstrap vs in-file appendix (**D-01..D-04** discretion).
- Optional link-checker stretch — explicitly deferred.

## Deferred Ideas

- CI badge HTTP validation — deferred (see `47-CONTEXT.md` `<deferred>`).
