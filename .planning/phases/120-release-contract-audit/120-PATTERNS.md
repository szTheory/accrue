# Phase 120: Release Contract Audit - Pattern Map

**Mapped:** 2026-05-07
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `RELEASING.md` | config | request-response | `RELEASING.md` | exact |
| `release-please-config.json` | config | transform | `release-please-config.json` | exact |
| `.release-please-manifest.json` | config | CRUD | `.release-please-manifest.json` | exact |
| `.github/workflows/release-please.yml` | config | event-driven | `.github/workflows/release-please.yml` | exact |
| `.github/workflows/publish-hex.yml` | config | event-driven | `.github/workflows/publish-hex.yml` | exact |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `scripts/ci/verify_release_manifest_alignment.sh` | utility | transform | `scripts/ci/verify_release_manifest_alignment.sh` | exact |
| `scripts/ci/verify_package_docs.sh` | utility | transform | `scripts/ci/verify_package_docs.sh` | exact |
| `scripts/ci/verify_release_contract.sh` | utility | transform | `scripts/ci/verify_release_manifest_alignment.sh` + `scripts/ci/verify_package_docs.sh` | role-match |

## Pattern Assignments

### `RELEASING.md` (config, request-response)

**Analog:** `RELEASING.md`

**Narrative contract pattern** ([RELEASING.md](/Users/jon/projects/accrue/RELEASING.md:3)):
```md
This runbook is written for the **recurring** maintainer path: linked `accrue` +
`accrue_admin` releases via **Release Please** on a green `main`, followed by ordered
Hex publishes and lightweight post-publish checks.
```

**"Last verified against" pattern** ([RELEASING.md](/Users/jon/projects/accrue/RELEASING.md:24)):
```md
10. **Last verified line.** Update the line below whenever `release-please-config.json`,
`.release-please-manifest.json`, or `.github/workflows/release-please.yml` change.

**Last verified against** `release-please-config.json`, `.release-please-manifest.json`,
and `.github/workflows/release-please.yml` on **2026-04-23** (UTC).
```

**Ordered publish checklist pattern** ([RELEASING.md](/Users/jon/projects/accrue/RELEASING.md:32)):
```md
3. Review the PR: both `accrue/mix.exs` and `accrue_admin/mix.exs` `@version` values match the manifest
4. ... merge the combined Release Please PR manually on GitHub ...
5. Confirm Hex package availability for **`accrue`** before relying on **`accrue_admin`** consumers.
6. Let `.github/workflows/release-please.yml` publish **`accrue_admin`** ...
```

**Manual recovery pattern** ([RELEASING.md](/Users/jon/projects/accrue/RELEASING.md:155)):
```md
Use `.github/workflows/publish-hex.yml` only as a manual fallback or recovery path:

- `package`: choose `accrue` or `accrue_admin`
- `tag`: reviewed tag or commit ref to publish from
- `release_version`: expected version at that ref
```

### `release-please-config.json` (config, transform)

**Analog:** `release-please-config.json`

**Linked-version plugin pattern** ([release-please-config.json](/Users/jon/projects/accrue/release-please-config.json:3)):
```json
"separate-pull-requests": false,
"include-component-in-tag": true,
"plugins": [
  {
    "type": "linked-versions",
    "groupName": "accrue-monorepo",
    "components": ["accrue", "accrue_admin", "accrue_portal"]
  }
]
```

**Per-package entry pattern** ([release-please-config.json](/Users/jon/projects/accrue/release-please-config.json:12)):
```json
"accrue": {
  "component": "accrue",
  "release-type": "elixir",
  "package-name": "accrue",
  "changelog-path": "CHANGELOG.md",
  "include-component-in-tag": true
}
```

### `.release-please-manifest.json` (config, CRUD)

**Analog:** `.release-please-manifest.json`

**Flat manifest pattern** ([.release-please-manifest.json](/Users/jon/projects/accrue/.release-please-manifest.json:1)):
```json
{
  "accrue": "1.0.0",
  "accrue_admin": "1.0.0",
  "accrue_portal": "1.0.0"
}
```

### `.github/workflows/release-please.yml` (config, event-driven)

**Analog:** `.github/workflows/release-please.yml`

**Workflow trigger + output contract** ([release-please.yml](/Users/jon/projects/accrue/.github/workflows/release-please.yml:3)):
```yaml
on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  release:
    outputs:
      accrue_release_created: ${{ steps.release.outputs.accrue_release_created }}
      accrue_admin_release_created: ${{ steps.release.outputs.accrue_admin_release_created }}
      accrue_portal_release_created: ${{ steps.release.outputs.accrue_portal_release_created }}
```

**Shell-in-workflow output writer pattern** ([release-please.yml](/Users/jon/projects/accrue/.github/workflows/release-please.yml:43)):
```yaml
- name: Run Release Please
  id: release
  run: |
    set -euo pipefail
    release_exists() {
      gh release view "$1" --repo "$repo" >/dev/null 2>&1
    }
    write_release_outputs() {
      local output_prefix="$1"
      local manifest_path="$2"
      version="$(jq -r --arg path "$manifest_path" '.[$path] // empty' .release-please-manifest.json)"
```

**Lockstep fallback pattern** ([release-please.yml](/Users/jon/projects/accrue/.github/workflows/release-please.yml:130)):
```yaml
# Release Please sometimes creates only the core GitHub Release when both
# packages bump in one merge; accrue_admin would never publish.
if [ "$accrue_created" = "true" ] && [ "$accrue_admin_created" != "true" ]; then
  if [ -n "$accrue_version" ] && [ -n "$accrue_admin_version" ] && [ "$accrue_version" = "$accrue_admin_version" ]; then
    echo "accrue_admin_release_created=true" >> "$GITHUB_OUTPUT"
```

**Ordered publish jobs pattern** ([release-please.yml](/Users/jon/projects/accrue/.github/workflows/release-please.yml:166)):
```yaml
publish-accrue-admin:
  needs: [release, publish-accrue]
  if: ${{ always() && needs.release.outputs.accrue_admin_release_created == 'true'
    && (needs.release.outputs.accrue_release_created != 'true' || needs.publish-accrue.result == 'success') }}

publish-accrue-portal:
  needs: [release, publish-accrue, publish-accrue-admin]
```

### `.github/workflows/publish-hex.yml` (config, event-driven)

**Analog:** `.github/workflows/publish-hex.yml`

**Manual workflow dispatch input pattern** ([publish-hex.yml](/Users/jon/projects/accrue/.github/workflows/publish-hex.yml:3)):
```yaml
on:
  workflow_dispatch:
    inputs:
      package:
        description: 'Package to publish. Run accrue before accrue_admin when recovering a same-day release.'
        required: true
        type: choice
        options:
          - accrue
          - accrue_admin
```

**Per-package recovery job pattern** ([publish-hex.yml](/Users/jon/projects/accrue/.github/workflows/publish-hex.yml:22)):
```yaml
publish-accrue:
  if: ${{ inputs.package == 'accrue' }}
  steps:
    - uses: actions/checkout@v6
      with:
        ref: ${{ inputs.tag }}
    - name: Verify accrue release version
      run: grep -n "@version \"${{ inputs.release_version }}\"" accrue/mix.exs
```

**Publish env gate pattern** ([publish-hex.yml](/Users/jon/projects/accrue/.github/workflows/publish-hex.yml:51)):
```yaml
publish-accrue-admin:
  env:
    ACCRUE_ADMIN_HEX_RELEASE: "1"
  steps:
    - name: Dry run accrue_admin Hex publish
      run: cd accrue_admin && mix hex.publish --dry-run
```

### `.github/workflows/ci.yml` (config, batch)

**Analog:** `.github/workflows/ci.yml`

**Verifier wiring pattern** ([ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml:29)):
```yaml
docs-contracts-shift-left:
  steps:
    - name: verify_package_docs.sh
      run: bash scripts/ci/verify_package_docs.sh
    - name: Adoption proof matrix contract
      run: bash scripts/ci/verify_adoption_proof_matrix.sh

release-manifest-ssot:
  steps:
    - name: Verify Release Please manifest ↔ mix.exs @version
      run: bash scripts/ci/verify_release_manifest_alignment.sh
```

**Stable job-contract comment pattern** ([ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml:3)):
```yaml
# Job id contract — stable YAML `jobs:` keys relied on by docs, `act`, and anchors:
# `release-manifest-ssot`, `release-gate`, `phase18-tax-gate`, `admin-drift-docs`,
# `host-integration`, `annotation-sweep`, `live-stripe`.
```

### `scripts/ci/verify_release_manifest_alignment.sh` (utility, transform)

**Analog:** `scripts/ci/verify_release_manifest_alignment.sh`

**Verifier bootstrap pattern** ([verify_release_manifest_alignment.sh](/Users/jon/projects/accrue/scripts/ci/verify_release_manifest_alignment.sh:1)):
```bash
#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}
```

**Shared fail helper pattern** ([verify_release_manifest_alignment.sh](/Users/jon/projects/accrue/scripts/ci/verify_release_manifest_alignment.sh:9)):
```bash
fail() {
  echo "[verify_release_manifest_alignment] $*" >&2
  exit 1
}
```

**Manifest-to-source assertion pattern** ([verify_release_manifest_alignment.sh](/Users/jon/projects/accrue/scripts/ci/verify_release_manifest_alignment.sh:19)):
```bash
m_accrue=$(jq -r '.accrue // empty' "$MANIFEST")
m_admin=$(jq -r '.accrue_admin // empty' "$MANIFEST")
mix_accrue=$(sed -n 's/^  @version "\\([^"]*\\)"/\\1/p' "$ROOT_DIR/accrue/mix.exs" | head -n 1)
mix_admin=$(sed -n 's/^  @version "\\([^"]*\\)"/\\1/p' "$ROOT_DIR/accrue_admin/mix.exs" | head -n 1)
[[ "$m_accrue" == "$m_admin" ]] || fail "manifest lockstep violated: accrue=$m_accrue accrue_admin=$m_admin"
```

### `scripts/ci/verify_package_docs.sh` (utility, transform)

**Analog:** `scripts/ci/verify_package_docs.sh`

**Helper-function pattern** ([verify_package_docs.sh](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:9)):
```bash
fail() {
  echo "[verify_package_docs] package docs verification failed: $*" >&2
  exit 1
}

require_fixed() {
  local file=$1
  local needle=$2
  grep -Fq "$needle" "$file" || fail "$file is missing: $needle"
}
```

**Version extraction pattern** ([verify_package_docs.sh](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:14)):
```bash
extract_version() {
  local file=$1
  version=$(sed -n 's/^  @version "\\([^"]*\\)"/\\1/p' "$file" | head -n 1)
  [[ -n "$version" ]] || fail "could not parse @version from $file"
  printf '%s\n' "$version"
}
```

**Invariant bundle pattern** ([verify_package_docs.sh](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:219)):
```bash
require_fixed "$ROOT_DIR/RELEASING.md" "Canonical local demo: Fake"
require_fixed "$ROOT_DIR/RELEASING.md" "Provider parity: Stripe test mode"
require_fixed "$ROOT_DIR/RELEASING.md" "Advisory/manual: live Stripe"
require_fixed "$ROOT_DIR/RELEASING.md" "HEX_API_KEY"
require_fixed "$ROOT_DIR/RELEASING.md" "RELEASE_PLEASE_TOKEN"
```

### `scripts/ci/verify_release_contract.sh` (utility, transform)

**Analog:** `scripts/ci/verify_release_manifest_alignment.sh` + `scripts/ci/verify_package_docs.sh`

**Copy bootstrap/error shape from** [verify_release_manifest_alignment.sh](/Users/jon/projects/accrue/scripts/ci/verify_release_manifest_alignment.sh:1):
```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}
fail() {
  echo "[verify_release_manifest_alignment] $*" >&2
  exit 1
}
```

**Copy reusable assertion helpers from** [verify_package_docs.sh](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:23):
```bash
require_fixed() {
  local file=$1
  local needle=$2
  grep -Fq "$needle" "$file" || fail "$file is missing: $needle"
}

require_regex() {
  local file=$1
  local pattern=$2
  grep -Eq "$pattern" "$file" || fail "$file does not match: $pattern"
}
```

**Planner-target core pattern to emulate:** bundle cross-file assertions the way `verify_package_docs.sh` does, but point them at `RELEASING.md`, `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`, and `.github/workflows/publish-hex.yml`.

## Shared Patterns

### Release Scope SSOT
**Source:** [release-please-config.json](/Users/jon/projects/accrue/release-please-config.json:5), [.release-please-manifest.json](/Users/jon/projects/accrue/.release-please-manifest.json:1), [release-please.yml](/Users/jon/projects/accrue/.github/workflows/release-please.yml:22)
**Apply to:** runbook, workflow, and verifier work in this phase
```json
"plugins": [
  {
    "type": "linked-versions",
    "groupName": "accrue-monorepo",
    "components": ["accrue", "accrue_admin", "accrue_portal"]
  }
]
```

### Ordered Publish Contract
**Source:** [release-please.yml](/Users/jon/projects/accrue/.github/workflows/release-please.yml:195), [publish-hex.yml](/Users/jon/projects/accrue/.github/workflows/publish-hex.yml:6), [RELEASING.md](/Users/jon/projects/accrue/RELEASING.md:165)
**Apply to:** `RELEASING.md`, `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`
```yaml
publish-accrue-admin:
  needs: [release, publish-accrue]

publish-accrue-portal:
  needs: [release, publish-accrue, publish-accrue-admin]
```

### Verifier Script Style
**Source:** [verify_release_manifest_alignment.sh](/Users/jon/projects/accrue/scripts/ci/verify_release_manifest_alignment.sh:9), [verify_package_docs.sh](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh:23)
**Apply to:** any new release-contract verifier
```bash
fail() {
  echo "[script_name] $*" >&2
  exit 1
}

grep -Fq "$needle" "$file" || fail "$file is missing: $needle"
```

### Human-Gated Release Automation
**Source:** [release-pr-automation.yml](/Users/jon/projects/accrue/.github/workflows/release-pr-automation.yml:14), [gh_merge_release_pr.sh](/Users/jon/projects/accrue/scripts/ci/gh_merge_release_pr.sh:14)
**Apply to:** any runbook text that discusses PR merge automation
```yaml
on:
  workflow_dispatch:
    inputs:
      pr_number:
        description: 'PR number to queue for merge when green (merge commit)'
```

```bash
# Modes:
#   (default)  gh pr checks --watch  then  gh pr merge --merge
#   --auto     gh pr merge --merge --auto
```

## No Analog Found

None. The codebase already has direct analogs for runbook wording, release workflows, manifest/config wiring, and shell-based contract verifiers.

## Metadata

**Analog search scope:** repo root release docs, `.github/workflows/`, `scripts/ci/`
**Files scanned:** 11
**Pattern extraction date:** 2026-05-07
