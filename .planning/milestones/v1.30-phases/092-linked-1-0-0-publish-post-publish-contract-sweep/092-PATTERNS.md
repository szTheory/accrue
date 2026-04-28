# Phase 92: Linked 1.0.0 publish + post-publish contract sweep - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 10 editable/create targets
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/mix.exs` | config | transform | `accrue_admin/mix.exs` | exact |
| `accrue_admin/mix.exs` | config | transform | `accrue/mix.exs` | exact |
| `.release-please-manifest.json` | config | transform | `release-please-config.json` | role-match |
| `accrue/README.md` | utility | file-I/O | `accrue_admin/README.md` | exact |
| `accrue_admin/README.md` | utility | file-I/O | `accrue/README.md` | exact |
| `accrue/guides/first_hour.md` | utility | file-I/O | `examples/accrue_host/README.md` | exact |
| `examples/accrue_host/README.md` | utility | file-I/O | `accrue/guides/first_hour.md` | exact |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | utility | file-I/O | `scripts/ci/verify_adoption_proof_matrix.sh` | partial |
| `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-VALIDATION.md` | test | batch | `.planning/milestones/v1.30-phases/091-pre-publish-prep/091-VALIDATION.md` | exact |
| `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-VERIFICATION.md` | test | batch | `.planning/milestones/v1.30-phases/091-pre-publish-prep/091-VERIFICATION.md` | exact |

## Inspection-Only Surfaces

These are Phase 92 proof surfaces but not primary hand-edit targets:

| Surface | Why inspect | Pattern source |
|---|---|---|
| `accrue/CHANGELOG.md` | Release Please must render the prepared `## [1.0.0]` block from `## Unreleased` without manual numbered-heading edits. | `.planning/milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md:60-76` |
| `accrue_admin/CHANGELOG.md` | Same lockstep release rendering requirement as core package. | `.planning/milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md:60-76` |

## Pattern Assignments

### `accrue/mix.exs` and `accrue_admin/mix.exs` (config, transform)

**Analogs:** `accrue_admin/mix.exs`, `accrue/mix.exs`

**Version source pattern**
- `accrue/mix.exs:1-10`
- `accrue_admin/mix.exs:1-10`

```elixir
@version "0.3.1"

def project do
  [
    app: :accrue,
    version: @version,
```

**Published-doc/source-ref parity pattern**
- `accrue/mix.exs:114-119`
- `accrue_admin/mix.exs:60-69`

```elixir
files: ~w(lib priv guides mix.exs README* LICENSE* CHANGELOG*)
source_ref: "accrue_admin-v#{@version}"
extras: [
  "README.md",
  "guides/admin_ui.md",
```

**Hex release dependency gate pattern**
- `accrue_admin/mix.exs:94-99`

```elixir
if System.get_env("ACCRUE_ADMIN_HEX_RELEASE") == "1" do
  {:accrue, "~> #{@version}"}
else
  {:accrue, path: "../accrue"}
end
```

**Planner guidance:** bump only the `@version` literals; preserve the existing `@version` plumbing, `source_ref`, package `files`, and the `ACCRUE_ADMIN_HEX_RELEASE` gate exactly.

---

### `.release-please-manifest.json` (config, transform)

**Analog:** `release-please-config.json`

**Linked-version config pattern**
- `release-please-config.json:3-10`

```json
"separate-pull-requests": false,
"include-component-in-tag": true,
"plugins": [
  {
    "type": "linked-versions",
    "groupName": "accrue-monorepo",
    "components": ["accrue", "accrue_admin"]
  }
]
```

**Current manifest shape**
- `.release-please-manifest.json:1-4`

```json
{
  "accrue": "0.3.1",
  "accrue_admin": "0.3.1"
}
```

**Validation guard pattern**
- `scripts/ci/verify_release_manifest_alignment.sh:13-32`

```bash
m_accrue=$(jq -r '.accrue // empty' "$MANIFEST")
m_admin=$(jq -r '.accrue_admin // empty' "$MANIFEST")
mix_accrue=$(sed -n 's/^  @version "\([^"]*\)"/\1/p' "$ROOT_DIR/accrue/mix.exs" | head -n 1)
mix_admin=$(sed -n 's/^  @version "\([^"]*\)"/\1/p' "$ROOT_DIR/accrue_admin/mix.exs" | head -n 1)
[[ "$m_accrue" == "$m_admin" ]] || fail "manifest lockstep violated: accrue=$m_accrue accrue_admin=$m_admin"
```

**Planner guidance:** update both manifest keys together in one edit; Phase 92 should continue to rely on the repo’s manifest-mode lockstep config and the existing SSOT verifier.

---

### `accrue/README.md` and `accrue_admin/README.md` (utility, file-I/O)

**Analogs:** `accrue_admin/README.md`, `accrue/README.md`

**Hex-vs-main callout pattern**
- `accrue/README.md:23-27`
- `accrue_admin/README.md:15-18`

```md
> **Hex vs `main`:** The `{:accrue, "~> …"}` line below tracks `accrue/mix.exs` `@version` on the branch you are reading...
```

```md
> **Hex vs `main`:** The `{:accrue_admin, "~> …"}` line below tracks `accrue_admin/mix.exs` `@version` on the branch you are reading...
```

**Install-snippet pattern**
- `accrue/README.md:29-37`
- `accrue_admin/README.md:21-27`

```elixir
defp deps do
  [
    {:accrue, "~> 0.3.1"}
  ]
end
```

```elixir
defp deps do
  [
    {:accrue_admin, "~> 0.3.1"}
  ]
end
```

**Cross-package coupling pattern**
- `accrue_admin/README.md:17-18,72`

```md
Keep **`accrue`** on the **same `~>` train** when both packages are in the host `mix.exs`...
Published `accrue_admin` releases resolve `accrue ~> 0.3.1`.
```

**Verifier contract to satisfy**
- `scripts/ci/verify_package_docs.sh:61-80`

```bash
require_fixed "$ROOT_DIR/accrue/README.md" "{:accrue, \"~> $accrue_version\"}"
require_fixed "$ROOT_DIR/accrue_admin/README.md" "{:accrue_admin, \"~> $accrue_admin_version\"}"
require_fixed "$ROOT_DIR/accrue_admin/README.md" "accrue ~> $accrue_version"
require_fixed "$ROOT_DIR/accrue/README.md" '> **Hex vs `main`:**'
require_fixed "$ROOT_DIR/accrue_admin/README.md" '> **Hex vs `main`:**'
```

**Planner guidance:** move only the versioned literals and any directly adjacent release prose; keep the existing Hex-vs-main framing and same-train coupling language intact.

---

### `accrue/guides/first_hour.md` and `examples/accrue_host/README.md` (utility, file-I/O)

**Analogs:** `examples/accrue_host/README.md`, `accrue/guides/first_hour.md`

**Same-PR parity pattern**
- `accrue/guides/first_hour.md:18-20`
- `examples/accrue_host/README.md:27-30`

```md
Public wording and step order stay aligned with [`examples/accrue_host/README.md`](../../examples/accrue_host/README.md#proof-and-verification); when the spine or command vocabulary changes, update that README in the **same** pull request.
```

**Versioned install pins pattern**
- `accrue/guides/first_hour.md:47-62`

```elixir
defp deps do
  [
    {:accrue, "~> 0.3.1"},
    {:accrue_admin, "~> 0.3.1"}
  ]
end
```

**Host proof/readme structure pattern**
- `examples/accrue_host/README.md:99-117`

```md
Pull requests are merge-blocked on GitHub Actions jobs `docs-contracts-shift-left` and `host-integration`...
- `mix verify` is the focused local proof suite...
- `mix verify.full` is the CI-equivalent local gate.
- `bash scripts/ci/accrue_host_uat.sh` is the thin repo-root wrapper...
```

**Verifier contract to satisfy**
- `scripts/ci/verify_package_docs.sh:118-153`

```bash
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "## First run"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "## Seeded history"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "## Proof and verification"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "{:accrue, \"~> $accrue_version\"}"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "{:accrue_admin, \"~> $accrue_admin_version\"}"
```

**Planner guidance:** update `first_hour.md` install needles to `1.0.0`; touch `examples/accrue_host/README.md` only if release-facing wording needs honesty adjustments, and preserve the existing VERIFY-01 / proof-mode section layout.

---

### `examples/accrue_host/docs/adoption-proof-matrix.md` (utility, file-I/O)

**Analog:** `scripts/ci/verify_adoption_proof_matrix.sh`

**Layering and proof-taxonomy pattern**
- `examples/accrue_host/docs/adoption-proof-matrix.md:7-12,29-44`

```md
## Layering note (local proof vs merge-blocking CI)
**Layer B (local Fake-backed proof):**
**Layer C (merge-blocking `docs-contracts-shift-left` + `host-integration`):**
## Organization billing proof (ORG-09)
### Primary archetype (merge-blocking)
### Recipe lanes (advisory by default)
```

**Script-enforced needles**
- `scripts/ci/verify_adoption_proof_matrix.sh:13-31`

```bash
require_substring "## Layering note (local proof vs merge-blocking CI)" "Layer B/C layering heading"
require_substring "**Layer C (merge-blocking \`docs-contracts-shift-left\` + \`host-integration\`):**" "Layer C label"
require_substring "verify_package_docs.sh" "verify_package_docs script name in matrix Layer C"
require_substring "Accrue.Billing.create_checkout_session/2" "checkout facade API in matrix"
require_substring "Accrue.Billing.create_billing_portal_session/2" "billing portal facade API in matrix"
```

**Planner guidance:** keep the current section ordering and exact proof-lane terminology; Phase 92 can refresh wording/evidence, but any edit must preserve every verifier needle already enforced by `verify_adoption_proof_matrix.sh`.

---

### `092-VALIDATION.md` (test, batch)

**Analog:** `.planning/milestones/v1.30-phases/091-pre-publish-prep/091-VALIDATION.md`

**Requirement-to-evidence structure**
- `091-VALIDATION.md:12-35`

```md
## Requirement-to-Evidence Map

1. **REL-06**
   - ...
2. **REL-07**
   - ...
```

**Command-block pattern**
- `091-VALIDATION.md:37-54`

```bash
rg -Fq '## Post-1.0 cadence (maintainer intent)' RELEASING.md
rg -Fq '{:accrue, "~> 0.3.1"}' accrue/README.md
rg -Fq '### Reaffirmed at 1.0.0 (2026-04-26)' .planning/PROJECT.md
```

**Reviewed-SHA closeout pattern**
- `091-VALIDATION.md:56-74`

```md
Execution must not close Phase 91 until `091-VERIFICATION.md` records a single reviewed merge SHA...
Do not flip ... to complete ... until the reviewed-SHA evidence above is present...
```

**Planner guidance:** keep the current Phase 92 file in the same mold: preconditions, numbered requirement map, one fenced command block, then explicit reviewed-SHA closeout rules.

---

### `092-VERIFICATION.md` (test, batch)

**Analogs:** `.planning/milestones/v1.30-phases/091-pre-publish-prep/091-VERIFICATION.md`, `.planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md`

**Lean checklist spine**
- `091-VERIFICATION.md:6-18`
- `086-VERIFICATION.md:6-16`

```md
## Preconditions
- Workspace `accrue/mix.exs` `@version`: ...
- Reviewed merge SHA: ...

## Evidence checklist
1. **REL-06**
```

**Verifier transcript annex pattern**
- `091-VERIFICATION.md:35-50`

```md
## Verifier transcripts

### docs-contracts-shift-left
- `bash scripts/ci/verify_package_docs.sh` — passed ...

### host-integration
- Local transcript on reviewed SHA: `bash scripts/ci/accrue_host_uat.sh` passed ...
```

**Post-publish PPX checklist pattern**
- `086-VERIFICATION.md:20-37`

```md
1. **PPX-05** — `bash scripts/ci/verify_package_docs.sh` ...
2. **PPX-06** — `bash scripts/ci/verify_adoption_proof_matrix.sh` ...
3. **PPX-07** — Merge-blocking `docs-contracts-shift-left` bundle ...
```

**Planner guidance:** Phase 92 verification should reuse the same three-part spine as 91/86, then add Hex package URLs, GitHub release/tag URLs, UTC publish timestamps, publish ordering proof (`accrue` before `accrue_admin`), and `release-manifest-ssot` evidence.

## Shared Patterns

### Ordered linked publish
**Sources:** `.github/workflows/release-please.yml:141-200`, `accrue_admin/mix.exs:94-99`
**Apply to:** `accrue/mix.exs`, `accrue_admin/mix.exs`, `.release-please-manifest.json`, `092-VERIFICATION.md`

```yaml
publish-accrue:
  needs: release
publish-accrue-admin:
  needs: [release, publish-accrue]
  if: ${{ always() && needs.release.outputs.accrue_admin_release_created == 'true' && (needs.release.outputs.accrue_release_created != 'true' || needs.publish-accrue.result == 'success') }}
```

### Release-manifest SSOT
**Sources:** `.github/workflows/ci.yml:56-65`, `scripts/ci/verify_release_manifest_alignment.sh:13-32`
**Apply to:** version bumps and `092-VALIDATION.md` / `092-VERIFICATION.md`

```yaml
release-manifest-ssot:
  steps:
    - name: Verify Release Please manifest ↔ mix.exs @version
      run: bash scripts/ci/verify_release_manifest_alignment.sh
```

### Docs-contracts-shift-left bundle
**Sources:** `.github/workflows/ci.yml:29-54`, `091-VERIFICATION.md:39-46`
**Apply to:** `accrue/README.md`, `accrue_admin/README.md`, `accrue/guides/first_hour.md`, `examples/accrue_host/README.md`, `examples/accrue_host/docs/adoption-proof-matrix.md`, `092-VERIFICATION.md`

```yaml
docs-contracts-shift-left:
  steps:
    - name: verify_package_docs.sh
    - name: v1.17 friction + north-star SSOT contract
    - name: VERIFY-01 README contract
    - name: Production readiness discoverability contract
    - name: Adoption proof matrix contract
    - name: Core admin invoice VERIFY flow id drift guard
```

### Same-PR docs parity
**Sources:** `accrue/guides/first_hour.md:18-20`, `.planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-CONTEXT.md:22-39`
**Apply to:** `accrue/guides/first_hour.md`, `examples/accrue_host/README.md`, `examples/accrue_host/docs/adoption-proof-matrix.md`

```md
...update that README in the **same** pull request...
```

## No Analog Found

None. Every editable/create target in Phase 92 has a direct repo analog or a strong sibling/phase precedent.

## Metadata

**Analog search scope:** `.planning/milestones/v1.28-phases/086-*`, `.planning/milestones/v1.30-phases/091-*`, `.github/workflows/`, `scripts/ci/`, `accrue/`, `accrue_admin/`, `examples/accrue_host/`
**Priority precedent note:** No Phase 68 or 75 artifact was present in this repo snapshot; Phase 86 and 91 provided the operative precedents.
**Pattern extraction date:** 2026-04-28
