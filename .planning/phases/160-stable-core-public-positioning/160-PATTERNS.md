# Phase 160: Stable-Core Public Positioning - Pattern Map

**Mapped:** 2026-05-31  
**Files analyzed:** 14  
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/ci/verify_stable_core_posture.sh` | utility | transform | `scripts/ci/verify_package_docs.sh` | exact |
| `scripts/ci/verify_release_notes_contract.sh` | utility | transform | `scripts/ci/verify_release_notes_contract.sh` | exact |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `scripts/ci/README.md` | docs | transform | `scripts/ci/README.md` | exact |
| `README.md` | docs | request-response | `README.md` | exact |
| `accrue/README.md` | docs | request-response | `accrue/README.md` | exact |
| `accrue/guides/first_hour.md` | docs | request-response | `accrue/guides/first_hour.md` | exact |
| `accrue/guides/jobs_to_be_done.md` | docs | request-response | `accrue/guides/jobs_to_be_done.md` | exact |
| `accrue/guides/maturity-and-maintenance.md` | docs | request-response | `accrue/guides/maturity-and-maintenance.md` | exact |
| `accrue/guides/release-notes.md` | docs | transform | `accrue/guides/release-notes.md` | exact |
| `accrue_admin/README.md` | docs | request-response | `accrue_admin/README.md` | exact |
| `accrue_portal/README.md` | docs | request-response | `accrue_portal/README.md` | exact |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | docs | transform | `examples/accrue_host/docs/adoption-proof-matrix.md` | exact |
| `.planning/PROJECT.md` / `.planning/REQUIREMENTS.md` / `.planning/processor-support-matrix.md` | docs | transform | same files (existing mirrors) | exact |

## Pattern Assignments

### `scripts/ci/verify_stable_core_posture.sh` (utility, transform)

**Analog:** `scripts/ci/verify_package_docs.sh`

**Script skeleton + fail helper** (`scripts/ci/verify_package_docs.sh:1-12`):
```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
fail() {
  echo "[verify_package_docs] package docs verification failed: $*" >&2
  exit 1
}
```

**Reusable matcher helpers** (`scripts/ci/verify_package_docs.sh:23-44`):
```bash
require_fixed() { grep -Fq "$2" "$1" || fail "$1 is missing: $2"; }
require_regex() { grep -Eq "$2" "$1" || fail "$1 does not match: $2"; }
require_absent_regex() {
  if grep -Eq "$2" "$1"; then fail "$1 must not match: $2"; fi
}
```

**Positive + negative drift pattern** (`scripts/ci/verify_processor_support_matrix.sh:85-92`):
```bash
if grep -Fq "| checkout.hosted_handoff | Local proof helper | Supported | No | Stripe-only |" "${matrix}"; then
  echo "verify_processor_support_matrix: stale Stripe-only checkout row still present" >&2
  exit 1
fi
```

### `scripts/ci/verify_release_notes_contract.sh` (utility, transform)

**Analog:** `scripts/ci/verify_release_notes_contract.sh`

**Version extraction and lockstep checks** (`scripts/ci/verify_release_notes_contract.sh:14-30`):
```bash
extract_version() { ... }
accrue_version=$(extract_version "$ROOT_DIR/accrue/mix.exs")
accrue_admin_version=$(extract_version "$ROOT_DIR/accrue_admin/mix.exs")
accrue_portal_version=$(extract_version "$ROOT_DIR/accrue_portal/mix.exs")
[[ "$accrue_version" == "$accrue_admin_version" ]] || fail ...
```

**Narrow substring contract style** (`scripts/ci/verify_release_notes_contract.sh:32-41`):
```bash
grep -Fq "# Release notes (plain-language)" "$notes" || fail ...
grep -Fq "## accrue" "$notes" || fail ...
version_heading_count=$(grep -Ec "^### ${accrue_version}$" "$notes" || true)
```

### `.github/workflows/ci.yml` (config, batch)

**Analog:** `.github/workflows/ci.yml`

**Docs-contracts-shift-left insertion pattern** (`.github/workflows/ci.yml:30-75`):
```yaml
jobs:
  docs-contracts-shift-left:
    steps:
      - uses: actions/checkout@v6
      - name: verify_package_docs.sh
        run: bash scripts/ci/verify_package_docs.sh
      - name: Release notes freshness contract
        run: bash scripts/ci/verify_release_notes_contract.sh
```

### `scripts/ci/README.md` (docs, transform)

**Analog:** `scripts/ci/README.md`

**Gate registry table pattern** (`scripts/ci/README.md:11-18`):
```md
| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
```

**Triage section pattern** (`scripts/ci/README.md:132-137`):
```md
### Triage: verify_release_notes_contract.sh
- `verify_release_notes_contract:` (stderr prefix on failure) — ...
```

### Public docs surfaces (`README.md`, `accrue/README.md`, `accrue/guides/*`, package READMEs)

**Root posture voice** (`README.md:19-22`):
```md
## Maintenance posture
The `1.0.x` line treats the public facade ... stability boundary ...
```

**Core package stable boundary wording** (`accrue/README.md:70-73`):
```md
## Stability
... done enough for the `1.0.x` line because the documented facade is the contract ...
```

**Guide layering + link-out pattern** (`accrue/guides/maturity-and-maintenance.md:41-45`):
```md
## Related
- [Jobs to Be Done — Scope and maturity](jobs_to_be_done.md#scope-and-maturity)
```

**First Hour thin mirror pattern** (`accrue/guides/first_hour.md:26-33`):
```md
This guide mirrors only the setup-critical needles from the processor support matrix...
For maintenance posture ... see [Maturity and maintenance](maturity-and-maintenance.md).
```

**Host/adoption proof mirror wording** (`examples/accrue_host/docs/adoption-proof-matrix.md:5-13`):
```md
... Fake-first lane ... provider-honest ...
... exact bundle membership lives in `scripts/ci/README.md` and `.github/workflows/ci.yml`
```

### Planning mirrors (`.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/processor-support-matrix.md`)

**Analogs:** same files

**Stable-core statement pattern** (`.planning/PROJECT.md:15-23`):
```md
**Stable core / demand-driven expansion.** As of 2026-05-31 ...
```

**Requirement IDs pattern** (`.planning/REQUIREMENTS.md:17-20`):
```md
- [ ] POS-01 ...
- [ ] POS-03 ...
```

**Canonical capability SSOT pattern** (`.planning/processor-support-matrix.md:1-8`):
```md
# Processor support matrix
This file is the canonical support SSOT ...
```

## Shared Patterns

### Contract verifier style
**Source:** `scripts/ci/verify_package_docs.sh:1-44`  
**Apply to:** `verify_stable_core_posture.sh`, lightweight additions in `verify_release_notes_contract.sh`  
Use `set -euo pipefail`, computed `ROOT_DIR`, `fail` helper with unique stderr prefix, then `require_fixed` / `require_regex` / `require_absent_regex`.

### Negative drift guards
**Source:** `scripts/ci/verify_processor_support_matrix.sh:85-123`, `scripts/ci/verify_adoption_proof_matrix.sh:72-85`  
**Apply to:** `verify_stable_core_posture.sh`  
Pin forbidden regressions with explicit `if grep ...; then fail`.

### CI wiring discipline
**Source:** `.github/workflows/ci.yml:30-75`  
**Apply to:** docs contracts only  
Add one explicit step under `docs-contracts-shift-left`; keep release/job scopes unchanged.

### Thin mirror docs discipline
**Source:** `accrue/guides/first_hour.md:26-33`, `examples/accrue_host/docs/adoption-proof-matrix.md:12-13`, `accrue_portal/README.md:51-54`  
**Apply to:** root/package/example docs  
Keep short boundary summary + canonical link; avoid duplicating full capability tables.

## No Analog Found

None.

## Metadata

**Analog search scope:** `scripts/ci/`, `.github/workflows/`, root/package READMEs, `accrue/guides/`, `examples/accrue_host/docs/`, `.planning/*.md`  
**Files scanned:** 17  
**Pattern extraction date:** 2026-05-31
