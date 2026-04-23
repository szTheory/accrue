# Phase 59: Golden path + quickstart coherence - Discussion log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`59-CONTEXT.md`**.

**Date:** 2026-04-23  
**Phase:** 59 — Golden path + quickstart coherence  
**Areas discussed:** Hex vs `main` + version pins; Sigra vs `Accrue.Auth` messaging; verifier scope + contributor preflight; capsule H/M/R + spine structural coherence  
**Mode:** User selected **all** areas and requested **parallel subagent research** + one-shot cohesive recommendations.

---

## 1 — Hex vs `main` and version pins

| Approach | Description | Selected |
|----------|-------------|----------|
| A | Three-part `~> X.Y.Z` locked to `mix.exs` `@version`, enforced by `verify_package_docs` + Hex vs `main` banner | ✓ |
| B | Two-segment `~> 0.3` in human docs | |
| C | Generated install blocks from templates | |
| D | CI-only / vague “use Hex” without pins | |

**User's choice:** Research synthesis — **Approach A** (matches existing repo machinery and Mix semantics for pre-1.0; avoids misleading `~> 0.3`; defers C/D).

**Notes:** Compared to Phoenix/Ecto README norms (post-1.0 two-segment), Pay/Cashier/Stripe doc drift lessons; recommendation aligns with “billing state, modeled clearly” and honest dual-track docs.

---

## 2 — Sigra vs `Accrue.Auth` across First Hour / host README / quickstart

| Approach | Description | Selected |
|----------|-------------|----------|
| A | Host README SSOT for demo Sigra; First Hour = one trust paragraph + links; quickstart ≤ one line → `auth_adapters.md` | ✓ (primary) |
| B | `auth_adapters.md` only; spine files are links | (partial — contract depth lives there) |
| C | Duplicate blockquote on all surfaces | |
| D | Per-capsule-only disclaimers | ✓ (light, combined with A) |

**User's choice:** **A + slice of D** — host README authoritative for demo mechanics; First Hour trust boundary + capsule routing; quickstart stays thin.

**Notes:** Rails dummy / Jumpstart patterns (demo stack replaceable); avoid banner fatigue and D-02 drift from triple duplication.

---

## 3 — Verifier scope for golden-path doc PRs

| Policy | Description | Selected |
|--------|-------------|----------|
| Branch protection as truth | Full CI including `host-integration` remains merge bar | ✓ |
| Local bash trio preflight | `verify_package_docs` && `verify_verify01_readme_contract` && `verify_adoption_proof_matrix` before PR | ✓ |
| Extend `verify_package_docs` to `quickstart.md` | Close INT-06 gap (script did not grep quickstart at discussion time) | ✓ |
| Path-filtered docs-only CI | Deferred unless queue pain + fallback | |

**User's choice:** **Honest merge story** + **ordered local preflight** + **extend package docs verifier for quickstart**.

**Notes:** Repo fact checked: **`verify_package_docs.sh`** had no `quickstart` matches when researched; **D-12** in CONTEXT closes that.

---

## 4 — Capsule H/M/R and spine ordering coherence

| Strategy | Description | Selected |
|----------|-------------|----------|
| A | Same-PR paired edits + reviewer checklist (D-02) | ✓ |
| B | Lightweight structural verifier (headings + spine tokens) | ✓ |
| C | YAML/codegen SSOT | (defer until pain) |
| D | Spine only in First Hour; host README thin links | (rejected — conflicts Phase 51 mirror) |

**User's choice:** **A + B**; **not C** until recurring drift; **not D**.

**Notes:** Diátaxis (one tutorial spine), Stripe-style linear happy path vs dual front doors, Google dev doc style for numbered sequences.

---

## Claude's discretion

- Final prose for trust paragraph and verifier token lists (**59-CONTEXT.md** § Claude's discretion).

## Deferred ideas

- YAML/codegen doc pipeline; CI path filters for docs-only PRs; relaxed two-segment pins pre-1.0 — see **`<deferred>`** in **`59-CONTEXT.md`**.
