# Phase 249: Local Gate Parity & Planning Truth - Context

**Gathered:** 2026-10-24
**Status:** Ready for planning
**Source:** Maintainer-approved v1.67 shape (2026-10-24 session) plus a local replay of `.github/workflows/ci.yml`. No separate discuss-phase was run; the decisions below were made and approved in that session.

<domain>
## Phase Boundary

Make the current integration head (branch `gsd/phase-233-shared-direction-portal-contract`, about 856 commits ahead of `origin/main` 7971753a) pass every merge-blocking CI check that can run locally. Make planning state honest. Out of scope: pushing, opening a PR, or anything remote (Phase 250), release alignment (Phase 251), and any new product behavior.
</domain>

<decisions>
## Implementation Decisions (locked)

### Gate integrity
- Fix every red at its source. Never weaken, skip, or make a gate vacuous ("absent is OK" must itself be provable). A gate that finds nothing must be shown able to find a known positive (CLAUDE.md "Agent Working Discipline").
- Never falsify sha256-pinned archived evidence. `scripts/ci/verify_phase248_render_proof.mjs` is pinned in the archived 248 capture manifest, so do not edit it. If the D-32 module-boundary guard must cover a pinned script, find a compliant route: the contract's own exemption mechanism if one exists, or a documented exemption with rationale. Do not edit the pinned bytes.
- Archived phase fingerprints (`covered_digest` under `.planning/milestones/*-phases/`) are frozen by design. Do not re-mint them. Recompute the current phase's digest only through `scanArtifact` + `computeDigest`.

### Known reds (from the local ci.yml replay at 291a44c0; re-measure, do not trust this list blindly)
docs-contracts-shift-left:
- SL-E completion evidence: `requirements file does not exist: .planning/REQUIREMENTS.md`. REQUIREMENTS.md now exists for v1.67 (commit 956e5dd5), so re-run and see what remains.
- SL-A PR claims: claim C1 `grep -c -F -- "open_count: 0" .planning/WINDOWS.md` measured 0, expected 1.
- SL-G artifact fixed point: `phase null` (STATE `current_phase` unset). Also `--fixtures` / node test 18 reported `covered file missing on disk: .planning/REQUIREMENTS.md`, possibly resolved now. For the record, origin/main kept `current_phase: 232` after v1.62.
- verify_package_docs.sh: bare breakpoint `@media` in `accrue_admin/assets/css/app.css` without a `/* --ax-bp-NAME ↑/↓ */` annotation (DSY-01).
- v1.17 friction and roadmap hygiene: the ROADMAP Planning Doctrine has already been restored verbatim (commit 713d8569) and both checks pass. Keep them passing.
- Executable UAT contract: `245-02-SUMMARY.md coverage D2: human_judgment must be false`. This is an archived v1.66 summary. Determine the truthful fix: either the coverage really was automated, or the contract's opt-in scope needs to be reconciled. Do not rewrite history falsely.
- D-16 committed window dispositions: the ship-window ledger has 12 open rows with no disposition partner (ids 15-20, 28-30, 36-38).
- D-32 CI script contract: missing the shared module-boundary guard in `accrue_host_preview_custody_test_entry.mjs`, `test_accrue_host_preview_custody.mjs`, `test_accrue_host_proof_paths.mjs`, `verify_phase240_evidence.mjs`, `verify_phase245_baseline.mjs`, `verify_phase246_render_proof.mjs`, `verify_phase247_render_proof.mjs`, `verify_phase248_integrated_proof.mjs`, `verify_phase248_render_proof.mjs` (pinned).

admin jobs:
- `mix compile --warnings-as-errors` fails on the unused `subscription` binding at `accrue_admin/lib/accrue_admin/live/subscription_live.ex:1286`. This blocks admin-group-contracts, admin-hardening-guardrails and admin-phase200-guardrails.
- `verify_phase190_automation_contract`: missing `/^status: complete$/` in `.planning/milestones/v1.53-phases/190-.../190-VERIFICATION.md`. This may be a verifier/archive-path issue or a frontmatter-shape change. Investigate before editing archived files.
- Phase 190 group-contract browser gate: 3 tests × desktop/mobile fail (`admin-group-contracts.spec.js:616, 626, 643`). Classify each as a real regression or a stale contract.

Not yet replayed: release-gate (mix test matrix), host-integration, playwright-e2e shards, host-docker-smoke, `accrue_admin_browser.yml` (pixel-diff visual gate). Run these locally where feasible.

### Planning truth
- Delete `.planning/HANDOFF.json` (stale, 2026-10-07).
- Record the out-of-band owner-feedback commits `3d7d949d..b4a7eeac` (2026-10-11..19) in MILESTONES.md (under v1.66, next to "Post-archive tooling") and in STATE.md as work done outside GSD. Cite `.planning/notes/2026-10-1{2,3,4,8}-admin-owner-feedback.md` as receipts. No backdated PLAN/VERIFICATION and no phase verdict claimed.
- File resolved debug sessions (`.planning/debug/phase24{5,8}-*.md`, status resolved) under `debug/resolved/`.
- Keep the 63 `.planning/quick/*` dirs as they are. Keep milestone tags local.

### Resolved research assumptions (decided 2026-10-24 under the maintainer's "follow your plan" authority; reversible, non-falsifying routes)
- **A1 (ledger dispositions):** Accept the RESEARCH.md R2 proposal. Waive 15, 16, 17, 18, 19 and 36; mark 20, 28, 29, 30, 37 and 38 fixed. Use only `gsd-tools windows fixed|waive`. Each waive reason names the owner, the cause and the release impact. Each "fixed" must cite the passing command that proves it (re-run it in this phase; don't rely only on research-time output).
- **A2 (D-16):** Add an explicit scope-bound join to the D-16 verifier (`--ledger-through-id` or equivalent) with fixtures and negative controls, rather than minting a new record. The CI invocation passes the bound explicitly, and an unbounded run keeps its current strict behavior.
- **A3 (exec-UAT):** Add a narrow recorded-deviation list for the archived 245–248 summaries' honest `human_judgment: true` entries. Pin each entry to the summary's path and sha256, and give it a reason. Any byte change to a listed summary, or a listed entry that no longer exists, re-fails the check (negative controls required). Do not edit digest-covered archived summaries.
- **A4 (D-32):** Add a hash-pinned `ARCHIVED_EVIDENCE_VERIFIER_EXEMPTIONS` map for the sha-pinned or receipt-bound evidence verifiers (at least `verify_phase247_render_proof.mjs` and `verify_phase248_render_proof.mjs`; others only where editing would falsify a recorded receipt). Each entry carries a reason and a stale-exemption check, plus negative controls. The non-pinned scripts get the real module-boundary guard and hermetic tests.
- **Visual baselines:** The Linux-only pixel-diff gate is measured remotely in Phase 250 (CI diff first; re-mint via `workflow_dispatch` only for intentional changes). Phase 249 does not re-mint baselines locally.
- **host-integration:** `verify.install` runs `accrue.install --yes`, which may rewrite tracked files. Run it in a scratch clone with real installs (never symlinked deps), or on a committed tree whose `git status` is checked afterwards.
- **SL-F (PR-body currency):** This needs a live PR and token, so it moves to Phase 250. It is not a Phase 249 red.

### Host preview-custody decision (maintainer, 2026-10-25)
- **Finding (249-14):** `scripts/ci/accrue_host_preview_custody.sh` (added in Phase 243-02, `de9e4d5d`) fails closed unless it can identify the maintainer's Docker `accrue-host` preview. Hosted CI has no preview, so the host-integration dev-boot/browser lanes and playwright-e2e would REFUSE in CI. This was masked because no full CI run has happened since 2026-09-18.
- **Decision:** Add an explicit opt-in CI mode to the custody check. `ci.yml` sets a dedicated env flag, and the check then *proves* that no preview instance exists: either no Docker binary, or zero volumes and zero containers carrying the preview's compose-project label. Any preview it finds → REFUSE. Without the flag, behavior is unchanged. Fixtures and negative controls are required: flag set + preview present → refuse; flag unset + no preview → refuse as today; flag set + absent → pass, and say so explicitly in the log.
- **Proof location:** the maintainer chose to prove the host dev-boot, browser and playwright-e2e lanes in remote CI (Phase 250, exact head SHA). The host mix test phases (bounded + full) are already proven locally (64/0 and 237/0). No Docker on the maintainer's machine. GREEN-05's wording and the Phase 249/250 success criteria are updated to match, with this reason recorded.

### Claude's Discretion
- Plan/wave decomposition, ordering, and the specific technical fix for each red, provided the gate-integrity rules above hold.
- Whether a red is better fixed in the verifier (archive-awareness) or in the artifact, decided by which one is actually wrong.
</decisions>

<canonical_refs>
## Canonical References

- `CLAUDE.md`: Executable Acceptance Policy; Agent Working Discipline; "Milestone close breaks contracts that read .planning/phases/"
- `.github/workflows/ci.yml`: the exact commands to run (jobs docs-contracts-shift-left, admin-*, release-gate, host-integration, playwright-e2e)
- `.github/workflows/accrue_admin_browser.yml`: visual pixel-diff gate
- `scripts/ci/phase_evidence_path.mjs`: archive-aware evidence path resolver
- `scripts/ci/verify_artifact_fixed_point.mjs`: covered_digest tooling
- `.planning/milestones/v1.62-MILESTONE-AUDIT.md`: precedent for integration hygiene
- `.planning/quick/261024-pla-route-archive-unaware-phase-245-248-veri/261024-pla-SUMMARY.md`: archive sweep fix already landed
</canonical_refs>

<specifics>
## Specific Ideas

- Reproduce CI faithfully. When replaying `run:` blocks, write each block to a temp `.sh` file. Never pass a dumped string to `bash -c`, which escapes newlines and yields false results.
- Scratch worktrees must install real deps or copy them. Never symlink `node_modules` or `deps`: `npm ci` empties the link target.
- Commit each green fix immediately. Never run destructive git in the live tree.
</specifics>

<deferred>
## Deferred Ideas

These go to a later milestone (see REQUIREMENTS.md "Future Requirements"): webhook list multi-status filter, recovery fixture integrity, LiveView 1.1.32 alignment, ExMoney/Storybook notices, Sigra datetime triage, dead `ci.yml:881` alternation, mailglass cap documentation, and re-capture or retirement of the drifted 245/248 evidence verifiers.
</deferred>

---

*Phase: 249-local-gate-parity-planning-truth*
*Context gathered: 2026-10-24*

### Orchestrator rulings on the gap closure (2026-10-25)
- **249-18 editing the custody script is allowed.** Its digest appears only in the v1.66 Phase 245 capture manifests' `source_digests`, which are source *inputs* that already went stale: the 245 verifier reports "source digest is stale", and 249-01 already edited `app.css` from the same manifest. That is not a pinned receipt verifier, so the locked "never falsify pinned evidence" rule is not violated. Record the 245 receipt as historical under the deferred re-capture/retire item.
- **249-15 local listing:** if `playwright test --list` is refused by the custody preflight on the maintainer's machine (expected, because a preview volume exists), that refusal is the recorded positive control, not a blocker. The per-shard non-zero test count then moves to Phase 250 with the full shards. Do not bypass or flag around the preflight locally.
