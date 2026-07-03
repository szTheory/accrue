---
phase: 204
slug: ranked-hardening-roadmap
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-02
updated: 2026-07-03
---

# Phase 204 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Markdown/content-contract checks with `bash`, `rg`, `awk`, and `git`; no product test framework is required because Phase 204 is roadmap-only. |
| **Config file** | None; the validation target is `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md`. |
| **Quick run command** | `CMD-204-quick` from the command catalog below. |
| **Full suite command** | `CMD-204-full` from the command catalog below. |
| **Estimated runtime** | Less than 10 seconds on the local repository. |

---

## Sampling Rate

- **After Task 1 commit:** Run `CMD-RD-01` and `CMD-RD-03`.
- **After Task 2 commit:** Run `CMD-RD-02`, `CMD-RD-03`, and `CMD-RD-04`.
- **After Task 3 commit:** Run `CMD-BOUNDARY` and `CMD-204-full`.
- **After every plan wave:** Run `CMD-204-full`.
- **Before `/gsd:verify-work`:** `CMD-204-full` must be green and the executor summary must record the command output.
- **Max feedback latency:** 10 seconds.

---

## Command Catalog

### CMD-204-quick

```bash
bash -lc 'set -euo pipefail
roadmap=.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md
test -s "$roadmap"
for section in "How to read this roadmap" "Ranking method" "Ranked Top 10" "Implementation Cards" "Suggested Follow-Up Milestones" "Explicit Deferrals" "Requirement Coverage" "Phase Handoff and Boundary"; do
  rg -q "^## $section$" "$roadmap"
done
rg -qF "| Rank | Change | Area / quality dimension | Impact | Effort | Risk reduction | Timing / slice | Done criteria |" "$roadmap"
test "$(rg -c "^### Rank [0-9]+ - " "$roadmap")" -eq 10
'
```

### CMD-RD-01

```bash
bash -lc 'set -euo pipefail
roadmap=.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md
test -s "$roadmap"
rg -q "^## Ranked Top 10$" "$roadmap"
rg -qF "| Rank | Change | Area / quality dimension | Impact | Effort | Risk reduction | Timing / slice | Done criteria |" "$roadmap"
rows="$(awk '"'"'/^## Ranked Top 10$/{inside=1; next} /^## Implementation Cards$/{inside=0} inside && $0 ~ /^\| [0-9]+ /{count++} END{print count+0}'"'"' "$roadmap")"
test "$rows" -eq 10
for term in "public toolchain" "evaluator" "provider" "release recovery" "CI timing" "schema-prefix" "metadata" "browser" "release-gate" "portal"; do
  rg -qi "$term" "$roadmap"
done
rg -q "Done criteria" "$roadmap"
'
```

### CMD-RD-02

```bash
bash -lc 'set -euo pipefail
roadmap=.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md
test -s "$roadmap"
rg -q "^## Implementation Cards$" "$roadmap"
test "$(rg -c "^### Rank [0-9]+ - " "$roadmap")" -eq 10
for label in "Source evidence" "Reader/JTBD served" "Scope" "Non-goals" "Implementation approach" "Verification" "Rollback" "Metrics/evidence needed"; do
  test "$(rg -c "^\\*\\*$label:\\*\\*" "$roadmap")" -eq 10
done
rg -q "^## Suggested Follow-Up Milestones$" "$roadmap"
for slice in "Public Truth And Proof-State Baseline" "Evaluator Path And Release Safety" "CI Critical Path Cleanup" "Schema Prefix Contract Hardening" "Portal Parity Readiness"; do
  rg -q "$slice" "$roadmap"
done
'
```

### CMD-RD-03

```bash
bash -lc 'set -euo pipefail
roadmap=.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md
test -s "$roadmap"
test "$(rg -c "^\\*\\*Source evidence:\\*\\*" "$roadmap")" -eq 10
for phase in "Phase 201" "Phase 202" "Phase 203"; do
  rg -q "$phase" "$roadmap"
done
rg -Eq "201-SOFTWARE-QUALITY-AUDIT|202-CI-CD-PERFORMANCE-AUDIT|203-DB-SCHEMA-CONTRACT-ADR|Phase 201|Phase 202|Phase 203" "$roadmap"
'
```

### CMD-RD-04

```bash
bash -lc 'set -euo pipefail
roadmap=.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md
test -s "$roadmap"
rg -q "^## Explicit Deferrals$" "$roadmap"
for term in "test-value classification" "portal white-label" "support triage" "pixel-diff" "schema rename" "data movement" "branch-protection" "broad docs" "enterprise governance" "i18n" "runtime performance" "favicon"; do
  rg -qi "$term" "$roadmap"
done
rg -Eqi "unless|until|revisit|trigger|risk" "$roadmap"
'
```

### CMD-BOUNDARY

```bash
bash -lc 'set -euo pipefail
roadmap=.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md
test -s "$roadmap"
rg -q "^## Phase Handoff and Boundary$" "$roadmap"
rg -q "roadmap-only" "$roadmap"
rg -Eqi "does not change|did not change" "$roadmap"
for surface in "product behavior" "public APIs" "DB defaults" "CI topology" "release automation" "runtime UI" "CSS" "routes" "package metadata" "examples" "scripts" "public docs"; do
  rg -qi "$surface" "$roadmap"
done
changed="$(git status --short -- README.md CONTRIBUTING.md RELEASING.md .github scripts accrue accrue_admin accrue_portal examples package.json mix.exs 2>/dev/null || true)"
test -z "$changed"
'
```

### CMD-204-full

```bash
bash -lc 'set -euo pipefail
roadmap=.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md
test -s "$roadmap"
for section in "How to read this roadmap" "Ranking method" "Ranked Top 10" "Implementation Cards" "Suggested Follow-Up Milestones" "Explicit Deferrals" "Requirement Coverage" "Phase Handoff and Boundary"; do
  rg -q "^## $section$" "$roadmap"
done
for req in RD-01 RD-02 RD-03 RD-04; do
  rg -q "$req" "$roadmap"
done
rg -qF "| Rank | Change | Area / quality dimension | Impact | Effort | Risk reduction | Timing / slice | Done criteria |" "$roadmap"
rows="$(awk '"'"'/^## Ranked Top 10$/{inside=1; next} /^## Implementation Cards$/{inside=0} inside && $0 ~ /^\| [0-9]+ /{count++} END{print count+0}'"'"' "$roadmap")"
test "$rows" -eq 10
test "$(rg -c "^### Rank [0-9]+ - " "$roadmap")" -eq 10
for label in "Source evidence" "Reader/JTBD served" "Scope" "Non-goals" "Implementation approach" "Verification" "Rollback" "Metrics/evidence needed"; do
  test "$(rg -c "^\\*\\*$label:\\*\\*" "$roadmap")" -eq 10
done
for phase in "Phase 201" "Phase 202" "Phase 203"; do
  rg -q "$phase" "$roadmap"
done
for deferral in "test-value classification" "portal white-label" "support triage" "pixel-diff" "schema rename" "data movement" "branch-protection" "broad docs" "enterprise governance" "i18n" "runtime performance" "favicon"; do
  rg -qi "$deferral" "$roadmap"
done
rg -q "roadmap-only" "$roadmap"
changed="$(git status --short -- README.md CONTRIBUTING.md RELEASING.md .github scripts accrue accrue_admin accrue_portal examples package.json mix.exs 2>/dev/null || true)"
test -z "$changed"
'
```

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 204-01-01-RD01 | 01 | 1 | RD-01 | T-204-02 | Ranked Top 10 uses the required columns, contains exactly ten ranked rows, preserves D-11 subject order, and includes done criteria. | content contract | CMD-RD-01 | yes | pending |
| 204-01-02-RD02 | 01 | 1 | RD-02 | T-204-05 | Follow-up work is grouped into implementation cards and the five milestone-sized slices locked by D-13. | content contract | CMD-RD-02 | yes | pending |
| 204-01-01-RD03 | 01 | 1 | RD-03 | T-204-02 | Ranked rows and implementation cards cite Phase 201, Phase 202, or Phase 203 evidence rather than generic preferences. | content contract | CMD-RD-03 | yes | pending |
| 204-01-02-RD04 | 01 | 1 | RD-04 | T-204-05 | Explicit deferrals include the locked deferred categories and keep polish or overbuilt work behind risk-based reopen triggers. | content contract | CMD-RD-04 | yes | pending |
| 204-01-03-boundary | 01 | 1 | RD-01, RD-02, RD-03, RD-04 | T-204-01 / T-204-04 | The roadmap states the phase is roadmap-only and no implementation surfaces changed. | content contract | CMD-BOUNDARY | yes | pending |

*Status values: pending, green, red, flaky.*

---

## Wave 0 Requirements

- Existing infrastructure covers all Phase 204 requirements: `bash`, `rg`, `awk`, `git`, and the draft target artifact are already available.
- No test scaffolds, package installs, product test config, or Wave 0 framework setup are required.
- The target artifact `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` exists before execution as the draft to be upgraded.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | RD-01, RD-02, RD-03, RD-04 | All Phase 204 behaviors are Markdown content contracts with automated checks. | Not applicable. |

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands in `204-01-PLAN.md`.
- [x] RD-01, RD-02, RD-03, and RD-04 map to concrete content-contract commands in this artifact.
- [x] Sampling continuity: no three consecutive tasks can proceed without automated verification.
- [x] Wave 0 is complete because no missing test file or framework dependency exists for this roadmap-only phase.
- [x] No watch-mode flags appear in validation commands.
- [x] Feedback latency target is less than 10 seconds.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** approved 2026-07-03 for Phase 204 planning execution; command results remain pending until the executor runs the plan.
