# Phase 51 — Technical research

**Question:** What do we need to know to plan **INT-01..INT-03** (golden path, VERIFY discoverability, troubleshooting anchors) well?

### Doc spine precedents (OSS)

- **Single spine + entry paths:** Rails/Pay-style “one happy path” reduces drift; optional **capsules** (Hex consumer vs monorepo clone vs read-only eval) join the same ordered spine instead of maintaining parallel full tutorials (**51-CONTEXT D-01**).
- **Two-layer README:** Product root = intent + routing; **executable** commands and VERIFY detail stay in **one** host README section (`#proof-and-verification`) to avoid contradictory matrices (**51-CONTEXT D-09, D-10**).
- **Stable diagnostic codes:** Stripe-style codes + deep links; Accrue already implements **`ACCRUE-DX-*`** in `Accrue.SetupDiagnostic` and **`accrue/guides/troubleshooting.md`** with `{#kebab-case}` anchors — Phase 51 **aligns prose** rather than inventing new schemes.

### Repo-specific constraints

- **VERIFY-01 contract script:** `scripts/ci/verify_verify01_readme_contract.sh` asserts required substrings and spec paths in **`examples/accrue_host/README.md`** — any edit to the proof section must keep the script green.
- **Command vocabulary:** Retain **`mix verify`** vs **`mix verify.full`**; distinguish **Layer A** (per-package release gate), **Layer B** (host Fake proof), **Layer C** (PR `host-integration` + shift-left scripts + documented conditionals) — avoid implying one Mix task equals full merge contract (**51-CONTEXT D-06**).
- **Installer SSOT:** Rerun/conflict behavior documented in **`accrue/guides/upgrade.md`**; first-hour and host README carry **pointers only** (**51-CONTEXT D-16**).

### Gaps addressed by planning

- **Entry capsules (H/M/R)** are named in **51-CONTEXT** but not yet consistently surfaced at the top of **`first_hour.md`** and **`examples/accrue_host/README.md`**.
- **`CONTRIBUTING.md`** has ADOPT / `scripts/ci/README.md` triage but lacks the short **VERIFY-01 / host proof** bridge (**D-08**).
- **`troubleshooting.md`** intro explains the matrix but does not yet **document the anchor slug convention** once for link maintainers (**D-14**).
- **`webhooks.md`** mentions signature failures but can add a **single** deep link into the **`ACCRUE-DX-WEBHOOK-RAW-BODY`** section per hybrid SSOT (**D-13**).

---

## Validation Architecture

Phase 51 is **documentation-only**; validation is **shift-left scripts + optional host Mix aliases**, not new ExUnit modules.

| Dimension | Approach |
|-----------|----------|
| **Contract gates** | After any change to **root `README.md`** “Proof path” block or **`examples/accrue_host/README.md`** proof / VERIFY-01 section: run `bash scripts/ci/verify_verify01_readme_contract.sh` (extend only if new mandatory substrings are agreed and scripted). |
| **Fast host smoke** | `cd examples/accrue_host && mix verify` — bounded Fake slice; run after substantive doc changes that reference verify composition. |
| **Full maintainer gate** | `cd examples/accrue_host && mix verify.full` — before merge when VERIFY-01 prose, Playwright entry points, or CI-equivalent commands are touched. |
| **Formatting** | Markdown-only; no compiler gate on prose. Optional: `mix format` if any `.ex` / `.exs` touched (e.g. installer output). |

Sampling: run **verify_verify01** after plans **01** and **02** touch README proof surfaces; run **`mix verify`** once after wave 2 if executor touched host README command blocks.

---

## RESEARCH COMPLETE

*Phase 51 — integrator golden path docs*
