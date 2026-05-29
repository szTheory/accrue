# Phase 152: Close v1.46 closure gaps: @since warnings, verification, Hex publish + tag - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 152-close-v1-46-closure-gaps-since-warnings-verification-hex-pub
**Areas discussed:** Release version

---

## Release version

| Option | Description | Selected |
|--------|-------------|----------|
| 1.3.0 | Let Release Please compute it: 16 `feat:` commits + no breaking changes since 1.2.0 = minor bump → 1.3.0. Treat docstring "1.4.0" as a typo; correct `@doc since:` to 1.3.0. No manual pinning. | ✓ |
| 1.4.0 (honor docstrings) | Manually pin the next linked release to 1.4.0 across all three mix.exs + manifest, overriding the pipeline's computed 1.3.0. | |

**User's choice:** 1.3.0 (Recommended)
**Notes:** This was the only fork escalated — published/irreversible, and the code (`@since "1.4.0"`) contradicted the Release Please linked-versions math (1.3.0). All other closure decisions were presented as locked decisive defaults and accepted without objection: convert stray `@since` → canonical `@doc since: "1.3.0"`; run the Phase 151 "Three Zeros" gate; publish via the established Release Please linked-versions PR + tags.

---

## Claude's Discretion

- Task ordering within the phase (fix `@since` → run gate → cut release PR).
- How the hand-written CHANGELOG "Unreleased" content is reconciled against Release-Please-generated entries.

## Deferred Ideas

None — discussion stayed within phase scope.
