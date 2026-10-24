---
phase: quick-261024-pla
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - scripts/ci/verify_phase245_baseline.mjs
  - scripts/ci/verify_phase248_integrated_proof.mjs
  - scripts/ci/verify_phase248_integrated_proof.test.mjs
  - scripts/ci/verify_phase248_render_proof.test.mjs
autonomous: true
requirements:
  - QUICK-261024-PLA
estimate:
  tokens: 60000
  raw_tokens: 40000
  tasks: 2
  confidence: low
must_haves:
  truths:
    - "node scripts/ci/verify_phase230_archive_invariants.mjs exits 0 (was exit 1 with 11 findings at base commit 32c0d4b1)"
    - "The same sweep run against an export of base commit 32c0d4b1 still exits 1 and reports the phase 245/248 literals (positive control)"
    - "verify_phase245_baseline.mjs reads its default coverage/manifest/findings and each recorded capture PNG path from the v1.66 archive; no ENOENT and no 'missing PNG' failure remains"
    - "verify_phase245_baseline.mjs --routes-only (default paths, no flags) prints PASS: route inventory"
    - "verify_phase245_baseline.mjs --self-test passes (its refreshed positive fixture no longer fails on unresolved recorded PNG paths)"
    - "The archive-fallback resolution tests in verify_phase248_integrated_proof.test.mjs (tests 10-13) still pass, and no 248 test fails with a path-resolution error"
  artifacts:
    - path: scripts/ci/verify_phase245_baseline.mjs
      provides: "Phase 245 verifier with archive-aware default and recorded-path reads"
    - path: scripts/ci/verify_phase248_integrated_proof.mjs
      provides: "Integrated-proof verifier reading the 245 owner source via resolvePhaseEvidencePath"
  key_links:
    - from: scripts/ci/verify_phase245_baseline.mjs
      to: scripts/ci/phase_evidence_path.mjs
      via: "import { resolvePhaseEvidencePath }"
      pattern: "resolvePhaseEvidencePath\\(PHASE245"
    - from: scripts/ci/verify_phase248_integrated_proof.mjs
      to: scripts/ci/phase_evidence_path.mjs
      via: "import { resolvePhaseEvidencePath }"
      pattern: "resolvePhaseEvidencePath\\("
---

<objective>
Make the merge-blocking archive sweep (`.github/workflows/ci.yml` lines 311-313, job docs-contracts-shift-left) green again by routing the 11 archive-unaware `.planning/phases/...` literals that the v1.66 archive left behind (phase dirs now live under `.planning/milestones/v1.66-phases/`) through the canonical resolver `resolvePhaseEvidencePath` from `scripts/ci/phase_evidence_path.mjs`. Literals that are not live reads get a same-line `archive-sweep-exempt: <reason>` marker.

Purpose: CLAUDE.md "Milestone close breaks contracts that read `.planning/phases/`" -- route each real read through the canonical resolver; do not revert the archive.
Output: four edited scripts in `scripts/ci/`, one commit.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md
@scripts/ci/phase_evidence_path.mjs
@scripts/ci/verify_phase230_archive_invariants.mjs

## What I saw at planning time (base commit 32c0d4b1, branch gsd/phase-233-shared-direction-portal-contract)

Sweep output (`node scripts/ci/verify_phase230_archive_invariants.mjs --repo .`, exit 1), exactly 11 findings:
- `scripts/ci/verify_phase245_baseline.mjs` lines 15, 16, 17 (default `opts.coverage/manifest/findings` paths) and 199 (PNG containment prefix `.planning/phases/245-.../captures`)
- `scripts/ci/verify_phase248_integrated_proof.mjs` line 8 (`OWNER_SOURCE`, the 245 FINDINGS file)
- `scripts/ci/verify_phase248_integrated_proof.test.mjs` lines 10, 11 (`proofPath`, `manifestPath` -- live reads), 52 (replace-text inside the proof markdown -- not a read), 64 and 96 (synthetic `245-baseline` slug under an mkdtemp root -- not a repo read)
- `scripts/ci/verify_phase248_render_proof.test.mjs` line 11 (`manifestRelative` -- live read)

How the sweep decides a literal is safe (from `verify_phase230_archive_invariants.mjs`): per file, a slug is "proven safe" only when THAT file calls `resolvePhaseEvidencePath(` with a quoted slug or with an identifier assigned by `const|let|var NAME = "<slug>"` (VAR_ASSIGN_RE), or contains a `.planning/milestones/<x>-phases/<slug>` literal. `repositoryRelativePhaseEvidencePath(` does NOT match RESOLVE_CALL_RE -- call `resolvePhaseEvidencePath` itself. A literal is also exempt with a same-line `// archive-sweep-exempt: <reason>` comment. Only quoted strings matching `.planning/phases/<slug>[/rest]` are inspected, so a template literal built from a slug constant (`${PHASE245}`) is not a literal. Existing marker style: see `scripts/ci/verify_pr_claims.mjs` lines 715-732.

`resolvePhaseEvidencePath(slug, artifact, { root })` returns the active path if it exists, else the single archived match under `.planning/milestones/*-phases/`; it THROWS on missing or ambiguous, and rejects `..`/`.`/empty segments. It works for directories too (`existsSync`).

Pre-existing failures that this task does NOT own (record them; do not try to fix them):
1. Phase 245/248 evidence is frozen provenance that has drifted from current main by design. `verify_phase245_baseline.mjs` against the archived paths reports many `capture Cxx source digest is stale for ...` lines; `verify_phase248_integrated_proof.mjs --proof ... --manifest ...` fails `served css digest or byte count differs from manifest`; `verify_phase248_integrated_proof.test.mjs` is 5 ok (tests 4, 10, 11, 12, 13) / 9 not ok; `verify_phase248_render_proof.test.mjs` fails with `current product source differs from tested source: accrue_admin/lib/accrue_admin/live/customer_live.ex`. None of these scripts is invoked by any `.github/workflows/*` file (grep confirmed). Re-capturing evidence is out of scope. Therefore "passes against archived evidence" is judged as: zero path-resolution failures (ENOENT, `missing evidence path`, `missing PNG`, `PNG escapes phase capture directory`), and no test that passed at base now fails.
2. `node scripts/ci/verify_artifact_fixed_point.mjs --repo . --require-acyclic --require-fixed-point --require-digest-match` already exits 1 at base with `phase null: no phase directory found` (STATE.md has no current phase between milestones). None of the four touched files is in any `covered_files` list (git grep confirmed), so no covered_digest can drift. Run the ci.yml lines 176-177 forms (node --test + --fixtures) as gates and confirm the --repo form's failure message is unchanged.
3. Do NOT edit `scripts/ci/verify_phase248_render_proof.mjs` -- its sha256 is pinned in the archived 248 capture manifest `source_digests`. Neither touched `.mjs` verifier is pinned there.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Route verify_phase245_baseline.mjs default and recorded-path reads through resolvePhaseEvidencePath</name>
  <files>scripts/ci/verify_phase245_baseline.mjs</files>
  <read_first>scripts/ci/verify_phase245_baseline.mjs (lines 1-90 and 175-252), scripts/ci/phase_evidence_path.mjs</read_first>
  <action>
Import `resolvePhaseEvidencePath` from `./phase_evidence_path.mjs`. Add `const PHASE245 = "245-rendered-baseline-and-realistic-preview";` (must be a plain double/single-quoted assignment so the sweep's VAR_ASSIGN_RE binds it).

Add one small helper, e.g. `resolveEvidenceInput(relativeOrAbsolute)`: if the argument matches `^\.planning/phases/<slug>/<rest>` (slug regex as in phase_evidence_path.mjs) and the active path does not exist, return `resolvePhaseEvidencePath(slug, rest, { root })`; otherwise return `path.resolve(root, arg)` unchanged. This keeps the recorded VERIFICATION.md commands (which pass `--coverage .planning/phases/245-.../245-COVERAGE.md` etc.) working after archival, and leaves temp/absolute paths (the --self-test passes mkdtemp files) untouched.

Lines 15-17: when an `opts.*` flag is given, resolve it with the helper; when absent, default to `resolvePhaseEvidencePath(PHASE245, "245-COVERAGE.md", { root })`, `(PHASE245, "captures/manifest.json", ...)`, `(PHASE245, "245-FINDINGS.md", ...)`. Resolve lazily or guard so an explicitly supplied flag never triggers a throw for an unrelated default (e.g. `--routes-only` with only `--coverage`). Convert a resolver throw into the script's existing failure output (prefix `FAIL:`), not an unhandled stack trace.

Line ~198-199 (PNG check): the manifest records each `capture.png.path` as the original `.planning/phases/245-.../captures/...` string. (a) Textually require the recorded string to start with the template-literal prefix built from PHASE245 (`.planning/phases/${PHASE245}/captures/`) and contain no `..` segment, else `fail("PNG escapes phase capture directory: ...")`. (b) Resolve it through the helper; if the resolver throws (missing), emit the existing `missing PNG <recorded path>` failure. (c) Also require the resolved absolute path to start with `resolvePhaseEvidencePath(PHASE245, "captures", { root }) + path.sep`. Keep the existing sha256 comparison. No remaining quoted `.planning/phases/245-...` literal may stay in the file (or, if one must, it carries a truthful same-line `archive-sweep-exempt:` marker -- prefer none).

Trap from CLAUDE.md: the archive fallback is for content reads only. This file makes no path-absence claim; do not add one, and do not route any "must not exist" check through the helper.

Do not touch the provenance logic (source-digest staleness, asset equality); those failures are pre-existing frozen-evidence drift, out of scope.
  </action>
  <verify>
    <automated>node scripts/ci/verify_phase245_baseline.mjs --routes-only | grep -qx 'PASS: route inventory' && node scripts/ci/verify_phase245_baseline.mjs --coverage .planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md --routes-only | grep -qx 'PASS: route inventory' && node scripts/ci/verify_phase245_baseline.mjs --self-test | grep -q '^self-test: refreshed-positive=1' && ! node scripts/ci/verify_phase245_baseline.mjs 2>&1 | grep -E -e 'ENOENT' -e 'missing PNG' -e 'escapes phase capture directory' && node scripts/ci/verify_phase230_archive_invariants.mjs --repo . 2>&1 | grep -c -e 'verify_phase245_baseline.mjs:' | grep -qx 0</automated>
  </verify>
  <done>Default and recorded-path reads resolve to `.planning/milestones/v1.66-phases/245-...`; routes-only (default and recorded-command forms) PASS; --self-test prints its success line; the full default run shows only pre-existing `source digest is stale` style provenance failures and no ENOENT / missing PNG / escape failures; the sweep reports zero findings for this file. Commit once green.</done>
</task>

<task type="auto">
  <name>Task 2: Route 248 integrated-proof owner source and both 248 tests; mark non-read literals; run the CI command chain</name>
  <files>scripts/ci/verify_phase248_integrated_proof.mjs, scripts/ci/verify_phase248_integrated_proof.test.mjs, scripts/ci/verify_phase248_render_proof.test.mjs</files>
  <read_first>scripts/ci/verify_phase248_integrated_proof.mjs (lines 1-60), scripts/ci/verify_phase248_integrated_proof.test.mjs, scripts/ci/verify_phase248_render_proof.test.mjs (lines 1-20)</read_first>
  <action>
Before editing, capture the baseline: `node --test scripts/ci/verify_phase248_integrated_proof.test.mjs scripts/ci/verify_phase248_render_proof.test.mjs 2>&1 | grep -E '^(ok|not ok)'` into a scratch file (session scratchpad, not the repo).

`verify_phase248_integrated_proof.mjs`: replace the `OWNER_SOURCE` literal with `const PHASE245_SLUG = '245-rendered-baseline-and-realistic-preview';` and, in `sourceKeys(root)`, compute the owner source via `resolvePhaseEvidencePath(PHASE245_SLUG, '245-FINDINGS.md', { root })`, then pass its repo-relative form through the existing `resolveEvidenceFile(root, ...)` so the existing symlink/escape guards still apply. Keep `resolveEvidenceFile` and its own archive fallback intact (it resolves path strings recorded inside the proof markdown, and tests 10-13 cover it). Import from `./phase_evidence_path.mjs`.

`verify_phase248_integrated_proof.test.mjs`: lines 10-11 -- add `const PHASE248 = '248-reproducible-scenarios-and-integrated-proof';` and set `proofPath` / `manifestPath` to the repo-relative form (`path.relative(root, ...)` with forward slashes) of `resolvePhaseEvidencePath(PHASE248, '248-PROOF.md', { root })` and `resolvePhaseEvidencePath(PHASE248, 'captures/phase248-current-proof/manifest.json', { root })`. Line 52 is search text replaced inside the proof markdown (a recorded string, never read from disk by the test): add a same-line `// archive-sweep-exempt: text substituted inside the proof markdown, not a filesystem read`. Lines 64 and 96 use the synthetic `245-baseline` slug under an mkdtemp root: add `// archive-sweep-exempt: synthetic fixture slug under an mkdtemp root, never a live repository read`. Do not change those fixture tests' semantics -- test 13 asserts the archive fallback is NOT applied to traversal paths (the CLAUDE.md absence/inversion trap); it must keep passing.

`verify_phase248_render_proof.test.mjs` line 11: same treatment -- `const PHASE248 = '248-reproducible-scenarios-and-integrated-proof';` and `canonicalManifest = resolvePhaseEvidencePath(PHASE248, 'captures/phase248-current-proof/manifest.json', { root: repo })`; drop the now-unused `manifestRelative` / `resolveEvidenceFile` import only if nothing else uses them.

Do NOT edit `scripts/ci/verify_phase248_render_proof.mjs` (digest-pinned in the archived manifest).

Then run the exact merge-blocking CI command chain from `.github/workflows/ci.yml` lines 311-313 and the fixed-point lines 176-177, plus the positive control: export base commit 32c0d4b1 (`git archive 32c0d4b1 scripts .github .planning | tar -x -C <scratch dir>`) and run the sweep with `--repo <scratch dir>`; it must exit 1 and list the 245/248 literals. Use a scratch dir, never the live tree; no destructive git commands. Commit once green.
  </action>
  <verify>
    <automated>node --test scripts/ci/verify_phase230_archive_invariants.mjs && node scripts/ci/verify_phase230_archive_invariants.mjs --fixtures && node scripts/ci/verify_phase230_archive_invariants.mjs && node scripts/ci/verify_phase230_archive_invariants.mjs --repo . && node --test --test-reporter=tap scripts/ci/verify_artifact_fixed_point.mjs && node scripts/ci/verify_artifact_fixed_point.mjs --fixtures --require-acyclic --require-fixed-point --require-digest-match && node --test scripts/ci/phase_evidence_path.test.mjs && node --test scripts/ci/verify_phase248_integrated_proof.test.mjs 2>&1 | grep -E '^ok (10|11|12|13) ' | wc -l | grep -qx ' *4' && ! node --test scripts/ci/verify_phase248_integrated_proof.test.mjs scripts/ci/verify_phase248_render_proof.test.mjs 2>&1 | grep -E -e 'ENOENT' -e 'missing evidence path' -e 'missing phase evidence' && S=$(mktemp -d) && git archive 32c0d4b1 scripts .github .planning | tar -x -C "$S" && ! node scripts/ci/verify_phase230_archive_invariants.mjs --repo "$S" > "$S.out" 2>&1 && grep -q 'verify_phase248_render_proof.test.mjs:11' "$S.out" && grep -q 'verify_phase245_baseline.mjs:15' "$S.out"; rc=$?; rm -rf "$S" "$S.out"; exit $rc</automated>
  </verify>
  <done>Sweep (all three ci.yml forms) exits 0; the base-commit export still fails the sweep with the 245/248 literals (checker proven able to find them); fixed-point node --test and --fixtures pass and the --repo form's only failure is still the pre-existing `phase null` message; 248 tests 10-13 pass, every 248 test that was `ok` in the baseline is still `ok`, and no 248 test fails on a path-resolution error. SUMMARY records the baseline vs after ok/not-ok lists and names the pre-existing provenance-drift and fixed-point failures as out of scope. Commit.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| CLI args / recorded manifest paths -> filesystem | Verifier reads paths supplied on the command line or recorded in committed evidence JSON |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-261024-01 | Tampering | verify_phase245_baseline.mjs PNG path resolution | low | mitigate | Recorded PNG path must textually start with the phase-245 captures prefix and contain no `..`; resolver rejects `.`/`..` segments; resolved path must sit inside the resolved captures dir |
| T-261024-02 | Information disclosure | verify_phase248_integrated_proof.mjs owner source | low | mitigate | Archive-resolved path is passed back through the existing resolveEvidenceFile symlink/escape guards |
| T-261024-03 | Repudiation | archive fallback applied to an absence claim | low | mitigate | Fallback used for content reads only; test 13 (no fallback for traversal) must keep passing |
| T-261024-SC | Tampering | npm/pip/cargo installs | low | accept | No package installs in this plan |
</threat_model>

<verification>
- `node scripts/ci/verify_phase230_archive_invariants.mjs --repo .` exits 0 (was exit 1, 11 findings).
- Positive control: the same sweep against an export of 32c0d4b1 exits 1 with the 245/248 findings.
- ci.yml lines 176-177 and 311-313 command forms pass.
- 245 verifier: routes-only PASS, self-test PASS, no path-resolution failures in the full run.
- 248 tests: no path-resolution failures, no newly failing test versus baseline.
</verification>

<success_criteria>
The merge-blocking archive sweep is green, the checker is shown still able to flag the original literals, and every touched verifier reads archived phase 245/248 evidence through `resolvePhaseEvidencePath` without changing what it validates.
</success_criteria>

<output>
Create `.planning/quick/261024-pla-route-archive-unaware-phase-245-248-veri/261024-pla-SUMMARY.md` when done (with `human_judgment: false`).
</output>
