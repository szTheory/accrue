# Phase 254: Recurring Quality, Reviewed Fixes and Curation - Pattern Map

**Mapped:** 2026-10-28
**Files analyzed:** 38 classification rows covering ~60 concrete new/modified files (grouped into 9 responsibility groups A-I)
**Analogs found:** 38 / 38 rows have a tracked analog (24 exact, 11 role-match, 3 partial); 5 sub-responsibilities inside those rows have no usable analog (see "No Analog Found")
**Tracked-source gate:** every analog path below was checked with `git ls-files -- <path>` (non-empty). The check was shown able to fail first: `git ls-files -- accrue_admin/tmp/phase253/manifest.json` printed nothing (gitignored, `.gitignore:36`) while `scripts/ci/phase252_paths.mjs` printed itself. No `accrue_admin/tmp/**`, `_build` or installed-mirror path is cited as an analog. Two installed-package paths appear only as non-analog evidence: Playwright's `node_modules/playwright/types/test.d.ts` (API existence) and `deps/phoenix_storybook/priv/static/css/phoenix_storybook.css` (the recompose script's input file, a gitignored dependency artifact). A mechanical pass over every backticked path in this file found no other untracked path except files this phase creates.

Line numbers were read this session. Re-grep before editing: the phase touches several files that other tasks in this same phase also edit.

## Findings the planner must absorb before reading the assignments

These are facts discovered while reading analogs. None is in CONTEXT.md; P1, P3 and P8 change plan content.

| # | Finding | Evidence | Consequence |
|---|---------|----------|-------------|
| P1 | The module-boundary guard contract is enforced in merge-blocking CI (`docs-contracts-shift-left`) and **the branch already fails it**. Live run: `node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage` printed `missing the shared module-boundary guard: generate_phase252_acceptance.mjs, generate_phase253_acceptance.mjs, phase252_paths.mjs, phase252_reporters.mjs, verify_phase252_production_boundary.mjs, verify_phase252_stories.mjs, verify_phase252_transparency.mjs, verify_phase253_compositions.mjs`. | `.github/workflows/ci.yml:490-492`; `scripts/ci/README.md:193`; `scripts/ci/verify_ci_script_contract.mjs:28` (cohort floor 68), `:35` (`LIBRARY_MODULE_ALLOWLIST`), `:128-187` (`assertGuardCoverage`), `:189-` (`assertNonVacuity`). | **Do not copy the Phase 252/253 entrypoint idiom** (`import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href`, e.g. `verify_phase253_compositions.mjs:1089`, `generate_phase253_acceptance.mjs:763`). Every NEW `scripts/ci/*.mjs` must use the conforming idiom in "Shared Pattern S1" (import `isMainModule`, assign inside `try/catch`, register at least one real `test()` under `NODE_TEST_CONTEXT`). A new library-only module (selector core, budget math) needs the same guard or a reasoned `LIBRARY_MODULE_ALLOWLIST` entry. The first D-25 push will surface the 8 pre-existing offenders as red; record them as a pre-existing deviation, do not fix them silently inside an unrelated plan. |
| P2 | `normalizeRepoPath` and `matchesRule` in `scripts/ci/phase252_paths.mjs` are module-private (`:110`, `:119`); only `classifyPath`, `assertOwnerMap`, `assertCiContract`, `CONSUMED_ROOTS`, `REQUIRED_OWNER` are exported. `classifyPath` returns `null` for **both** "unmapped" and "unsafe/traversal path" (`:137-147`). | `phase252_paths.mjs:110-147`. | D-09/D-10 selector must export `normalizeRepoPath` (edit is covered by the `phase252-path-classifier` root) and treat a `null` from normalization as FC-1 (`full`), never as "irrelevant". Keep `classifyPath`'s `null`-means-not-focused contract untouched for CIQ-01. |
| P3 | The literal `15` / `12` / `3` browser-row counts are pinned in **five** places, not the three named in D-39: `verify_phase252_stories.mjs:436,439`, `generate_phase252_acceptance.mjs:339,342,345`, **`phase252_reporters.mjs:342`** (`browserBindings`: `rows.length !== 15`, plus assertion ids `exact_twelve_canonical_width_theme_cells` / `three_compatibility_render_cases` at `:346-347,:419`), **`generate_phase252_acceptance.test.mjs:719`** (`/exactly 15\|omitted canonical cell/`), and `subscription_manifest_test.exs:454` (`length(entries) == 6`). | grep above. The e2e helper derives compatibility cases as "manifest entries whose `variation_id` is not in `CANONICAL_STATES`" (`phase252-story-helpers.js:103-114`), so retiring `populated` yields 14 cells with no helper edit. | The CURATE-01 literal amendment task must touch all five sites in one commit and keep `15/12/3` alive as a `frozen_baseline` fixture positive control. |
| P4 | `.gitignore` carries explicit per-phase `accrue_admin/tmp/phase25N/...` entries (`:30-38`). `accrue_admin/tmp/phase254/**` is **not** ignored (`git check-ignore -v accrue_admin/tmp/phase254/selection-x.json` printed nothing). | `.gitignore:30-38`. | Add `accrue_admin/tmp/phase254/` entries in the same style, or every local run leaves untracked files and D-11's `selection-<run_id>.json` risks being committed. CI upload steps are also explicit per phase (`ci.yml` after the Phase 252/253 "machine evidence" uploads): add a Phase 254 upload step, never widen the existing `path:` lists. |
| P5 | `E2E.Plug` cannot decide "review lane" today: `health_identity/2` builds its map with `Map.take(identity, [:nonce, :database, :role, :address, :port, :partition])` and drops `:lane` (`e2e_server.ex:216-221`), although `phase252_identity_from_env!` reads `PHASE252_E2E_LANE` (`:60`) and validates `env.lane in ["admin-test", "admin-review"]` (`:77`). | `accrue_admin/test/support/e2e_server.ex`. | D-13's 403 needs `:lane` added to the stored `:phase252_e2e_identity` (and to the `/health` payload `Map.take` list in `e2e_plug.ex:20-31` only if the lab health-identity check is updated in step; otherwise keep it internal). The legacy port-4017 server has no identity (`nil` branch, `e2e_server.ex:13-20`), so absence of identity must keep reset/seed allowed. |
| P6 | The new CIQ-03 visual spec runs on the **legacy** `mix accrue_admin.e2e.server` (port 4017); the lab refuses 4017 (`phase252_lab.mjs:55-56` "legacy admin E2E port ... is not accepted for a disposable lab"). The Phase 211 spec and `admin-visual-helpers.js` import reset/seed. | `phase252_lab.mjs:40-56`; `admin-visual-regression-phase211.spec.js:2-7`. | The new spec must define a local `login()` (one line) and must **not** import `support/admin-visual-helpers` (D-13 classifier would call it mounted). Verified-vs-inferred: that story routes render on the legacy server is still inferred (A4) - make the first task a positive-control probe. |
| P7 | The existing waits in the trap/keyboard probe are `waitForTimeout` (7 occurrences in `admin-interactions.spec.js`, at `:389,:404,:421,:438,:613,:629,:750`) and the probe rows are recorded, not asserted (`failure_kind` set at `:240,:281,:326,:431`, and `keyboard-flow-incomplete` near `:640`). | `admin-interactions.spec.js`. | D-29 journey is new code in this file but must use `expect.poll`, and the upgrade is "assert on the row's computed `inside`/`visible` value", not "read `recorder.rows` afterwards". |
| P8 | A full default Playwright run is **already broken** on this branch. `cd accrue_admin && npx playwright test --list --project=chromium-desktop` (no file filter) printed `Error: Phase 253 browser run has no owned launcher identity ... at subscription-compositions-phase253.spec.js:20` and `Total: 0 tests in 0 files`; the same command filtered to `e2e/admin-a11y.spec.js`, and `--project=visual-desktop`, list fine (positive controls). `phase252-review.spec.js` would also load under the default projects and expects `PHASE252_E2E_NONCE` health identity (`:12-21`). | `accrue_admin/playwright.config.js:42,47` (`testIgnore` lists only the Phase 211 and Phase 252-stories specs); `phase253-composition-helpers.js:72-76` (import-time throw via `readPhase253Manifest()`); `accrue_admin_browser.yml:94-95` runs `npm run e2e` before the visual gate at `:103-104`. | In `AccrueAdmin Browser UAT`, step `Run browser UAT` fails before `Phase 211 visual regression gate` ever runs, so CIQ-03's owner is masked (project memory: masked CI gates). Fixing `testIgnore` for both specs is a CIQ-03/F5 prerequisite and belongs in the first task that touches `playwright.config.js`; prove with the same `--list` command before and after, plus the project-ownership test (Group B). |

## File Classification

Role vocabulary: tool = Node CI verifier/library, config, test, spec (Playwright), model (Elixir manifest), middleware (Plug), data (generated or committed JSON), workflow.

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `scripts/ci/phase254_selection.mjs` (new) | tool | transform (git diff -> selection report) | `scripts/ci/phase252_paths.mjs` + `scripts/ci/verify_sensitive_token_census.mjs` (skeleton) | role-match |
| `scripts/ci/phase254_selection.test.mjs` (new) | test | request-response (fixture in/out) | `scripts/ci/verify_phase252_ci_contract.test.mjs` | exact |
| `scripts/ci/phase252_paths.mjs` (modify: export `normalizeRepoPath`, add roots) | tool | transform | itself | exact |
| `accrue_admin/storybook/phase254-selection.json` (new, generated) | data | batch (generate + diff-check) | `storybook/phase252-manifest.json` | exact |
| `accrue_admin/storybook/_support/subscription_manifest.ex` (modify: `depends_on`, projection, curation ledger, `caller_map`) | model | CRUD-free transform / generated JSON | itself (`source_digests/0`, `write!/1`, `verify!/1`, `caller_map/0`) | exact |
| `accrue_admin/storybook/_support/subscription_compositions_manifest.ex` (modify: `depends_on`) | model | transform | itself (`@source_paths`, `source_digests/0`, `write!/1`) | exact |
| `accrue_admin/test/support/e2e_plug.ex`, `e2e_server.ex` (modify: lane-aware 403) | middleware | request-response | itself (`post "/reset"`, `health_identity/2`) | exact |
| `accrue_admin/test/accrue_admin/e2e_plug_isolation_test.exs` (new) | test | request-response | `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs:172-177` | role-match |
| `scripts/dev/phase252_isolation.test.mjs` (extend) | test | request-response (two live lanes) | itself (`:203-232`) | exact |
| `scripts/ci/phase254_project_ownership.test.mjs` (new) | test (static contract) | transform (source scan) | `accrue_admin/e2e/verify-css-census.mjs` + `verify_phase252_ci_contract.test.mjs` | role-match |
| `accrue_admin/e2e/phase253-composition-helpers.js` (modify: per-case ledger, selection filter, a11y layer) | spec helper | file-I/O + event-driven | itself (`writeResults`, `appendResult`, `reconcileResults`) | exact |
| `accrue_admin/e2e/subscription-compositions-phase253.spec.js` (modify: dependent reconcile) | spec | request-response | itself | exact |
| `accrue_admin/playwright.phase252.config.js` (modify: dependent reconcile project) | config | n/a | `accrue_admin/playwright.config.js` (multi-project) | role-match |
| `.github/workflows/ci.yml`, `scripts/ci/verify_phase200_admin_guardrails.sh`, `.gitignore` (modify) | workflow/config | batch | `ci.yml:1036-1062` (base-sha diff), `verify_phase200_admin_guardrails.sh:23-24` | exact |
| `accrue_admin/e2e/subscription-visual-phase254.spec.js` (new) | spec | request-response (render + pixel diff) | `admin-visual-regression-phase211.spec.js` + `phase252-story-helpers.js:764-885` | role-match |
| `accrue_admin/playwright.config.js` (modify: `testIgnore` x2, `visual-desktop` `testMatch`) | config | n/a | itself (`:42,:47,:50-57`) | exact |
| `accrue_admin/e2e/visual-baseline-set.cjs` + `accrue_admin/test/js/visual_baseline_set_test.mjs` (modify) | tool + test | file-I/O | themselves | exact |
| `accrue_admin/e2e/__screenshots__/visual-desktop/manifest.json` (new) + 24 PNGs | data | batch | `storybook/phase252-manifest.json` (identity shape); 12 committed PNGs in the same folder | partial |
| `accrue_admin/e2e/admin-visual-regression-phase211.spec.js` (modify: duplicate `case`, geometry mask check) | spec | request-response | itself (`:62-72`, `:131-151`) | exact |
| `.github/workflows/accrue_admin_browser.yml` (modify) | workflow | batch | itself (`:4-17`, `:97-104`, `:129-197`) | exact |
| `scripts/ci/phase254_visual_contract.test.mjs` (new) | test (workflow mutation) | transform | `verify_phase252_ci_contract.test.mjs:74-100` | exact |
| `scripts/ci/phase252_reporters.mjs` (modify: keep per-test durations) | tool | transform | itself (`parsePlaywrightJson` `:286-323`) | exact |
| `scripts/ci/phase254_measure.mjs` (new; harness + fingerprint) | tool | batch / file-I/O | `verify_phase253_compositions.mjs` `spawnCaptured` (`:831-880`) | partial |
| `scripts/ci/phase254_budget.mjs` (+ `.test.mjs`) (new) | tool | transform | `scripts/ci/verify_ci_critical_path.mjs:151-167` + `render_ci_baseline.mjs:13` | role-match |
| `accrue_admin/storybook/phase254-budget.json` (new) | data | n/a | `.planning/milestones/v1.61-phases/227-measured-critical-path-improvement/227-ci-contract.json` (key shape) | partial |
| `accrue_admin/e2e/a11y-dispositions.json` + `scripts/ci/verify_a11y_dispositions.mjs` (+ test) (new) | data + tool | transform | `scripts/ci/verify_sensitive_token_census.mjs` (`:254-260`, scenarios) | role-match |
| `accrue_admin/e2e/foundation-tokens.spec.js` (modify: `parseColor` alpha) | spec | transform | itself (`:15-24`) | exact |
| `accrue_admin/e2e/admin-interactions.spec.js` (modify: keyboard journey) | spec | event-driven | itself (`focusCycleProbe` `:221-243`) + `admin-page-flow-phase191.spec.js:88-108,480-530` | role-match |
| `scripts/ci/recompose_storybook_css.mjs` (+ test) (new) | tool | file-I/O | `.planning/milestones/v1.57-phases/211-grep-gated-css-retirement-cross-surface-cleanup/211-03-PLAN.md:50` recipe + `accrue_admin/e2e/verify-css-census.mjs` (node-only self-test) | role-match |
| `accrue_admin/assets/css/app.css`, `priv/static/accrue_admin.css`, `priv/static/storybook.css` (modify) | config/style | n/a | themselves | exact |
| `accrue_admin/lib/accrue_admin/copy.ex`, `live/subscription_live.ex`, `storybook/_support/subscription_page_scenarios.ex` (modify) | model/utility | request-response | `copy.ex:1001`, `subscription_live.ex:2090-2125`, `subscription_page_scenarios.ex:180-195` | exact |
| New browser + ExUnit tests for UXQ-04 fixes, `254-*-red-evidence.json` | test + data | request-response | `foundation-tokens.spec.js`, `subscription_page_slice_test.exs:225-250` | role-match |
| `254-DESIGN-REVIEW.json` / `.md` + `scripts/ci/verify_phase254_design_review.mjs` (+ test) (new) | data + tool | transform | `generate_phase253_acceptance.mjs` (typed record -> generated view) + `phase_evidence_path.mjs` | role-match |
| `accrue_admin/storybook/subscription-curation.json` (new, generated) + `scripts/ci/verify_phase254_curation.mjs` (+ test) (new) | data + tool | batch / transform | `storybook/phase252-manifest.json` + `verify_phase252_stories.mjs:169-187` (regenerate-and-compare) | exact |
| `dev_support/ui_scenarios/cadence_subscriptions.exs`, `storybook/components/subscription_detail.story.exs`, `storybook/components/action_menu.story.exs` (modify) | model/story | transform | themselves | exact |
| Five pinned-literal sites (P3) and `subscription_manifest_test.exs:418,454` (modify) | tool + test | transform | themselves | exact |
| `guides/subscription-story-coverage.md` (regenerated, do not rename) | docs (generated) | batch | `SubscriptionManifest.coverage_guide/0` | exact |
| `scripts/ci/generate_phase254_acceptance.mjs` (+ test) (new) | tool | batch | `scripts/ci/generate_phase253_acceptance.mjs` + `.test.mjs` | exact |

## Pattern Assignments

### Group A - CIQ-02 transparent, fail-closed selection

#### `scripts/ci/phase254_selection.mjs` (tool, transform)

**Analogs:** `scripts/ci/phase252_paths.mjs` (classifier), `scripts/ci/verify_sensitive_token_census.mjs` (module skeleton + scenarios + scratch git repo), `scripts/ci/render_provider_summary.mjs:9-19` (summary escaping), `.github/workflows/ci.yml:1036-1062` (base-sha diff in CI).

**Classifier to extend** (`phase252_paths.mjs:110-147`). Reuse as-is; export `normalizeRepoPath` (P2):
```js
function normalizeRepoPath(value) {
  if (typeof value !== "string" || value.length === 0 || value.includes("\0")) return null;
  const normalized = value.replaceAll("\\", "/");
  if (normalized.startsWith("/") || /^[A-Za-z]:\//.test(normalized)) return null;
  const segments = normalized.split("/");
  if (segments.some((segment) => segment === ".." || segment === "." || segment === "")) return null;
  return segments.join("/");
}
export function classifyPath(value, { roots = CONSUMED_ROOTS, manifest } = {}) {
  const repoPath = normalizeRepoPath(value);
  if (!repoPath) return null;
  if (roots.some((rule) => rule.owner === REQUIRED_OWNER && matchesRule(repoPath, rule))) return REQUIRED_OWNER;
  if (manifestSourcePaths(manifest).some((source) => normalizeRepoPath(source) === repoPath)) return REQUIRED_OWNER;
  return null;
}
```
A consumed-root entry is `{ id, path, mode: "exact"|"prefix", owner }` (`:53-104`); every new id must also be appended to `REQUIRED_ROOT_IDS` (`:3-51`) or `assertOwnerMap` (`:149-173`) does not require it.

**Existing base-SHA diff precedent** (`ci.yml:1036-1062`) - shows the FC-3 shape (workflow_dispatch / zero or empty `from_sha` -> relevant=true) but uses `--name-only`; the selector must use `--name-status --no-renames` (D-10):
```bash
from_sha="$BEFORE_SHA"
if [ "$GITHUB_EVENT_NAME" = "pull_request" ] && [ -n "$BASE_SHA" ]; then from_sha="$BASE_SHA"; fi
if [ -z "$from_sha" ] || printf '%s' "$from_sha" | grep -Eq '^0+$'; then relevant=true
else git diff --name-only "$from_sha" "$GITHUB_SHA" > /tmp/phase190-changed-files.txt
```
`admin-phase200-guardrails` (`ci.yml:1242-1263`) checks out with default depth 1 and has `if: github.event_name != 'schedule'`; the job at `ci.yml:1035` and `:82,:108` already use `with: fetch-depth: 0`. Copy that `with:` block for the guardrail job (Pitfall 4 in RESEARCH).

**Report rendering - hostile-path escaping** (`render_provider_summary.mjs:9-19`); copy verbatim, then add a hostile-path fixture (`|`, backtick, `$(...)`, `::error::`, newline) to the self-test (RESEARCH Pitfall 10):
```js
function escapeMarkdown(value) {
  return String(value ?? "not recorded")
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/`/g, "&#96;")
    .replace(/[\\*_#[\]|]/g, (character) => `&#${character.codePointAt(0)};`)
    .replace(/:/g, "&#58;").replace(/[\r\n]/g, " ").replace(/[\u0000-\u001F\u007F]/g, "");
}
```
Output goes through `fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, ...)` (precedent `ci.yml:1515`).

**Module skeleton + self-test dispatch**: use Shared Pattern S1 (census `:374`, `:525-528`, `:575-590`). Fixtures that need a real repo (shallow clone, missing base, rename/delete old path, push event) use the census `withScratchRepo` pattern (`verify_sensitive_token_census.mjs:335-353`):
```js
function withScratchRepo(fn) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "gsd-token-census-"));
  try { spawnSync("git", ["-C", dir, "init", "-q"], { encoding: "utf8" }); /* ... */ return fn(dir); }
  finally { fs.rmSync(dir, { recursive: true, force: true }); }
}
function seed(dir, relativePath, content) {
  const absolute = path.join(dir, relativePath);
  fs.mkdirSync(path.dirname(absolute), { recursive: true });
  fs.writeFileSync(absolute, content);
  spawnSync("git", ["-C", dir, "add", "-A"], { encoding: "utf8" });
}
```
Never exercise git behavior in the live tree (CLAUDE.md working discipline); use `mktemp -d` repos only.

**Invariant helper idiom** (`verify_phase253_compositions.mjs:196-200`; `phase252_reporters.mjs:187-193` has the same `exactSet`):
```js
function exactSet(actual, expected, label) {
  const left = uniqueSorted(actual); const right = uniqueSorted(expected);
  if (left.length !== actual.length || right.length !== expected.length || JSON.stringify(left) !== JSON.stringify(right)) {
    fail(label + " mismatch; expected " + right.length + " unique values and received " + left.length);
  }
}
```
Use it for D-11 invariants: `selected ∩ excluded = ∅`, `selected ∪ excluded = total`, `selected ⊇ sentinels`, `depends_on ⊆ source_digests`.

**Test file** `phase254_selection.test.mjs`: follow `verify_phase252_ci_contract.test.mjs:53-72` (`classifyPath(representative, { manifest }) === REQUIRED_OWNER` for every root, `docs/architecture/unrelated.md -> null`) and `:121-155` (parametrized "removal must fail" negative controls). D-14 required controls map one-to-one onto named `test(...)` titles.

#### `accrue_admin/storybook/phase254-selection.json` + `depends_on` generation (data/model)

**Analog:** `storybook/phase252-manifest.json` (keys `schema_version`, `source_digests` 12 paths, `entries[]`) and the generate-and-compare lane `verify_phase252_stories.mjs:169-187`:
```js
export function manifestFreshnessCode() { return [
  '{:ok, _started} = Application.ensure_all_started(:localize)',
  "alias AccrueAdmin.Storybook.SubscriptionManifest",
  'temp = Path.join(System.tmp_dir!(), "phase252-manifest-current-#{System.unique_integer([:positive])}.json")',
  "try do",
  "  :ok = SubscriptionManifest.write!(temp)",
  "  generated = File.read!(temp)",
  '  checked_in = File.read!(Path.expand("../storybook/phase252-manifest.json", File.cwd!()))',
  '  if Jason.decode!(generated) != Jason.decode!(checked_in), do: raise("checked-in phase252 manifest is stale; ...")',
  ...
```
Copy this for the selection projection and for `subscription-curation.json` (D-37). It compares decoded JSON, not bytes (test `verify_phase252_ci_contract.test.mjs:210` pins "without serializer key-order noise").

**Elixir side:** add `depends_on` where each entry map is built - `SubscriptionManifest.entry!/4` (`subscription_manifest.ex:654-670`, the `%{key:, story_path:, ... expected: ...}` literal) and the Phase 253 `collection_variation_entry!/…` (`subscription_compositions_manifest.ex:477`) and `page_entry!/…` (`:564`). Constrain `depends_on` to keys of that module's own `source_digests/0` (`subscription_manifest.ex:113-128`, `subscription_compositions_manifest.ex:287-302`); enforce `⊆` in `verify!/1` next to the existing digest checks (`subscription_manifest.ex:146-168`, `subscription_compositions_manifest.ex:326-371`):
```elixir
unless manifest["source_digests"] == source_digests() do
  raise ArgumentError, "subscription manifest source digest is stale"
end
```
Today detail has 12 and collection/page has 11 `@source_paths` (`subscription_compositions_manifest.ex:19-31`); precision is group-level by construction, so most CSS/admin diffs go `full` (D-09 accepts this).

**Where it is consumed:** the Phase 253 compositions manifest is gitignored (`.gitignore:36`) and written at run time, so the **tracked** projection is what CI selectors and the visual spec read (RESEARCH F1). `accrue_admin/storybook/*.json` is not under any `CONSUMED_ROOTS` rule (only `accrue_admin/storybook/_support/` is, `phase252_paths.mjs:56`); add a root such as `{ id: "phase254-selection-projection", path: "accrue_admin/storybook/", mode: "prefix", owner }` plus the ids to `REQUIRED_ROOT_IDS`.

---

### Group B - Pure-story isolation and per-case ledger

#### `accrue_admin/test/support/e2e_plug.ex` + `e2e_server.ex` (middleware, request-response)

**Analog:** the same files. Reset/seed live at `e2e_plug.ex:60-63` (`post "/reset"`), `:125-128` (`post "/__e2e__/reset"`), and every `post "/seed/..."` / `"/__e2e__/seed/..."` route `:65-123,:151-161`. `/phase240/*` mutators (`:130-149`) are also state-changing: decide explicitly whether they are in the 403 set (they are mounted-only). `get "/health"` reads the identity (`:14-40`).

Lane is **not** retained (P5):
```elixir
# e2e_server.ex:216-221
defp health_identity(identity, ready?) do
  identity
  |> Map.take([:nonce, :database, :role, :address, :port, :partition])
  |> Map.put(:pid, String.to_integer(System.pid()))
  |> Map.put(:ready, ready?)
end
```
Add `:lane` to the `Map.take` list so `Application.get_env(:accrue_admin, :phase252_e2e_identity)` carries it; keep the `nil`-identity branch (`e2e_server.ex:13-20`, legacy port 4017) permissive. Implement the refusal once as a plug function used by every reset/seed route (do not duplicate 20 clauses): a `plug :refuse_in_review_lane` ahead of `plug(:match)` that matches `conn.method == "POST"` and a reset/seed path set derived from the route list.

**ExUnit analog** (`accrue_admin/test/accrue_admin/e2e_fixtures_test.exs:172-177`):
```elixir
test "POST /__e2e__/seed/edge-states returns 200" do
  conn = Plug.Test.conn(:post, "/__e2e__/seed/edge-states") |> AccrueAdmin.E2E.Plug.call([])
  assert conn.status == 200, "Expected 200 from POST /__e2e__/seed/edge-states, got #{conn.status}"
end
```
New `e2e_plug_isolation_test.exs`: `Application.put_env(:accrue_admin, :phase252_e2e_identity, %{lane: "admin-review", ...})` -> every reset/seed variant returns 403 and a marker row is unchanged; `lane: "admin-test"` -> 200 (positive control); restore env in `on_exit`.

**Two-live-server proof** (extend `scripts/dev/phase252_isolation.test.mjs:203-232`). Existing test already boots `admin-review` and `admin-test` sessions (`:162-201`) and uses `insertMarker`/`markerSnapshot`:
```js
const reset = await fetch(`http://127.0.0.1:${normal.config.port}/__e2e__/reset`, { method: "POST" });
assert.equal(reset.status, 200, "the ordinary test server should accept its real reset route");
...
assert.equal(reviewAfter, reviewBefore, "negative control: the review customer ... must reload byte-for-byte unchanged");
```
Add: `fetch(review.port ... /__e2e__/reset, POST)` -> `403` with `reviewMarker` snapshot unchanged, in the same test so positive and negative controls share one boot.

#### `scripts/ci/phase254_project_ownership.test.mjs` (static contract)

**Analog (static source scan with in-memory self-test):** `accrue_admin/e2e/verify-css-census.mjs:221-295` (`runSelfTest` with named `check(...)` pairs and a trailing `process.exit(1)` on failure) and the exact-token lookaround at its head. Mounted specs define local `reset`/`seed` that POST to `"/__e2e__/reset"` / `` `/__e2e__/seed/${...}` `` (`admin-a11y.spec.js:4-12`, `admin-interactions.spec.js:31-39`, `admin-page-flow-phase191.spec.js:84,111`) or import `./support/admin-visual-helpers` (`admin-visual-regression-phase211.spec.js:2-7`). The classifier therefore matches `/__e2e__/(reset|seed)` and the helper import. Pure-story specs today contain neither (`grep reset|seed` over `phase253-composition-helpers.js`, `subscription-compositions-phase253.spec.js`, `phase252-story-helpers.js` only hits "Reset filters" text at `phase253-composition-helpers.js:865-867`) - the positive control **must** be a seeded fixture string, and a known-pure spec must be shown to pass.
Also assert every `accrue_admin/e2e/*.spec.js` belongs to exactly one project: the default projects exclude specs via `testIgnore` (`playwright.config.js:42,:47`), `visual-desktop` via `testMatch` (`:55`), and the lab project via `testMatch` (`playwright.phase252.config.js:28,:47`) (RESEARCH F5).

#### `accrue_admin/e2e/phase253-composition-helpers.js` per-case ledger (spec helper, file-I/O)

**Analog:** itself. Today one shared JSON file is read-modify-written (`:390-400`):
```js
function appendResult(filePath, runId, manifestDigest, row) {
  if (!fs.existsSync(filePath)) throw new Error("Phase 253 current-run result ledger was not initialized");
  const results = JSON.parse(fs.readFileSync(filePath, "utf8"));
  if (results.run_id !== runId || results.manifest_sha256 !== manifestDigest) { throw ... }
  const existing = results.cases.findIndex((candidate) => candidate.key === row.key);
  if (existing === -1) results.cases.push(row); else results.cases[existing] = row;
  writeResults(filePath, results);
}
```
Atomic write already exists (`:358-362`): temp file `${filePath}.${process.pid}.tmp` + `fs.renameSync`. New design: one `<results-dir>/<sanitized-key>.json` per case via that same temp+rename; merge in a dependent reconcile project. Keep `reconcileResults` (`:409-444`) semantics: missing/duplicate/unexpected key checks, `row.status !== "passed"`, manifest/run identity, `served_assets.verified`. Change only what "expected" means (selected set) and keep full mode literally 151. The race positive control: a simulated interleaved write against the **old** `appendResult` loses a row; against the new layout it does not (D-14). Keep `beginCollectionResults` idempotency (`:369-376`).

Case universe to bind selection by ID (never `--grep` on titles): `createExpectedBrowserCellDefinitions` (`:295-331`) and the `key` field of every case (`${entry.key}::${width}::${theme}`, `...::synthetic-text::320::<theme>`, `geometry::negative-controls::320::light`).

#### `accrue_admin/playwright.phase252.config.js` (config)

**Analog:** itself (`workers: 1`, `fullyParallel: false`, one project `phase252-owned-review`, `reuseExistingServer: false`, launcher via `phase252_lab.mjs serve --lane admin-review`) and the multi-project shape in `playwright.config.js:36-58`. Verified API in the installed types: project-level `dependencies?: Array<string>` (`node_modules/playwright/types/test.d.ts:172`), `workers?` (`:742`), `shard` (`:1651`). The reconcile test becomes its own project with `dependencies: ["phase252-owned-review"]` and must live in the explicit `testMatch` regex (`:28,:47`). Do not enable multi-worker fan-out for the mounted lane (D-13); RESEARCH F7 shows per-cell cost is ~0.29 s so fan-out is not needed unless D-24 attribution says so.

---

### Group C - CIQ-03 deterministic Linux visual baselines

#### `accrue_admin/e2e/subscription-visual-phase254.spec.js` (spec, request-response)

**Analogs:** Phase 211 owner for the screenshot call + mask contract; `phase252-story-helpers.js:764-885` for the story-route boot, fonts, theme; `phase253-composition-helpers.js:512-556` for `setTheme` and served-asset verification.

**Screenshot call and options** (`admin-visual-regression-phase211.spec.js:237-242`); new cases add `maxDiffPixels: 0` and an **empty** mask list (D-17/D-19):
```js
await expect(page).toHaveScreenshot(file, { fullPage, animations: "disabled", mask: masks, maskColor: "#FF00FF" });
```
Config defaults stay untouched (`playwright.config.js:13-21`: `threshold: 0.2`, `maxDiffPixelRatio: 0.01`, `animations: "disabled"`, `caret: "hide"`, `scale: "css"`); `snapshotPathTemplate: "e2e/__screenshots__/{projectName}/{arg}{ext}"` (`:21`) has no `{platform}` token.

**Story-route boot + fonts + theme assertions** (`phase252-story-helpers.js:804-831`):
```js
await page.setViewportSize({ width, height: 900 });
await page.emulateMedia({ colorScheme: theme, reducedMotion: "reduce" });
await page.goto(`/__e2e__/login?to=${encodeURIComponent(route)}`);
await expect.poll(() => { const current = new URL(page.url()); return `${current.pathname}${current.search}`; }).toBe(route);
...
const fonts = await page.evaluate(() => ({ status: document.fonts.status,
  sans: document.fonts.check('400 16px "Geist"'), mono: document.fonts.check('400 12px "Geist Mono"') }));
expect(fonts, "...").toMatchObject({ status: "loaded", sans: true, mono: true });
```
D-17 asks for a stricter FontFace `status === "loaded"` check per face plus served woff2 sha256 (the woff2 files are tracked: `accrue_admin/priv/static/fonts/geist-sans-vf.woff2`, `geist-mono-vf.woff2`).

**Theme + served-asset identity** (`phase253-composition-helpers.js:512-556`; copy, and add woff2 to the hash set):
```js
async function setTheme(story, theme) {
  await story.evaluate((sandbox, selectedTheme) => {
    sandbox.classList.add("accrue-admin");
    sandbox.classList.toggle("ax-theme-dark-shim", selectedTheme === "dark");
  }, theme);
  await story.evaluate(async () => { if (document.fonts?.ready) await document.fonts.ready; await Promise.all([...document.images].map((image) => image.decode().catch(() => undefined))); });
}
// serveAndVerifyAssets: finds `storybook-css-` / `storybook-js-` hrefs, GETs them, then
if (sha256(servedCss) !== sha256(expectedCss) || sha256(servedJs) !== sha256(expectedJs)) throw new Error("served Storybook assets differ from the current compiled files");
```
`RESEARCH` Code Examples give the determinism setup (`page.clock.setFixedTime("2026-10-25T12:00:00Z")` before `goto`; `@now ~U[2026-10-25 12:00:00Z]` at `dev_support/ui_scenarios/cadence_subscriptions.exs:4`). The matrix (D-16) is 6 variations x {320,1280} x {light,dark} = 24, keyed from the tracked projection (Group A), not the gitignored manifest (P6/F1; the `visual-desktop` job has no launcher `RUN_ID`, see `phase253-composition-helpers.js:72-75`).

Split the spec into `prepareDeterministicCase()` (assertions runnable in the lab browser lane on macOS) and the Linux-only screenshot assertion (RESEARCH Open Question 4). Do not add an env flag that disables the screenshot.

**Do not** import `support/admin-visual-helpers` (P6). Define:
```js
async function login(page, target) { await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`); }
```

#### `accrue_admin/playwright.config.js` (config)

Edit points (read): both default projects carry the same exclusion and must gain the new spec, otherwise `npm run e2e` runs it on desktop and Pixel 5 and fails on missing baselines (F5):
```js
// :42 and :47
testIgnore: [/admin-visual-regression-phase211\.spec\.js/, /subscription-stories-phase252\.spec\.js/],
// :54-56
name: "visual-desktop",
testMatch: /admin-visual-regression-phase211\.spec\.js/,
```
New `testMatch` must be an alternation regex covering both visual specs. **Verified pre-existing break (P8):** `subscription-compositions-phase253.spec.js` and `phase252-review.spec.js` are not in either `testIgnore` list, so a full default run loads them; add both to both lists in the same edit.

#### `accrue_admin/e2e/visual-baseline-set.cjs` + `accrue_admin/test/js/visual_baseline_set_test.mjs` (tool + test, file-I/O)

**Analog:** itself. Today the guard only detects missing files (`visual-baseline-set.cjs:19-28`):
```js
function checkBaselineSet(directory) {
  const missing = EXPECTED_BASELINES.filter((name) => { try { return !fs.statSync(path.join(directory, name)).isFile(); } catch { return true; } });
  return { expected: EXPECTED_BASELINES, missing };
}
```
D-18 needs: PNG set === manifest keys (missing **and extra**), per-key sha256, case key, served css/js/font sha, scenario-file sha, Playwright + `browser.version()`, mint `github.sha`/`run_id`, reason, finding id. Keep CommonJS (the Phase 211 spec and the workflow call `node accrue_admin/e2e/visual-baseline-set.cjs <dir>`, `accrue_admin_browser.yml:101`) and keep the exported `EXPECTED_BASELINES`/`checkBaselineSet` names because the test imports them via `createRequire` (`visual_baseline_set_test.mjs:9-11`). Test style to extend: `withBaselineDirectory` temp dir + `spawnSync(process.execPath, [validator, directory])`, and one parametrized `test(\`partial set fails when ${omitted} is absent\`)` per name (`:74-85`). Add the symmetric extra-file control and a byte-mismatch control. This test runs in CI via `cd accrue_admin && node --test test/js/*.mjs` (`accrue_admin_browser.yml:97-98`).

#### `accrue_admin/e2e/admin-visual-regression-phase211.spec.js` (modify)

Fix the duplicate `case "invoices":` (`:62` returns `[]`; `:67` falls through the shared `component-kitchen`/`invoices`/`invoice-detail` group) and replace the regex protected-facts check (`:131-151`, `protectedFacts = [["identity", /customer|invoice|.../i], ...]` matched against masked **text**) with the geometry check from D-19. Its structure to preserve: `maskLocators` returns `page.locator("[data-ax-visual-timestamp-mask]").all()` (`:128`). The 12 existing baselines must not change in this task (D-06).

#### `.github/workflows/accrue_admin_browser.yml` (workflow)

Read-verified edit points: trigger paths (`:4-17`: only `accrue/**`, `accrue_admin/**`, itself; add `storybook/**`, `dev_support/ui_scenarios/**`, `brandbook/tokens/**`, `scripts/ci/phase254_*`, F3); guard + gate steps (`:97-104`); mint job `if: github.event_name == 'workflow_dispatch'` (`:131`), mint command (`:188-189`):
```yaml
- name: Mint visual baselines
  run: cd accrue_admin && npm run e2e:visual-regression -- --update-snapshots
- name: Upload minted baselines
  if: always()
```
Change to `--update-snapshots=changed` and `if: success()` (D-20). `verify_ci_efficiency_contract.mjs` scopes this workflow (`SCOPED_WORKFLOWS`, `:66`) - run it after editing. Top of file comment documents the concurrency shape the efficiency contract pins (`:19-27`); do not alter it.

#### `scripts/ci/phase254_visual_contract.test.mjs` (workflow mutation test)

**Analog (exact):** `verify_phase252_ci_contract.test.mjs:74-100` - read the workflow into a string, `.replace(...)` a line to a mutated form, `assert.throws(...)` on the contract function, and finish with `assert.doesNotThrow` on the real file. Mutations: add `--update-snapshots` to the non-mint job; remove `=changed`; change `if: success()` to `if: always()`; widen `threshold`/`maxDiffPixelRatio` in `playwright.config.js`; add `stylePath`; add `retries`.

---

### Group D - CIQ-04 measurement and frozen budget

#### `scripts/ci/phase252_reporters.mjs` (modify, keep rejection logic)

`parsePlaywrightJson` discards durations (`:303-322`):
```js
for (const test of spec.tests || []) {
  if (test.expectedStatus !== "passed" || !Array.isArray(test.results) || test.results.length !== 1 || test.results[0]?.status !== "passed") {
    fail(`browser test is failed, skipped, retried, or missing a result: ...`);
  }
  tests.push({ identity: test.title || spec.title, status: test.results[0].status });   // :311 - add duration: test.results[0].duration
}
...
return { identities, count: tests.length, skipped: 0, failed: 0 };                    // :322 - add durations
```
Keep every `fail(...)`; the summary guard `report.stats.expected/unexpected/skipped/flaky` (`:295-302`) is the D-23 "any skip/retry/flaky" rule. Return durations as a **new** field so `deriveExecutionEvidence` (`:376-411`) consumers (`verify_phase253_compositions.mjs`, `generate_phase252_acceptance.mjs`) are unaffected. `phase252_reporters.mjs` has no CLI (library); it still needs the guard or an allowlist per P1.

Per-lane wall-clock already exists in `verify_phase253_compositions.mjs:865`:
```js
duration_ms: Date.now() - start,
```
(set in `spawnCaptured`, `:831-880`) and the local results bundles; use these shapes, not new timers.

#### `scripts/ci/phase254_budget.mjs` (+ test) (tool, transform)

**Analog:** `scripts/ci/verify_ci_critical_path.mjs:151-167` (n = exactly 3 first-attempt observations, unique run IDs, one SHA, median vs threshold, per-observation ceiling with a substantiated `external_anomaly` escape, negative control must be present) and the contract JSON shape of `.planning/milestones/v1.61-phases/227-measured-critical-path-improvement/227-ci-contract.json` (keys: `schema_version`, `thresholds{keep_median_seconds,maximum_observation_seconds}`, `run_budget{final_candidate_attempts:3,allow_reruns:false,allow_replacements:false}`, `failure_classes`, `measurement_topology`, `proof_vector`). Percentile helper to copy (`render_ci_baseline.mjs:13`, nearest-rank):
```js
function percentile(values, fraction) { const ordered = [...values].sort((left, right) => left - right); return ordered[Math.ceil(fraction * ordered.length) - 1]; }
```
The 227 contract is read through the archive-aware resolver (`verify_ci_critical_path.mjs:13-14`: `resolvePhaseEvidencePath(PHASE_227, "227-ci-contract.json")`). The Phase 254 budget does the opposite on purpose: **tracked package path** `accrue_admin/storybook/phase254-budget.json` read directly (D-04), so milestone archival cannot break it. Add a `CONSUMED_ROOTS` entry. Never let CI rewrite it (D-23); the verifier is read-only and `--self-test` proves: identity-set mismatch, count drop without a CURATE-01 record id, skip/retry/flaky, digest != manifest, missing fingerprint/summary, ceiling exceeded -> fail; above `warn_at` -> `::warning` only (positive control: p90 x 1.25 boundary on both sides).

Warning emission: `::warning` workflow commands built from user-influenced strings need command-syntax escaping (`%`, CR, LF, and `:` / `,` inside properties) in addition to S4's Markdown escaping; give the renderer its own hostile-input fixture.

#### `scripts/ci/phase254_measure.mjs` (harness, partial analog)

No fingerprint helper exists (`git grep os.cpus|os.totalmem|os.arch` in `scripts` and `accrue_admin/e2e` returned nothing). Build from `spawnCaptured` (`verify_phase253_compositions.mjs:831-880`), `gitRevision` (`:910-914`), and the cold-start recipe `mixBuildPath(runId)` (`:243-246`, `os.tmpdir()/accrue-phase253-<user>/<runId>/mix-build/accrue-admin`), which is already an empty build path per run. Fingerprint field allow-list only (OS/arch/CPU model/cores/RAM, `ImageOS`, `ImageVersion`, OTP/Elixir/Node/Playwright versions, workers, source revision, manifest sha, dirty flag) - never dump `process.env` (Security Domain, Secrets in fingerprints). The `dirty` flag must come from `git status --porcelain` and a dirty sample is rejected for `frozen` metrics.

---

### Group E - UXQ-02 accessibility layer

#### Per-cell axe + deep probes in `phase253-composition-helpers.js` (spec helper)

**Axe invocation analog** (`admin-a11y.spec.js:21-28`) - copy the `AxeBuilder` + `withTags` call, **not** the filter:
```js
const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");   // :27 - the broad suppression D-27 forbids
```
Phase 200 storybook scan uses `.include(".psb-sandbox")` and the same filter (`admin-storybook-a11y-phase200.spec.js:42-52`); failure detail formatter to reuse: `phase200-storybook-helpers.js:132-147` (`axeFailureDetails`). New: tags `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa` (the `target-size` rule is `enabled:false` by default and only runs under `wcag22aa`, RESEARCH Standard Stack), no impact filter, and `results.incomplete` routed through the register too. Settled theme: `setTheme` (`phase253-composition-helpers.js:512-521`) for direct story cells.

**Contrast alpha defect to fix first** (`foundation-tokens.spec.js:15-24`):
```js
function parseColor(value) {
  const match = value.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([0-9.]+))?\)/);
  if (match) return match.slice(1, 4).map(Number);   // alpha (group 4) dropped
  const srgb = value.match(/color\(srgb\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/i);   // also drops "/ a"
```
Fix = composite over the actual background stack, with a positive control (translucent foreground that fails only when alpha is honored). Same file hosts `relativeLuminance` / `contrastRatio` (`:27-40`) - reuse them for the focus-ring >= 3:1 check.

**Not-obscured / top-element probe** (`admin-interactions.spec.js:131-144`, `topElementAt` using `document.elementFromPoint`) - the 2.4.11 probe analog; the hidden mirrors that axe must never target are `data-role="*-drawer-test-mirror"` (`charge_live.ex:362`, `customer_live.ex:487`, `connect_account_live.ex:284`; the subscription equivalent is `subscription-action-drawer-test-mirror`).

**Motion probe analog:** `reduced-motion.spec.js:1-70` (computed `transitionDuration` split on commas; `--ax-dur-3` token read from `document.documentElement`). New probe must run under both `reducedMotion: "reduce"` and `"no-preference"`.

**No existing analog** for: `adoptedStyleSheets` text-spacing, CDP `Page.setFontSizes` scaling, target-size bounding-box/spacing-circle (see "No Analog Found"). `git grep -n "adoptedStyleSheets\|bypassCSP\|setFontSizes"` over `accrue_admin/e2e` and `test/js` returns nothing (positive control: `elementFromPoint` returned `admin-interactions.spec.js:137`, `phase191-page-flow-helpers.js:213`). CSP that the adoptedStyleSheets probe may hit: `style-src 'self' 'nonce-...'` (`accrue_admin/lib/accrue_admin/csp_plug.ex:22`).

#### `accrue_admin/e2e/a11y-dispositions.json` + `scripts/ci/verify_a11y_dispositions.mjs` (+ test)

**Analog (zero-match fails):** `verify_sensitive_token_census.mjs:254-260`:
```js
export function assertNonVacuous(results) {
  for (const [id, bucket] of results.entries()) {
    if (bucket.total === 0) {
      fail(`census entry "${id}" matches zero occurrences corpus-wide -- a pattern that matches nothing cannot be evidence of anything`);
    }
  }
}
```
The register's "entry whose cells ran but matched zero nodes" rule is this idiom. Use the census `SCENARIOS` table (`:374-523`) for the fixture list (unused / broad / expired / wildcard / count-mismatch entries) and S1 for dispatch. The source-contract rule (no `disableRules` / `exclude` / `impact` filter in these owners) is a scan like `verify-css-census.mjs`; **its positive control must seed a file that contains each banned token**, and a known-clean owner file must pass. Register JSON lives in a tracked package path (`accrue_admin/e2e/`), which is already a consumed root (`phase252_paths.mjs:68`, `browser-specs`).

#### Mounted keyboard journey in `admin-interactions.spec.js`

**Analogs:** trap probe (`focusCycleProbe`, `:221-243`) whose result is recorded as a row:
```js
recorder.observe({ interaction_class: "focus-trap-restore", ..., actual: `before=...; inside=${inside}; ...`,
  failure_kind: inside ? null : "focus-escaped", coverage_status: inside ? "covered" : "gap" });
```
D-29 turns the **value** (`inside`, drawer visibility after Escape, `keyboard-flow-incomplete`) into an `expect(...)`; keep the recorder row for the existing report. Mounted drawer/step-up selectors and helpers to copy from `admin-page-flow-phase191.spec.js:88-108` (`clickActionTrigger`: `getByRole("button", { name: trigger })` or overflow menu `[data-ax-action-overflow-menu]` -> `getByRole("menuitem")`; `visibleDrawer`: `#ax-overlay-root [data-presentation='drawer']`) and `:480-530` (`#accrue-admin-step-up-dialog`, `#step-up-code`, `[data-role="step-up-submit"]`, `[data-role="cancel-now-form"]`, `[data-role="confirm-action"]`; `expect.poll` against `/__e2e__/phase240/action-status`). Restore-after-patch behavior being asserted lives in `accrue_admin/assets/js/hooks/focus_trap.js:27-38` (double `requestAnimationFrame`), which is why the journey must `expect.poll`, not `waitForTimeout` (P7). The file defines its own `reset`/`seed`/`login` (`:31-43`) - correct for a mounted test.

---

### Group F - UXQ-04 bounded design review and corrections

#### `scripts/ci/recompose_storybook_css.mjs` (+ test) - build step required before any CSS edit (RESEARCH F2)

**Recipe analog (hand recipe, not code):** `.planning/milestones/v1.57-phases/211-grep-gated-css-retirement-cross-surface-cleanup/211-03-PLAN.md:50` - extract the D-17 shim tail from the **current** `storybook.css` starting at the marker line, then concatenate: verbatim 3-line header, blank line, full `deps/phoenix_storybook/priv/static/css/phoenix_storybook.css`, blank line + literal `/* === accrue_admin.css bundle === */`, full fresh `priv/static/accrue_admin.css`, blank line, preserved shim tail. Current file facts: header lines 1-3 (`storybook.css:1-3`), shim marker `/* === D-17 Spike B: dark-mode class-to-attribute shim === */` at line 108. `mix accrue_admin.assets.build` does not touch it (`accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`; its ExUnit `accrue_admin_assets_build_test.exs:1-80` uses a `FakeRunner` and restores the committed bundles in `on_exit`).

**Freshness analog:** `ci.yml:994-1000` ("Rebuild package assets" then `git diff --exit-code -- accrue_admin/priv/static/accrue_admin.css accrue_admin/priv/static/accrue_admin.js`). Add `storybook.css`/`storybook.js` to that `git diff` path list only **after** the script makes the rebuild deterministic, and add a `--check` mode (embedded `accrue_admin.css` section sha256 === file sha256; shim tail byte-identical to the previous tail). Served-bytes equality analog: `accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs:20-30` (`assert_storybook_asset(:storybook_css, ..., "priv/static/storybook.css")`).

Self-test style: `verify-css-census.mjs` (pure in-memory fixtures, no fs). Cannot be guarded by `isMainModule`-less idiom (P1); use S1.

#### `app.css` corrections (config/style; edit tiers per D-34)

Verified current lines (all in `accrue_admin/assets/css/app.css`):
```css
/* :2984-2986 */ .ax-subscription-detail-page { gap: 0.0625rem; }
/* :3049-3051 */ .ax-subscription-detail-page .ax-stack-md { gap: 0.1875rem; }
/* :3059-3061 */ .ax-subscription-detail-page .ax-stack-sm { gap: 0.0625rem; }
/* :6709-6712 */ .ax-subscription-detail-page .ax-field-list, .ax-subscription-detail-page .ax-field-list-compact { gap: 0; }
/* :6719-6724 */ .ax-subscription-detail-page .ax-field { ...; gap: 0 0.25rem; }
/* :6726-6730 */ .ax-subscription-detail-page .ax-field-label, ... .ax-field-value { line-height: var(--ax-leading-normal); }
/* :6732-6740 */ .ax-field-label { margin:0; font-size: var(--ax-type-sm); font-weight: 600; color: var(--ax-muted); text-transform: uppercase; letter-spacing: var(--ax-tracking-wide); }
/* :4122-4125 */ .ax-field-label { font: var(--ax-type-label-font); letter-spacing: var(--ax-type-label-tracking); /* ax-type-exception: ... */ }
/* :777-781 */ .ax-display, .ax-kpi-value { /* ax-type-exception */ font-size: 1.5rem; line-height: var(--ax-leading-tight); ... }
/* :2158-2166 */ @media ... { .ax-display, .ax-kpi-value { /* ax-type-exception */ font-size: 1.75rem; } }
```
Tokens that exist (`theme.css`): `--ax-type-xs: 0.75rem` (`:26`), `--ax-type-xl: 1.5rem` (`:30`), `--ax-type-2xl: 1.75rem` (`:31`), `--ax-space-2xs: 0.125rem`, `--ax-space-xs: 0.25rem` (`:35-36`), `--ax-type-label-sm-font: 600 var(--ax-type-xs)/var(--ax-leading-normal) var(--ax-font-sans)` (`:101`). **FND-01 guard behavior** (`scripts/ci/verify_package_docs.sh:617-631`): the awk flags any `font-size|font-weight|line-height|letter-spacing|font-family :` line not inside an `ax-type-exception:` block, regardless of value - so swapping the two `rem` literals for `var(--ax-type-xl/2xl)` must **keep** the existing exception comments, `font:` shorthand is not matched, and a trailing `letter-spacing:` after a `font:` shorthand needs an exception comment like `:4123`. Test coupling to remember: a `verify_package_docs.sh` change also requires `PackageDocsVerifierTest` seed updates (project memory).

Cascade (Pitfall 6): `.ax-field-label` is declared at `:4122` and `:6732`; D-34's scoped `.ax-field-list .ax-field-label` raises specificity. Assert computed `font-size`, `line-height` and `text-transform` after the change by probe element rather than by order reasoning, and check `.ax-field-value` keeps `font-variant-numeric: tabular-nums`.

All three bundles ship together (D-07): `app.css` -> `mix accrue_admin.assets.build` -> `priv/static/accrue_admin.css` -> recompose script -> `priv/static/storybook.css`; `AccrueAdmin.Assets` embeds at compile time so a stale `_build` serves old bytes (`storybook_asset_test.exs` is the served-bytes check).

#### Copy owner fix (D-34 result-link) - `copy.ex`, `subscription_live.ex`, `subscription_page_scenarios.ex`

The literal currently lives in two places:
```elixir
# subscription_live.ex:2090-2097
defp put_action_result(socket, kind, message, href \\ nil, link_label \\ nil) do
  assign(socket, :action_result, %{ kind: kind, message: message,
    href: href || action_activity_path(socket),
    link_label: link_label || "Open scoped subscription activity" })
end
# subscription_live.ex:2111-2118  (private today)
defp action_activity_path(socket) do
  ScopedPath.build(socket.assigns.admin_mount_path, "/events", socket.assigns.current_owner_scope,
    %{"subject_type" => "Subscription", "subject_id" => socket.assigns.subscription.id})
end
# subscription_page_scenarios.ex:180-195 - story adapter duplicates both
message: AccrueAdmin.Live.SubscriptionLive.action_result_message(kind),
href: ScopedPath.build(page.admin_mount_path, "/events", scope, %{"subject_type" => "Subscription", "subject_id" => subscription.id}),
link_label: "Open scoped subscription activity"
```
Pattern for the new owner functions: `@doc false def action_result_message(:confirmed), do: Copy.subscription_action_recorded_info()` (`subscription_live.ex:2120-2121`) and `Copy.subscription_action_recorded_info` at `copy.ex:1001` (`def subscription_action_recorded_info, do: "Subscription action recorded."`). New: `Copy.subscription_action_activity_link_label/0` and a public `@doc false def action_activity_path(admin_mount_path, owner_scope, subscription_id)`; both `put_action_result` and the adapter call them. Test analog: `subscription_page_slice_test.exs:225-250` (`Floki.text(result) =~ SubscriptionLive.action_result_message(kind)` and `Floki.attribute(... "a"), "href")`); the literal-count guard is a source-reading ExUnit with a positive control (see `subscription_production_boundary_test.exs:164` `File.read!` loop for the file-scan shape). Regenerate `examples/accrue_host/e2e/generated/copy_strings.json` if drift appears (F8, `scripts/ci/accrue_host_verify_browser.sh:147`).

#### Design review record + verifier

**Analog for typed record -> generated view -> diff check:** `generate_phase253_acceptance.mjs` (`renderUat` `:729-733`, `generatePhase253Acceptance` `:735-750`, CLI `--latest` / `--write-uat` `:752-761`) and its test pattern `generate_phase253_acceptance.test.mjs` (e.g. `"generated Phase 253 UAT matches the project contract renderer once verification exists"`). Evidence in `.planning/phases/254-.../` is read through `scripts/ci/phase_evidence_path.mjs`:
```js
export function resolvePhaseEvidencePath(phaseSlug, artifactPath, { root = repositoryRoot } = {}) { /* active dir, else unique archived .../milestones/*-phases/<slug>/ match */ }
```
(`phase_evidence_path.mjs:29-48`). A literal `.planning/phases/<slug>` string in a script needs a same-line `archive-sweep-exempt: <reason>` marker (see `verify_ci_critical_path`-style uses; `phase_evidence_path.mjs:83`). Run `node scripts/ci/verify_phase230_archive_invariants.mjs --repo .` after adding the verifier. Reject score-like keys and tmp-path evidence with S1 scenarios; the red-evidence files `254-*-red-evidence.json` follow the "generated JSON + red-evidence JSON before fixes" convention (CONTEXT Established Patterns).

**Computed-style fix tests:** `foundation-tokens.spec.js` is the in-repo analog for resolving token values through the browser; probe element reading `var(--ax-space-*)` (no hard-coded px) is new but small. Scoped CSS guard with a negative fixture: `verify-css-census.mjs` `runSelfTest()` pattern.

---

### Group G - CURATE-01 retirement/merge ledger

#### Ledger in `SubscriptionManifest` + `subscription-curation.json` + guide

**Analog (exact):** the existing `write!/1` / `verify!/1` JSON pair and `coverage_guide/0`:
```elixir
# subscription_manifest.ex:130-142
def write!(path) when is_binary(path) do
  contents = %{ schema_version: 1, source_digests: source_digests(), entries: entries() }
  json = Jason.encode!(contents, pretty: true) <> "\n"
  path |> Path.dirname() |> File.mkdir_p!()
  File.write!(path, json)
end
# :464-470 write_coverage_guide!/1 -> File.write!(path, coverage_guide())
```
`coverage_guide/0` (`:474-529`) already renders `caller_map` rows into sections `Reachable / Uncovered / Not applicable` plus a Phase 253 supplement and digests; the curation records render as a new section appended the same way (guide path is pinned at `verify_phase253_compositions.mjs:40`; do not rename). Row validation idiom to copy for ledger records: `normalize_caller_row!/1` (`:791-822`) - required string fields, state membership list, "non-reachable rows need a reason", stable `key` from URI-encoded identity, sorted lists.

**Verifier (`scripts/ci/verify_phase254_curation.mjs`):** regenerate-and-compare (S2) + census-style seeded-positive scanning. The D-39 reference scan must find a seeded `populated` hit before a zero is accepted, and match the exact `variation_id` token; the counter-example is real: `git grep -n -e ":populated"` hits `accrue_admin/test/accrue_admin/dev/subscription_scenarios_test.exs:102,167`, `subscription_story_slice_test.exs:186`, `dev_support/ui_scenarios/cadence_subscriptions.exs:48,60`, `storybook/components/subscription_detail.story.exs:34`, `guides/subscription-story-coverage.md:27` - none of these are the unrelated `UI-E2-populated` ids in `generate_phase253_acceptance.mjs:31-36`. Use `git grep -n -e` (never `--` before the pattern).

#### Disposition-specific source edits (verify before acting, D-40)

- `subscription_detail||populated` retire: `cadence_subscriptions.exs:48` (`@ordinary_scenarios` entry) and `:60` (`def fetch!(:populated), do: fetch!(:active)`), `subscription_detail.story.exs:34` (`variation(:populated, :populated, "Populated compatibility ID")`), `subscription_manifest.ex:239-241` (`entry.variation_id in ["populated", "braintree_pruned", "dunning_active"]`), tests `subscription_scenarios_test.exs:96-110,167`, `subscription_story_slice_test.exs:186`. `CadenceSubscriptionFacts.list/0` is the shared ordinary list consumed by `SubscriptionScenarios.list/0` (`subscription_scenarios.ex:30,186`), the host/held-out validation block (`scripts/ci/fixtures/phase252-transparency/heldout-clean.json:33` embeds `CadenceSubscriptionFacts.list()`), and `subscription_scenarios_test.exs:96,236,271` (`refute :held_out_long_text in CadenceSubscriptionFacts.list()`) - handle the list change explicitly with those fixtures.
- Compat derivation (P3): `phase252-story-helpers.js:103-114` derives compat cells from entries not in `CANONICAL_STATES`; the literal count sites listed in P3 are the only hard-coded ones.
- `action_menu/provider_pruned` merge: variation at `storybook/components/action_menu.story.exs` (`%Variation{id: :provider_pruned, ... groups: provider_pruned_groups()}`); survivors `action_menu/danger` and `subscription_detail/braintree_pruned`.
- Stale gap rows (all in `subscription_manifest.ex`, verified): detail page `:312-328` (reason "The legacy detail Storybook route renders subscription_area/1 only...", `state: "uncovered"`), list `:330-345` (reason "The subscription list has no selected subscription Storybook composition."), mounted journey `:347-362` (reason "...Phase 253 owns the mounted Admin journey."). The lock-in assertion is `subscription_manifest_test.exs:418` (`assert page.state == "uncovered"` / `assert page.reason =~ "whole-page"`) and `:424`; the true claim to keep is the guide sentence at `subscription_manifest.ex:514` ("The legacy detail Storybook route ... does not prove a whole page") asserted at `subscription_manifest_test.exs:442` (`assert guide =~ "does not prove a whole page"`).

---

### Group H - CURATE-02 gap map, briefs, next-job input

**Gap map = extend `caller_map` rows** (`subscription_manifest.ex:194-437`, no supplements, D-41). Current row builder `caller_row!/8` (`:737-763`) returns `label, owner, path, tier, state, evidence, reason, contract, registry_proof_id, registry_components, story_path, manifest_keys, manifest_urls, route_path, route_evidence, classification` and merges `extra`; `normalize_caller_row!` (`:802`) restricts `state` to `["reachable","uncovered","not_applicable"]` - add `gated` there **and** update the test that asserts the same list (`subscription_manifest_test.exs:392`, `assert Enum.all?(rows, &(&1.state in ["reachable", "uncovered", "not_applicable"]))`). Route-seeding source of truth: Admin router `accrue_admin/lib/accrue_admin/router.ex:72-102` (`live("/subscriptions", AccrueAdmin.Live.SubscriptionsLive, :index)` etc.) and Portal router `accrue_portal/lib/accrue_portal/router.ex:128-143`. Both are already evidence markers for rows (`source_evidence!(root, "accrue_portal/lib/accrue_portal/router.ex", "live(\"/subscriptions\", ...")`). A new `live(` line should appear as an `uncovered` row automatically; positive control = a fixture router string with an extra route.

**Adopter briefs:** exactly the five in `.planning/research/ui-quality-engine/SCENARIOS.md` table (rows `launch`, `team`, `learner`, `operations`, `self_hosted`; `team` implemented, `self_hosted` synthetic). Verifier shape = S1 scenarios (overlap fixture must fail; one unique equivalence class each).

**Next-job scoring:** hard filters then ordinal ranking - no code analog (see No Analog Found). Keep it a pure function over the `caller_map` rows with fixture inputs; generated table lives in the guide (section appended in `coverage_guide/0`).

---

### Group I - Acceptance and wiring

#### `scripts/ci/generate_phase254_acceptance.mjs` (+ test) - exact analog `generate_phase253_acceptance.mjs`

Exports to mirror: `PHASE_SLUG`, `REQUIREMENT_IDS`, `TASK_IDS`, `EDGE_IDS`, `inspectPhase253Metadata`, `validatePhase253Evidence`, `validateCompletedSummaries`, `renderUat`, `generatePhase253Acceptance({ root, resultsPath, latest, writeUat })`. Output UAT must equal `renderAutomatedUat(phaseDir)` from `verify_executable_uat_contract.mjs:156` (test pattern `generate_phase253_acceptance.test.mjs` "matches the project contract renderer"). CLI check: `node scripts/ci/verify_executable_uat_contract.mjs --phase 254` (flag parsing `:686-711`). Use the conforming entrypoint (S1), not `:763`.

#### Owner wiring

- `scripts/ci/verify_phase200_admin_guardrails.sh:23-24` - append after the Phase 253 line, never edit the two pinned lines (their anchored regexes are `phase252_paths.mjs:235-236`):
```bash
run_step "Phase 252 complete subscription story acceptance" npm --prefix accrue_admin run phase252:check
run_step "Phase 253 focused composition acceptance" node scripts/ci/verify_phase253_compositions.mjs
```
- `phase252_paths.mjs` `assertCiContract` (`:193-249`) only requires 252/253 ordering; a new Phase 254 step needs its own regex + `requirePhase254` flag only if the planner wants the same ordering guarantee (test pattern `verify_phase252_ci_contract.test.mjs:157-186`).
- `accrue_admin/package.json:52` is the script style (`"phase252:check": "node ../scripts/ci/verify_phase252_stories.mjs"`); add `phase254:*` scripts alongside; `package.json` is already a consumed root (`phase252_paths.mjs:87`).
- `.gitignore:30-38` entries (P4) and a `phase254-machine-evidence` upload step mirroring the Phase 252/253 upload blocks after `ci.yml` job `admin-phase200-guardrails`.
- `CONSUMED_ROOTS` additions (and `REQUIRED_ROOT_IDS`) for: `scripts/ci/phase254_` prefix, `scripts/ci/verify_phase254_` prefix, `scripts/ci/generate_phase254_` prefix, `scripts/ci/recompose_storybook_css.mjs`, `scripts/ci/verify_a11y_dispositions.mjs`, `accrue_admin/storybook/` JSON files, `accrue_admin/e2e/__screenshots__/` (the PNG/manifest set), `accrue_admin/e2e/a11y-dispositions.json` (covered by `browser-specs` prefix), `accrue_admin/playwright.config.js` (**not** currently a root; only `playwright.phase252.config.js` is, `:69`) and `guides/subscription-story-coverage.md`. Each gets a positive path in the `positivePaths` array style of `verify_phase252_ci_contract.test.mjs:25-51` and a "removal must fail" control (`:145-153`).

---

## Shared Patterns

### S1 - Conforming verifier skeleton (apply to every new `scripts/ci/*.mjs`)
**Source:** `scripts/ci/verify_sensitive_token_census.mjs:1-19,374,525-528,575-590`; `scripts/ci/render_provider_summary.mjs:46-52`; guard `scripts/ci/main_module.mjs:27-35`; enforcement `scripts/ci/verify_ci_script_contract.mjs:128-187,189-` (see P1).
```js
import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

const SCENARIOS = [ ["named scenario with positive and negative control", () => { /* assert.* */ }], /* ... */ ];
export function verifyFixtures() { for (const [, scenario] of SCENARIOS) scenario(); return SCENARIOS.length; }

let invokedAsEntrypoint = false;
try { invokedAsEntrypoint = isMainModule(import.meta.url); } catch { invokedAsEntrypoint = false; }   // must be a bare assignment inside try/catch
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  for (const [name, scenario] of SCENARIOS) test(name, scenario);                  // >=1 real TAP name or non-vacuity check fails
} else if (invokedAsEntrypoint) {
  try { main(); /* handles --self-test / --fixtures via verifyFixtures() */ } catch (error) { console.error(`...: FAIL: ${error.message}`); process.exitCode = 1; }
}
```
Pure functions (no fs) may use the lighter `verify-css-census.mjs:221-232` `check(name, cond)` shape for `--self-test`. D-02: a `0 found` only counts after the same checker finds a seeded positive (CLAUDE.md "A check that finds nothing must be proved able to find something"; census `assertNonVacuous` is the in-repo form). Project convention: a verifier plus a `node --test` pair (`*.test.mjs` is exempt from the guard check but must still register real tests).

### S2 - Generated JSON is the source, the checked-in copy is diff-checked (curation ledger, selection projection, design-review view, guide)
**Source:** `verify_phase252_stories.mjs:169-187`, `subscription_manifest.ex:130-168`, `guides/subscription-story-coverage.md` via `write_coverage_guide!/1` (`:464-470`). Compare decoded JSON (key-order independent), regenerate to a temp path, delete in `after`. Editing digested files re-mints digests with the owning module's own tooling (D-05).

### S3 - Digest binding and tamper-evidence
**Source:** `phase253-composition-helpers.js:64-70,352-356` (`sha256`, `fileDigest`, `currentSourceAndAssetDigests`), `SubscriptionManifest.source_digests/0` (`:113-128`), census `pattern_sha256` (`verify_sensitive_token_census.mjs` entries). Every new tracked CI-read file records the sha256 of what it was derived from; the verifier recomputes and fails on drift. Asset set already hashed: `app.css`, `accrue_admin.css`, `storybook.css`, `storybook.js` (`phase253-composition-helpers.js:57-62`) - add woff2 and the scenario file for CIQ-03.

### S4 - Output escaping for untrusted strings
**Source:** `render_provider_summary.mjs:9-19` (strict), `render_ci_baseline.mjs:10` (lighter `\\|`<>` + newline). Apply to every changed-path, test title, and register field that reaches `$GITHUB_STEP_SUMMARY` or `::warning` output. Include a hostile-input fixture in each renderer's self-test.

### S5 - Fail-closed errors with a phase prefix
**Source:** `phase252_paths.mjs:106-108` (`fail(message)` -> `new Error("Phase 252 CI contract: ...")`), `verify_phase253_compositions.mjs:184-186`, census `fail` (`verify_sensitive_token_census.mjs:91`). One `fail()` per module with a distinctive prefix so tests assert `/prefix: message/`. No silent `catch` -> pass; the idiom `invokedAsEntrypoint` catch is the only permitted swallow.

### S6 - Archive-safe evidence reads
**Source:** `phase_evidence_path.mjs:29-53`, usage `verify_ci_critical_path.mjs:13-14`. CI-read inputs for Phase 254 live in tracked package paths (D-04); planning records a verifier reads go through `resolvePhaseEvidencePath("254-recurring-quality-reviewed-fixes-and-curation", "<artifact>")`. Real-read literals elsewhere need `archive-sweep-exempt:`; run `node scripts/ci/verify_phase230_archive_invariants.mjs --repo .` after any milestone archive. Absence claims (`path_exists: false`) must not resolve through the archive.

### S7 - Executable acceptance only (no human gate, no score, no LLM)
**Source:** CLAUDE.md "Executable Acceptance Policy"; `renderUat` (`generate_phase253_acceptance.mjs:729-733`) `source: automated`, `human_judgment: false` (`phase253-composition-helpers.js:79,382`). The single permitted human interaction is the owner-confirmed first push (D-25 / RESEARCH Open Question 5).

### S8 - Never weaken an existing gate (D-06)
Pinned-now values to leave alone: `playwright.config.js:13-21` (`threshold 0.2`, `maxDiffPixelRatio 0.01`), `workers: 1`, no `retries` key anywhere, `parsePlaywrightJson` skip/retry/flaky rejection (`phase252_reporters.mjs:294-309`), 12 Phase 211 baselines, 151 full-mode cells, kitchen proof. New cases pass stricter options **in the call** (`maxDiffPixels: 0`), not by editing defaults.

## No Analog Found

| File / Responsibility | Role | Data Flow | Reason |
|---|---|---|---|
| Machine fingerprint + cold/warm/focused/incremental protocol harness (`phase254_measure.mjs`) | tool | batch | No `os.*` fingerprint code exists in `scripts` or `accrue_admin/e2e`; no warm-preview probe in `phase252_lab.mjs`. Only `spawnCaptured`, `gitRevision`, `mixBuildPath` and the Phase 226/227 CI-side collectors (GitHub API, not local timing) are reusable. Planner: use RESEARCH D-21 protocol and ship positive controls for fingerprint completeness. |
| WCAG 1.4.12 text-spacing, 1.4.4 200% text (CDP `Page.setFontSizes`), 2.5.8 target-size/spacing-circle probes | spec | request-response | No `adoptedStyleSheets`, `bypassCSP`, `setFontSizes`, or bounding-box target-size code anywhere in `accrue_admin/e2e` or `test/js`. Assumptions A1/A2 are unverified: first task is a spike with a positive control and a seeded "unapplied" negative; if `setFontSizes` does not scale `rem`, record a disposition, do not prove by a root-font multiplier. Use `elementFromPoint` (`admin-interactions.spec.js:131-144`) and `reduced-motion.spec.js` only for the 2.4.11 and motion probes. |
| Visual identity manifest (`__screenshots__/visual-desktop/manifest.json`) | data | batch | Closest are `storybook/phase252-manifest.json` (shape) and the 12 committed PNGs; nothing records per-PNG sha256 / `browser.version()` / mint run id today. Also no existing Docker pre-flight (A6). |
| Next-job candidate scoring (hard filters, ordinal weights, tie-breaks) | tool | transform | No ranking code exists. Implement as a pure function over the extended `caller_map` rows with fixture-driven negative controls (Portal-adjacency must not win while gated). |
| Reconcile as a dependent Playwright project | config | n/a | Config API verified in types only (`test.d.ts:172`); no existing config in the repo uses `dependencies`. Prove it with a failing-upstream fixture before relying on it. |

## Metadata

**Analog search scope:** `scripts/ci/`, `scripts/dev/`, `accrue_admin/e2e/`, `accrue_admin/test/{support,js,accrue_admin/dev,mix}`, `accrue_admin/storybook/_support/`, `accrue_admin/lib/accrue_admin/{copy.ex,live,csp_plug.ex,router.ex}`, `accrue_admin/assets/css/`, `accrue_admin/priv/static/`, `storybook/`, `dev_support/ui_scenarios/`, `.github/workflows/`, `guides/`, `accrue_portal/lib/accrue_portal/router.ex`, `.planning/milestones/v1.57-phases/211-*` and `v1.61-phases/227-*` (archived precedents), `.planning/phases/253-*`.
**Files read for excerpts:** ~60. **Live commands run (read-only):** `git ls-files`/`check-ignore`/`grep`, `node scripts/ci/verify_ci_script_contract.mjs --repo . ... --require-guard-coverage` (reported 8 offenders, P1), `node scripts/ci/verify_phase230_archive_invariants.mjs --repo .` (test-mode run), Playwright types grep.
**Not verified at runtime (inferred from source):** story routes on the legacy port-4017 server (A4), `adoptedStyleSheets` under the admin CSP (A2), `Page.setFontSizes` effect on `rem` (A1), workflow dispatch from a non-default branch (A3).
**Project guidance:** no `.claude/skills/` or `.agents/skills/` entries found; CLAUDE.md Executable Acceptance Policy and Agent Working Discipline applied (positive controls, `git grep -e`, no destructive git, archive sweep, digest re-mint).
**Pattern extraction date:** 2026-10-28
