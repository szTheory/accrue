# scripts/ci — contributor map

This directory hosts merge-adjacent bash gates and host-app checks. Use it as the first stop when CI fails on documentation or VERIFY-01 contracts.

**After a push:** from the repo root, **`bash scripts/ci/watch_ci.sh`** waits on the latest GitHub Actions **CI** run for **`main`** (optional branch argument). Requires the **`gh`** CLI and auth (`gh auth login`).

## ADOPT gates (v1.7 adoption milestone)

Evidence for **ADOPT-01..06** is summarized in **`.planning/milestones/v1.7-ROADMAP.md`** / **`.planning/milestones/v1.7-REQUIREMENTS.md`** (milestone archives). Granular phase **`*-VERIFICATION.md`** ledgers for phases **32–36** live in **git history** (trees under `.planning/phases/` were pruned after **`phases.clear`** on **2026-04-23**).

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| ADOPT-01 | `scripts/ci/verify_package_docs.sh` (root `README.md` proof path + merge-blocking labels); root `README.md` | `accrue/test/accrue/docs/package_docs_verifier_test.exs` (invokes verifier end-to-end) | `.planning/milestones/v1.7-ROADMAP.md` (Phases **32–33**) |
| ADOPT-02 | `scripts/ci/verify_verify01_readme_contract.sh`; `examples/accrue_host/README.md` (VERIFY-01 / Playwright / host-integration prose) | — (bash-only contract; runs in **`docs-contracts-shift-left`** CI job) | `.planning/milestones/v1.7-ROADMAP.md` |
| ADOPT-03 | `verify_package_docs.sh` pins on `accrue/guides/testing.md`, `accrue/guides/first_hour.md`, `guides/testing-live-stripe.md` | `package_docs_verifier_test.exs` | `.planning/milestones/v1.7-ROADMAP.md` |
| ADOPT-04 | `accrue/guides/first_hour.md` §4 + `upgrade.md#installer-rerun-behavior` anchor | `accrue/test/accrue/docs/first_hour_guide_test.exs` | `.planning/milestones/v1.7-ROADMAP.md` |
| ADOPT-05 | `verify_package_docs.sh` `require_fixed` / `require_regex` pins (First Hour, troubleshooting, host README, package READMEs) | `package_docs_verifier_test.exs` (fixture drift regressions) | `.planning/milestones/v1.7-ROADMAP.md` |
| ADOPT-06 | `.github/workflows/ci.yml` stable job-id header comments; `README.md` + `guides/testing-live-stripe.md` lane wording | `package_docs_verifier_test.exs` (workflow/contributor drift cases) | `.planning/milestones/v1.7-ROADMAP.md` |

## ORG gates (v1.8 org billing proof)

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| ORG-09 | `scripts/ci/verify_adoption_proof_matrix.sh`; `examples/accrue_host/docs/adoption-proof-matrix.md` | `accrue/test/accrue/docs/organization_billing_guide_test.exs`; `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs` | `.planning/milestones/v1.8-ROADMAP.md` (Phase **39**) |

## INT gates (v1.16 integrator + proof continuity)

This table is **delta-maintained** for merge-blocking checks **touched by phases 59–61** on this milestone branch. The **normative** required-job set for every pull request remains **`.github/workflows/ci.yml`** plus **branch protection** — treat those as completeness SSOT, not this markdown registry alone.

Granular **`*-VERIFICATION.md`** for phases **59–61** live in **git history** (pruned from `.planning/phases/`); milestone narrative and requirements closure: **`.planning/milestones/v1.16-ROADMAP.md`**, **`.planning/milestones/v1.16-REQUIREMENTS.md`**.

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| INT-06 | `accrue/guides/first_hour.md`; `examples/accrue_host/README.md`; `accrue/guides/quickstart.md`; `CONTRIBUTING.md` — scripts `verify_package_docs.sh`, `verify_v1_17_friction_research_contract.sh`, `verify_verify01_readme_contract.sh`, `verify_production_readiness_discoverability.sh`, `verify_adoption_proof_matrix.sh` | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | `.planning/milestones/v1.16-ROADMAP.md` (Phase **59**) |
| INT-07 | `examples/accrue_host/docs/adoption-proof-matrix.md`; `examples/accrue_host/docs/evaluator-walkthrough-script.md` — scripts `verify_adoption_proof_matrix.sh` (add `verify_package_docs.sh` only when pins touch matrix paths) | `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs` when ORG-09 matrix literals change; else **—** | `.planning/milestones/v1.16-ROADMAP.md` (Phase **60**) |
| INT-08 | Root `README.md` merge-blocking proof path + cross-package pins — `verify_package_docs.sh`; VERIFY-01 host README depth — `verify_verify01_readme_contract.sh` | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | `.planning/milestones/v1.16-ROADMAP.md` (Phase **61**) |
| INT-09 | Workspace **`@version`** vs **public Hex** honesty — `verify_package_docs.sh` enforces **`first_hour`**, **`accrue/README.md`**, **`accrue_admin/README.md`** pins; **`.planning/PROJECT.md`** / **`.planning/MILESTONES.md`** are **manual** mirrors (edit alongside intentional SemVer / milestone copy changes) | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | `.planning/milestones/v1.16-ROADMAP.md` (Phase **61**) |
| INT-10 (planning SSOT) | `scripts/ci/verify_v1_17_friction_research_contract.sh` — **`.planning/research/v1.17-FRICTION-INVENTORY.md`**, **`v1.17-north-star.md`**, **`STATE.md` / `PROJECT.md` / `ROADMAP.md`** pointer anchors | `accrue/test/accrue/docs/v1_17_friction_research_contract_test.exs` | `.planning/milestones/v1.17-phases/62-friction-triage-north-star/62-VALIDATION.md` |
| INT-11 (v1.21 capsule parity) | Same-PR discipline for **First Hour** ↔ **host README** proof spine — see subsection **First Hour + host README capsule parity** below | — | `.planning/REQUIREMENTS.md` (**INT-11**); inventory row **`v1.17-P2-001`** |

### First Hour + host README capsule parity (**INT-11**)

When a PR edits **any** of:

- **`accrue/guides/first_hour.md`** — especially **§ How to enter this guide** (capsules **H** / **M** / **R**) or the ordered story that must stay aligned with the host demo, or
- **`examples/accrue_host/README.md`** — especially [**#proof-and-verification**](../../examples/accrue_host/README.md#proof-and-verification) and the numbered Fake-backed arc,

then **in the same PR** (unless it is a pure typo with zero semantic change):

1. Re-read the other file’s matching capsule / proof section and align command vocabulary, cross-links, and “Hex vs `main`” framing.
2. Run **`bash scripts/ci/verify_package_docs.sh`** when First Hour or package README pins move; run **`bash scripts/ci/verify_verify01_readme_contract.sh`** when host README VERIFY-01 depth changes.
3. If you intentionally change only one side, add a short PR note explaining why the other file does **not** need an edit (rare — reviewers should push back).

This checklist closes **`v1.17-P2-001`**-class drift risk (**P2** → **closed** in **`.planning/research/v1.17-FRICTION-INVENTORY.md`** with **v1.21** evidence).

## PRS gates (v1.22 production path discoverability)

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| PRS-01..03 | `scripts/ci/verify_production_readiness_discoverability.sh`; root **`README.md`**; **`accrue/README.md`**; **`accrue/guides/production-readiness.md`** §1–§10 headings | — (bash-only contract; runs in **`docs-contracts-shift-left`**) | `.planning/REQUIREMENTS.md` (**PRS-01..03**); **`.planning/ROADMAP.md`** Phase **74** |

**Co-update rule:** intentional edits to **`accrue/guides/production-readiness.md`** section titles **`### 1.`**–**`### 10.`**, or to the canonical link targets checked by the script, ship in the **same PR** as **`verify_production_readiness_discoverability.sh`** and any **root / `accrue` README** link text required to stay discoverable.

### Triage: verify_production_readiness_discoverability.sh

- **`verify_production_readiness_discoverability:`** (stderr prefix on failure) — treat as **PRS-01..03**: missing root or package README links to **`production-readiness.md`**, or missing **`### 1.`**–**`### 10.`** / intro heading in the guide. Fix docs first; only relax needles after an intentional checklist renumbering milestone.

### Triage: verify_v1_17_friction_research_contract.sh

- **`verify_v1_17_friction_research_contract:`** (stderr prefix on failure) — treat as **INT-10 / FRG-01..03** planning SSOT: inventory table shape (four rows, two P0 with **INT-10** + **→63**), backlog anchors (**INT-10** / **BIL-03** / **ADM-12**), no **`*(example)*`**, no ambiguous **`v1.17-P0-`** substring, **STATE**/**PROJECT** links, **S1**/**S5** rows in north star, **ROADMAP** FRG-03 slice links, plus **UAT-04** binary gate that **`.planning/milestones/v1.17-REQUIREMENTS.md`** exists (historical v1.17 requirements archive). Fix **`.planning/research/*.md`** first; only relax needles after an intentional milestone edit.

### Triage: verify_adoption_proof_matrix.sh

- **`verify_adoption_proof_matrix:`** (stderr prefix on failure) — treat as **ORG-09**: missing ORG-09 headings, primary/recipe lane markers, `phx.gen.auth` / `use Accrue.Billable` / `non-Sigra` literals, **ORG-05** / **ORG-06** / **ORG-07** / **ORG-08** rows, Layer C script names (including **`verify_core_admin_invoice_verify_ids.sh`**), or the self-referential script path in `adoption-proof-matrix.md`. Fix the matrix doc first; only change needles in the script after an intentional taxonomy edit.
- **SSOT:** the adoption proof matrix lives at **`examples/accrue_host/docs/adoption-proof-matrix.md`** — click-through from here: [**adoption-proof-matrix.md**](../../examples/accrue_host/docs/adoption-proof-matrix.md).
- **CI job:** this gate runs under GitHub Actions job id **`docs-contracts-shift-left`** (see `.github/workflows/ci.yml`).
- **Co-update rule:** any intentional change to adoption-proof matrix taxonomy, archetype labels, or row-level text that affects verifier needles **must** ship in the **same PR / commit** as edits to **`scripts/ci/verify_adoption_proof_matrix.sh`** and to **any ExUnit file that embeds matrix literals** — today that thin harness is **`accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs`** (shell-out only; it does not duplicate bash needles). **`verify_adoption_proof_matrix.sh`** remains the **canonical substring list** for this contract.

### Triage: host-integration / `accrue_host_uat.sh`

Failures on **`host-integration`** start from **`bash scripts/ci/accrue_host_uat.sh`**, which runs **`mix verify.full`** inside **`examples/accrue_host`**.

- **`[host-integration] phase=bounded_mix_tests`** — bounded ExUnit slice (`mix verify`-style subset).
- **`[host-integration] phase=full_mix_tests`** — full **`mix test`** for the host app.
- **`[host-integration] phase=dev_boot_smoke`** — bounded **`mix phx.server`** boot check.
- **`[host-integration] phase=browser_playwright`** — headless Playwright gate.

Normative VERIFY-01 detail lives in the host README: [**Proof and verification**](examples/accrue_host/README.md#proof-and-verification).

## When package docs verification fails

Stderr lines from `verify_package_docs.sh` are prefixed with `[verify_package_docs]` so log scrapers and humans can tell this gate apart from other scripts. Use the triage bullets below to map the failing file or substring back to the ADOPT row before editing unrelated docs.

### Triage: verify_package_docs.sh

- `ADOPT-01` — failures mentioning root `README.md`, `## Proof path (VERIFY-01)`, `proof-and-verification`, or PR merge-blocking / `host-integration` wording in the root README pair.
- `ADOPT-02` — failures on `examples/accrue_host/README.md` sections (`## Proof and verification`, `### Verification modes`, VERIFY-01 markers); also run `bash scripts/ci/verify_verify01_readme_contract.sh` because VERIFY-01 depth is split across that script.
- `ADOPT-03` — failures on `accrue/guides/testing.md`, `accrue/guides/first_hour.md`, or `guides/testing-live-stripe.md` missing the merge-blocking one-liner / advisory lane text enforced by `require_fixed`.
- `ADOPT-04` — failures on `accrue/guides/first_hour.md` missing `upgrade.md#installer-rerun-behavior` or First Hour structure pins.
- `ADOPT-05` — failures on `accrue/guides/troubleshooting.md` (`mix accrue.install --check`), RELEASING/provider-parity phrasing, or other `require_fixed` clusters added in Phase 33.
- `ADOPT-06` — failures involving `.github/workflows/ci.yml` (not directly read here but referenced by docs), `CONTRIBUTING.md` UAT wording, or `guides/testing-live-stripe.md` / `RELEASING.md` keys such as `STRIPE_TEST_SECRET_KEY` / `release-gate` / `retain-on-failure`.
