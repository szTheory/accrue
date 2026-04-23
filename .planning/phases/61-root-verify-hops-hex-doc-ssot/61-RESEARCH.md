# Phase 61 — Technical research

**Phase:** 61 — Root VERIFY hops + Hex doc SSOT  
**Question:** What do we need to know to plan INT-08 / INT-09 well?

## Findings

### CI job split (blast radius)

- **`release-gate`** runs `mix test` in `accrue/`, including `Accrue.Docs.PackageDocsVerifierTest`, which shells **`scripts/ci/verify_package_docs.sh`** with default `ROOT_DIR` = repo root. This gate **does not** run **`verify_verify01_readme_contract.sh`**.
- **`host-integration`** runs **`verify_verify01_readme_contract.sh`** first (cheap), then adoption matrix + UAT + Playwright stack. Host VERIFY-01 **dynamic** law (Playwright glob from README, `sk_live` negation) **must** stay in the bash script; **cannot** be removed from `verify_package_docs` in favor of verify01-only checks without widening `release-gate` into host-integration.

### Dedupe rule (D-07) — practical interpretation

- **Same file, same substring, different jobs:** Keeping **`mix verify.full`** (and similar) in **`verify_package_docs`** for **`examples/accrue_host/README.md`** remains valid: **`release-gate`** must remain self-sufficient for structural doc pins.
- **True redundancy** to remove: needles in **`verify_package_docs`** that **only** duplicate **VERIFY-01-section semantics** already enforced by **`verify_verify01_readme_contract.sh`** **and** add no value to **`release-gate`** (e.g. a long prose phrase duplicated when a shorter structural pin suffices). Executor should **diff** `require_fixed` targets for `host_readme_md` between the two scripts and drop **at most** lines where CONTEXT D-07 assigns ownership to **`verify_verify01`**.

### Root README vs host README (INT-08, D-01)

- Current root **`README.md`** already has **`## Proof path (VERIFY-01)`**, fenced **`cd examples/accrue_host && mix verify.full`**, merge-blocking **`host-integration`** sentence, and a single deep link to **`examples/accrue_host/README.md#proof-and-verification`**. This matches **hybrid IA** (D-01).
- **INT-08** enforcement path: extend **`verify_package_docs.sh`** only with **additional** `require_fixed` / `require_regex` lines that encode **new** invariants agreed in discuss (e.g. stable anchor fragment, job id spelling) — avoid prose-length checks (D-03).

### Planning mirrors (INT-09, D-08–D-10)

- **`.planning/PROJECT.md`** already carries **“Public Hex (last published)”** vs **workspace `@version`** language (HYG-style). **`.planning/MILESTONES.md`** v1.16 header still has a **stale “Next: plan-phase 59”** line — violates reader trust; fix under INT-09 honesty.
- **D-09:** Add or preserve a **two-line** pattern: branch **`@version`** vs **last published Hex** pair + **https://hex.pm/packages/accrue** (and admin) where milestone prose discusses installs.

### Registry (Phase 60 handoff)

- **`scripts/ci/README.md`** uses a placeholder row: **`INT-08/INT-09` — Phase 61**. Replace with **two** INT table rows mirroring INT-06/07 columns (script owner, ExUnit, phase VERIFICATION path once 61 ships).

## Pitfalls

- **Do not** add **`verify_root_readme_*.sh`** (D-06).
- **Do not** label unreleased **`@version`** as “released on Hex” anywhere (INT-09, Phase 59 continuity).
- Changing **`verify_package_docs.sh`** success **`echo`** lines requires updating **`package_docs_verifier_test.exs`** substring assertions.

## Validation Architecture

Phase 61 is **documentation + bash + ExUnit contract** work. Automated feedback:

1. **`bash scripts/ci/verify_package_docs.sh`** — primary merge-adjacent doc gate (must exit 0 after edits).
2. **`bash scripts/ci/verify_verify01_readme_contract.sh`** — host VERIFY-01 shift-left gate (must exit 0 if host README touched).
3. **`mix test test/accrue/docs/package_docs_verifier_test.exs`** (from `accrue/` app dir) — pins script output and fixture drift regressions.

**Sampling:** run (1) after every task touching markdown or `verify_package_docs.sh`; run (2) when `examples/accrue_host/README.md` changes; run (3) when the script or test file changes.

**Dimension 8 (Nyquist):** No new application runtime features — validation is **existing** test + bash commands; no Wave 0 framework install.

## RESEARCH COMPLETE
