---
phase: 204
slug: ranked-hardening-roadmap
status: green
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-02
updated: 2026-07-03
audited: 2026-07-03
runtime_tests_applicable: false
---

# Phase 204 - Nyquist Validation Coverage

## Audit Result

Phase 204 is a roadmap-only Markdown planning phase. Its observable behavior is
the content contract of
`.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md`, plus
the source/citation trail and the proof that implementation surfaces were not
changed.

All Phase 204 requirements are covered by automated artifact/content
verification. No generated product tests are appropriate for this phase because
there is no runtime behavior, public API, database behavior, CI topology change,
release automation change, UI change, package metadata change, or product source
change to exercise.

The pre-existing validation strategy was audited after execution. It already
mapped RD-01 through RD-04 to content checks, but its statuses were still
pre-execution `pending`. During the audit, three catalog commands exposed a
validation-command portability bug: this repository's `rg` treats `-E` as an
encoding option, so `rg -Eq` and `rg -Eqi` fail before checking content. The
commands below use the corrected `rg -q -e` and `rg -qi -e` form and were rerun.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Markdown/content-contract checks with `bash`, `rg`, `awk`, `node`, and `git`. |
| Runtime/product tests | Not applicable; Phase 204 did not modify runtime or implementation surfaces. |
| Config file | None. |
| Primary target | `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` |
| Quick command | `CMD-204-quick` |
| Full command | `CMD-204-full` |
| Estimated runtime | Less than 10 seconds locally. |

## Requirement Coverage Map

| Task ID | Requirement | Required behavior | Test type | Automated command | Status |
|---------|-------------|-------------------|-----------|-------------------|--------|
| 204-01-01-RD01 | RD-01 | The roadmap has a ranked top-10 hardening list with required columns, ten populated rows, locked subject order, and done criteria. | artifact/content | `CMD-RD-01`, `CMD-PARSER` | green |
| 204-01-02-RD02 | RD-02 | Follow-up work is grouped into one card per rank and five milestone-sized slices, not one cleanup list. | artifact/content | `CMD-RD-02`, `CMD-PARSER` | green |
| 204-01-01-RD03 | RD-03 | Ranked rows, implementation cards, and milestone slices cite Phase 201, Phase 202, or Phase 203 evidence. | artifact/content | `CMD-RD-03`, `CMD-PARSER`, `CMD-KEY-LINKS` | green |
| 204-01-02-RD04 | RD-04 | Polish-only or overbuilt work is explicitly deferred behind risk-based reopen thresholds. | artifact/content | `CMD-RD-04` | green |
| 204-01-03-boundary | RD-01, RD-02, RD-03, RD-04 | The roadmap states the phase is roadmap-only and no product/public implementation surfaces changed. | artifact/content + git scope | `CMD-BOUNDARY`, `CMD-COMMIT-SCOPE` | green |

## Executed Results

| Command | What it verifies | Actual result |
|---------|------------------|---------------|
| `CMD-204-quick` | Required sections, top-10 table header, and 10 implementation-card headings. | Exit 0, no stdout. |
| `CMD-RD-01` | RD-01 top-10 structure, row count, subject cues, and done criteria. | Exit 0, no stdout. |
| `CMD-RD-02` | RD-02 card count, card field labels, and five milestone slice names. | Exit 0, no stdout. |
| `CMD-RD-03` | RD-03 evidence cues and source evidence labels. | First run failed due invalid `rg -Eq`; corrected command exited 0. |
| `CMD-RD-04` | RD-04 explicit deferrals and reopen/risk language. | First run failed due invalid `rg -Eqi`; corrected command exited 0. |
| `CMD-BOUNDARY` | Roadmap-only boundary and clean product/public surface status. | First run failed due invalid `rg -Eqi`; corrected command exited 0. |
| `CMD-204-full` | Combined section, requirement, row, card, evidence, deferral, and boundary checks. | Exit 0, no stdout. |
| `CMD-PARSER` | Structural parser for ranked rows, card field order, milestone evidence, and RD rows. | Exit 0, stdout `{"rankedRows":10,"cards":10,"milestones":5,"requirements":4}`. |
| `CMD-KEY-LINKS` | Existence and citation checks for Phase 201, 202, 203, context, and UI spec evidence. | Exit 0, no stdout. |
| `CMD-COMMIT-SCOPE` | Phase 204 execution commits stayed in Phase 204 roadmap/summary/verification artifacts. | Exit 0; output lists only Phase 204 files. |

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
rg -q -e "201-SOFTWARE-QUALITY-AUDIT|202-CI-CD-PERFORMANCE-AUDIT|203-DB-SCHEMA-CONTRACT-ADR|Phase 201|Phase 202|Phase 203" "$roadmap"
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
rg -qi -e "unless|until|revisit|trigger|risk" "$roadmap"
'
```

### CMD-BOUNDARY

```bash
bash -lc 'set -euo pipefail
roadmap=.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md
test -s "$roadmap"
rg -q "^## Phase Handoff and Boundary$" "$roadmap"
rg -q "roadmap-only" "$roadmap"
rg -qi -e "does not change|did not change" "$roadmap"
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

### CMD-PARSER

```bash
node <<'NODE'
const fs = require('fs');
const path = '.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md';
const text = fs.readFileSync(path, 'utf8');
const fail = (msg) => { throw new Error(msg); };
const section = (start, end) => {
  const a = text.indexOf(`## ${start}`);
  if (a < 0) fail(`missing section ${start}`);
  const b = end ? text.indexOf(`## ${end}`, a) : text.length;
  if (end && b < 0) fail(`missing section ${end}`);
  return text.slice(a, b < 0 ? text.length : b);
};
const hasEvidence = (s) => /Phase 20[123]/.test(s);
const ranked = section('Ranked Top 10', 'Implementation Cards');
const rows = ranked.split('\n').filter((line) => /^\| [0-9]+ \|/.test(line));
if (rows.length !== 10) fail(`expected 10 ranked rows, found ${rows.length}`);
rows.forEach((row, i) => {
  if (!hasEvidence(row)) fail(`ranked row ${i + 1} lacks Phase 201/202/203 evidence`);
  const cells = row.split('|').slice(1, -1).map((cell) => cell.trim());
  if (cells.length !== 8 || cells.some((cell) => !cell)) fail(`ranked row ${i + 1} has incomplete cells`);
});
const cards = section('Implementation Cards', 'Suggested Follow-Up Milestones');
const cardMatches = [...cards.matchAll(/^### Rank (\d+) - .+$/gm)];
if (cardMatches.length !== 10) fail(`expected 10 cards, found ${cardMatches.length}`);
const fields = ['Source evidence', 'Reader/JTBD served', 'Scope', 'Non-goals', 'Implementation approach', 'Verification', 'Rollback', 'Metrics/evidence needed'];
for (let i = 0; i < cardMatches.length; i++) {
  const start = cardMatches[i].index;
  const end = i + 1 < cardMatches.length ? cardMatches[i + 1].index : cards.length;
  const block = cards.slice(start, end);
  let last = -1;
  for (const field of fields) {
    const idx = block.indexOf(`**${field}:**`);
    if (idx < 0) fail(`card ${i + 1} missing ${field}`);
    if (idx < last) fail(`card ${i + 1} field ${field} out of order`);
    last = idx;
  }
  const sourceLine = block.match(/^\*\*Source evidence:\*\*.*$/m)?.[0] || '';
  if (!hasEvidence(sourceLine)) fail(`card ${i + 1} source evidence lacks Phase 201/202/203`);
}
const milestones = section('Suggested Follow-Up Milestones', 'Explicit Deferrals');
const milestoneMatches = [...milestones.matchAll(/^### (.+)$/gm)];
if (milestoneMatches.length !== 5) fail(`expected 5 milestones, found ${milestoneMatches.length}`);
for (let i = 0; i < milestoneMatches.length; i++) {
  const start = milestoneMatches[i].index;
  const end = i + 1 < milestoneMatches.length ? milestoneMatches[i + 1].index : milestones.length;
  const block = milestones.slice(start, end);
  const sourceLine = block.match(/^Source evidence:.*$/m)?.[0] || '';
  if (!hasEvidence(sourceLine)) fail(`milestone ${milestoneMatches[i][1]} lacks Phase 201/202/203 source evidence`);
}
const coverage = section('Requirement Coverage', 'Phase Handoff and Boundary');
for (const req of ['RD-01', 'RD-02', 'RD-03', 'RD-04']) {
  if (!new RegExp(`^\\| ${req} \\|`, 'm').test(coverage)) fail(`missing coverage row ${req}`);
}
console.log(JSON.stringify({ rankedRows: rows.length, cards: cardMatches.length, milestones: milestoneMatches.length, requirements: 4 }));
NODE
```

### CMD-KEY-LINKS

```bash
bash -lc 'set -euo pipefail
roadmap=.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md
for target in \
  .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md \
  .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md \
  .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md \
  .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md \
  .planning/phases/204-ranked-hardening-roadmap/204-UI-SPEC.md; do
  test -f "$target"
done
rg -q "Phase 201|software-quality|201-SOFTWARE-QUALITY-AUDIT" "$roadmap"
rg -q "Phase 202|Baseline Metrics Needed|Phase 204 Handoff|202-CI-CD-PERFORMANCE-AUDIT" "$roadmap"
rg -q "Phase 203|billing|public|schema-prefix|203-DB-SCHEMA-CONTRACT-ADR" "$roadmap"
rg -q "D-07|D-11|D-21|D-24" .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md
rg -q "How to read this roadmap|Ranked Top 10|Implementation Cards" .planning/phases/204-ranked-hardening-roadmap/204-UI-SPEC.md
'
```

### CMD-COMMIT-SCOPE

```bash
git show --name-status --format='commit %h %s' \
  372c21f8 fa20022a 685cb70b 634cf145 e69bca64 e3dfcc4a -- \
  .planning/phases/204-ranked-hardening-roadmap
git status --short -- README.md CONTRIBUTING.md RELEASING.md .github scripts accrue accrue_admin accrue_portal examples package.json mix.exs
```

## Manual-Only Verifications

| Behavior | Requirement | Why manual | Status |
|----------|-------------|------------|--------|
| None | RD-01, RD-02, RD-03, RD-04 | All Phase 204 behaviors are inspectable through automated Markdown, parser, link, and git-scope checks. | Not applicable |

## Validation Audit Trail

| Metric | Count |
|--------|-------|
| Requirements audited | 4 |
| Automated coverage entries | 5 |
| Product/runtime tests generated | 0 |
| Manual-only entries | 0 |
| Escalated blockers | 0 |
| Validation command fixes | 3 |

Notes:

- Implementation files were not modified.
- Product test files were not created because runtime tests would be false
  coverage for this Markdown-only roadmap phase.
- Existing unrelated dirty planning files outside Phase 204 were present before
  this audit and were not touched.
- Product/public surface `git status` for README, public docs, packages,
  source, examples, scripts, and workflow paths returned empty.

## Validation Sign-Off

- [x] RD-01, RD-02, RD-03, and RD-04 map to concrete automated checks.
- [x] The checks verify behavior of the roadmap artifact, not just file
  existence.
- [x] Parser coverage checks row/card/slice evidence and card field order.
- [x] Key-link coverage checks Phase 201, Phase 202, Phase 203, context, and
  UI-spec evidence paths.
- [x] Boundary coverage confirms no implementation/product surfaces changed.
- [x] No manual-only validation is required.
- [x] `nyquist_compliant: true` is supported by executed green commands.
