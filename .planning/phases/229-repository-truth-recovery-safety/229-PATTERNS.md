# Phase 229: Repository Truth & Recovery Safety - Pattern Map

**Mapped:** 2026-09-12  
**Files analyzed:** 9  
**Analogs found:** 8 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/ci/collect_repository_inventory.mjs` | utility | batch | `scripts/ci/collect_ci_baseline.mjs` | role-match |
| `scripts/ci/render_repository_inventory.mjs` | utility | transform | `scripts/ci/render_ci_baseline.mjs` | exact |
| `scripts/ci/verify_repository_inventory.mjs` | test | transform | `scripts/ci/verify_ci_baseline.mjs` | exact |
| `scripts/ci/preserve_repository_state.sh` | utility | file-I/O | `scripts/ci/preflight_phase227_candidate.sh` | partial |
| `scripts/ci/ci_monitor.cjs` | utility / CLI | request-response and streaming | `scripts/ci/collect_ci_baseline.mjs` | role-match |
| `scripts/ci/watch_ci.sh` | utility / compatibility wrapper | request-response | itself | exact modification target |
| `scripts/ci/README.md` | documentation | request-response | its Phase 226 evidence and watcher sections | exact modification target |
| `.planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json` | data artifact | batch | `226-CI-BASELINE.ndjson` | role-match |
| `.planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md` | documentation artifact | transform | `226-CI-BASELINE.md` | exact |

The `collect_*`, `render_*`, `verify_*`, and inventory filenames are the narrow, proposed implementation paths inferred from D-01 through D-06. The selected JSON/NDJSON layout remains discretionary, but it must have one canonical source artifact and one deterministic rendering.

## Pattern Assignments

### `scripts/ci/collect_repository_inventory.mjs` (utility, batch)

**Analog:** `scripts/ci/collect_ci_baseline.mjs` (tracked)

Use a dependency-free ESM Node CLI. Require explicit repository identity, validate it before collection, use an explicit command/API boundary, normalize records into an allowlisted schema, sort output, and give the top-level failure path a stable prefix. Do not persist raw logs, tokens, environment values, user paths, or GitHub payloads.

**Imports, trusted identity, and fail-closed helpers** (`scripts/ci/collect_ci_baseline.mjs:3-43`):

```javascript
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

function fail(message) { throw new Error(message); }

export function createRepositoryValidationContext({ expectedRepository } = {}) {
  if (typeof expectedRepository !== "string" ||
      !/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(expectedRepository)) {
    fail("expectedRepository must be an owner/repository string");
  }
  return Object.freeze({ expectedRepository: String(expectedRepository) });
}
```

**Explicit live-collection boundary and deterministic output** (`scripts/ci/collect_ci_baseline.mjs:467-484`):

```javascript
const options = args(process.argv.slice(2));
if (!options.repo) fail("--repo is required");
const validationContext = createRepositoryValidationContext({ expectedRepository: options.repo });
// Live collection is selected only after explicit required options are present.
const output = `${records
  .map((record) => JSON.stringify(validateRecord(record, validationContext)))
  .sort((left, right) => left.localeCompare(right))
  .join("\n")}\n`;
if (options.out) fs.writeFileSync(options.out, output); else process.stdout.write(output);
```

Apply this to a sanitised record that explicitly distinguishes local `main`, observed remote `main`, cached `origin/main`, the milestone branch, and the immutable v1.61 tag. Every remote fact needs `repository`, `observed_at`, full object SHA(s), the read-only command/API request that produced it, and an `available`/`unavailable` state; never silently substitute local state when GitHub is unavailable.

### `scripts/ci/render_repository_inventory.mjs` and `229-REPOSITORY-INVENTORY.md` (utility/documentation artifact, transform)

**Analog:** `scripts/ci/render_ci_baseline.mjs` (tracked)

Make Markdown a pure projection of the validated machine-readable source. Render the maintainer diagnostic in the required fact → state → owner → next command → immutable evidence order. Escape all interpolated Markdown and let the verifier byte-compare the rendered output; do not hand-edit it.

**Validation before rendering and escaping** (`scripts/ci/render_ci_baseline.mjs:7-15`):

```javascript
function escapeMarkdown(value) {
  return String(value)
    .replace(/[\\|`<>]/g, (char) => `\\${char}`)
    .replace(/[\r\n]+/g, " ");
}

export function renderBaseline(records, validationContext) {
  if (!Array.isArray(records)) throw new Error("records must be an array");
  records.forEach((record) => validateRecord(record, validationContext));
  // derive tables only from validated records
}
```

**Action-first report and reproducible commands** (`scripts/ci/render_ci_baseline.mjs:82-93`):

```javascript
return [
  "# CI Baseline", "", "## Current fact", "",
  `**State:** ${stagedConclusion}. **Owner:** CI maintainers. ` +
    "**Next command:** `node scripts/ci/verify_ci_baseline.mjs ...`.",
  "",
  "Privacy-safe, schema-v1 evidence. Raw logs, actors, branches, secrets, " +
    "payloads, and artifact contents are not persisted.",
  // deterministic, source-derived sections
].join("\n");
```

The Phase 229 renderer should additionally include exact restore commands for every preservation ref and bundle, hashes for each untracked artifact, and an explicit `unavailable` remote section when observation cannot be made. Do not put outside-repository bundle locations or user-owned untracked absolute paths in the committed rendering; use sanitized identifiers and a locally generated recovery manifest where needed.

### `scripts/ci/verify_repository_inventory.mjs` (test, transform)

**Analog:** `scripts/ci/verify_ci_baseline.mjs` (tracked)

Verify both schema invariants and byte reproducibility. Support fixture/self-test mode that exercises valid input plus a negative control (foreign repository, missing full SHA, unsanitized/forbidden field, nondeterministic render, and unavailable remote misreported as a fact). Use one asynchronous top-level failure boundary.

**Rendered-evidence byte check and CLI contract** (`scripts/ci/verify_ci_baseline.mjs:558-589`):

```javascript
const args = process.argv.slice(2);
const expectedRepository = args[args.indexOf("--expected-repository") + 1];
if (!expectedRepository) fail("--expected-repository is required");

const records = fs.readFileSync(source, "utf8").trim().split("\n")
  .filter(Boolean).map((line) => JSON.parse(line));
const expected = renderBaseline(records, validationContext);
assert.equal(fs.readFileSync(rendered, "utf8"), expected,
  "rendered Markdown must be byte-reproducible");

try { await main(); } catch (error) {
  console.error(`ci baseline fixtures: FAIL: ${error.message}`);
  process.exitCode = 1;
}
```

**Negative controls stay local and cleanup temporary data** (`scripts/ci/verify_ci_baseline.mjs:546-555`):

```javascript
try {
  // assert rejection of foreign or malformed evidence before a rendered file exists
  rejectsForbiddenFields(fixture, validationContext);
} finally {
  fs.rmSync(temp, { recursive: true, force: true });
}
```

### `scripts/ci/preserve_repository_state.sh` (utility, file-I/O)

**Analog:** `scripts/ci/preflight_phase227_candidate.sh` (tracked), partial match

There is no existing preservation-ref-plus-external-bundle implementation. Copy the analog's strict Bash parsing, exact SHA validation, repository-root resolution, temporary-resource cleanup, and independently checked Git object identity. Phase 229 must add its own requirement that the preservation refs and verified bundle are created *before* any fetch/ref refresh/manipulation, and that the bundle destination is outside the repository.

**Strict CLI parsing and exact object identity** (`scripts/ci/preflight_phase227_candidate.sh:1-21`):

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: $0 --commit <40-hex-sha> ..." >&2; exit 64; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit) commit="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done
[[ "$commit" =~ ^[0-9a-f]{40}$ ]] || {
  echo "commit must be a full lowercase 40-hex SHA" >&2; exit 64;
}
root="$(git rev-parse --show-toplevel)"
resolved="$(git -C "$root" rev-parse "${commit}^{commit}")"
[[ "$resolved" == "$commit" ]] || {
  echo "commit does not resolve exactly" >&2; exit 65;
}
```

**Cleanup trap and postcondition checking** (`scripts/ci/preflight_phase227_candidate.sh:22-32`):

```bash
scratch="$(mktemp -d "${TMPDIR:-/tmp}/phase227-preflight.XXXXXX")"
cleanup() {
  git -C "$root" worktree remove --force "$worktree" >/dev/null 2>&1 || true
  rmdir "$scratch" 2>/dev/null || true
}
trap cleanup EXIT
git -C "$root" worktree add --detach "$worktree" "$commit" >/dev/null
[[ "$(git -C "$worktree" rev-parse HEAD)" == "$commit" ]] || exit 65
[[ -z "$(git -C "$worktree" status --porcelain)" ]] || exit 65
```

For Phase 229, do **not** copy the analog's forced temporary-worktree removal as a cleanup policy for user worktrees. Limit removal to a newly-created private temp worktree, create collision-safe named local refs, run `git bundle verify` against the new external bundle, and emit restore commands plus object IDs. Hash untracked artifacts read-only before classification; never move, delete, add, or absorb them.

### `scripts/ci/ci_monitor.cjs` and `scripts/ci/watch_ci.sh` (utility/compatibility wrapper, request-response and streaming)

**Analogs:** `scripts/ci/collect_ci_baseline.mjs` (tracked) for repository-bound GitHub reads; `scripts/ci/watch_ci.sh` (tracked) for the compatibility command surface.

The monitor owns list, exact-SHA inspect, failure summary, and bounded watch. It must pass `-R szTheory/accrue` (or an equivalent validated `--repo`) on every `gh` operation, require a full SHA for exact inspection, print the SHA together with run/job failure details, and contain no dispatch/rerun/cancel/write operation. Watch must have an explicit poll/timeout bound rather than an unbounded `gh run watch` call.

**Existing compatibility surface to replace with delegation, not a second implementation** (`scripts/ci/watch_ci.sh:1-23`):

```bash
#!/usr/bin/env bash
set -euo pipefail

branch="${1:-main}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

if ! command -v gh >/dev/null 2>&1; then
  echo "watch_ci: gh CLI not found; install https://cli.github.com/" >&2
  exit 1
fi

run_id="$(gh run list --branch "$branch" --workflow CI --limit 1 \
  --json databaseId --jq '.[0].databaseId')"
gh run watch "$run_id" --exit-status
```

Replace its branch-only lookup with a thin `exec node scripts/ci/ci_monitor.cjs watch ...` wrapper that preserves a documented branch compatibility argument but routes into the exact-SHA-aware command. Never retain two separate GH-query implementations.

**Repository-bound GitHub request pattern** (`scripts/ci/collect_ci_baseline.mjs:423-462`):

```javascript
export async function liveRuns(repo, workflow, windowDays, { fetchPages } = {}) {
  const cutoff = new Date(Date.now() - windowDays * 86_400_000)
    .toISOString().slice(0, 10);
  const listed = (await fetchPages(
    `/repos/${repo}/actions/workflows/${workflow}/runs?per_page=100&created=>=${cutoff}`
  )).flatMap((page) => page.workflow_runs || []);
  // validate each run.head_sha as a full 40-hex SHA before emitting it
}
```

### `scripts/ci/README.md` (documentation, request-response)

**Analog:** `scripts/ci/README.md` Phase 226 evidence map and watcher note (tracked)

Extend this contributor entry point with one Phase 229 table row and a short command matrix: `list`, `inspect --sha FULL_SHA`, and bounded `watch --sha FULL_SHA`. State that each command is read-only, binds to `szTheory/accrue`, and that a green Actions conclusion is not live-provider proof.

**Evidence map and literal provider boundary** (`scripts/ci/README.md:3-23`):

```markdown
| Evidence | What it answers | Command |
| --- | --- | --- |
| [CI baseline](...) and [NDJSON record](...) | Which fixed workflow cohort was measured | `node scripts/ci/verify_ci_baseline.mjs ...` |

Provider triage is literal: `proved` means the selected suite executed ...;
`non_run` means a PR or push has no provider proof for that SHA.
```

**Existing watcher wording to supersede** (`scripts/ci/README.md:142`):

```markdown
**After a push:** from the repo root, **`bash scripts/ci/watch_ci.sh`** waits on
the latest GitHub Actions **CI** run for **`main`** (optional branch argument).
```

## Shared Patterns

### Repository identity and exact SHA

**Sources:** `scripts/ci/collect_ci_baseline.mjs:39-55, 423-462`; `scripts/ci/preflight_phase227_candidate.sh:14-21`

Apply to: inventory collector, verifier, preservation command, and monitor. Validate `owner/repository` and full 40-hex object IDs before they affect a record or an observation. Bind every claimed remote result to repository, timestamp, exact SHA, and the command/API query.

### Sanitized evidence plus deterministic rendering

**Sources:** `scripts/ci/render_ci_baseline.mjs:69-105`; `scripts/ci/verify_ci_baseline.mjs:558-589`

Apply to: Phase 229 source inventory and Markdown view. Source records are the authority; Markdown is regenerated and byte-compared. Persist immutable IDs/URLs and short bounded classifications, not raw GitHub payloads, local machine paths, untracked contents, logs, actors, or secrets.

### Literal CI and provider state

**Sources:** `scripts/ci/README.md:5-23`; `.github/workflows/ci.yml:1-24`

Apply to: inventory and monitor output. Keep `success`/`failure` Actions conclusion distinct from provider `proved`, `failed`, `misconfigured`, `blocked`, `skipped`, and `non_run`. A successful CI run alone never proves the provider lane.

### Read-only recovery boundary

**Source:** `scripts/ci/preflight_phase227_candidate.sh:18-32` (strict object/postcondition mechanics only)

Apply to: preservation workflow. The Phase 229 command may create local preservation refs and an external verified bundle, then inspect/fetch after those recovery points exist. It must not force-push, move tags, delete refs/files, alter user-owned artifacts, dispatch/rerun/cancel CI, or reconcile histories.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `scripts/ci/preserve_repository_state.sh` | utility | file-I/O | No tracked script creates named preservation refs, verifies an external git bundle, and inventories untracked artifacts without modifying them. Use the partial preflight mechanics above plus Phase 229's stricter non-destructive boundary. |

## Metadata

**Analog search scope:** `scripts/ci/`, `.github/workflows/`, `.planning/milestones/v1.61-phases/`  
**Files scanned:** 14  
**Pattern extraction date:** 2026-09-12
