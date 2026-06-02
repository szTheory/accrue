# Phase 159: Linked Release Readiness + Publish Proof - Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` | config | append-only, event-driven | `.planning/milestones/v1.23-phases/75-post-publish-contract-alignment/75-VERIFICATION.md` + `scripts/ci/capture_linked_release_proof.sh` | partial-match |
| `scripts/ci/verify_release_manifest_alignment.sh` | utility | transform, request-response | `scripts/ci/verify_release_contract.sh` | role-match |
| `scripts/ci/capture_linked_release_proof.sh` | utility | event-driven, request-response | `scripts/ci/capture_linked_release_proof.sh` | exact |
| `scripts/ci/README.md` | config | transform | `scripts/ci/README.md` | exact |
| `RELEASING.md` | config | transform | `RELEASING.md` | exact |
| `.github/workflows/release-please.yml` | config | event-driven | `.github/workflows/release-please.yml` | exact |

## Pattern Assignments

### `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` (config, append-only/event-driven)

**Analog:** `.planning/milestones/v1.23-phases/75-post-publish-contract-alignment/75-VERIFICATION.md`

**Ledger/document structure pattern** (lines 1-13):
```markdown
# Phase 75 — Post-publish contract alignment — Verification

**Milestone:** v1.23  
**Status:** **Complete** (2026-04-24)

## Preconditions
...
## Evidence checklist
...
```

**Checklist + sign-off pattern** (lines 11-26):
```markdown
## Evidence checklist

1. **PPX-01** — ...
2. **PPX-02** — ...

## Sign-off

- [x] Maintainer: requirements ... satisfied ...
```

**Append-only machine block pattern source:** `scripts/ci/capture_linked_release_proof.sh` (lines 145-179)
```bash
{
  printf '\n### Proof capture %s\n\n' "$captured_at"
  printf 'PR_NUMBER: %s\n' "$PR_NUMBER"
  printf 'TARGET_VERSION: %s\n' "$VERSION"
  printf 'RUN_ID: %s\n\n' "$RUN_ID"
  ...
} >>"$OUTPUT_PATH"
```

---

### `scripts/ci/verify_release_manifest_alignment.sh` (utility, transform/request-response)

**Analog:** `scripts/ci/verify_release_contract.sh`

**Script guard + fail helper pattern** (verify_release_manifest_alignment.sh lines 1-12):
```bash
#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[verify_release_manifest_alignment] $*" >&2
  exit 1
}
```

**Dependency and strict assertion pattern** (verify_release_contract.sh lines 28-43):
```bash
command -v jq >/dev/null 2>&1 || fail "jq is required but not installed"
...
[[ "$components" == "accrue,accrue_admin,accrue_portal" ]] ||
  fail "unexpected linked release scope: $components"
```

**Version extraction pattern** (verify_release_manifest_alignment.sh lines 19-38):
```bash
m_accrue=$(jq -r '.accrue // empty' "$MANIFEST")
m_admin=$(jq -r '.accrue_admin // empty' "$MANIFEST")
...
mix_accrue=$(sed -n 's/^  @version "\([^"]*\)"/\1/p' "$ROOT_DIR/accrue/mix.exs" | head -n 1)
mix_admin=$(sed -n 's/^  @version "\([^"]*\)"/\1/p' "$ROOT_DIR/accrue_admin/mix.exs" | head -n 1)
```

---

### `scripts/ci/capture_linked_release_proof.sh` (utility, event-driven/request-response)

**Analog:** `scripts/ci/capture_linked_release_proof.sh`

**CLI argument contract pattern** (lines 16-27, 50-85):
```bash
Usage: bash scripts/ci/capture_linked_release_proof.sh --version <x.y.z> --run-id <id> --pr <number-or-url> --output <path>
...
[[ -n "$VERSION" ]] || fail "--version is required"
[[ -n "$RUN_ID" ]] || fail "--run-id is required"
[[ -n "$PR_ARG" ]] || fail "--pr is required"
[[ -n "$OUTPUT" ]] || fail "--output is required"
```

**External truth reconciliation pattern** (lines 99-141):
```bash
RUN_JSON=$(gh run view "$RUN_ID" --repo "$REPO" --json databaseId,url,workflowName,conclusion,jobs)
...
for package in accrue accrue_admin accrue_portal; do
  tag="${package}-v${VERSION}"
  ...
  release_json=$(gh release view "$tag" --repo "$REPO" --json tagName,url,publishedAt)
  ...
  hex_json=$(curl -fsSL "https://hex.pm/api/packages/${package}")
  ...
done
```

**Append-only proof write pattern** (lines 145-179):
```bash
{
  printf '\n### Proof capture %s\n\n' "$captured_at"
  ...
  printf '\n#### Hex API truth\n\n'
  ...
} >>"$OUTPUT_PATH"
```

---

### `scripts/ci/README.md` (config, transform)

**Analog:** `scripts/ci/README.md`

**Gate map table pattern** (lines 169-175):
```markdown
## REL gates (v1.38 linked publish proof)

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| REL-10 | `scripts/ci/verify_release_pr_scope.sh` ... |
| REL-11 | `scripts/ci/capture_linked_release_proof.sh` ... |
```

**Triage section pattern** (lines 176-188):
```markdown
### Triage: verify_release_pr_scope.sh
...
### Triage: capture_linked_release_proof.sh
...
```

---

### `RELEASING.md` (config, transform)

**Analog:** `RELEASING.md`

**Primary path vs fallback pattern** (lines 42-49, 167-184):
```markdown
4. **Default (primary path):** merge the combined Release Please PR ...
...
## Manual fallback
...
Use `.github/workflows/publish-hex.yml` only as a manual fallback or recovery path:
...
Manual fallback order:
1. Publish `accrue`.
2. Confirm Hex availability.
3. Publish `accrue_admin`.
4. Confirm Hex availability.
5. Publish `accrue_portal`.
```

**Strict publish ordering pattern** (lines 71-77):
```markdown
- `accrue` publishes first.
- `accrue_admin` publishes only after the `accrue` publish job succeeds ...
- `accrue_portal` publishes only after the `accrue` publish job succeeds and ... after `accrue_admin` ...
- `accrue_admin` dry-run and publish steps export `ACCRUE_ADMIN_HEX_RELEASE=1`.
- `accrue_portal` dry-run and publish steps export `ACCRUE_PORTAL_HEX_RELEASE=1`.
```

---

### `.github/workflows/release-please.yml` (config, event-driven)

**Analog:** `.github/workflows/release-please.yml`

**Workflow output fan-out pattern** (lines 23-34):
```yaml
outputs:
  accrue_release_created: ${{ steps.release.outputs.accrue_release_created }}
  ...
  accrue_portal_release_created: ${{ steps.release.outputs.accrue_portal_release_created }}
```

**Serialized publish DAG pattern** (lines 238-241, 271-275):
```yaml
publish-accrue-admin:
  needs: [release, publish-accrue]
...
publish-accrue-portal:
  needs: [release, publish-accrue, publish-accrue-admin]
```

**Package-local publish-mode env pattern** (lines 243-245, 276-278):
```yaml
env:
  ACCRUE_ADMIN_HEX_RELEASE: "1"
...
env:
  ACCRUE_PORTAL_HEX_RELEASE: "1"
```

## Shared Patterns

### Error Handling for release scripts
**Source:** `scripts/ci/capture_linked_release_proof.sh:11-14`, `scripts/ci/verify_release_pr_scope.sh:11-14`, `scripts/ci/verify_release_manifest_alignment.sh:9-12`
```bash
fail() {
  echo "[script_name] $*" >&2
  exit 1
}
```
**Apply to:** `scripts/ci/*` release-proof utilities.

### CLI dependency checks
**Source:** `scripts/ci/capture_linked_release_proof.sh:87-90`, `scripts/ci/verify_release_pr_scope.sh:95-98`
```bash
require_cmd gh
require_cmd jq
require_cmd curl
```
**Apply to:** scripts that consume GitHub/Hex APIs.

### Three-package lockstep iteration
**Source:** `scripts/ci/capture_linked_release_proof.sh:124-141`, `scripts/ci/verify_release_pr_scope.sh:126-148`
```bash
for package in accrue accrue_admin accrue_portal; do
  ...
done
```
**Apply to:** all release verifiers and proof capture scripts.

### Append-only proof artifact writes
**Source:** `scripts/ci/capture_linked_release_proof.sh:145-179`
```bash
{ ... } >>"$OUTPUT_PATH"
```
**Apply to:** `159-VERIFICATION.md` updates (no rewrite-in-place proof logic).

## No Analog Found

None.

## Metadata

**Analog search scope:** `.planning/phases`, `.planning/milestones`, `scripts/ci`, `.github/workflows`, root docs (`RELEASING.md`), package `mix.exs` files.  
**Files scanned:** 10  
**Pattern extraction date:** 2026-05-31
