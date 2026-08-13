---
phase: 227
slug: measured-critical-path-improvement
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-12
---

# Phase 227 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js built-in assertions plus shell workflow contracts |
| **Config file** | none — repository CI verifiers are dependency-free executables |
| **Quick run command** | `node scripts/ci/verify_ci_critical_path.mjs --fixtures` |
| **Full suite command** | `node --check scripts/ci/verify_ci_critical_path.mjs && node scripts/ci/verify_ci_critical_path.mjs --fixtures && node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository acme/accrue && node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path --expected-repository szTheory/accrue && node scripts/ci/verify_provider_proof.mjs --fixtures && bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh` |
| **Estimated runtime** | ~60 seconds locally, excluding recorded GitHub Actions runs |

---

## Sampling Rate

- **After every task commit:** Run `node scripts/ci/verify_ci_critical_path.mjs --fixtures`
- **After every plan wave:** Run the full suite command above
- **Before `$gsd-verify-work`:** Full suite, three qualifying first-attempt post-change runs, controlled negative control, and rollback-result record must be green
- **Max feedback latency:** 60 seconds for local verification; live Actions evidence is an explicit recorded checkpoint

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 227-01-01 | 01 | 1 | PATH-01, SAFE-01 | T-227-01 | Fail closed on graph and stable external-contract drift | static + fixture | `node scripts/ci/verify_ci_critical_path.mjs --fixtures` | ❌ W0 | ⬜ pending |
| 227-01-02 | 01 | 1 | PATH-02, SAFE-02 | T-227-02 | Preserve independent lanes, aggregate failure, artifacts, and inverse-patch rollback | static + negative control | `node scripts/ci/verify_ci_critical_path.mjs --fixtures` | ❌ W0 | ⬜ pending |
| 227-02-01 | 02 | 2 | PATH-01, PATH-02 | T-227-03 | Accept only comparable first-attempt evidence meeting the locked timing threshold | evidence contract | `node scripts/ci/verify_ci_critical_path.mjs --evidence .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson` | ❌ W0 | ⬜ pending |
| 227-03-01 | 03 | 3 | SAFE-01, SAFE-02 | T-227-01 / T-227-02 | Retain or roll back from recorded proof without weakening checks or hiding failures | full regression + recorded live evidence | Full suite command plus immutable Actions links recorded in the evidence pack | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/ci/verify_ci_critical_path.mjs` — exact graph, contract-manifest, comparison, negative-control, and rollback verifier
- [ ] `.planning/phases/227-measured-critical-path-improvement/227-ci-contract.json` — stable required job, label, artifact, upload-condition, and retention manifest
- [ ] `.planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson` — sanitized immutable comparison observations
- [ ] `.planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md` — concise maintainer-facing before/after and rollback report
- [ ] Controlled failure fixture/procedure and recorded immutable Actions result

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Three successful first-attempt same-event-class runs meet the keep gate | PATH-01, PATH-02 | Requires GitHub Actions execution authority and immutable run links | Trigger or identify three independent compatible runs; record every observation; verify median ≤1,666s and no observation >2,602s without a substantiated external anomaly |
| Controlled failure preserves host/browser completion and artifacts while `annotation-sweep` fails | SAFE-01, SAFE-02 | Requires a real Actions failure-propagation observation | Run the documented controlled failure; record job conclusions and artifact links; execute the local verifier against the sanitized record |
| Exact inverse patch restores the prior graph and evidence contract | SAFE-02 | Requires applying and proving the rollback path without leaving a feature switch | Apply the inverse dependency patch, rerun static/negative controls, and record a fresh successful first-attempt restoration run |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s for local checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
