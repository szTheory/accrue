# scripts/ci — contributor map

## Phase 226 CI evidence: read this first

Phase 226 keeps one durable baseline and two small, privacy-safe runtime records. Read every incident in this order: **fact**, **literal state**, **owner**, **next command**, then the linked evidence artifact or log. A green job conclusion is a raw fact; it is not provider proof by itself.

| Evidence | What it answers | Command |
| --- | --- | --- |
| [CI baseline](../../.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md) and [NDJSON record](../../.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson) | Which fixed workflow cohort was measured, where time went, and which critical-path claim is comparable | `node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository acme/accrue` |
| `live-stripe-proof` Actions artifact | Whether the selected Stripe test-mode suite produced proof for its own SHA | `node scripts/ci/verify_provider_proof.mjs --fixtures` |
| `accrue-host-ci-setup-facts` Actions artifact | Whether the host or CI owns the setup failure and the narrow repair command | `bash scripts/ci/verify_ci_setup_diagnostics.sh` |

Run the complete contract before changing any of these surfaces:

```bash
node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository acme/accrue && \
node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --expected-repository szTheory/accrue && \
node scripts/ci/verify_provider_proof.mjs --fixtures && \
bash scripts/ci/verify_ci_setup_diagnostics.sh && \
bash scripts/ci/verify_phase225_required_lane_evidence.sh
```

Provider triage is literal: `proved` means the selected suite executed, selected tests, passed, and wrote its manifest. `misconfigured` means configuration, fixtures, or selection was absent; `failed` means selected assertions failed; `blocked` means the runner or upstream could not complete; `skipped` is an intentional bypass with a reason; `non_run` means a PR or push has no provider proof for that SHA. Start a local repair with `cd accrue && mix test.live`. Setup codes and their owners are listed in the [host setup matrix](../../examples/accrue_host/README.md#phase-226-setup-ownership).

## Phase 227 bounded critical-path measurement

Phase 227 has one authorized candidate graph: `host-integration` needs only
`docs-contracts-shift-left`. Its exact inverse restores
`needs: [admin-drift-docs, docs-contracts-shift-left]`. Before a measurement,
prove the restored graph locally, then restore only that candidate edge and run:

```bash
node scripts/ci/verify_ci_critical_path.mjs --fixtures --require-preflight \
  --workflow .github/workflows/ci.yml \
  --contract .planning/phases/227-measured-critical-path-improvement/227-ci-contract.json
```

The CI workflow's required Boolean `run_live_stripe` input defaults to `true`.
Only the three recorded candidate dispatches use `false`; that value makes the
provider lane `non_run`, not provider proof. Dispatch only the immutable
candidate SHA recorded in the Phase 227 evidence:

```bash
gh workflow run ci.yml --repo szTheory/accrue --ref CANDIDATE_SHA -f run_live_stripe=false
```

Do not use a rerun, a replacement cohort, a pull request, or a mutable ref as a
timing sample. If any predicate fails, apply the exact inverse, push its
immutable restored SHA, and use the recorded terminal command with
`run_live_stripe=true` for the one permitted restoration proof.

The Phase 227 proof vector requires the success-path
`accrue-host-phase15-screenshots` artifact. `accrue-host-ci-setup-facts` remains
in the artifact inventory as a failure diagnostic; it must not be required
alongside a successful `host-integration` job. The append-only correction and
candidate reclassifications are recorded in `227-CI-CRITICAL-PATH.ndjson`.

Verify the current terminal rollback decision locally. The restoration-run
budget is exhausted, so the verified-only command remains a deliberate negative
assertion rather than authorization for another dispatch:

```bash
node scripts/ci/verify_ci_critical_path.mjs --require-final-decision \
  --evidence .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson \
  --expected-repository szTheory/accrue

node scripts/ci/verify_ci_critical_path.mjs --require-rollback-verified \
  --verify-live-actions \
  --evidence .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson \
  --expected-repository szTheory/accrue
```

The first command validates the immutable failed restoration vector as well as
the rollback label. The second command intentionally fails while the latest
rollback record is `rollback_applied_unverified`; unsupported `--require-*`
flags also fail closed.

This directory hosts merge-adjacent bash gates and host-app checks. Use it as the first stop when CI fails on documentation or VERIFY-01 contracts.

### Triage: Phase 225 required-lane incidents

- **Release webhook test-isolation signal:** run `cd accrue && mix test test/accrue/webhook/ingest_test.exs --warnings-as-errors`. The responsible source is `accrue/test/accrue/webhook/ingest_test.exs`; it must assert facts owned by its created webhook event rather than suite-global tables.
- **Admin page-flow budget signal:** run `bash scripts/ci/verify_phase192_admin_guardrails.sh`. The responsible source is `accrue_admin/e2e/admin-page-flow-phase191.spec.js`; it owns the bounded browser traversal, not CI retries or topology.

For classification, immutable Actions evidence links, current proof status, and the required/advisory distinction, see [Phase 225's causal index](../../.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md). Keep raw logs, reports, traces, screenshots, and payloads in Actions artifacts.

## v1.59 first-adopter release contract

Run one coordinated, credential-free release-contract check from the repository
root:

```bash
bash scripts/ci/verify_release_contract.sh
```

`docs-contracts-shift-left` owns this merge-blocking command. It first invokes
`verify_reference_scenario_contract.sh`, which owns the versioned fixture and
generated capability matrix, then checks the hand-authored adoption recipe,
App Review and privacy guide, scenario/runbook inventory, release notes, and
watchlist responsibilities. Do not copy generated support cells into a guide:
update the fixture and regenerate the matrix for exact facts; update guides and
runbooks only for explanation or procedure.

When it fails, fix the artifact named in the failure: the fixture or generated
matrix for exact-fact drift; the guide for public wording or App Review/privacy
content; `operator-runbooks.md` for a missing incident procedure or job/next
action copy; and `v1.59-WATCHLIST.md` for owner/reassessment drift. Keep the
fixture, generated matrix, linked scenario IDs, release guide, runbooks, notes,
and watchlist together in the same review whenever the v1.59 public contract
changes.

**After a push:** from the repo root, **`bash scripts/ci/watch_ci.sh`** waits on the latest GitHub Actions **CI** run for **`main`** (optional branch argument). Requires the **`gh`** CLI and auth (`gh auth login`).

## Executable acceptance ratchet (Phase 218+)

`verify_executable_uat_contract.mjs` remains available for phase-scoped acceptance checks. The former project-wide historical scan is parked with the archived v1.59 phase tree; it should be re-enabled only when a new milestone explicitly adopts the executable-UAT contract.

Generate or refresh a phase artifact after its executable checks and verifier pass:

```bash
node scripts/ci/verify_executable_uat_contract.mjs --phase 218 --write
```

Use `--all-since 218` to reproduce CI. Live provider checks are added as scheduled automation only when credentials exist and upstream-drift coverage has recurring value; they do not create manual UAT.

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

### Support-contract mirror parity (Phase 119)

When a PR edits support wording for checkout, billing portal, Stripe, or
Braintree in any of:

- **`.planning/processor-support-matrix.md`** as the support SSOT,
- **`accrue/README.md`** or **`accrue/guides/first_hour.md`** as package-facing mirrors,
- **`examples/accrue_host/README.md`** or **`examples/accrue_host/docs/adoption-proof-matrix.md`** as proof/reference mirrors,

then update the same provider-honest wording in the **same PR** for:

- **`scripts/ci/verify_processor_support_matrix.sh`** when the SSOT literals move,
- **`scripts/ci/verify_package_docs.sh`** when package-doc or host README needles move,
- **`scripts/ci/verify_verify01_readme_contract.sh`** when host README proof wording changes,
- **`scripts/ci/verify_adoption_proof_matrix.sh`** when matrix wording changes.

Run the full support-contract bundle from the repo root before merging:

```bash
bash scripts/ci/verify_processor_support_matrix.sh && \
  bash scripts/ci/verify_package_docs.sh && \
  bash scripts/ci/verify_verify01_readme_contract.sh && \
  bash scripts/ci/verify_adoption_proof_matrix.sh
```

This rule exists so stale Stripe-only checkout or billing-portal wording
cannot drift back into package docs, host proof docs, or shift-left gates. For
Phase 119, the same-PR rule also applies to the official active-subscription-change
contract: `swap_plan/3` plus `preview_upcoming_invoice/2`, preview-before-commit
wording, `bounded first-party` / `testing/local-only` / `unsupported` labels,
and the explicit Braintree no-preview boundary.

### Support-contract bundle (Phase 119 closeout)

`docs-contracts-shift-left` is the merge-blocking CI home for the named
**support-contract bundle**. It pins the canonical support matrix plus the thin
mirrors for checkout, portal, and the promoted swap/preview contract. The exact
bundle membership is:

- `bash scripts/ci/verify_processor_support_matrix.sh` — canonical support SSOT in `.planning/processor-support-matrix.md`
- `bash scripts/ci/verify_package_docs.sh` — package-facing mirrors in `accrue/README.md`, `accrue/guides/first_hour.md`, `accrue/guides/testing.md`, and `guides/testing-live-stripe.md`
- `bash scripts/ci/verify_verify01_readme_contract.sh` — thin host README proof wording in `examples/accrue_host/README.md`
- `bash scripts/ci/verify_adoption_proof_matrix.sh` — thin host proof taxonomy in `examples/accrue_host/docs/adoption-proof-matrix.md`
- `bash scripts/ci/verify_stable_core_posture.sh` — stable-core posture alignment across public docs and planning mirrors

Run the full bundle from the repo root when you touch support wording:

```bash
bash scripts/ci/verify_processor_support_matrix.sh && \
  bash scripts/ci/verify_package_docs.sh && \
  bash scripts/ci/verify_verify01_readme_contract.sh && \
  bash scripts/ci/verify_adoption_proof_matrix.sh && \
  bash scripts/ci/verify_stable_core_posture.sh
```

Surface-to-script map:

- If you edit `.planning/processor-support-matrix.md`, expect `verify_processor_support_matrix.sh` and job `docs-contracts-shift-left` to fail first.
- If you edit `accrue/README.md`, `accrue/guides/first_hour.md`, `accrue/guides/testing.md`, or `guides/testing-live-stripe.md`, expect `verify_package_docs.sh`.
- If you edit `examples/accrue_host/README.md`, expect `verify_verify01_readme_contract.sh` plus `verify_package_docs.sh` for shared structural pins.
- If you edit `examples/accrue_host/docs/adoption-proof-matrix.md`, expect `verify_adoption_proof_matrix.sh`.

### Local required-lane preflight

Before pushing a release-sensitive repair, run:

```bash
bash scripts/ci/verify_release_preflight.sh
```

It runs the deterministic docs-contract bundle plus local format, compile,
tests, Credo, Dialyzer, and ExDoc checks for `accrue` and `accrue_admin`, and
format, compile, and test checks for `accrue_portal`.
It does not replace GitHub's clean-host matrix, service-container, browser, or
artifact proof, so a fresh Actions run remains required for release evidence.

## PRS gates (v1.22 production path discoverability)

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| PRS-01..03 | `scripts/ci/verify_production_readiness_discoverability.sh`; root **`README.md`**; **`accrue/README.md`**; **`accrue/guides/production-readiness.md`** §1–§10 headings | — (bash-only contract; runs in **`docs-contracts-shift-left`**) | `.planning/REQUIREMENTS.md` (**PRS-01..03**); **`.planning/ROADMAP.md`** Phase **74** |

**Co-update rule:** intentional edits to **`accrue/guides/production-readiness.md`** section titles **`### 1.`**–**`### 10.`**, or to the canonical link targets checked by the script, ship in the **same PR** as **`verify_production_readiness_discoverability.sh`** and any **root / `accrue` README** link text required to stay discoverable.

### Triage: verify_production_readiness_discoverability.sh

- **`verify_production_readiness_discoverability:`** (stderr prefix on failure) — treat as **PRS-01..03**: missing root or package README links to **`production-readiness.md`**, or missing **`### 1.`**–**`### 10.`** / intro heading in the guide. Fix docs first; only relax needles after an intentional checklist renumbering milestone.

### Triage: verify_v1_17_friction_research_contract.sh

- **`verify_v1_17_friction_research_contract:`** (stderr prefix on failure) — treat as **INT-10 / FRG-01..03** planning SSOT: inventory table shape (**five** rows: two **P0**, two **P1**, one **P2**; two P0 with **INT-10** + **→63**), backlog anchors (**INT-10** / **BIL-03** / **ADM-12**), no **`*(example)*`**, no ambiguous **`v1.17-P0-`** substring, **STATE**/**PROJECT** links, **S1**/**S5** rows in north star, **ROADMAP** FRG-03 slice links, plus **UAT-04** binary gate that **`.planning/milestones/v1.17-REQUIREMENTS.md`** exists (historical v1.17 requirements archive). Fix **`.planning/research/*.md`** first; only relax needles after an intentional milestone edit.

### Triage: verify_release_notes_contract.sh

- **`verify_release_notes_contract:`** (stderr prefix on failure) — treat as the plain-language release-notes freshness gate for `accrue/guides/release-notes.md`.
- The script requires the current lockstep package version from `accrue/mix.exs`, `accrue_admin/mix.exs`, and `accrue_portal/mix.exs` to appear in release-notes headings for both `accrue` and `accrue_admin`.
- If this fails during a release, update `accrue/guides/release-notes.md` in the same PR as the version bump so HexDocs does not stall on an older story while changelogs and package versions advance.

### Triage: verify_stable_core_posture.sh

- **`verify_stable_core_posture:`** (stderr prefix on failure) is the dedicated stable-core posture gate for POS-01..03.
- Expected anchor categories:
  - canonical posture surfaces (`README.md`, `accrue/README.md`, `maturity-and-maintenance.md`, `jobs_to_be_done.md`, `release-notes.md`),
  - maintainer mirrors (`.planning/PROJECT.md`, active `.planning/REQUIREMENTS.md` when present, otherwise the current archived milestone requirements from `.planning/STATE.md`, `.planning/processor-support-matrix.md`, adoption-proof matrix),
  - thin package/proof mirrors (`first_hour.md`, `accrue_admin/README.md`, `accrue_portal/README.md`, `examples/accrue_host/README.md`).
- Negative guards block retired public posture terms: `feature freeze`, `no new features ever`, and `maintenance only`.
- If this gate fails, update canonical public guides first and keep package/proof mirrors thin. Do not create a second support matrix or move policy authority away from public guides.

## BAK/PAU gates (v1.48 backlog anchor closure + pause rule)

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| BAK-01 | `scripts/ci/verify_roadmap_hygiene.sh`; `.planning/ROADMAP.md` historical anchors and deferred ledger | — | `.planning/phases/161-backlog-anchor-closure-pause-rule/161-01-SUMMARY.md` |
| BAK-02 | `scripts/ci/verify_roadmap_hygiene.sh`; `.planning/ROADMAP.md`; `.planning/STATE.md` | — | `.planning/phases/161-backlog-anchor-closure-pause-rule/161-01-SUMMARY.md` |
| PAU-01 | `scripts/ci/verify_roadmap_hygiene.sh`; `.planning/PROJECT.md`; `.planning/ROADMAP.md`; `.planning/STATE.md` | — | `.planning/phases/161-backlog-anchor-closure-pause-rule/161-01-SUMMARY.md` |

### Triage: verify_roadmap_hygiene.sh

- **`verify_roadmap_hygiene:`** (stderr prefix on failure) is the dedicated roadmap hygiene gate for BAK-01, BAK-02, and PAU-01.
- Expected governed surfaces: `.planning/PROJECT.md` owns the canonical pause rule, `.planning/ROADMAP.md` owns the historical-anchor and dormant/deferred ledger, and `.planning/STATE.md` mirrors session-continuity deferred rows.
- Fix failures in the canonical surface first, then update mirrors. Do not loosen verifier needles unless an intentional planning-doctrine change moves the source of truth.

### Triage: verify_adoption_proof_matrix.sh

- **`verify_adoption_proof_matrix:`** (stderr prefix on failure) — treat as **ORG-09**: missing ORG-09 headings, primary/recipe lane markers, `phx.gen.auth` / `use Accrue.Billable` / `non-Sigra` literals, **ORG-05** / **ORG-06** / **ORG-07** / **ORG-08** rows, Layer C script names (including **`verify_core_admin_invoice_verify_ids.sh`**), or the self-referential script path in `adoption-proof-matrix.md`. Fix the matrix doc first; only change needles in the script after an intentional taxonomy edit.
- **SSOT:** the adoption proof matrix lives at **`examples/accrue_host/docs/adoption-proof-matrix.md`** — click-through from here: [**adoption-proof-matrix.md**](../../examples/accrue_host/docs/adoption-proof-matrix.md).
- **CI job:** this gate runs under GitHub Actions job id **`docs-contracts-shift-left`** (see `.github/workflows/ci.yml`).
- **Co-update rule:** any intentional change to adoption-proof matrix taxonomy, archetype labels, or row-level text that affects verifier needles **must** ship in the **same PR / commit** as edits to **`scripts/ci/verify_adoption_proof_matrix.sh`** and to **any ExUnit file that embeds matrix literals** — today that thin harness is **`accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs`** (shell-out only; it does not duplicate bash needles). **`verify_adoption_proof_matrix.sh`** remains the **canonical substring list** for this contract.

### Triage: verify_docker_dx_contract.sh

- **`verify_docker_dx_contract:`** (stderr prefix on failure) — treat as the `examples/accrue_host` Docker DX contract: stable `http://accrue.localhost/admin`, shared Traefik `dev_proxy`, external `proxy` network, DNS-safe `INSTANCE`, loopback-only ephemeral fallback ports, no default DB host port, native Apple Silicon boot, path-dep volume shadows, and warm-cache asset markers.
- Fix the canonical surfaces first: `examples/accrue_host/Makefile`, `docker-compose.yml`, `docker-compose.override.yml.example`, `bin/dev-entrypoint.sh`, `bin/dev-banner.sh`, `README.md`, and `docs/docker-dx.md`. Only relax verifier needles when the Docker contract intentionally changes.
- The script renders Compose config for the default instance and `INSTANCE=accrue-foo`; it does not start containers. Live Docker route/boot proof still belongs in host UAT or a local smoke note.

### Triage: host-integration / `accrue_host_uat.sh`

Failures on **`host-integration`** start from **`bash scripts/ci/accrue_host_uat.sh`**, which runs **`mix verify.full`** inside **`examples/accrue_host`**.

- **`[host-integration] phase=bounded_mix_tests`** — bounded ExUnit slice (`mix verify`-style subset).
- **`[host-integration] phase=full_mix_tests`** — full **`mix test`** for the host app.
- **`[host-integration] phase=dev_boot_smoke`** — bounded **`mix phx.server`** boot check.
- **`[host-integration] phase=browser_playwright`** — headless Playwright gate.

Normative VERIFY-01 detail lives in the host README: [**Proof and verification**](../../examples/accrue_host/README.md#proof-and-verification).

## When package docs verification fails

Stderr lines from `verify_package_docs.sh` are prefixed with `[verify_package_docs]` so log scrapers and humans can tell this gate apart from other scripts. Use the triage bullets below to map the failing file or substring back to the ADOPT row before editing unrelated docs.

### Triage: verify_package_docs.sh

- `ADOPT-01` — failures mentioning root `README.md`, `## Proof path (VERIFY-01)`, `proof-and-verification`, or PR merge-blocking / `host-integration` wording in the root README pair.
- `ADOPT-02` — failures on `examples/accrue_host/README.md` sections (`## Proof and verification`, `### Verification modes`, VERIFY-01 markers); also run `bash scripts/ci/verify_verify01_readme_contract.sh` because VERIFY-01 depth is split across that script.
- `ADOPT-03` — failures on `accrue/guides/testing.md`, `accrue/guides/first_hour.md`, or `guides/testing-live-stripe.md` missing the merge-blocking one-liner / advisory lane text enforced by `require_fixed`.
- `ADOPT-04` — failures on `accrue/guides/first_hour.md` missing `upgrade.md#installer-rerun-behavior` or First Hour structure pins.
- `ADOPT-05` — failures on `accrue/guides/troubleshooting.md` (`mix accrue.install --check`), RELEASING/provider-parity phrasing, or other `require_fixed` clusters added in Phase 33.
- `ADOPT-06` — failures involving `.github/workflows/ci.yml` (not directly read here but referenced by docs), `CONTRIBUTING.md` UAT wording, or `guides/testing-live-stripe.md` / `RELEASING.md` keys such as `STRIPE_TEST_SECRET_KEY` / `release-gate` / `retain-on-failure`.

## REL gates (v1.48 linked release readiness + publish proof)

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| REL-01 | `scripts/ci/verify_release_pr_scope.sh`; `scripts/ci/verify_release_manifest_alignment.sh`; `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` (`PR_NUMBER`, `TARGET_VERSION`) | — | `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` |
| REL-02 | `scripts/ci/verify_release_manifest_alignment.sh`; deterministic CI bundle evidence rows in `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` | — | `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` |
| REL-03 | `scripts/ci/capture_linked_release_proof.sh`; `scripts/ci/accrue_host_hex_smoke.sh`; `.github/workflows/release-please.yml`; `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` (`RUN_ID`) | — | `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` |

## POS gates (v1.48 stable-core public positioning)

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| POS-01 | `scripts/ci/verify_stable_core_posture.sh`; root `README.md`; `accrue/README.md`; `accrue/guides/maturity-and-maintenance.md`; `accrue/guides/jobs_to_be_done.md` | — | `.planning/phases/160-stable-core-public-positioning/160-03-SUMMARY.md` |
| POS-02 | `scripts/ci/verify_stable_core_posture.sh`; `accrue/guides/first_hour.md`; `accrue_admin/README.md`; `accrue_portal/README.md`; `examples/accrue_host/README.md` | — | `.planning/phases/160-stable-core-public-positioning/160-03-SUMMARY.md` |
| POS-03 | `scripts/ci/verify_stable_core_posture.sh`; `scripts/ci/verify_release_notes_contract.sh`; `accrue/guides/release-notes.md`; `.planning/processor-support-matrix.md`; `examples/accrue_host/docs/adoption-proof-matrix.md` | — | `.planning/phases/160-stable-core-public-positioning/160-03-SUMMARY.md` |

### Triage: verify_release_pr_scope.sh

- `verify_release_pr_scope:` failures mean the live Release Please PR does not satisfy the locked three-package contract. The PR must update `.release-please-manifest.json`, all three package `mix.exs` files, and all three package `CHANGELOG.md` files before merge.
- Use `bash scripts/ci/verify_release_pr_scope.sh --pr <number-or-url> [--version <x.y.z>]` before merge. A passing result is the REL-01 pre-merge gate.
- Record the passing identifier pair in `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` as `PR_NUMBER:` and `TARGET_VERSION:` and stop using “latest release PR” shortcuts after that.
- If the Release Please branch is stale relative to `main`, force-sync `release-please--branches--main` back to `main`, rerun Release Please, and only then apply the portal repair on the regenerated branch.
- If Release Please leaves `accrue_portal` behind while `accrue` and `accrue_admin` advance together, run `bash scripts/ci/repair_linked_release_pr.sh --version <x.y.z>` on the checked-out release branch and push the repaired branch before merge.

### Triage: capture_linked_release_proof.sh

- `capture_linked_release_proof:` failures mean the shipped linked release is not publicly proven yet. The script requires one exact PR number, one exact `TARGET_VERSION`, and one exact Release Please `RUN_ID`.
- Use `bash scripts/ci/capture_linked_release_proof.sh --version <x.y.z> --run-id <id> --pr <number-or-url> --output .planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` after merge and after the Release Please workflow finishes.
- The ledger is append-only: the script records workflow ordering, git tags, GitHub release URLs, and Hex API truth for `accrue`, `accrue_admin`, and `accrue_portal`.
- The current proof chain is `verify_release_manifest_alignment.sh` -> `capture_linked_release_proof.sh` -> `accrue_host_hex_smoke.sh`, with all outcomes recorded in the Phase 159 ledger.
- If partial publish or post-publish verification fails, do not immediately retry, revert, or retire. Instead, use the structured recovery append path to record the failure in `159-VERIFICATION.md` before taking corrective action. See `.planning/phases/162-close-gap-rel-01-rel-03-linked-release-proof/162-VERIFICATION.md` for a non-authoritative index of this recovery flow.
