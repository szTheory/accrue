# Phase 161: Backlog Anchor Closure + Pause Rule - Pattern Map

**Mapped:** 2026-06-01
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/PROJECT.md` | config | request-response | `.planning/PROJECT.md` | exact |
| `.planning/ROADMAP.md` | config | request-response | `.planning/ROADMAP.md` | exact |
| `.planning/STATE.md` | config | request-response | `.planning/STATE.md` | exact |
| `scripts/ci/verify_roadmap_hygiene.sh` (new) | utility | transform | `scripts/ci/verify_stable_core_posture.sh` | exact |
| `scripts/ci/README.md` | config | request-response | `scripts/ci/README.md` | exact |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |

## Pattern Assignments

### `scripts/ci/verify_roadmap_hygiene.sh` (utility, transform)

**Analog:** `scripts/ci/verify_stable_core_posture.sh`

**Script skeleton + failure prefix** (`scripts/ci/verify_stable_core_posture.sh:1-12`):
```bash
#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "verify_stable_core_posture: $*" >&2
  exit 1
}
```

**Reusable assertion helpers** (`scripts/ci/verify_stable_core_posture.sh:14-26`):
```bash
require_fixed() { grep -Fq "$2" "$1" || fail "$1 is missing: $2"; }
require_regex() { grep -Eq "$2" "$1" || fail "$1 does not match: $2"; }
require_absent_regex() {
  if grep -Eq "$2" "$1"; then
    fail "$1 must not match: $2"
  fi
}
```

**Multi-file contract pattern** (`scripts/ci/verify_stable_core_posture.sh:28-49`):
```bash
public_anchor_files=(...paths...)
thin_mirror_files=(...paths...)

for file in "${public_anchor_files[@]}" "${thin_mirror_files[@]}"; do
  [[ -f "$file" ]] || fail "missing $file"
done
```

**Positive + negative wording checks** (`scripts/ci/verify_stable_core_posture.sh:51-77`):
```bash
require_fixed "$ROOT_DIR/.planning/PROJECT.md" "stable-core / demand-driven expansion"
...
for file in "${public_anchor_files[@]}" "${thin_mirror_files[@]}"; do
  require_absent_regex "$file" "feature freeze|no new features ever|maintenance only"
done
```

**Second analog for planning anchors** (`scripts/ci/verify_v1_17_friction_research_contract.sh:6-12, 61-73`):
```bash
inv="${repo_root}/.planning/research/v1.17-FRICTION-INVENTORY.md"
state="${repo_root}/.planning/STATE.md"
project="${repo_root}/.planning/PROJECT.md"
roadmap="${repo_root}/.planning/ROADMAP.md"
...
grep -Fq '.planning/research/v1.17-FRICTION-INVENTORY.md' "$state" || die ...
grep -Fq 'research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63' "$roadmap" || die ...
```

---

### `.github/workflows/ci.yml` (config, batch)

**Analog:** `.github/workflows/ci.yml`

**Docs-contracts lane placement** (`.github/workflows/ci.yml:29-37`):
```yaml
jobs:
  docs-contracts-shift-left:
    name: Docs and bash contracts (shift-left)
    if: github.event_name != 'schedule'
    runs-on: ubuntu-24.04
```

**Verifier step pattern** (`.github/workflows/ci.yml:58-77`):
```yaml
- name: v1.17 friction + north-star SSOT contract
  run: bash scripts/ci/verify_v1_17_friction_research_contract.sh
...
- name: Stable-core posture contract
  run: bash scripts/ci/verify_stable_core_posture.sh
```

Use the same style to add the new hygiene verifier as a dedicated named step in this job.

---

### `scripts/ci/README.md` (config, request-response)

**Analog:** `scripts/ci/README.md`

**REQ-ID mapping table pattern** (`scripts/ci/README.md:181-196`):
```markdown
## REL/POS gates ...
| REQ-ID | Primary script(s) or artifact | ... |
| POS-01 | `scripts/ci/verify_stable_core_posture.sh`; ... |
```

**Triage subsection pattern** (`scripts/ci/README.md:140-149`):
```markdown
### Triage: verify_stable_core_posture.sh
- `verify_stable_core_posture:` ... dedicated ... gate ...
- Negative guards block ... terms ...
```

Add a new BAK/PAU row and a matching `### Triage: verify_roadmap_hygiene.sh` section with expected failure prefix and fix-first guidance.

---

### `.planning/PROJECT.md` (config, request-response)

**Analog:** `.planning/PROJECT.md`

**Canonical doctrine section pattern** (`.planning/PROJECT.md:13-24`):
```markdown
## Development Posture
**Stable core / demand-driven expansion.** ...
Default future milestone posture:
- Prefer ...
- Do not start broad feature milestones because ...
```

Phase 161 pause rule should follow this canonical-policy style (strong default + explicit reopen criteria, no feature-freeze language).

---

### `.planning/ROADMAP.md` (config, request-response)

**Analog:** `.planning/ROADMAP.md`

**Thin mirror of doctrine + reopen criteria** (`.planning/ROADMAP.md:9-20`):
```markdown
## Planning Doctrine
Accrue is in **stable core / demand-driven expansion** posture ...
Future feature milestones require at least one of:
- a concrete adopter failure mode,
...
```

**Historical/non-active anchor section pattern** (`.planning/ROADMAP.md:171-177`):
```markdown
## Historical Backlog Anchors (not active scope)
These ... are retained for traceability only.
```

Use this exact historical-vs-active framing for FRG anchors and deferred seeds.

---

### `.planning/STATE.md` (config, request-response)

**Analog:** `.planning/STATE.md`

**Session continuity + current focus pattern** (`.planning/STATE.md:24-31,173-177`):
```markdown
**Current focus:** Phase 161 — backlog anchor closure + pause rule
...
## Session Continuity
Stopped at: ...
Resume file: ...
```

**Deferred items registry pattern** (`.planning/STATE.md:158-172`):
```markdown
## Deferred Items
| Category | Item | Status | Deferred At |
```

Phase 161 should preserve this tabular deferred register and add explicit trigger semantics for surviving deferred seeds/ideas.

## Shared Patterns

### Fast-fail docs verifier contract
**Sources:** `scripts/ci/verify_stable_core_posture.sh:1-26`, `scripts/ci/verify_v1_17_friction_research_contract.sh:13-16`
**Apply to:** `scripts/ci/verify_roadmap_hygiene.sh`
```bash
set -euo pipefail
# helper functions with script-specific stderr prefix
```

### Canonical doctrine + thin mirrors
**Sources:** `.planning/PROJECT.md:13-24`, `.planning/ROADMAP.md:9-20`, `.planning/STATE.md:130-156`
**Apply to:** pause rule wording across planning docs
```markdown
One canonical policy owner + concise mirror text in roadmap/state.
```

### Shift-left CI integration
**Sources:** `.github/workflows/ci.yml:30-77`, `scripts/ci/README.md:90-109`
**Apply to:** add hygiene verifier to existing `docs-contracts-shift-left` lane (no new CI lane)
```yaml
- name: <contract name>
  run: bash scripts/ci/<verifier>.sh
```

### Negative-guard wording checks
**Source:** `scripts/ci/verify_stable_core_posture.sh:75-77`
**Apply to:** guard against active-scope or feature-freeze drift in roadmap/pause-rule mirrors
```bash
require_absent_regex "$file" "feature freeze|maintenance only"
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `.planning/`, `scripts/ci/`, `.github/workflows/`
**Files scanned:** 8 primary analog/reference files
**Pattern extraction date:** 2026-06-01
