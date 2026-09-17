# Phase 225: Required-Lane Signal Repair - Pattern Map

**Mapped:** 2026-08-08  
**Files analyzed:** 8  
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md` | documentation | transform | `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/192-VERIFICATION.md` | role-match |
| `accrue/test/accrue/webhook/ingest_test.exs` | test | CRUD | `accrue/test/accrue/webhook/ingest_test.exs` (existing assertions) | exact |
| `accrue_admin/e2e/admin-page-flow-phase191.spec.js` | test | request-response | `accrue_admin/e2e/admin-page-flow-phase200.spec.js` | role-match |
| `.github/workflows/ci.yml` | config | batch | its `admin-phase200-guardrails` artifact block | exact |
| `scripts/ci/verify_phase192_admin_guardrails.sh` | utility | batch | `scripts/ci/verify_phase200_admin_guardrails.sh` | role-match |
| `scripts/ci/verify_phase192_guardrail_contract.sh` | test | batch | `scripts/ci/verify_phase200_guardrail_contract.sh` | exact |
| `scripts/ci/verify_phase192_ci_contract.sh` | test | batch | `scripts/ci/verify_phase200_ci_contract.sh` | exact |
| `scripts/ci/README.md` | documentation | request-response | its contributor-map and triage sections | exact |

## Pattern Assignments

### `.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md` (documentation, transform)

**Analog:** `.planning/milestones/v1.53-phases/192-idempotent-verification-sign-off/192-VERIFICATION.md`

Use a compact front matter/status record, then a goal/evidence table and a command/result table. Keep binary/raw browser data out of Markdown; name artifacts and immutable evidence links instead. The Phase 192 record also separates verified facts from residual risk.

**Status and evidence shape** (lines 1-17, 27-35):

```markdown
---
phase: 192-idempotent-verification-sign-off
verified: 2026-06-20T14:30:00Z
status: passed
...
residual_risks:
  - "..."
---

## Goal Achievement

| # | Roadmap success criterion | Status | Evidence |
|---|---|---|---|
```

**Executable-proof shape** (lines 61-74):

```markdown
## Behavioral Evidence

| Command | Result | Notes |
|---|---|---|
| `bash scripts/ci/verify_phase192_admin_guardrails.sh` | PASS | ... |
```

For Phase 225, lead each normalized incident with `What failed`, `Classification`, `Next command`, and an immutable evidence link; then carry all D-01 fields. Include one webhook incident listing the three required matrix cells separately from advisory Sigra, and one Admin capacity/topology incident. Do not mark fresh-run evidence passed until it exists.

---

### `accrue/test/accrue/webhook/ingest_test.exs` (test, CRUD)

**Analog:** the same file’s setup/import contract plus `accrue/lib/accrue/webhook/ingest.ex`

Keep the established `RepoCase`, fixture, and direct `Ingest.run/4` test setup. Replace only suite-global observations with event-owned queries. The application’s persist query and `record_received_event/3` define the exact stable identities to assert.

**Test setup** (`accrue/test/accrue/webhook/ingest_test.exs:1-13`):

```elixir
defmodule Accrue.Webhook.IngestTest do
  use Accrue.RepoCase

  alias Accrue.Webhook.{Ingest, WebhookEvent}
  import Accrue.WebhookFixtures

  @processor :stripe
end
```

**Production identity query and duplicate branch** (`accrue/lib/accrue/webhook/ingest.ex:85-119`):

```elixir
from(w in WebhookEvent,
  where: w.processor == ^processor_str and w.processor_event_id == ^stripe_event.id,
  limit: 1
)

case existing do
  %WebhookEvent{} -> {:ok, {:duplicate, existing}}
  nil ->
    repo.insert(changeset,
      on_conflict: :nothing,
      conflict_target: [:processor, :processor_event_id]
    )
end
```

**Linked durable facts** (`accrue/lib/accrue/webhook/ingest.ex:54-60, 129-141`):

```elixir
with {:ok, _job} <- repo.insert(DispatchWorker.new(%{webhook_event_id: row.id})),
     {:ok, _event} <- record_received_event(processor_str, stripe_event, row) do
  {:ok, persisted}
end

Events.record(%{
  type: "webhook.received",
  subject_type: "WebhookEvent",
  subject_id: to_string(row.id),
  ...
})
```

Use `TestRepo.get_by!/2` for `(processor, processor_event_id)`, an `Oban.Job` query constrained by worker and `args["webhook_event_id"] == event.id`, and an event query constrained by `type` and `subject_id`. In the duplicate test, capture the first owned event/job IDs, run the duplicate, and prove that same identity has no second owned job/ledger write—never assert global table counts. Rename the current success-path “rollback” test unless a true deterministic failure seam is introduced.

---

### `accrue_admin/e2e/admin-page-flow-phase191.spec.js` (test, request-response)

**Analog:** `accrue_admin/e2e/admin-page-flow-phase200.spec.js`, with existing Phase 191 helpers

Make each deterministic partition a native, separately named Playwright test. Preserve reset/seed boundaries, helper reuse, `workers: 1`, and trace-on-failure. Per-viewport tests are the closest fit: each retains both themes and all `phase191PageFlows()` assertions but has a measured per-test budget.

**Existing overloaded traversal to partition** (`accrue_admin/e2e/admin-page-flow-phase191.spec.js:219-243`):

```javascript
test("... page flows avoid clipping ...", async ({ page, request }) => {
  test.setTimeout(60_000);
  await reset(request);
  const fixtureData = await seedPhase191Matrix(request);

  for (const viewport of PHASE191_VIEWPORTS) {
    await page.setViewportSize({ width: viewport.width, height: viewport.height });
    for (const theme of ["light", "dark"]) {
      for (const flow of phase191PageFlows()) {
        await login(page, resolvePhase191Route(flow, fixtureData));
        await setPhase191Theme(page, theme);
        // existing assertions
      }
    }
  }
});
```

**Fixture/test boundary to preserve** (`accrue_admin/e2e/admin-page-flow-phase200.spec.js:62-76`):

```javascript
test.describe("Phase 200 page-flow final evidence", () => {
  test("...", async ({ page, request }, testInfo) => {
    testInfo.setTimeout(180_000);
    const fixtures = await seedPhase200Fixtures(request);
    // one coherent reported unit owns setup and its traversal
  });
});
```

**Runner constraints** (`accrue_admin/playwright.config.js:6-29`):

```javascript
timeout: 30_000,
fullyParallel: false,
workers: 1,
use: { trace: "retain-on-failure", screenshot: "only-on-failure" },
```

---

### `.github/workflows/ci.yml` (config, batch)

**Analog:** `admin-hardening-guardrails` itself and Phase 200’s matching artifact contract.

Preserve the stable job ID/name, command order, release matrix, `fail-fast: false`, and `if: always()` Playwright uploads. Change only the generated-evidence producer/path to files that the repaired Phase 192 boundary actually emits, then update its contract verifier in the same plan slice.

**Required/advisory release semantics** (`.github/workflows/ci.yml:168-234`):

```yaml
release-gate:
  name: Release gate (...)${{ matrix.support == 'advisory' && ' [advisory]' || '' }}
  strategy:
    fail-fast: false
  # ... three support: 'required' cells and one support: 'advisory' Sigra cell
  continue-on-error: ${{ matrix.support == 'advisory' }}
```

**Artifact wiring shape** (`.github/workflows/ci.yml:675-705`):

```yaml
- name: Upload Phase 192 Playwright evidence
  if: always()
  uses: actions/upload-artifact@v7
  with:
    name: phase192-admin-playwright-evidence
    path: accrue_admin/test-results
    if-no-files-found: ignore

- name: Upload Phase 192 generated evidence
  if: always()
  uses: actions/upload-artifact@v7
  with:
    name: phase192-generated-evidence
    path: |
      # only actually-generated, privacy-safe Phase 192 files
    if-no-files-found: ignore
```

The closest structural companion is the Phase 200 job’s paired report/evidence/generated-evidence design at `.github/workflows/ci.yml:779-814`; do not adopt its Phase 200 artifact list wholesale.

---

### `scripts/ci/verify_phase192_admin_guardrails.sh` (utility, batch)

**Analog:** `scripts/ci/verify_phase200_admin_guardrails.sh`

Maintain the small `run_step` wrapper and fixed, explicit commands. If Phase 225 adds a real Phase 192 evidence producer, put it as a named narrow step here—not in an opaque shell loop or broad Playwright command.

**Runner pattern** (`scripts/ci/verify_phase200_admin_guardrails.sh:4-22`):

```bash
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

run_step() {
  local label="$1"
  shift
  echo "==> ${label}"
  (cd "$root_dir" && "$@")
}

run_step "Phase 200 page-flow final evidence" bash -c \
  "cd accrue_admin && env -u NO_COLOR npx playwright test e2e/admin-page-flow-phase200.spec.js --workers=1"
```

The existing Phase 192 runner at `:14-20` is the canonical command order to retain. Contract scripts deliberately prohibit broad `npm run e2e` / bare `playwright test` use.

---

### `scripts/ci/verify_phase192_guardrail_contract.sh` (test, batch)

**Analog:** `scripts/ci/verify_phase200_guardrail_contract.sh`

Keep contract checks declarative: resolve package script values, require each expected narrow command/file, and reject broad or evidence-capture additions to the deterministic guardrail lane. Add/update only the expectations made necessary by the Phase 192 producer/partition.

**Script-value and source guard pattern** (`scripts/ci/verify_phase200_guardrail_contract.sh:64-73, 96-104, 145-160`):

```bash
package_script_value() {
  local script_name="$1"
  node -e '... JSON.parse(fs.readFileSync(...)) ...' "$package_file" "$script_name" ||
    fail "missing package script: ${script_name}"
}

require_fixed "$runner_file" "cd accrue_admin && ... playwright test e2e/... --workers=1"

require_no_broad_playwright "${runner_file#$root_dir/}" "$runner_source"
```

---

### `scripts/ci/verify_phase192_ci_contract.sh` (test, batch)

**Analog:** `scripts/ci/verify_phase200_ci_contract.sh`

The CI contract is the guard against accidental changes to a stable job. Retain its `job_body` extraction and positive/negative checks; synchronize it with any intended workflow artifact-path change.

**Job-boundary and assertion pattern** (`scripts/ci/verify_phase192_ci_contract.sh:53-60, 78-125`):

```bash
job_body() {
  local job_id="$1"
  awk -v job_id="$job_id" '
    $0 == "  " job_id ":" { in_job = 1 }
    in_job && $0 ~ /^  [A-Za-z0-9_-]+:/ && $0 != "  " job_id ":" { exit }
    in_job { print }
  ' "$ci_file"
}

phase192_job="$(job_body "admin-hardening-guardrails")"
require_source_fixed "admin-hardening-guardrails job" "$phase192_job" "if: always()"
```

**Prohibition pattern** (`scripts/ci/verify_phase192_ci_contract.sh:127-137`):

```bash
for pattern in \
  'npm run e2e([[:space:]"'\'';&|]|$)' \
  'playwright test([[:space:]]+--|[[:space:]]*(["'\'';&|]|$))' \
  'trace[[:space:]_-]*capture|capture[[:space:]_-]*trace'
do
  require_source_absent_regex "admin-hardening-guardrails run commands" "$phase192_run_lines" "$pattern"
done
```

---

### `scripts/ci/README.md` (documentation, request-response)

**Analog:** `scripts/ci/README.md:1-30` and existing `### Triage:` sections.

Add a short Phase 225 triage section with the exact failing signature, classification, one narrow credential-free command, canonical repair surface, and evidence/artifact destination. Use the contributor-map voice: command first; tell maintainers to fix the named canonical artifact before loosening verifiers.

**Contributor-facing triage pattern** (`scripts/ci/README.md:3-30`):

```markdown
This directory hosts merge-adjacent bash gates ... Use it as the first stop when CI fails ...

```bash
bash scripts/ci/verify_release_contract.sh
```

When it fails, fix the artifact named in the failure: ...
```

## Shared Patterns

### Identity-scoped integration assertions

**Sources:** `accrue/test/support/repo_case.ex:21-33`; `accrue/lib/accrue/webhook/ingest.ex:85-141`  
**Apply to:** every repaired ingest assertion.

```elixir
setup tags do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Accrue.TestRepo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  :ok
end
```

Sandbox ownership isolates a connection, not assumptions that relevant tables have no unrelated rows. Query by the event’s persisted identity.

### CI contracts lock behavior, not just file presence

**Sources:** `scripts/ci/verify_phase192_ci_contract.sh:67-145`; `scripts/ci/verify_phase192_guardrail_contract.sh:47-118`  
**Apply to:** all workflow/runner artifact changes.

Contract verifiers must retain stable job identity, required command ordering and `if: always()` artifacts while rejecting broad suites, unapproved retries, or capture/signoff work in the guardrail lane.

### Trace-first Playwright evidence

**Sources:** `accrue_admin/playwright.config.js:19-29`; `.github/workflows/ci.yml:678-705`  
**Apply to:** the partitioned Phase 191 cases and the repaired artifact path.

```javascript
use: {
  baseURL,
  trace: "retain-on-failure",
  screenshot: "only-on-failure"
}
```

Keep reports/test-results as Actions artifacts. Checked-in Markdown should link the immutable run/job/artifact evidence without copying raw reports, logs, secrets, or user data.

## No Analog Found

None. The exact generated-evidence producer/path is intentionally unresolved until implementation inspects the existing Phase 192 generation tooling; use the Phase 200 producer + workflow + contract trio as the shape, but do not copy its artifacts as Phase 192 facts.

## Metadata

**Analog search scope:** `.planning/milestones/`, `accrue/test/accrue/webhook/`, `accrue/lib/accrue/webhook/`, `accrue_admin/e2e/`, `accrue_admin/playwright.config.js`, `scripts/ci/`, `.github/workflows/`  
**Files scanned:** 14  
**Pattern extraction date:** 2026-08-08
