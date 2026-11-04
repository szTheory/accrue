---
phase: "254"
slug: "recurring-quality-reviewed-fixes-and-curation"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-28"
---

# Phase 254 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `254-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node `node:test` (scripts/ci), ExUnit via lab (accrue_admin), Playwright 1.59.1 (browser) |
| **Config file** | `accrue_admin/playwright.config.js`, `accrue_admin/playwright.phase252.config.js` |
| **Quick run command** | `node --test --test-reporter=tap scripts/ci/<new>.test.mjs` + `node scripts/ci/<verifier>.mjs --self-test` |
| **Full suite command** | `npm --prefix accrue_admin run phase252:check && node scripts/ci/verify_phase253_compositions.mjs` + Phase 254 aggregate |
| **Estimated runtime** | ~60 seconds quick; ~420 seconds full |

---

## Sampling Rate

- **After every task commit:** task's `node --test` / `--self-test` + focused lab command (≤ 60 s target)
- **After every plan wave:** full suite command above
- **Before `/gsd-verify-work`:** Full suite must be green, plus `verify_phase230_archive_invariants.mjs --repo .` and `verify_executable_uat_contract.mjs --phase 254`
- **Max feedback latency:** 60 seconds (per task)

---

## Research Validation Architecture (verbatim)

> `workflow.nyquist_validation` is `true` in `.planning/config.json` `[VERIFIED: config read]`.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Node `node:test` (TAP) for `scripts/ci`; ExUnit for `accrue_admin` (via lab); Playwright 1.59.1 for browser |
| Config file | `accrue_admin/playwright.config.js` (legacy; `visual-desktop`), `accrue_admin/playwright.phase252.config.js` (lab, `workers: 1`, requires `PHASE252_E2E_*` env) |
| Quick run command | `node --test --test-reporter=tap scripts/ci/<new>.test.mjs` and `node scripts/ci/<verifier>.mjs --self-test` |
| Full suite command | `npm --prefix accrue_admin run phase252:check && node scripts/ci/verify_phase253_compositions.mjs` (existing), plus the new Phase 254 aggregate added after them; CI: `bash scripts/ci/verify_phase200_admin_guardrails.sh` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CIQ-02 | collection-only diff → `affected` + non-empty exclusions; `docs/x.md` → sentinels only; `accrue/lib/**`, `mix.lock`, `app.css` → `full`; missing metadata/shallow/empty base/push → broaden/`full`; invariant breaches hard-fail | unit + self-test | `node --test --test-reporter=tap scripts/ci/phase254_selection.test.mjs && node scripts/ci/phase254_selection.mjs --self-test` | ❌ Wave 1/2 |
| CIQ-02 | review-lane reset/seed → 403, marker unchanged; test lane → 200 | ExUnit | `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/e2e_plug_isolation_test.exs` (path illustrative) | ❌ Wave 2 |
| CIQ-02 | pure-story project rejects specs touching reset/seed or `admin-visual-helpers`; every `e2e/*.spec.js` owned by exactly one project | static contract | `node --test --test-reporter=tap scripts/ci/phase254_project_ownership.test.mjs` | ❌ Wave 2 |
| CIQ-02 | per-case ledger loses no row under interleaved writes (old ledger loses one — positive control) | unit | in `verify_phase253_compositions.test.mjs` or new test | ❌ Wave 2 |
| CIQ-02 | full mode still literal counts (14/151 post-curation; 15/151 as frozen baseline fixture) | acceptance | `node scripts/ci/verify_phase253_compositions.mjs` + `npm --prefix accrue_admin run phase252:check` | ✅ (literals amended) |
| CIQ-03 | 24 new + 12 existing PNG set == manifest keys; extra/missing fail; byte/asset/Chromium mismatch fail | node test | `cd accrue_admin && node --test test/js/*.mjs` | ✅ partial (needs new cases) |
| CIQ-03 | determinism: fonts loaded, animations 0, theme token differs, content asserts, mask geometry negative control | browser (Linux) | `cd accrue_admin && npm run e2e:visual-regression` (CI authoritative); `--repeat-each=3` once in mint PR | ❌ Wave 5 |
| CIQ-03 | `--update-snapshots` only in mint job; thresholds pinned; upload `if: success()` | contract | `node --test --test-reporter=tap scripts/ci/phase254_visual_contract.test.mjs` | ❌ Wave 5 |
| CIQ-04 | harness records fingerprint + per-test durations; reporter keeps retry/flaky/skip rejection | unit | `node --test --test-reporter=tap scripts/ci/phase252_reporters.test.mjs` (or the existing suite that covers it) | ✅/❌ confirm in Wave 0 |
| CIQ-04 | budget verifier: identity-set mismatch, count drop w/o record id, skip/retry/flaky, digest mismatch, missing fingerprint/summary, ceiling → fail; above `warn_at` → warn only | unit + self-test | `node --test --test-reporter=tap scripts/ci/phase254_budget.test.mjs && node scripts/ci/phase254_budget.mjs --self-test` | ❌ Wave 3 |
| UXQ-02 | each probe fails on its injected defect and passes on the real cell | browser | `node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-compositions-phase253.spec.js` | ✅ extend |
| UXQ-02 | register validator rejections (unmatched, zero-node, broad target, wildcard, expired, count mismatch) and source-contract (`disableRules|exclude|impact filter` absent in these owners — with seeded positive) | node test | `node --test --test-reporter=tap scripts/ci/verify_a11y_dispositions.test.mjs && node scripts/ci/verify_a11y_dispositions.mjs --self-test` | ❌ Wave 4 |
| UXQ-02 | mounted keyboard journey (focus restore via `expect.poll`) | browser (legacy server) | `cd accrue_admin && env -u NO_COLOR npx playwright test e2e/admin-interactions.spec.js --workers=1` | ✅ extend |
| UXQ-04 | each fix red on pre-fix commit, green after: gaps via token-resolved `rowGap`, label size = key size, 767/768 heading, copy owner functions + literal-count guard | browser + ExUnit | lab `browser` / `exec` commands for new specs/tests; red evidence JSON `254-*-red-evidence.json` | ❌ Wave 4 |
| UXQ-04 | record verifier: no score keys, no tmp-path evidence, every changed PNG maps to a finding, source shas current, MD view in sync | node test | `node --test --test-reporter=tap scripts/ci/verify_phase254_design_review.test.mjs && node scripts/ci/verify_phase254_design_review.mjs --self-test` | ❌ Wave 5 |
| UXQ-04 | `storybook.css` embeds current `accrue_admin.css` | node test | `node scripts/ci/recompose_storybook_css.mjs --check && node --test --test-reporter=tap scripts/ci/recompose_storybook_css.test.mjs` | ❌ Wave 4 |
| CURATE-01 | ledger rules D-39 incl. seeded-positive reference scan, survivor in rendered results, preserved regressions run in required lane | node + ExUnit | `node --test --test-reporter=tap scripts/ci/verify_phase254_curation.test.mjs`; `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_manifest_test.exs` | ❌/✅ amend |
| CURATE-02 | new route in router fixture appears `uncovered`; five briefs each claim a unique class; overlap rejected; Portal gated candidate cannot win | node + ExUnit | same files as CURATE-01 | ❌ Wave 6 |
| All | executable acceptance + UAT artifact | generator | `node scripts/ci/generate_phase254_acceptance.mjs --latest --write-uat && node scripts/ci/verify_executable_uat_contract.mjs --phase 254` | ❌ Wave 6 |

### Sampling Rate
- **Per task commit:** the task's `node --test` / `--self-test` plus its focused lab command (≤ 60 s target).
- **Per wave merge:** `npm --prefix accrue_admin run phase252:check` and `node scripts/ci/verify_phase253_compositions.mjs` (≈ 7 min locally — consider running at wave boundaries only), plus the new Phase 254 aggregate.
- **Phase gate:** full local aggregate green, then CI observation on the pushed branch (owner-confirmed), `verify_phase230_archive_invariants.mjs --repo .`, and `verify_executable_uat_contract.mjs --phase 254`.

### Wave 0 Gaps
- [ ] Probe spikes (each with positive control, recorded in a spike note): `Page.setFontSizes` scaling (A1), `adoptedStyleSheets` under CSP (A2), story routes on the legacy server (A4).
- [ ] `scripts/ci/phase254_selection.{mjs,test.mjs}` skeleton + `phase254-selection.json` projection generator.
- [ ] Per-test duration retention in `phase252_reporters.mjs` (keep rejection logic) + test.
- [ ] `recompose_storybook_css.mjs` (+ `--check`) before any CSS edit.
- [ ] Project-ownership static contract for `e2e/*.spec.js` (F5).
- [ ] `CONSUMED_ROOTS` entries for every new CI-read path + `classifyPath` tests.

---

## Per-Task Verification Map

*Populated by the planner/executor from PLAN.md `<automated>` commands.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 254-01-01 | 254-01 | 1 | CIQ-04 | T-254-01, T-254-02, T-254-06, T-254-SC | Fingerprinted sample of one existing lane end-to-end, with per-test durations kept | auto | node --test --test-reporter=tap scripts/ci/phase252_reporters.test.mjs scripts/ci/phase254_measure.test.mjs scripts/ci/phase252_reporters.mjs && node scripts/ci/phase254_measure.mjs --self-test && git check-ignore -q accrue_admin/tmp/phase254/x.json | yes | ✅ green |
| 254-01-02 | 254-01 | 1 | CIQ-04 | T-254-01, T-254-02, T-254-06, T-254-SC | Cold, warm-preview and focused protocols over the existing Phase 252/253 lanes, with D-24 attribution | auto | node --test --test-reporter=tap scripts/ci/phase254_measure.test.mjs && node -e 'const fs=require("node:fs");import("./scripts/ci/phase254_measure.mjs").then(({PROTOCOLS,FINGERPRINT_KEYS})=>{const b=JSON.parse(fs.readFileSync("accrue_admin/storybook/phase254-budget.json","utf8"));const modes=new Set(b.metrics.local.map(m=>m.mode));const ok=b.frozen===null&&["cold","warm","focused"].every(m=>modes.has(m))&&b.metrics.local.every(m=>m.informs_only===true&&m.smoke===false&&FINGERPRINT_KEYS.every(k=>k in m.fingerprint)&&m.n===PROTOCOLS[m.mode].runs&&m.warmup===PROTOCOLS[m.mode].warmup)&&b.deviations.length===1&&b.deviations[0].id==="DEV-254-01"&&b.deviations[0].status==="open";process.exit(ok?0:1)})' | yes | ✅ green |
| 254-01-03 | 254-01 | 1 | CIQ-04 | T-254-01, T-254-02, T-254-06, T-254-SC | CI fingerprint/evidence upload steps and the ci-collect reader | auto | node --test --test-reporter=tap scripts/ci/phase254_measure.test.mjs && node scripts/ci/verify_ci_efficiency_contract.mjs --repo . && for f in .github/workflows/ci.yml .github/workflows/accrue_admin_browser.yml; do test "$(grep -v -e '^[[:space:]]*#' "$f" &#124; grep -c -e 'name: Phase 254 machine fingerprint')" = 1 && test "$(grep -v -e '^[[:space:]]*#' "$f" &#124; grep -c -e 'name: Upload Phase 254 machine evidence')" = 1 &#124;&#124; exit 1; done | yes | ✅ green |
| 254-02-01 | 254-02 | 1 | CIQ-02, CIQ-04 | T-254-03, T-254-04, T-254-SC | Guard the four Phase 252 path/boundary/story/transparency verifiers | auto | node -e 'const fs=require("node:fs"),os=require("node:os"),path=require("node:path");const files=["scripts/ci/phase252_paths.mjs","scripts/ci/verify_phase252_production_boundary.mjs","scripts/ci/verify_phase252_stories.mjs","scripts/ci/verify_phase252_transparency.mjs"];const f=p=>({relativePath:p,absolutePath:path.resolve(p),spawnPath:p,cwd:process.cwd()});import("./scripts/ci/verify_ci_script_contract.mjs").then(({assertGuardCoverage})=>{const d=fs.mkdtempSync(path.join(os.tmpdir(),"p254-guard-"));const g=path.join(d,"guardless.mjs");fs.writeFileSync(g,"console.log(1);\n");let fired=false;try{assertGuardCoverage([{relativePath:"scripts/ci/guardless.mjs",absolutePath:g,spawnPath:g,cwd:d}],new Map())}catch(e){fired=/module-boundary guard/.test(e.message)}if(!fired){console.error("positive control did not fire");process.exit(1)}assertGuardCoverage(files.map(f),new Map());console.log("guard coverage: four files PASS")})' && node --test --test-reporter=tap scripts/ci/phase252_paths.mjs scripts/ci/verify_phase252_production_boundary.mjs scripts/ci/verify_phase252_stories.mjs scripts/ci/verify_phase252_transparency.mjs scripts/ci/verify_phase252_ci_contract.test.mjs | yes | ✅ green |
| 254-02-02 | 254-02 | 1 | CIQ-02, CIQ-04 | T-254-03, T-254-04, T-254-SC | Guard the two acceptance generators and the Phase 253 aggregate | auto | node -e 'const fs=require("node:fs"),os=require("node:os"),path=require("node:path");const files=["scripts/ci/generate_phase252_acceptance.mjs","scripts/ci/generate_phase253_acceptance.mjs","scripts/ci/verify_phase253_compositions.mjs"];const f=p=>({relativePath:p,absolutePath:path.resolve(p),spawnPath:p,cwd:process.cwd()});import("./scripts/ci/verify_ci_script_contract.mjs").then(({assertGuardCoverage})=>{const d=fs.mkdtempSync(path.join(os.tmpdir(),"p254-guard-"));const g=path.join(d,"guardless.mjs");fs.writeFileSync(g,"console.log(1);\n");let fired=false;try{assertGuardCoverage([{relativePath:"scripts/ci/guardless.mjs",absolutePath:g,spawnPath:g,cwd:d}],new Map())}catch(e){fired=/module-boundary guard/.test(e.message)}if(!fired){console.error("positive control did not fire");process.exit(1)}assertGuardCoverage(files.map(f),new Map());console.log("guard coverage: three files PASS")})' && node --test --test-reporter=tap scripts/ci/generate_phase252_acceptance.mjs scripts/ci/generate_phase253_acceptance.mjs scripts/ci/verify_phase253_compositions.mjs scripts/ci/generate_phase252_acceptance.test.mjs scripts/ci/generate_phase253_acceptance.test.mjs scripts/ci/verify_phase253_compositions.test.mjs | yes | ✅ green |
| 254-02-03 | 254-02 | 1 | CIQ-02, CIQ-04 | T-254-03, T-254-04, T-254-SC | Default projects stop loading lab specs; spec ownership and pure-story classifier contract | auto | node --test --test-reporter=tap scripts/ci/phase254_project_ownership.test.mjs && cd accrue_admin && npx playwright test --list --project=chromium-desktop &#124; tee /dev/stderr &#124; grep -E -e '^Total: [1-9][0-9]* tests?' && npx playwright test --list --project=visual-desktop &#124; grep -E -e 'admin-visual-regression-phase211' | yes | ✅ green |
| 254-03-01 | 254-03 | 2 | CIQ-04 | T-254-05, T-254-36, T-254-SC | Owner confirms the first outward push (D-25) | checkpoint:decision | checkpoint:decision (recorded answer for 254-03-01) | n/a | ✅ green |
| 254-03-02 | 254-03 | 2 | CIQ-04 | T-254-05, T-254-36, T-254-SC | Pre-push gate, push, draft PR, first CI observations and mechanical triage | auto | node --test --test-reporter=tap scripts/ci/phase254_measure.test.mjs && git rev-parse --abbrev-ref '@{u}' && test "$(gh pr view --json isDraft --jq .isDraft)" = "true" && node -e 'const b=require("./accrue_admin/storybook/phase254-budget.json");const ci=b.metrics.ci&#124;&#124;[];const ok=j=>ci.some(s=>s.job===j&&s.attempt===1&&typeof s.conclusion==="string"&&s.informs_only===true&&s.fingerprint&&s.fingerprint.image_os&&s.cache&&typeof s.cache.hits==="number"&&typeof s.cache.misses==="number");const d=b.deviations.find(x=>x.id==="DEV-254-02");const C=["in-scope","pre-existing-on-main","out-of-scope-branch-only","environmental"];if(!ok("admin-phase200-guardrails")&#124;&#124;!ok("browser-uat")&#124;&#124;!d&#124;&#124;!Array.isArray(d.entries)&#124;&#124;!d.entries.every(e=>C.includes(e.classification))&#124;&#124;d.entries.some(e=>e.classification==="in-scope"&&!(e.fixed_in_sha&&e.followup_run_id)))process.exit(1)' | yes | ✅ green |
| 254-03-03 | 254-03 | 2 | CIQ-04 | T-254-05, T-254-36, T-254-SC | Owner disposition of out-of-scope CI reds (escalation) | checkpoint:decision | checkpoint:decision (recorded answer for 254-03-03) | n/a | ✅ green |
| 254-04-01 | 254-04 | 3 | CURATE-01 | T-254-07, T-254-08, T-254-SC | Ledger to JSON to guide to verifier, end-to-end with the three primitive-retain records | auto | node --test --test-reporter=tap scripts/ci/verify_phase254_curation.test.mjs && node scripts/ci/verify_phase254_curation.mjs --self-test && node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_manifest_test.exs && node scripts/ci/verify_phase254_curation.mjs && node -e 'const c=require("./accrue_admin/storybook/subscription-curation.json"),m=require("./storybook/phase252-manifest.json");const fb=c.frozen_baseline,S=fb.subjects&#124;&#124;[];const has=(p,v)=>S.some(x=>x.story_path===p&&(v===null&#124;&#124;x.variation_id===v));const covered=c.records.every(r=>has(r.subject.story_path,r.subject.variation_id));if(fb.entries!==m.entries.length&#124;&#124;c.records.length!==3&#124;&#124;!c.records.every(r=>r.disposition==="retain")&#124;&#124;!(c.amendments&#124;&#124;[]).some(a=>a.id==="AMD-254-01")&#124;&#124;!fb.source_commit&#124;&#124;!has("/components/subscription_detail","populated")&#124;&#124;!has("/components/action_menu","provider_pruned")&#124;&#124;!covered)process.exit(1)' && (cd accrue_admin && MIX_ENV=test mix run --no-start -e '{:ok, _} = Application.ensure_all_started(:localize); m = AccrueAdmin.Storybook.SubscriptionManifest; :ok = m.verify!(Path.expand("../storybook/phase252-manifest.json")); t = Path.join(System.tmp_dir!(), "phase254-guide-#{System.unique_integer([:positive])}.md"); :ok = m.write_coverage_guide!(t); same = File.read!(t) == File.read!(Path.expand("../guides/subscription-story-coverage.md")); File.rm(t); unless same, do: raise("committed guide is stale")') | yes | ✅ green |
| 254-04-02 | 254-04 | 3 | CURATE-01 | T-254-07, T-254-08, T-254-SC | Derive the five pinned Phase 252 count sites from the ledger | auto | node --test --test-reporter=tap scripts/ci/generate_phase252_acceptance.test.mjs scripts/ci/phase252_reporters.test.mjs scripts/ci/verify_phase254_curation.test.mjs && node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_manifest_test.exs | yes | ✅ green |
| 254-04-03 | 254-04 | 3 | CURATE-01 | T-254-07, T-254-08, T-254-SC | Retain and reclassify braintree_pruned and dunning_active with recorded claim drift | auto | node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_manifest_test.exs && node scripts/ci/verify_phase254_curation.mjs && node -e 'const c=require("./accrue_admin/storybook/subscription-curation.json");const ids=c.records.map(r=>r.id);if(ids.length!==5&#124;&#124;ids.join()!==[...ids].sort().join()&#124;&#124;!["CUR-254-04","CUR-254-05"].every(i=>c.records.find(r=>r.id===i&&r.disposition==="reclassify")))process.exit(1)' && (cd accrue_admin && MIX_ENV=test mix run --no-start -e '{:ok, _} = Application.ensure_all_started(:localize); m = AccrueAdmin.Storybook.SubscriptionManifest; :ok = m.verify!(Path.expand("../storybook/phase252-manifest.json")); t = Path.join(System.tmp_dir!(), "phase254-guide-#{System.unique_integer([:positive])}.md"); :ok = m.write_coverage_guide!(t); same = File.read!(t) == File.read!(Path.expand("../guides/subscription-story-coverage.md")); File.rm(t); unless same, do: raise("committed guide is stale")') | yes | ✅ green |
| 254-05-01 | 254-05 | 4 | CIQ-02 | T-254-09, T-254-10, T-254-SC | Review lane refuses reset/seed with 403, proved in ExUnit and on two live lab servers | auto | node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/e2e_plug_isolation_test.exs && node scripts/dev/phase252_lab.mjs isolation | yes | ✅ green |
| 254-05-02 | 254-05 | 4 | CIQ-02 | T-254-09, T-254-10, T-254-SC | Side-effect-free per-case ledger with an interleaving race control | auto | node --test --test-reporter=tap scripts/ci/phase254_result_ledger.test.mjs | yes | ✅ green |
| 254-05-03 | 254-05 | 4 | CIQ-02 | T-254-09, T-254-10, T-254-SC | Composition cells write per-case files; dependent reconcile project merges them | auto | node --test --test-reporter=tap scripts/ci/phase254_project_ownership.test.mjs scripts/ci/phase254_result_ledger.test.mjs | yes | ✅ green |
| 254-06-01 | 254-06 | 5 | CURATE-01 | T-254-11, T-254-12, T-254-SC | Make populated-dependent tests ledger-aware before any removal | auto | node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_scenarios_test.exs && grep -c -e 'curation_ledger' accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs | yes | ✅ green |
| 254-06-02 | 254-06 | 5 | CURATE-01 | T-254-11, T-254-12, T-254-SC | Retire subscription_detail&#124;&#124;populated with commit-anchored duplicate evidence | auto | node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_scenarios_test.exs && node scripts/ci/verify_phase252_transparency.mjs --self-test && node scripts/ci/verify_phase254_curation.mjs --self-test && node scripts/ci/verify_phase254_curation.mjs && (cd accrue_admin && MIX_ENV=test mix run --no-start -e '{:ok, _} = Application.ensure_all_started(:localize); m = AccrueAdmin.Storybook.SubscriptionManifest; :ok = m.verify!(Path.expand("../storybook/phase252-manifest.json")); t = Path.join(System.tmp_dir!(), "phase254-guide-#{System.unique_integer([:positive])}.md"); :ok = m.write_coverage_guide!(t); same = File.read!(t) == File.read!(Path.expand("../guides/subscription-story-coverage.md")); File.rm(t); unless same, do: raise("committed guide is stale")') | yes | ✅ green |
| 254-06-03 | 254-06 | 5 | CURATE-01 | T-254-11, T-254-12, T-254-SC | Merge action_menu/provider_pruned and correct the stale caller_map rows | auto | node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_manifest_test.exs && node scripts/ci/verify_phase254_curation.mjs && node -e 'const c=require("./accrue_admin/storybook/subscription-curation.json");const ids=c.records.map(r=>r.id);if(ids.length!==7&#124;&#124;ids.join()!==[...ids].sort().join())process.exit(1)' && (cd accrue_admin && MIX_ENV=test mix run --no-start -e '{:ok, _} = Application.ensure_all_started(:localize); m = AccrueAdmin.Storybook.SubscriptionManifest; :ok = m.verify!(Path.expand("../storybook/phase252-manifest.json")); t = Path.join(System.tmp_dir!(), "phase254-guide-#{System.unique_integer([:positive])}.md"); :ok = m.write_coverage_guide!(t); same = File.read!(t) == File.read!(Path.expand("../guides/subscription-story-coverage.md")); File.rm(t); unless same, do: raise("committed guide is stale")') | yes | ✅ green |
| 254-07-01 | 254-07 | 6 | CIQ-02 | T-254-13, T-254-14, T-254-15, T-254-SC | depends_on in both compiled manifests, constrained to source_digests | auto | cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_compositions_manifest_test.exs && cd .. && node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_manifest_test.exs && node scripts/ci/verify_phase254_curation.mjs && (cd accrue_admin && MIX_ENV=test mix run --no-start -e '{:ok, _} = Application.ensure_all_started(:localize); m = AccrueAdmin.Storybook.SubscriptionManifest; :ok = m.verify!(Path.expand("../storybook/phase252-manifest.json")); t = Path.join(System.tmp_dir!(), "phase254-guide-#{System.unique_integer([:positive])}.md"); :ok = m.write_coverage_guide!(t); same = File.read!(t) == File.read!(Path.expand("../guides/subscription-story-coverage.md")); File.rm(t); unless same, do: raise("committed guide is stale")') | yes | ✅ green |
| 254-07-02 | 254-07 | 6 | CIQ-02 | T-254-13, T-254-14, T-254-15, T-254-SC | Shared cell universe and the tracked selection projection with sentinels | auto | node --test --test-reporter=tap scripts/ci/phase254_selection.test.mjs && node scripts/ci/phase254_selection.mjs project --check && node -e 'Promise.all([import("./scripts/ci/verify_phase254_curation.mjs")]).then(([cur])=>{const p=require("./accrue_admin/storybook/phase254-selection.json");const c=require("./accrue_admin/storybook/subscription-curation.json");const e=cur.expectedPhase252Cells(c);if(p.always_run.length!==e.total&#124;&#124;!p.cases.length&#124;&#124;new Set(p.cases.map(x=>x.id)).size!==p.cases.length&#124;&#124;p.cases.length!==p.expected_case_count)process.exit(1)})' | yes | ✅ green |
| 254-07-03 | 254-07 | 6 | CIQ-02 | T-254-13, T-254-14, T-254-15, T-254-SC | Fail-closed select verb, report, invariants and the D-14 control set | auto | node --test --test-reporter=tap scripts/ci/phase254_selection.test.mjs scripts/ci/verify_phase252_ci_contract.test.mjs && node scripts/ci/phase254_selection.mjs --self-test && node scripts/ci/phase254_selection.mjs project --check | yes | ✅ green |
| 254-08-01 | 254-08 | 7 | CIQ-02 | T-254-16, T-254-17, T-254-SC | The composition lane executes exactly the reported selection | auto | node --test --test-reporter=tap scripts/ci/verify_phase253_compositions.test.mjs && node scripts/ci/phase254_selection.mjs select --event pull_request --changed-paths-file scripts/ci/fixtures/phase254-selection/collection-only.txt --out accrue_admin/tmp/phase254/selection-local.json && node -e 'import("./scripts/ci/phase254_selection.mjs").then(({assertSelectionInvariants})=>{const r=require("./accrue_admin/tmp/phase254/selection-local.json");assertSelectionInvariants(r);process.exit(r.mode==="affected"&&r.excluded.length>0?0:1)})' | yes | ✅ green |
| 254-08-02 | 254-08 | 7 | CIQ-02 | T-254-16, T-254-17, T-254-SC | CI computes the selection on full history; new Phase 254 paths are admitted roots | auto | node --test --test-reporter=tap scripts/ci/verify_phase252_ci_contract.test.mjs && node scripts/ci/verify_ci_efficiency_contract.mjs --repo . && bash scripts/ci/verify_phase200_guardrail_contract.sh | yes | ✅ green |
| 254-09-01 | 254-09 | 8 | CIQ-04, CIQ-02 | T-254-18, T-254-19, T-254-41, T-254-SC | Budget check, freeze and target-evaluation logic with fail/warn controls | auto | node --test --test-reporter=tap scripts/ci/phase254_budget.test.mjs && node scripts/ci/phase254_budget.mjs --self-test | yes | ✅ green |
| 254-09-02 | 254-09 | 8 | CIQ-04, CIQ-02 | T-254-18, T-254-19, T-254-41, T-254-SC | Append the budget check to the required owner | auto | bash scripts/ci/verify_phase200_guardrail_contract.sh && node --test --test-reporter=tap scripts/ci/verify_phase252_ci_contract.test.mjs && node scripts/ci/phase254_budget.mjs restamp-manifest --check && node -e 'const b=require("./accrue_admin/storybook/phase254-budget.json");const d=b.deviations.filter(x=>x.kind==="manifest-restamp");process.exit(d.some(x=>/^DEV-254-1[1-9]$/.test(x.id)&&x.status==="resolved"&&x.from&&x.to)?0:1)' | yes | ✅ green |
| 254-09-03 | 254-09 | 8 | CIQ-04, CIQ-02 | T-254-18, T-254-19, T-254-41, T-254-SC | Three first-attempt CI runs, target evaluations, D-24 resolution, allowances and the freeze | auto | node -e 'const b=require("./accrue_admin/storybook/phase254-budget.json");const f=b.frozen,r=(f&&f.basis&&f.basis.runs)&#124;&#124;[];const cc=(f&&f.composition_cell)&#124;&#124;{};const T=["warm_preview_s","focused_check_s","additional_warm_browser_s","incremental_ci_critical_path_s"];const te=b.target_evaluations&#124;&#124;[];const D=id=>b.deviations.find(d=>d.id===id);const ids=new Set(b.deviations.map(d=>d.id));const a=b.allowances&#124;&#124;{};const fo=D("DEV-254-05");const d1=D("DEV-254-01");const basis=(id,k)=>{const d=D(id);return d&&d.kind===k&&d.status==="accepted"&&!!d.owner_decision};const ok=f&&f.metric==="owner_job_added_s"&&typeof f.value==="number"&&r.length===3&&new Set(r.map(x=>x.run_id)).size===3&&new Set(r.map(x=>x.head_sha)).size===1&&r.every(x=>x.attempt===1&&x.conclusion==="success"&&x.fingerprint&&x.fingerprint.image_os&&x.fingerprint.dirty===false&&x.cache&&typeof x.cache.hits==="number"&&typeof x.cache.misses==="number")&&cc.lane==="phase253-compositions-browser"&&typeof cc.per_cell_p90_s==="number"&&cc.cells>0&&(cc.run_ids&#124;&#124;[]).length===3&&Math.abs(b.warn_at-b.metrics.freeze.p90*f.multipliers.warn_at)<1e-6&&Math.abs(b.ceiling-f.value*f.multipliers.ceiling)<1e-6&&T.every(k=>te.filter(e=>e.target===k&&typeof e.measured_s==="number").length===1)&&te.every(e=>e.met===true&#124;&#124;ids.has(e.deviation_id))&&["focused_check_s","additional_warm_browser_s"].every(k=>te.some(e=>e.target===k&&typeof e.cells==="number"&&e.basis_deviation_id==="DEV-254-10"))&&["visual","a11y"].every(k=>a[k]&&typeof a[k].baseline_p90_s==="number"&&typeof a[k].max_added_s==="number"&&a[k].basis&&a[k].basis.length)&&a.visual.n>=1&&fo&&["ciq02-fanout","ciq02-fanout-enabled"].includes(fo.kind)&&Math.abs(fo.per_cell_p90_s-cc.per_cell_p90_s)<1e-9&&(fo.isolation_test_ids&#124;&#124;[]).length>0&&(D("DEV-254-08")&#124;&#124;{}).kind==="visual-owner-outside-critical-path"&&basis("DEV-254-09","ciq04-visual-sample-basis")&&basis("DEV-254-10","ciq04-full-mode-basis")&&d1&&["resolved","accepted"].includes(d1.status)&&d1.closed_by==="254-09-03"&&d1.closing_measurement&&(d1.closing_measurement.resolved_by&#124;&#124;[]).length>0&&d1.before&&d1.after&&b.deviations.every(d=>!d.before&#124;&#124;!d.after&#124;&#124;d.after.cells>=d.before.cells);process.exit(ok?0:1)' && node scripts/ci/phase254_budget.mjs restamp-manifest --check && node scripts/ci/phase254_budget.mjs check --evidence-latest accrue_admin/tmp/phase254/ci | yes | ✅ green |
| 254-10-01 | 254-10 | 9 | UXQ-04 | T-254-20, T-254-21, T-254-SC | Deterministic storybook.css recompose with CI freshness | auto | node --test --test-reporter=tap scripts/ci/recompose_storybook_css.test.mjs && node scripts/ci/recompose_storybook_css.mjs --self-test && node scripts/ci/recompose_storybook_css.mjs --check && node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/storybook_asset_test.exs && node scripts/ci/verify_ci_efficiency_contract.mjs --repo . | yes | ✅ green |
| 254-10-02 | 254-10 | 9 | UXQ-04 | T-254-20, T-254-21, T-254-SC | Open the typed design review record at stage assessment, with its verifier | auto | node --test --test-reporter=tap scripts/ci/verify_phase254_design_review.test.mjs && node scripts/ci/verify_phase254_design_review.mjs --self-test && node scripts/ci/verify_phase254_design_review.mjs --check --stage assessment && node scripts/ci/verify_phase230_archive_invariants.mjs --repo . | yes | ✅ green |
| 254-11-01 | 254-11 | 10 | UXQ-02 | T-254-22, T-254-23, T-254-SC | All-severity axe in every selected cell, end-to-end through the register validator | auto | node --test --test-reporter=tap scripts/ci/verify_a11y_dispositions.test.mjs && node scripts/ci/verify_a11y_dispositions.mjs --self-test | yes | ✅ green |
| 254-11-02 | 254-11 | 10 | UXQ-02 | T-254-22, T-254-23, T-254-SC | Alpha-correct contrast and the D-28 deep probes, each with its injected control | auto | node --test --test-reporter=tap scripts/ci/verify_a11y_dispositions.test.mjs && cd accrue_admin && env -u NO_COLOR npx playwright test e2e/foundation-tokens.spec.js --project=chromium-desktop --workers=1 | yes | ✅ green |
| 254-11-03 | 254-11 | 10 | UXQ-02 | T-254-22, T-254-23, T-254-SC | Mounted keyboard journey with asserted focus restore | auto | cd accrue_admin && env -u NO_COLOR npx playwright test e2e/admin-interactions.spec.js --workers=1 --grep "D-29 keyboard journey" | yes | ✅ green |
| 254-12-01 | 254-12 | 11 | UXQ-04, UXQ-02 | T-254-24, T-254-37, T-254-SC | D-35 computed-style tests, proved red on the pre-fix commit from the parsed report | auto | node --test --test-reporter=tap scripts/ci/verify_phase254_design_review.test.mjs scripts/ci/phase254_project_ownership.test.mjs && mkdir -p accrue_admin/tmp/phase254 && rm -f accrue_admin/tmp/phase254/design-red.json && st=0 && { PLAYWRIGHT_JSON_OUTPUT_FILE="$PWD/accrue_admin/tmp/phase254/design-red.json" node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-design-phase254.spec.js --reporter=json &#124;&#124; st=$?; } && test "$st" -ne 0 && node scripts/ci/verify_phase254_design_review.mjs --check-red --report accrue_admin/tmp/phase254/design-red.json --evidence .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-12-01-red-evidence.json | yes | ✅ green |
| 254-12-02 | 254-12 | 11 | UXQ-04, UXQ-02 | T-254-24, T-254-37, T-254-SC | CSS, routed a11y and contract corrections across all artifacts | auto | cd accrue_admin && mix accrue_admin.assets.build && a=$(shasum -a 256 priv/static/accrue_admin.css &#124; cut -d' ' -f1) && mix accrue_admin.assets.build && b=$(shasum -a 256 priv/static/accrue_admin.css &#124; cut -d' ' -f1) && test "$a" = "$b" && cd .. && node scripts/ci/recompose_storybook_css.mjs --check && bash scripts/ci/verify_package_docs.sh && rc=$(node -p 'require("./.planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-12-01-red-evidence.json").commit') && git show "$rc:accrue_admin/assets/css/app.css" > accrue_admin/tmp/phase254/app-prefix.css && node -e 'const fs=require("node:fs");import("./scripts/ci/verify_phase254_design_review.mjs").then(({scanSubscriptionDetailSpacing:s})=>{const before=s(fs.readFileSync("accrue_admin/tmp/phase254/app-prefix.css","utf8"));const after=s(fs.readFileSync("accrue_admin/assets/css/app.css","utf8"));process.exit(before.length>0&&after.length===0?0:1)})' && node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-design-phase254.spec.js && node scripts/ci/verify_a11y_dispositions.mjs --self-test && node -e 'const r=require("./accrue_admin/e2e/a11y-dispositions.json");process.exit((r.entries&#124;&#124;[]).some(e=>e.exception_class==="routed-defect")?1:0)' && u=.planning/phases/253-real-groups-and-a-whole-subscription-job/253-UI-SPEC.md && test "$(grep -c -e '^&#124; Section title' "$u")" = 1 && grep -q -e '^&#124; Page heading.*--ax-type-xl.*--ax-type-2xl' "$u" | yes | ✅ green |
| 254-13-01 | 254-13 | 12 | UXQ-04 | T-254-25, T-254-38, T-254-SC | Copy-tier tests named by finding id, proved red on the pre-fix commit | auto | mkdir -p accrue_admin/tmp/phase254 && st=0 && { node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_action_copy_test.exs > accrue_admin/tmp/phase254/copy-red.txt 2>&1 &#124;&#124; st=$?; } && test "$st" -ne 0 && node scripts/ci/verify_phase254_design_review.mjs --check-red --format exunit --report accrue_admin/tmp/phase254/copy-red.txt --evidence .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-13-01-red-evidence.json | yes | ✅ green |
| 254-13-02 | 254-13 | 12 | UXQ-04 | T-254-25, T-254-38, T-254-SC | Copy-tier owner functions for the result link, wired into the required lane | auto | node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_action_copy_test.exs && f=examples/accrue_host/e2e/generated/copy_strings.json && a=$(shasum -a 256 "$f" &#124; cut -d' ' -f1) && (cd accrue_admin && mix accrue_admin.export_copy_strings) && b=$(shasum -a 256 "$f" &#124; cut -d' ' -f1) && test "$a" = "$b" && (cd accrue_admin && MIX_ENV=test mix run --no-start -e '{:ok, _} = Application.ensure_all_started(:localize); m = AccrueAdmin.Storybook.SubscriptionManifest; :ok = m.verify!(Path.expand("../storybook/phase252-manifest.json")); t = Path.join(System.tmp_dir!(), "phase254-guide-#{System.unique_integer([:positive])}.md"); :ok = m.write_coverage_guide!(t); same = File.read!(t) == File.read!(Path.expand("../guides/subscription-story-coverage.md")); File.rm(t); unless same, do: raise("committed guide is stale")') && node scripts/ci/verify_phase254_curation.mjs && node scripts/ci/phase254_selection.mjs project --check && node scripts/ci/phase254_budget.mjs restamp-manifest --check | yes | ✅ green |
| 254-13-03 | 254-13 | 12 | UXQ-04 | T-254-25, T-254-38, T-254-SC | Close the correction batch in the design review record (stage corrected) | auto | node --test --test-reporter=tap scripts/ci/verify_phase254_design_review.test.mjs && node scripts/ci/verify_phase254_design_review.mjs --check --stage corrected | yes | ✅ green |
| 254-14-01 | 254-14 | 13 | CIQ-03 | T-254-26, T-254-27, T-254-SC | Story routes on the legacy server, then one deterministic case end-to-end up to the screenshot | auto | node scripts/ci/phase254_selection.mjs project --check && node --test --test-reporter=tap scripts/ci/phase254_project_ownership.test.mjs && node scripts/ci/verify_ci_efficiency_contract.mjs --repo . && mkdir -p accrue_admin/tmp/phase254 && rm -f accrue_admin/tmp/phase254/visual-local.json && (cd accrue_admin && PLAYWRIGHT_JSON_OUTPUT_FILE="$PWD/tmp/phase254/visual-local.json" npx playwright test e2e/subscription-visual-phase254.spec.js --project=visual-desktop --workers=1 --update-snapshots=none --grep "A4 &#124;phase254-page-active-w1280-light" --reporter=json; test -s tmp/phase254/visual-local.json) && node -e 'const r=require("./accrue_admin/tmp/phase254/visual-local.json");const v=require("./accrue_admin/storybook/phase254-visual-cases.json");const t=[];const walk=s=>{(s.specs&#124;&#124;[]).forEach(sp=>sp.tests.forEach(x=>t.push({title:sp.title,res:x.results[0]})));(s.suites&#124;&#124;[]).forEach(walk)};r.suites.forEach(walk);const probe=t.filter(x=>/^A4 /.test(x.title));const cases=t.filter(x=>!probe.includes(x));const a4=v.sourcing&&v.sourcing.a4;const probeOk=a4==="story-routes"?probe.length>0&&probe.every(x=>x.res.status==="passed"):a4==="mounted-fallback"&&probe.length>0&&probe.some(x=>x.res.status!=="passed")&&v.cases.every(c=>c.kind==="mounted")&&!!v.sourcing.probe_error;const missing=x=>x.res.status!=="passed"&&(x.res.errors&#124;&#124;[]).length>0&&x.res.errors.every(e=>/snapshot.*(doesn.t exist&#124;missing)/i.test(e.message&#124;&#124;""));const keys=new Set(v.cases.map(c=>c.key));if(!probeOk&#124;&#124;!(v.amendments&#124;&#124;[]).some(a=>a.id==="AMD-254-02")&#124;&#124;cases.length!==1&#124;&#124;!keys.has(cases[0].title)&#124;&#124;!cases.every(missing))process.exit(1)' && d=accrue_admin/e2e/__screenshots__ && touch "$d/.phase254-probe" && test -n "$(git status --porcelain --untracked-files=all -- "$d")" && rm -f "$d/.phase254-probe" && test -z "$(git status --porcelain --untracked-files=all -- "$d")" | yes | ✅ green |
| 254-14-02 | 254-14 | 13 | CIQ-03 | T-254-26, T-254-27, T-254-SC | Identity manifest and the upgraded baseline set guard | auto | cd accrue_admin && node --test test/js/*.mjs && cd .. && node accrue_admin/e2e/visual-baseline-set.cjs accrue_admin/e2e/__screenshots__/visual-desktop --pre-mint && node --test --test-reporter=tap scripts/ci/phase254_visual_manifest.test.mjs && node scripts/ci/phase254_visual_manifest.mjs --self-test | yes | ✅ green |
| 254-14-03 | 254-14 | 13 | CIQ-03 | T-254-26, T-254-27, T-254-SC | Mint workflow hardening, its mutation contract, and the Phase 211 spec fixes | auto | node --test --test-reporter=tap scripts/ci/phase254_visual_contract.test.mjs && node scripts/ci/verify_ci_efficiency_contract.mjs --repo . && (cd accrue_admin && node --test --test-name-pattern='byte' test/js/visual_baseline_set_test.mjs) && node accrue_admin/e2e/visual-baseline-set.cjs accrue_admin/e2e/__screenshots__/visual-desktop --pre-mint | yes | ✅ green |
| 254-15-01 | 254-15 | 14 | CIQ-03, UXQ-04, CIQ-04 | T-254-28, T-254-29, T-254-39, T-254-SC | Mint on the Linux owner, disposition every changed PNG, commit attributable baselines, observe the gate | auto | base=$(git merge-base HEAD origin/main) && head=$(git rev-parse HEAD) && branch=$(git branch --show-current) && node accrue_admin/e2e/visual-baseline-set.cjs accrue_admin/e2e/__screenshots__/visual-desktop && node scripts/ci/phase254_visual_manifest.mjs check --base "$base" && for k in subscriptions subscriptions-dark; do test "$(git rev-parse "HEAD^:accrue_admin/e2e/__screenshots__/visual-desktop/$k.png")" = "$(git hash-object "accrue_admin/e2e/__screenshots__/visual-desktop/$k.png")" &#124;&#124; exit 1; done && mkdir -p accrue_admin/tmp/phase254 && id=$(gh run list --workflow accrue_admin_browser.yml --branch "$branch" --event pull_request --commit "$head" --limit 1 --json databaseId --jq '.[0].databaseId') && test -n "$id" && gh run view "$id" --json attempt,headSha,jobs > accrue_admin/tmp/phase254/uat-run.json && HEAD_SHA="$head" node -e 'const r=require("./accrue_admin/tmp/phase254/uat-run.json");const b=require("./accrue_admin/storybook/phase254-budget.json");const m=require("./accrue_admin/e2e/__screenshots__/visual-desktop/manifest.json");const v=require("./accrue_admin/storybook/phase254-visual-cases.json");const keys=Object.keys(m.entries&#124;&#124;m);const job=r.jobs.find(j=>/browser-uat&#124;Browser UAT/i.test(j.name));const steps=(job&&job.steps)&#124;&#124;[];const owned=[/baseline set/i,/manifest/i,/visual regression/i];const ownedOk=owned.every(re=>steps.some(s=>re.test(s.name)&&s.conclusion==="success"));const tri=b.deviations.filter(d=>d.kind==="browser-uat-triage").flatMap(d=>d.entries&#124;&#124;[]);const othersOk=steps.filter(s=>s.conclusion==="failure").every(s=>tri.some(e=>e.step===s.name&&(e.fixed_in_sha&#124;&#124;e.decision)));const vis=b.metrics.visual;const ok=r.attempt===1&&r.headSha===process.env.HEAD_SHA&&ownedOk&&othersOk&&keys.length===12+v.cases.length&&vis&&typeof vis.added_s==="number"&&vis.per_cell&&typeof vis.per_cell.p90_ms==="number"&&b.deviations.some(d=>d.kind==="visual-cell-budget-freeze");const E=Object.values(m.entries&#124;&#124;{}).filter(e=>e&&typeof e==="object"&&"mint_run_id" in e&&e.provenance!=="phase211-committed");const runs=[...new Set(E.map(e=>String(e.mint_run_id)))].sort();const amd=(v.amendments&#124;&#124;[]).find(a=>a.id==="AMD-254-06");const mintOk=runs.length===1&#124;&#124;(runs.length>1&&!!amd&&!!amd.owner_decision&&JSON.stringify([...(amd.amended&#124;&#124;[])].map(String).sort())===JSON.stringify(runs));process.exit(ok&&mintOk?0:1)' && test -n "$(git log -n 1 -E --grep='^test\(visual\): rebaseline' --format=%H)" | yes | ✅ green |
| 254-15-02 | 254-15 | 14 | CIQ-03, UXQ-04, CIQ-04 | T-254-28, T-254-29, T-254-39, T-254-SC | Owner disposition of environmental baseline drift or out-of-scope Browser UAT reds (escalation) | checkpoint:decision | checkpoint:decision (recorded answer for 254-15-02) | n/a | ✅ green |
| 254-15-03 | 254-15 | 14 | CIQ-03, UXQ-04, CIQ-04 | T-254-28, T-254-29, T-254-39, T-254-SC | Confirmation pass from committed captures; record reaches stage confirmed | auto | node --test --test-reporter=tap scripts/ci/verify_phase254_design_review.test.mjs && node scripts/ci/verify_phase254_design_review.mjs --self-test && node scripts/ci/verify_phase254_design_review.mjs --check --stage confirmed | yes | ✅ green |
| 254-16-01 | 254-16 | 15 | CURATE-02 | T-254-30, T-254-31, T-254-SC | Route-seeded gap map rows, end-to-end into the guide | auto | node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_manifest_test.exs && (cd accrue_admin && MIX_ENV=test mix run --no-start -e '{:ok, _} = Application.ensure_all_started(:localize); m = AccrueAdmin.Storybook.SubscriptionManifest; :ok = m.verify!(Path.expand("../storybook/phase252-manifest.json")); t = Path.join(System.tmp_dir!(), "phase254-guide-#{System.unique_integer([:positive])}.md"); :ok = m.write_coverage_guide!(t); same = File.read!(t) == File.read!(Path.expand("../guides/subscription-story-coverage.md")); File.rm(t); unless same, do: raise("committed guide is stale")') && node scripts/ci/verify_phase254_curation.mjs && node scripts/ci/phase254_selection.mjs project --check && node scripts/ci/phase254_budget.mjs restamp-manifest --check | yes | ✅ green |
| 254-16-02 | 254-16 | 15 | CURATE-02 | T-254-30, T-254-31, T-254-SC | Five distinct synthetic adopter briefs | auto | node --test --test-reporter=tap scripts/ci/verify_phase254_curation.test.mjs && node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_manifest_test.exs && node scripts/ci/verify_phase254_curation.mjs && node -e 'const c=require("./accrue_admin/storybook/subscription-curation.json");const b=c.briefs&#124;&#124;[];process.exit(b.length===5&&b.every(x=>x.synthetic===true&&x.maintenance_cost&&typeof x.maintenance_cost.browser_cost_s==="number"&&["high","medium","low"].includes(x.maintenance_cost.level))?0:1)' && (cd accrue_admin && MIX_ENV=test mix run --no-start -e '{:ok, _} = Application.ensure_all_started(:localize); m = AccrueAdmin.Storybook.SubscriptionManifest; :ok = m.verify!(Path.expand("../storybook/phase252-manifest.json")); t = Path.join(System.tmp_dir!(), "phase254-guide-#{System.unique_integer([:positive])}.md"); :ok = m.write_coverage_guide!(t); same = File.read!(t) == File.read!(Path.expand("../guides/subscription-story-coverage.md")); File.rm(t); unless same, do: raise("committed guide is stale")') && node scripts/ci/verify_phase254_curation.mjs && node scripts/ci/phase254_selection.mjs project --check && node scripts/ci/phase254_budget.mjs restamp-manifest --check | yes | ✅ green |
| 254-16-03 | 254-16 | 15 | CURATE-02 | T-254-30, T-254-31, T-254-SC | Hard-filtered, cost-aware next-job candidates and the recommendation input | auto | node --test --test-reporter=tap scripts/ci/verify_phase254_curation.test.mjs && node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_manifest_test.exs && node scripts/ci/verify_phase254_curation.mjs && node -e 'const c=require("./accrue_admin/storybook/subscription-curation.json");const n=c.next_job;if(!n&#124;&#124;n.status!=="recommendation-input"&#124;&#124;!n.recommendation&#124;&#124;n.candidates.find(x=>x.id===n.recommendation).filters.gated)process.exit(1)' && cnt() { grep -c -E -e '^### Phase &#124;^- .*\*\*v[0-9]+\.[0-9]+' "$1"; } && tmp=$(mktemp -d) && git show HEAD:.planning/ROADMAP.md > "$tmp/head.md" && cp "$tmp/head.md" "$tmp/seeded.md" && printf '\n### Phase 999: probe\n' >> "$tmp/seeded.md" && test "$(cnt "$tmp/seeded.md")" -eq "$(( $(cnt "$tmp/head.md") + 1 ))" && test "$(cnt .planning/ROADMAP.md)" -eq "$(cnt "$tmp/head.md")" && (cd accrue_admin && MIX_ENV=test mix run --no-start -e '{:ok, _} = Application.ensure_all_started(:localize); m = AccrueAdmin.Storybook.SubscriptionManifest; :ok = m.verify!(Path.expand("../storybook/phase252-manifest.json")); t = Path.join(System.tmp_dir!(), "phase254-guide-#{System.unique_integer([:positive])}.md"); :ok = m.write_coverage_guide!(t); same = File.read!(t) == File.read!(Path.expand("../guides/subscription-story-coverage.md")); File.rm(t); unless same, do: raise("committed guide is stale")') && node scripts/ci/verify_phase254_curation.mjs && node scripts/ci/phase254_selection.mjs project --check && node scripts/ci/phase254_budget.mjs restamp-manifest --check | yes | ✅ green |
| 254-17-01 | 254-17 | 16 | CIQ-02, UXQ-02, UXQ-04, CURATE-01, CURATE-02 | T-254-32, T-254-33, T-254-SC | One required-owner step for every Phase 254 record check, with admitted roots | auto | bash scripts/ci/verify_phase200_guardrail_contract.sh && node --test --test-reporter=tap scripts/ci/verify_phase252_ci_contract.test.mjs scripts/ci/verify_phase254_quality.mjs && node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor | yes | ✅ green |
| 254-17-02 | 254-17 | 16 | CIQ-02, UXQ-02, UXQ-04, CURATE-01, CURATE-02 | T-254-32, T-254-33, T-254-SC | Bounded transparency checks over the generated surfaces | auto | node --test --test-reporter=tap scripts/ci/verify_phase254_transparency.test.mjs | yes | ✅ green |
| 254-17-03 | 254-17 | 16 | CIQ-02, UXQ-02, UXQ-04, CURATE-01, CURATE-02 | T-254-32, T-254-33, T-254-SC | Native fail-first proof, then promote the three prohibition entries | auto | node --test --test-reporter=tap scripts/ci/verify_phase254_transparency.test.mjs && node -e 'const p=require("./.planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-NATIVE-PROHIBITION-PROOF.json");const F="scripts/ci/fixtures/phase254-transparency/";const ids=["selection-violation.json","a11y-claim-violation.json","brief-violation.json"];const ok=Array.isArray(p.checks)&&ids.every(id=>{const c=p.checks.filter(x=>x.projection&&x.projection.check_violation_fixture===F+id);if(c.length!==1)return false;const {projection:pr,result:r}=c[0];return pr.check_target==="scripts/ci/verify_phase254_transparency.test.mjs"&&pr.check_clean_fixture===F+"clean.json"&&pr.status==="resolved"&&r&&r.status==="green"&&r.flagged===false&&(r.evidence&#124;&#124;[]).some(e=>e.passed===true&&e.failFirst===true&&e.failFirstProof==="violation-fixture")});process.exit(ok?0:1)' && for f in 07 11 16; do grep -q -e 'check_target: scripts/ci/verify_phase254_transparency.test.mjs' .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-$f-PLAN.md &#124;&#124; exit 1; done | yes | ✅ green |
| 254-18-01 | 254-18 | 17 | CIQ-02, CIQ-03, CIQ-04, UXQ-02, UXQ-04, CURATE-01, CURATE-02 | T-254-34, T-254-35, T-254-40, T-254-42, T-254-SC | Final CI observation, triage and closure of every deviation | auto | node -e 'const {spawnSync,execFileSync}=require("node:child_process");const b=require("./accrue_admin/storybook/phase254-budget.json");const f=b.metrics.final;const OWN=["admin-phase200-guardrails","browser-uat"];const tri=b.deviations.filter(d=>d.kind==="final-triage").flatMap(d=>d.entries&#124;&#124;[]);const kr=new Set((b.known_reds&#124;&#124;[]).filter(k=>k.decision==="accept-known-red").map(k=>k.id));const disp=r=>tri.some(e=>e.job===r.job&&e.run_id===r.run_id&&(e.main_run_id&&e.classification==="pre-existing-on-main"&#124;&#124;kr.has(e.known_red_id)&#124;&#124;e.decision));const num=m=>m&&typeof m.added_s==="number"&&m.per_cell&&typeof m.per_cell.p90_ms==="number";const evidenceOnly=new Set(["accrue_admin/storybook/phase254-budget.json",".planning/STATE.md",".planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-VALIDATION.md",".planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-18-SUMMARY.md",".planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-UAT.md",".planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-VERIFICATION.md"]);const measured=f&&/^[a-f0-9]{40}$/.test(f.head_sha)&&spawnSync("git",["merge-base","--is-ancestor",f.head_sha,"HEAD"]).status===0;const later=measured?execFileSync("git",["diff","--name-only",f.head_sha+"..HEAD"],{encoding:"utf8"}).split(/\r?\n/).filter(Boolean):["missing-measured-ancestor"];const ok=measured&&later.every(p=>evidenceOnly.has(p))&&f.runs.length>0&&f.runs.every(r=>r.attempt===1)&&OWN.every(j=>f.runs.some(r=>r.job===j&&r.conclusion==="success"&&r.phase_owned_ok===true))&&f.runs.filter(r=>!OWN.includes(r.job)&&r.conclusion!=="success").every(disp)&&b.deviations.length>0&&b.deviations.every(d=>["resolved","accepted"].includes(d.status))&&num(b.metrics.visual)&&num(b.metrics.a11y)&&b.deviations.some(d=>d.kind==="a11y-cell-budget-freeze");process.exit(ok?0:1)' | yes | ✅ green |
| 254-18-02 | 254-18 | 17 | CIQ-02, CIQ-03, CIQ-04, UXQ-02, UXQ-04, CURATE-01, CURATE-02 | T-254-34, T-254-35, T-254-40, T-254-42, T-254-SC | Owner disposition of out-of-scope reds on the final runs (escalation) | checkpoint:decision | checkpoint:decision (recorded answer for 254-18-02) | n/a | ✅ green |
| 254-18-03 | 254-18 | 17 | CIQ-02, CIQ-03, CIQ-04, UXQ-02, UXQ-04, CURATE-01, CURATE-02 | T-254-34, T-254-35, T-254-40, T-254-42, T-254-SC | Acceptance generator, Per-Task Verification Map and pending-state check | auto | node --test --test-reporter=tap scripts/ci/generate_phase254_acceptance.test.mjs && node scripts/ci/generate_phase254_acceptance.mjs --latest --expect-pending 254-18 | yes | ✅ green |
*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Manual-Only Verifications

All phase behaviors have automated verification (Executable Acceptance Policy). The owner-confirmed push (D-25) is a credential/irreversible-operation action, not an acceptance substitute.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated evidence map complete

<!-- phase254-task-results:start
{
  "schema_version": 1,
  "tasks": {
    "254-01-01": {
      "task_id": "254-01-01",
      "command_sha256": "e60e7b0f40ca22fbb0a0737f31595a409712add00f76e96b6aabc9b7fdaf003c",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node --test --test-reporter=tap scripts/ci/phase254_measure.test.mjs (28 tests, 0 fail)",
        "node scripts/ci/phase254_measure.mjs --self-test (6 scenarios)",
        "node --test --test-reporter=tap scripts/ci/phase252_reporters.test.mjs scripts/ci/phase252_reporters.mjs (13 + 2 named tests); generate_phase252/253_acceptance, verify_phase252_ci_contract and verify_phase253_compositions suites 89/89"
      ]
    },
    "254-01-02": {
      "task_id": "254-01-02",
      "command_sha256": "54fb8cb5ec97e44ade3e29e98f0c00c568ff286d49d94c83b327ee88285b92b0",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node scripts/ci/phase254_measure.mjs cold|warm|focused --lane phase252-render, then provisional-budget; budget record verification one-liner from 254-01-02 (verify true)"
      ]
    },
    "254-01-03": {
      "task_id": "254-01-03",
      "command_sha256": "a19faf4d1a9c90a73fd4c4637fa8a990df5205b4c375b2c3d36df5b3ab709a6b",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node scripts/ci/verify_ci_efficiency_contract.mjs --repo . ; bash scripts/ci/verify_phase200_ci_contract.sh ; step-name count 1 per workflow"
      ]
    },
    "254-02-01": {
      "task_id": "254-02-01",
      "command_sha256": "a66b6dd799cfdf3da18e6670fcd43b4db85b1c8935292590a636c2c6a058e7e7",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "assertGuardCoverage positive control (guardless scratch file throws) then PASS on the four and the three files; node --test --test-reporter=tap on the modules plus verify_phase252_ci_contract.test.mjs 57/57, generators and compositions suites 77/77",
        "node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity (PASS, whole cohort)"
      ]
    },
    "254-02-02": {
      "task_id": "254-02-02",
      "command_sha256": "d2589703876f84a3793b50b1edd9d6de3fe1bfe2886647eed993b3cda70a39ef",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "assertGuardCoverage positive control (guardless scratch file throws) then PASS on the four and the three files; node --test --test-reporter=tap on the modules plus verify_phase252_ci_contract.test.mjs 57/57, generators and compositions suites 77/77",
        "node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity (PASS, whole cohort)"
      ]
    },
    "254-02-03": {
      "task_id": "254-02-03",
      "command_sha256": "eb60f41d9a1a2bbfa2cf1aa6f7005fd1ccf31afa410ebcf1399c6f88f8a183eb",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "cd accrue_admin && npx playwright test --list --project=chromium-desktop (Total: 140 tests in 23 files, no Error); --project=chromium-mobile (140 in 23); --project=visual-desktop (1 test, admin-visual-regression-phase211, unchanged)",
        "node --test --test-reporter=tap scripts/ci/phase254_project_ownership.test.mjs (14 tests, 0 fail); RED at d31a73e95 named phase252-review and subscription-compositions-phase253 as double-owned"
      ]
    },
    "254-03-01": {
      "task_id": "254-03-01",
      "command_sha256": "02b5fadbaa1eb0760c4b29030c71b8a68241a70c698ed88017f5d44e925c2eb3",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "254-03-CHECKPOINT-LOG.md"
      ],
      "checkpoint_answer": "push-approved"
    },
    "254-03-02": {
      "task_id": "254-03-02",
      "command_sha256": "5157211ba8903b160b1d12f22ebe5f87ae8f2bd0552c13bfb7fe71b12414713d",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node -e budget check from the plan: metrics.ci holds admin-phase200-guardrails and browser-uat samples with attempt 1, conclusion, fingerprint.image_os, numeric cache hits/misses and informs_only true (29 samples; runs listed below)",
        "node --test --test-reporter=tap scripts/ci/phase254_measure.test.mjs (47 pass, 0 fail); node scripts/ci/phase254_measure.mjs --self-test (6 scenarios)",
        "the plan's DEV-254-02 closing check exits 0: status accepted, closed_by 254-03, closing run ids 40805796792 and 40805796802, unresolved_entries 0, after.cells 166 >= before.cells 166",
        "Browser UAT 40805796802 success (a11y scan, action-menu geometry, Phase 211 gate); CI 40805796792 Admin Phase 200 deterministic guardrails success, 21 Phase 252 lanes and 10 Phase 253 lanes passed"
      ]
    },
    "254-03-03": {
      "task_id": "254-03-03",
      "command_sha256": "d5231383f69d8bef34d4785d16543e775d87f358d0024e8839bd4fca21dca426",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "254-03-SUMMARY.md"
      ],
      "checkpoint_answer": "fix-in-phase; accept-known-red for KR-254-06"
    },
    "254-04-01": {
      "task_id": "254-04-01",
      "command_sha256": "ba9c8cfe1be472c0e1de226ecd1ea864be4ee4837ac4b8484dd5cf449a7bffed",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node scripts/ci/verify_phase254_curation.mjs --self-test (19 scenarios) and node --test scripts/ci/verify_phase254_curation.test.mjs (32 pass)",
        "node scripts/ci/verify_phase254_curation.mjs (regenerates through mix, decoded equality with the committed ledger, frozen subjects re-derived from source_commit) and --results-latest (survivors present in rendered results)",
        "accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs via mix run --no-start (19 ExUnit tests including ledger shape, byte-identical regeneration and the injected-writer interruption)"
      ]
    },
    "254-04-02": {
      "task_id": "254-04-02",
      "command_sha256": "f2e4a2f369121980dd131b2f93a34e93e161f7b72157167af6362ff7e3641549",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node --test scripts/ci/generate_phase252_acceptance.test.mjs scripts/ci/phase252_reporters.test.mjs scripts/ci/verify_phase254_curation.test.mjs (99 pass, mutation fixtures: 15 rows against a one-retirement ledger and 14 against frozen-only fail at every site; a missing ledger throws)",
        "npm --prefix accrue_admin run phase252:check (21 commands passed, 15 browser rows from the ledger-derived expectation)"
      ]
    },
    "254-04-03": {
      "task_id": "254-04-03",
      "command_sha256": "adb3789213b9460d3250904af2dbba3a752dbf5b12cb5d2b50739cadb88bb6e3",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "subscription_manifest_test.exs: braintree_pruned and dunning_active are retained and reclassified..., the regenerated guide lists every curation record..."
      ]
    },
    "254-05-01": {
      "task_id": "254-05-01",
      "command_sha256": "0c7b114dd9d4083454912467b100f016513d824b5f595bf0b12ef41061a11b00",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node scripts/dev/phase252_lab.mjs exec --lane admin-test -- sh -c 'cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/e2e_plug_isolation_test.exs' (6 tests, 0 failures, 0 skips; 22 declared POST routes read from the plug source, 24 distinct spellings asserted 403)",
        "node scripts/dev/phase252_lab.mjs isolation (5 pass, 0 fail, 0 skipped): 12 mutator routes return 403 on the live review server and its marker snapshot is byte-identical in the same test whose admin-test server returns 200 on /__e2e__/reset"
      ]
    },
    "254-05-02": {
      "task_id": "254-05-02",
      "command_sha256": "db4838ae5226492f56e04e9ead9fc33f5238fe81b2e0a4b37c7ae7a5b2bab8c6",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node --test scripts/ci/phase254_result_ledger.test.mjs (16 pass): old-algorithm control loses case-one, per-case layout keeps both, two concurrent writer processes keep 120 of 120 rows, merge rejects foreign run or manifest, duplicate key, misnamed file and unparsable file, key sanitization rejects separators and dot segments",
        "phase254_result_ledger.test.mjs: scratch two-project fixture (failing upstream gives the dependent status skipped; passing upstream gives passed), real-config assertion, four in-memory mutations that must throw, and a project-membership test"
      ]
    },
    "254-05-03": {
      "task_id": "254-05-03",
      "command_sha256": "1a1fcf659e299a48fe19ae331d5cb1e389e08f759f70e2421683558ec134c984",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node scripts/ci/verify_phase253_compositions.mjs: 10 serial lanes passed, browser cells=151, Playwright report 152 identities (151 cells plus 'reconciles every compiled collection and whole-page cell against this run and served assets' in project phase254-reconcile)",
        "node --test scripts/ci/verify_phase253_compositions.test.mjs (14 pass) including a reconcile identity in the wrong project, a cell in the reconcile project and a missing projectName",
        "phase254_result_ledger.test.mjs: scratch two-project fixture (failing upstream gives the dependent status skipped; passing upstream gives passed), real-config assertion, four in-memory mutations that must throw, and a project-membership test"
      ]
    },
    "254-06-01": {
      "task_id": "254-06-01",
      "command_sha256": "2c0af5cffb2c24eb574b2c8f3a8db2c2afc03d9bc7bb27424918ae439967dd6b",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "scenarios, story-slice and manifest ExUnit files via mix run --no-start (13, 5 and 20 tests, 0 failures, 0 skips), including a synthetic-ledger test that follows a retirement"
      ]
    },
    "254-06-02": {
      "task_id": "254-06-02",
      "command_sha256": "bd32fe6d911b1f61bbd18509f7f92489f18aaa8645f9907cb61fbf4b5b2b44d5",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node scripts/ci/verify_phase254_curation.mjs (duplicate blocks and the fetch!(:populated) -> fetch!(:active) alias re-derived from git show at 9b40acc8e, frozen-manifest cross-check, per-record context scan) and --results-latest (survivors present in the newest rendered Phase 252 results)",
        "node scripts/ci/verify_phase254_curation.mjs --self-test (24 scenarios): commit-anchored evidence passes where blocks and alias held and fails for differing blocks, a missing alias, forged evidence and an unreachable commit; contexts; additional survivors; AMD link",
        "scenarios, story-slice and manifest ExUnit files via mix run --no-start (13, 5 and 20 tests, 0 failures, 0 skips), including a synthetic-ledger test that follows a retirement",
        "verify_phase254_curation.mjs shape evidence (actionMenuShape at origin commit fdcd6c4eb for provider_pruned and danger, survivor re-parsed in the current story, subject and helper absent) and the 24-scenario self-test; subscription_manifest_test.exs 'populated is retired and provider_pruned merged...'"
      ]
    },
    "254-06-03": {
      "task_id": "254-06-03",
      "command_sha256": "081a16e032c09fe3ab0666195e46a9ba93e280fe1385eb307b1d0ee44de9db0d",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "npm --prefix accrue_admin run phase252:check (21 of 21 commands, newest bundle 14 browser rows: 12 canonical, 2 compatibility, no populated) and node scripts/ci/verify_phase253_compositions.mjs (10 serial lanes, browser cells=151)",
        "subscription_manifest_test.exs 'current caller map reconciles production sources...' asserts the three rows reachable, page keys equal the compiled Phase 253 page entries, list keys equal the collection entries, journey keys a subset of the page keys, and the journey test file exists"
      ]
    },
    "254-07-01": {
      "task_id": "254-07-01",
      "command_sha256": "3b5f54d53f4c43a52712bd66a86803a40be641a3e917e1c7ab038ae7e22471dc",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "subscription_manifest_test.exs (22 tests) and subscription_compositions_manifest_test.exs (9 tests) via mix run --no-start, 0 failures, 0 skips: sorted subset and tier-split tests, plus an injected out-of-digest path failing validate_depends_on!/2 and verify!/1 in all three compositions sections"
      ]
    },
    "254-07-02": {
      "task_id": "254-07-02",
      "command_sha256": "c7e4b64689b08a4afff568d85a7727a04e983b80fee3d0172aa490e8cc4cdab0",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node scripts/ci/phase254_selection.mjs project --check (151 cases equal the shared universe, 14 Phase 252 cases, 8 sentinels), re-run after the Phase 252 and Phase 253 aggregates regenerated their manifests",
        "phase254_selection.test.mjs: identical-151-keys with a pinned key digest, committed projection equals the universe, stale-projection with a removed case, sentinel D-12 coverage with a seeded gap, pinned sentinels_sha256"
      ]
    },
    "254-07-03": {
      "task_id": "254-07-03",
      "command_sha256": "c8996e1ee3b42f9fa772db858806880e4089c98ca416ad3e700a1fa4e61b25d6",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node --test scripts/ci/phase254_selection.test.mjs scripts/ci/verify_phase252_ci_contract.test.mjs (57 tests, 0 failures) and node scripts/ci/phase254_selection.mjs --self-test (8 scenarios, hostile-path fixture named)",
        "npm --prefix accrue_admin run phase252:check (21 of 21) and node scripts/ci/verify_phase253_compositions.mjs (10 serial lanes, browser cells=151) after the extraction and the manifest change"
      ]
    },
    "254-08-01": {
      "task_id": "254-08-01",
      "command_sha256": "dc915bf3ed20a1359b42fb0963acf3ee5be03a25f47163771594624449ef4605",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "PHASE254_SELECTION=accrue_admin/tmp/phase254/selection-local.json node scripts/ci/verify_phase253_compositions.mjs: 10 serial lanes passed, browser cells=58, bundle selection.mode affected, selected_count 58 equal to the report, below expected_case_count 151",
        "env -u PHASE254_SELECTION node scripts/ci/verify_phase253_compositions.mjs: 10 serial lanes passed, browser cells=151, bundle selection.mode full reason no-selection-file",
        "node --test verify_phase253_compositions.test.mjs: 19 tests, 0 failures (selection resolution, report rejections, reconcile excluded and missing rows, aggregate excluded row, missing row, forged block, full-sweep guard)"
      ]
    },
    "254-08-02": {
      "task_id": "254-08-02",
      "command_sha256": "70836c7114bf7bfab85fe72604abc21c380059b65ea0e32d1561c4205cf80a0c",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node --test verify_phase252_ci_contract.test.mjs: 26 tests, 0 failures, including the two Phase 254 tests (nine representative paths with removal controls, and eleven workflow mutations beside a passing control)",
        "verify_ci_efficiency_contract.mjs --repo ., verify_phase200_guardrail_contract.sh, verify_phase200_ci_contract.sh, verify_ci_script_contract.mjs (guard coverage, non-vacuity, cohort floor) and actionlint ci.yml all exit 0"
      ]
    },
    "254-09-01": {
      "task_id": "254-09-01",
      "command_sha256": "e5884859575bdcda9e5af875294e17cd8fea3b55a7b763696ba52c0dfd11df71",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node --test scripts/ci/phase254_budget.test.mjs (32 tests, 0 failures) and node scripts/ci/phase254_budget.mjs --self-test (23 scenarios, including the warn_at boundary at 129.999, 130 and 130.001, the ceiling boundary and the hostile-title fixture)",
        "frozen check against downloaded run evidence: --elapsed-s 1287 passes (976 s), 1800 warns (1489 s above warn_at 1221.25), 3000 fails (2689 s above ceiling 2397.5)"
      ]
    },
    "254-09-02": {
      "task_id": "254-09-02",
      "command_sha256": "0c2a22154b3bad90f83f84a7d19e71a10bb14fca9bce33949c4f6a685f4aaa2d",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "bash scripts/ci/verify_phase200_guardrail_contract.sh and node --test scripts/ci/verify_phase252_ci_contract.test.mjs (28 pass), including removed, moved-before, conditionally gated and renamed budget step mutations beside a passing control",
        "node scripts/ci/phase254_budget.mjs restamp-manifest --check exits 0 with DEV-254-11 resolved (bd02091c9213 to d0cc29a5f69a, cause 254-09-02)",
        "node scripts/ci/phase254_budget.mjs check --evidence-latest accrue_admin/tmp/phase254/ci exits 0 on run 40832242001; the full guardrail runner passes locally with the frozen budget"
      ]
    },
    "254-09-03": {
      "task_id": "254-09-03",
      "command_sha256": "e7b2a13fde37039d8765ed9574f50e35994ac0170c7e3aa56a0921a099347e4a",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "the plan's budget predicate over phase254-budget.json exits 0 (frozen.metric owner_job_added_s, three distinct attempt-1 success runs on head 4825e9fa0 with clean ubuntu24 fingerprints and cache objects, composition_cell, derived warn_at and ceiling, four evaluations, allowances, DEV-254-01/05/08/09/10)",
        "node scripts/ci/phase254_budget.mjs check --evidence-latest accrue_admin/tmp/phase254/ci exits 0 on run 40832242001; the full guardrail runner passes locally with the frozen budget"
      ]
    },
    "254-10-01": {
      "task_id": "254-10-01",
      "command_sha256": "d2e7fbc590d0cdcabd82cc72f4a20135d46d55d1dd123161ef7266312febc05f",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node --test scripts/ci/recompose_storybook_css.test.mjs (13 pass, including the one-byte drift case, the exact-composition case, a drifted PSB or brand section, a missing shim tail, an admin bundle without a trailing newline and the real-tree --check) and node scripts/ci/recompose_storybook_css.mjs --self-test (5 scenarios)",
        "node scripts/ci/recompose_storybook_css.mjs --check: embedded section sha256 a519a7541d05b74c769dd938e493fc886149585def2ff5bfa00cc7a270f77699 equals the bundle sha256; --write twice left cmp-identical bytes; lab ExUnit storybook_asset_test.exs 4 tests 0 failures; verify_ci_efficiency_contract.mjs and verify_ci_script_contract.mjs pass",
        "verify_phase253_compositions.mjs (rc 0), npm run phase200:storybook (rc 0), npm run phase252:check (rc 0), plus theme_test.exs and subscription_production_boundary_test.exs (17 tests, 0 failures), all run on the recomposed bundle"
      ]
    },
    "254-10-02": {
      "task_id": "254-10-02",
      "command_sha256": "d08fede2ab4316a5edb13ff110dac2ea86c8854ecc5f4e98d04a0283d12496d5",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node scripts/ci/verify_phase254_design_review.mjs --check --stage assessment exits 0 (9 findings, 16 captures, 7 rubric verdicts, 6 deferrals; every source sha and needle matches the file at source_commit 4a018ce9a; the Markdown view equals the renderer output)",
        "node --test scripts/ci/verify_phase254_design_review.test.mjs (37 pass) and --self-test (18 scenarios, each with a passing control); two seeded mutations of the verifier (needle check removed, cross-dimension check removed) both made the self-test fail",
        "scanSubscriptionDetailSpacing positive control on the real app.css at source_commit finds exactly the five D-34 overrides (0.0625rem, 0.1875rem, 0.0625rem, 0, 0 0.25rem) and passes a token-only fixture"
      ]
    },
    "254-11-01": {
      "task_id": "254-11-01",
      "command_sha256": "95a3440115636897e506fa87db57cbc8f3c39baa4c293ab0caa0ca9e6eb0c60a",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node scripts/ci/verify_phase253_compositions.mjs passed (10 serial lanes, 151 browser cells, 3:04) and node scripts/ci/verify_a11y_dispositions.mjs --results-latest passed: 151 cells reported, every cell rules_evaluated between 61 and 63, 566 observations all matched, 924 incomplete contrast results auto-resolved by compositing, 30 register entries each matched in a cell that ran (or decided by the journey)",
        "node --test scripts/ci/verify_a11y_dispositions.test.mjs (86 tests, 0 failures) and node scripts/ci/verify_a11y_dispositions.mjs --self-test (15 scenarios, each with a passing control); the real owner files pass the source contract, and the same scan flags each seeded banned token (disableRules, exclude, impact, withRules, options, configure)"
      ]
    },
    "254-11-02": {
      "task_id": "254-11-02",
      "command_sha256": "a6c092de36c1c39a99763a738b3077cfc93e798b8c20b462d127d9dc7a39d296",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "contrast, encoding (NFC vs NFD, long Unicode identities differing in the last code point, duplicate row names), target-size, focus and deep-subset fixtures in verify_a11y_dispositions.test.mjs (40 deep-probe cells are exactly the named subset)",
        "geometry::negative-controls::320::light recorded all seven injected controls as detected (unnamed button, overlapping undersized target, outline none, unapplied spacing, unapplied scaling, motion under reduce, undispositioned incomplete); cd accrue_admin && env -u NO_COLOR npx playwright test e2e/foundation-tokens.spec.js --project=chromium-desktop --workers=1 passed (2 tests)"
      ]
    },
    "254-11-03": {
      "task_id": "254-11-03",
      "command_sha256": "9203ef1875f8c64602d61024e04f67c562e2b28f49dad590347e3c359f13c82e",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "cd accrue_admin && env -u NO_COLOR npx playwright test e2e/admin-interactions.spec.js --workers=1 passed (14 tests: 7 per project, chromium-desktop and chromium-mobile); the journey alone passed 45 of 45 repeats on fresh servers (25 desktop, 10 desktop and 10 mobile). The focus-return checkpoints are routed defects A11Y-254-29 and A11Y-254-30 (see Routed defects)."
      ]
    },
    "254-12-01": {
      "task_id": "254-12-01",
      "command_sha256": "3eab0d72d54611f6543e7ee87d4b36fff915bc17b99d93d7220f505aff0b512d",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node --test scripts/ci/verify_phase254_design_review.test.mjs (parseRedReport/evaluate/record/check fixtures: setup crash, timeout, skip, missing result, unexpected failure, unkeyed test, assertion without values, expect-pass failure and bare finding keys each rejected beside a passing control; AMD-254-04 and AMD-254-05 scenarios) and node scripts/ci/verify_phase254_design_review.mjs --self-test (20 scenarios)",
        "PLAYWRIGHT_JSON_OUTPUT_FILE=accrue_admin/tmp/phase254/design-red.json node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-design-phase254.spec.js --reporter=json exited 1 on 073e33792 (9 failing, 4 passing); --record-red wrote 254-12-01-red-evidence.json and --check-red reproduced it",
        "grep checks on 253-UI-SPEC.md (one Section title row, Page heading row naming --ax-type-xl and --ax-type-2xl) and node scripts/ci/verify_phase254_design_review.mjs --check --stage assessment (the real record still passes against the amended contract)"
      ]
    },
    "254-12-02": {
      "task_id": "254-12-02",
      "command_sha256": "c534b2f71337e7ca5e149e1f46183a2dd7f1c6e533bac877c127dd468c5842dc",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-design-phase254.spec.js: 13 passed; two consecutive mix accrue_admin.assets.build runs gave sha256 63fbca43...f299; recompose_storybook_css.mjs --check, verify_package_docs.sh (FND-01, FND-05) and the theme and component ExUnit suites (195 tests) pass",
        "node scripts/ci/verify_phase253_compositions.mjs passed (10 serial lanes, 151 browser cells) and node scripts/ci/verify_a11y_dispositions.mjs --results-latest passed: 151 cells reported, 40 deep-probe cells, 0 observations, 0 register entries",
        "cd accrue_admin && env -u NO_COLOR npx playwright test e2e/admin-interactions.spec.js passed (14 tests); the D-29 journey with the empty register passed 80 of 80 repeats on chromium-desktop and 40 of 40 on chromium-mobile on fresh servers",
        "node --test test/js/focus_trap_test.mjs (15 tests; the closed-menu, closed-disclosure and no-steal tests each fail against the pre-fix module) and overlay_components_test.exs (drawer body region, modal and popover untouched)"
      ]
    },
    "254-13-01": {
      "task_id": "254-13-01",
      "command_sha256": "8ed4b10c19c94896617f2e259c2e4059398bbcb19bc66f5d4aecf61d97e3a367",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "lab ExUnit run of subscription_action_copy_test.exs on 0f7b2b014 exited 2 (5 tests, 5 failures); verify_phase254_design_review.mjs --record-red --format exunit wrote 254-13-01-red-evidence.json and --check-red --format exunit reproduced it",
        "subscription_action_copy_test.exs 5 tests 0 failures (lab and db-free); subscription_page_slice_test.exs 7, subscription_manifest_test.exs 22, subscription_compositions_manifest_test.exs 9 pass db-free; subscription_live_test.exs and subscription_journey_test.exs pass in the lab"
      ]
    },
    "254-13-02": {
      "task_id": "254-13-02",
      "command_sha256": "3570cf5ab7915654c8fc0413baebdeba00aa65ba313a8a2166e70da001d08847",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node scripts/ci/verify_phase253_compositions.mjs exited 0 (run c3c62d3a...); npm --prefix accrue_admin run phase252:check passed 21 commands; results.json contains subscription-design-phase254 and subscription_action_copy_test; verify_phase253_compositions.test.mjs 23 tests include the new lane inventory and design-evidence rejection scenarios",
        "SubscriptionManifest.verify!/1 accepts the committed manifest and the regenerated guide equals the committed guide; verify_phase254_curation.mjs, phase254_selection.mjs project --check, phase254_budget.mjs restamp-manifest --check (DEV-254-21, f16cf209eada) and phase254_budget.mjs check pass; two mix accrue_admin.export_copy_strings --out runs left copy_strings.json at sha256 6a5e3920...d817 (no diff)"
      ]
    },
    "254-13-03": {
      "task_id": "254-13-03",
      "command_sha256": "5593fb49a9f8986cb79e3d8469bfcb949e3d706c5204aeab45c3ab71e7c34200",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node scripts/ci/verify_phase254_design_review.mjs --check --stage corrected exited 0 (9 findings, 16 captures, 7 verdicts, 6 deferrals; Markdown view current); node --test scripts/ci/verify_phase254_design_review.test.mjs 46 pass; --self-test 20 scenarios"
      ]
    },
    "254-14-01": {
      "task_id": "254-14-01",
      "command_sha256": "4b05bda4c6fcae9d173c88731bc1abfc4e42154c6ac3725bbfdb064a973c5bb3",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "playwright test subscription-visual-phase254.spec.js --project=visual-desktop --update-snapshots=none: 2 A4 tests passed; 32 case tests (equal to cases.length) each failed only with the missing-snapshot error; filtered run (A4 plus phase254-page-active-w1280-light) exactly one case test; e2e/__screenshots__ unchanged after a seeded probe file was detected and removed",
        "scratch config (snapshot path outside the repository) with --update-snapshots=all run twice: 32 PNGs, sha256 sums identical across both runs. macOS output, never committed; it proves the determinism assertions, not Linux pixels"
      ]
    },
    "254-14-02": {
      "task_id": "254-14-02",
      "command_sha256": "947b64db03d920fe259b2cdbdd38f2e8b8fdd9df1886bfae6703334ae46f6003",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node --test test/js/*.mjs in accrue_admin: 87 pass, including extra file, byte mismatch, field errors, legacy and case PNG removed together with its entry, --pre-mint limits, and a real-directory byte check with a flipped-byte positive control",
        "node --test scripts/ci/phase254_visual_manifest.test.mjs (12 pass) and phase254_visual_manifest.mjs --self-test (4 scenarios); a simulated mint (macOS scratch PNGs plus the real identity files, build then strict guard then check) passed with 44 entries"
      ]
    },
    "254-14-03": {
      "task_id": "254-14-03",
      "command_sha256": "1f4a7ebe245ebb08dfe71f5ac5f96263fa07ab3612580217b97943d0b0d909b7",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node --test scripts/ci/phase254_visual_contract.test.mjs: 11 pass (--pre-mint, --update-snapshots outside the mint job, no =changed, bare or =all, upload always() or without success(), repeat-each, manifest build, fetch-depth, check step removed or reordered, F3 triggers, threshold, maxDiffPixelRatio, retries, stylePath in config and both specs, looser screenshot call, env switch); verify_ci_efficiency_contract.mjs passes",
        "scratch-config run of admin-visual-regression-phase211.spec.js with --update-snapshots=all: both tests passed (the 6-surface test and the masked-amount negative control); a seeded mutation that disables the overlap test made the negative control fail; the 12 legacy PNG bytes equal their manifest sha256 (guard byte tests)"
      ]
    },
    "254-15-01": {
      "task_id": "254-15-01",
      "command_sha256": "0c79385670b7af83edde909ecfb86c517a3a789c8730c7546f9853b52e36cc69",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "Linux mint run 41682891880; visual-baseline-set.cjs and phase254_visual_manifest.mjs check --base origin merge-base",
        "AccrueAdmin Browser UAT run 41695128833, attempt 1, head 7e8d0cda49a59bbf1e893ad26a27a93b513bc59f; all 32 Phase 254 visual cells passed",
        "CI run 41695128675 phase252-machine-evidence and phase253-machine-evidence artifacts; subscription-render-browser, phase253-compositions-browser and phase254-design-browser path/hash checks"
      ]
    },
    "254-15-02": {
      "task_id": "254-15-02",
      "command_sha256": "9c9888cb23f85dce8119f91c91901c56aab62412b077432b3bdcd03ecc3fddfb",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "254-15-CHECKPOINT-LOG.md"
      ],
      "checkpoint_answer": "fix-in-phase; accept-attributable"
    },
    "254-15-03": {
      "task_id": "254-15-03",
      "command_sha256": "a2e736abaa9184e078b1227ee1fedea04293bdc885b406012fe9690bcae76c84",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "phase254-budget.json metrics.visual and DEV-254-36: 59 s added job time; 794 ms median and 1195 ms p90 per cell",
        "node --test scripts/ci/verify_phase254_design_review.test.mjs (51/51); verify_phase254_design_review.mjs --self-test (24 scenarios) and --check --stage confirmed"
      ]
    },
    "254-16-01": {
      "task_id": "254-16-01",
      "command_sha256": "0b68e151c7b48b2e525e7dee2a1ddcc934814bbf7d8e505347b51c9425c736c7",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "SubscriptionManifest tests: real-router reconciliation, positive extra-route fixture, and 22/22 task-01 lab tests",
        "Generated ledger and guide fixed point; curation, selection, and budget digest checks"
      ]
    },
    "254-16-02": {
      "task_id": "254-16-02",
      "command_sha256": "6237a36afaf731cd26289a21e4ece948974f0703f46bba792b9701deeaa10962",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "Node curation verifier: six brief rejection fixtures; full task-02 run 45/45 tests and 24/24 lab tests",
        "Generated ledger and guide fixed point; curation, selection, and budget digest checks"
      ]
    },
    "254-16-03": {
      "task_id": "254-16-03",
      "command_sha256": "79edf7a6ae5ba810ccaaa8ef7d53c526c3323ff04f2d8d6babc9dd70bc93b75d",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "Node curation verifier: two gatedCannotWin violation fixtures and one clean fixture; full task-03 run 48/48 tests and 27/27 lab tests",
        "Roadmap-count check with seeded Phase 999 positive control; unchanged committed and working phase/milestone counts"
      ]
    },
    "254-17-01": {
      "task_id": "254-17-01",
      "command_sha256": "933c5edfc569a7e647b2d1ec4040f552c2379f0d50329dfd18fc3981ddc426e6",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "Node owner-contract mutations cover removed, gated, renamed and reordered aggregate steps; positive/removal path controls cover every new root.",
        "bash scripts/ci/verify_phase200_guardrail_contract.sh; node --test scripts/ci/verify_phase252_ci_contract.test.mjs scripts/ci/verify_phase254_quality.mjs (37/37); strict verify_ci_script_contract cohort (PASS).",
        "node scripts/ci/verify_phase254_quality.mjs: all five checks passed serially."
      ]
    },
    "254-17-02": {
      "task_id": "254-17-02",
      "command_sha256": "bb13ff35e8c245855fe273582109f964d1b16b7d2492dfb532857fcc570db531",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "scripts/ci/verify_phase254_transparency.test.mjs (11/11): current generated surfaces and clean fixture pass; selection, a11y/design and brief violations each fail their own assertion.",
        "The brief-violation fixture is rejected while the current generated guide and clean fixture pass."
      ]
    },
    "254-17-03": {
      "task_id": "254-17-03",
      "command_sha256": "f3c5f98a1b8e02226684c2fe23c791fe1e55bbd962fc1355fdb5527ef0adf313",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "gsd_run check prohibition-enforcement pre/post outputs; the proof records three resolved green results with passed=true, failFirst=true and failFirstProof=violation-fixture.",
        "Exact Plan 17 task-03 verifier validates one proof row per assigned violation fixture and all three plan targets."
      ]
    },
    "254-18-01": {
      "task_id": "254-18-01",
      "command_sha256": "8bdc666925e7db652c50e94d7f4589bde6c7fb8c2ce4654ac3fd4b0944cd17e7",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "phase254_budget.mjs check passed for the final attempt-1 runs; visual added time was 67 s and a11y added time was -175.356 s; all 151 a11y timings were retained (p90 2539 ms)."
      ]
    },
    "254-18-02": {
      "task_id": "254-18-02",
      "command_sha256": "9058241d6b455ec51b31c1476be54f9afcae1f8b9ffee257638f52e86599ca94",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "254-18-SUMMARY.md"
      ],
      "checkpoint_answer": "not required"
    },
    "254-18-03": {
      "task_id": "254-18-03",
      "command_sha256": "cddc2a46d0c0fdb666105c9257591b01677abdc71d65e03f51a9c7c9a416aa15",
      "status": "pass",
      "skipped": 0,
      "retries": 0,
      "evidence_refs": [
        "node --test --test-reporter=tap scripts/ci/generate_phase254_acceptance.test.mjs (29/29): per-task command identities and result references are enforced; missing evidence and the pending-summary fixture are rejected correctly."
      ]
    }
  }
}
phase254-task-results:end -->
