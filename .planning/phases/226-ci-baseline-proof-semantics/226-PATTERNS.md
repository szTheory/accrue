# Phase 226: CI Baseline & Proof Semantics - Pattern Map

**Mapped:** 2026-08-09  
**Files analyzed:** 6  
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/ci/capture_ci_baseline.sh` | utility | request-response / transform | `scripts/ci/annotation_sweep.sh` | role-match |
| `scripts/ci/verify_ci_baseline_contract.sh` | test | transform | `scripts/ci/verify_phase192_ci_contract.sh` | exact |
| `226-CI-BASELINE.json` | config | transform | `baseline.cells.json` (Phase 187) | partial-match |
| `226-CI-BASELINE.md` | documentation | transform | `187-BASELINE.md` | role-match |
| `226-SETUP-OWNERSHIP.md` | documentation | request-response | `examples/accrue_host/README.md` | role-match |
| `.github/workflows/ci.yml` | config | event-driven | existing `docs-contracts-shift-left` job | exact |

## Pattern Assignments

### `scripts/ci/capture_ci_baseline.sh` (utility, request-response / transform)

**Analog:** `scripts/ci/annotation_sweep.sh`

Start as a strict Bash utility with an isolated temporary directory and cleanup trap. Preserve this tool's API-versioned `gh api` form, but the new collector must be **metadata-only**: do not add the annotation/log/artifact-download calls used by the analog.

**Strict startup and cleanup** (`scripts/ci/annotation_sweep.sh:22-23, 61-85`):

```bash
set -euo pipefail

api_base="${GITHUB_API_URL:-https://api.github.com}"
repo_path="/repos/${GITHUB_REPOSITORY}"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

GH_TOKEN="$token" gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "$endpoint" >"$body_file"
```

**Validation/error convention** (`scripts/ci/annotation_sweep.sh:43-59`): validate a numeric run ID, repository, `gh`, and `jq` before API access; send errors to stderr and fail non-zero. Adapt the required inputs rather than silently defaulting to a run or attempt.

```bash
if [ -z "${GITHUB_REPOSITORY:-}" ] || [ -z "${GITHUB_RUN_ID:-}" ]; then
  echo "annotation_sweep.sh requires GITHUB_REPOSITORY and GITHUB_RUN_ID." >&2
  usage >&2
  exit 2
fi
```

**Pagination pattern** (`scripts/ci/annotation_sweep.sh:88-132`): retain the page loop for run jobs and artifacts; reduce each provider response through an explicit `jq` allowlist immediately. Never serialize provider response JSON, environment values, log text, signed URLs, or artifact contents to the checked-in baseline.

---

### `scripts/ci/verify_ci_baseline_contract.sh` (test, transform)

**Analog:** `scripts/ci/verify_phase192_ci_contract.sh`

Follow the repository's static, fail-closed Bash contract style: resolve repo-relative files, expose small assertion helpers, extract a CI job only when needed, and end with a stable `: ok` marker.

**Imports/setup and failure helper** (`scripts/ci/verify_phase192_ci_contract.sh:1-17`):

```bash
#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() {
  echo "verify_phase192_ci_contract: $*" >&2
  exit 1
}

require_file() {
  local file="$1"
  [ -f "$file" ] || fail "missing file: ${file#$root_dir/}"
}
```

**Positive and negative semantic assertions** (`scripts/ci/verify_phase192_ci_contract.sh:19-50`): copy `require_fixed`, `require_source_fixed`, and `require_source_absent_regex`. Use them to assert each proof-state enum and required CI identity exists, and reject log endpoints, secret/environment fields, raw payload fields, and URLs containing `?`.

```bash
require_source_absent_regex() {
  local label="$1"
  local source="$2"
  local pattern="$3"

  if printf '%s\n' "$source" | grep -Eiq "$pattern"; then
    fail "forbidden /${pattern}/ found in ${label}"
  fi
}
```

**Workflow job extraction** (`scripts/ci/verify_phase192_ci_contract.sh:53-60`): reuse this exact YAML-boundary parser to validate stable job IDs, `needs`, `continue-on-error`, artifact names, and Node/Playwright command references without changing workflow topology.

```bash
job_body() {
  local job_id="$1"

  awk -v job_id="$job_id" '
    $0 == "  " job_id ":" { in_job = 1 }
    in_job && $0 ~ /^  [A-Za-z0-9_-]+:/ && $0 != "  " job_id ":" { exit }
    in_job { print }
  ' "$ci_file"
}
```

Use `jq` as a required executable and test fixtures through a root override, following `scripts/ci/verify_release_contract.sh:5-33`, rather than making a contract test require authenticated live API access.

---

### `226-CI-BASELINE.json` (config, transform)

**Analog:** `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json` and its companion `187-BASELINE.md`

This is a new domain schema, so there is no exact CI-data analog. Keep JSON as the canonical structured fact source and render Markdown from it; Phase 187 establishes that ownership rule explicitly (`187-BASELINE.md:3-7`):

```markdown
Structured artifacts are canonical for Phase 187 and Phase 192 comparison:
baseline.cells.json and defects.ndjson are canonical. If this markdown disagrees
with those files, regenerate the markdown from the structured artifacts.
```

For Phase 226, make the machine record an explicit allowlist: run ID/event/SHA/attempt/status/timestamps/durations, eligibility and exclusion reason, job ID/name/policy/conclusion/proof state, step name/conclusion/duration, cache state, artifact name/size/expiry, and normalized root signature. Encode unavailable provider data as `null`; do not manufacture timings or cache hits.

---

### `226-CI-BASELINE.md` (documentation, transform)

**Analog:** `.planning/milestones/v1.53-phases/187-audit-baseline/187-BASELINE.md`

Use a concise human-readable overview that points to the JSON as authority, then tables for cohort eligibility, wall/queue/critical-path timing, job/setup costs, proof state, exclusions, and privacy posture. Phase 187's table-forward summary is the relevant layout pattern (`187-BASELINE.md:9-68`):

```markdown
## Artifact Counts

- Baseline cells: 21276
- Covered cells: 4303

## Coverage Summary

### By Coverage Status

| Status | Cells |
| --- | --- |
| covered | 4303 |
```

For Phase 226, replace UI counts with measured CI facts and retain the contrary measured conclusion: the initial required chain is ~39m36s and staged release → admin drift/docs → host integration → Playwright, rather than queue-bound. Link canonical Actions run/job pages only; raw reports and traces remain Actions-owned.

---

### `226-SETUP-OWNERSHIP.md` (documentation, request-response)

**Analog:** `examples/accrue_host/README.md`

Write an ownership matrix followed by symptom → first command → next safe action. Keep host-local bootstrap commands verbatim and distinguish them from CI provisioning.

**Host full-gate ownership** (`examples/accrue_host/README.md:299-321`):

```markdown
cd examples/accrue_host
mix setup
mix verify.full
```

`mix verify.full` is the CI-equivalent local host gate. It layers compile,
asset-build, dev-boot, regression, and browser smoke on top of `mix verify`.
```

**Browser diagnostic commands** (`examples/accrue_host/README.md:443-460`):

```bash
cd examples/accrue_host
npm ci
npm run e2e:install
npm run e2e:a11y
```

The underlying host package owns the install alias (`examples/accrue_host/package.json:4-12`):

```json
"e2e": "env -u NO_COLOR playwright test",
"e2e:install": "playwright install chromium"
```

Reference the existing repo wrapper, rather than duplicating its server/fixture lifecycle: `scripts/ci/accrue_host_uat.sh:18-46` resolves `examples/accrue_host`, preserves PG/port inputs, checks `pg_isready` when available, and delegates to `mix verify.full`.

---

### `.github/workflows/ci.yml` (config, event-driven)

**Analog:** existing `docs-contracts-shift-left` job plus the established CI graph

Add the new contract invocation to the existing shift-left/release-facing surface; do not create a new required check or alter `needs` identities. Its job belongs to the non-scheduled default CI lane (`.github/workflows/ci.yml:35-45`):

```yaml
docs-contracts-shift-left:
  name: Docs and bash contracts (shift-left)
  if: github.event_name != 'schedule'
  runs-on: ubuntu-24.04

  steps:
    - uses: actions/checkout@v6
```

The contract must reflect, not reinterpret, workflow policy:

```yaml
# Required cells remain release-blocking; only clearly labeled advisory cells may use continue-on-error.
continue-on-error: ${{ matrix.support == 'advisory' }}
```

(`.github/workflows/ci.yml:188-234`)

Preserve the scheduled-lane distinction (`.github/workflows/ci.yml:18-28, 41`) and release critical-path edges: `admin-drift-docs` needs `release-gate` (`:439-443`), `host-integration` needs admin drift/docs and shift-left (`:889-901`), and Playwright shards need host integration (`:1015-1019`). Existing host CI ownership is authoritative: Node 22 setup, `npm ci`, `npm run e2e:install`, then `bash scripts/ci/accrue_host_uat.sh` (`:943-971`); failure-only report/traces remain artifacts (`:980-998`).

## Shared Patterns

### Fail-closed contracts

**Sources:** `scripts/ci/verify_phase192_ci_contract.sh:9-60`; `scripts/ci/verify_release_contract.sh:14-33`  
**Apply to:** collector verification and workflow-semantic checks.

Use `set -euo pipefail`, root-relative paths, `fail`, file existence checks, and exact positive/negative assertions. A contract must fail on absent files, taxonomy drift, unsafe values, or unexpected workflow shape—never warn and continue.

### Proof state is policy plus observation

**Sources:** `.github/workflows/ci.yml:168-234`; `scripts/ci/annotation_sweep.sh:151-174`; `225-CI-INCIDENTS.md:32-35`  
**Apply to:** JSON records, Markdown tables, contract checks.

Required release cells use `support: required`; only matrix advisory cells use `continue-on-error`; advisory jobs are visibly tagged `[advisory]`. Store this declaration separately from observed conclusion, and render only a required successful qualifying job as `proved`. A `skipped` upload/lane and all advisory work remain non-proof.

### Privacy boundary

**Source:** `.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md:1-3`  
**Apply to:** collector, baseline JSON/Markdown, tests.

```markdown
This is the privacy-safe causal index for the active required-lane signatures. Raw logs, browser reports, traces, screenshots, server output, payloads, secrets, and user data remain GitHub Actions artifacts.
```

The Phase 226 collector must use this same boundary: checked-in facts are allowlisted metadata; raw evidence stays in Actions.

### Setup ownership

**Sources:** `.github/workflows/ci.yml:943-971`; `examples/accrue_host/README.md:443-460`; `scripts/ci/accrue_host_uat.sh:18-46`  
**Apply to:** setup ownership runbook and its contract.

CI provisions Node/browser and calls the existing wrapper. Host maintainers bootstrap their own Node/npm/Chromium and local database, then use the documented `npm ci`, `npm run e2e:install`, and `mix verify.full` entry points. Do not introduce a competing bootstrap script.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `scripts/ci/capture_ci_baseline.sh` | utility | request-response / transform | No checked-in metadata-only Actions collector exists; adapt the API, pagination, strict-mode, and cleanup conventions from `annotation_sweep.sh`. |
| `226-CI-BASELINE.json` | config | transform | No CI timing/proof-state baseline schema exists; Phase 187 supplies only the structured-source-plus-rendered-summary ownership convention. |

## Metadata

**Analog search scope:** `.github/workflows/`, `scripts/ci/`, `examples/accrue_host/`, Phase 225 and Phase 187 planning artifacts  
**Files scanned:** 11  
**Pattern extraction date:** 2026-08-09
