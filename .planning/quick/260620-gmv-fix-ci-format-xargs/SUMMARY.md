---
quick_id: 260620-gmv
slug: fix-ci-format-xargs
date: 2026-06-20
type: quick
status: complete
commit: 0ce75413
---

# Summary — fix(ci): green main (format + CMP-05 xargs portability)

## What changed

- **`accrue/test/accrue/docs/package_docs_verifier_test.exs`** — ran `mix format`;
  the multi-line `String.replace(..., global: false)` calls now match the formatter.
- **`scripts/ci/verify_package_docs.sh`** — appended `|| true` to both CMP-05
  command substitutions (`primitive_override_hit`, `inline_style_hit`) and added
  comments. The no-hit path no longer aborts under `set -euo pipefail` when GNU
  xargs (CI Linux) returns 123 on empty/no-match grep input.

## Root cause

Both failures **predate** the v1.53 milestone close — main CI was already red at
`0195b09d` (pre-push HEAD). Introduced by Phase 188/189 commits (`dd2f0a69` format,
`156861c1` CMP-05 block). The verify_package_docs.sh bug only manifested on CI
because BSD xargs (macOS) exits 0 on empty input while GNU xargs (Linux) runs the
command and propagates grep's exit 1 as 123 — invisible to local runs.

## Verification

- `cd accrue && mix format --check-formatted` → exit 0
- `bash -n` + `bash -e scripts/ci/verify_package_docs.sh` → exit 0
- 123-pipeline absorbed by `|| true` under `set -euo pipefail` → exit 0
- Real `.ax-button {…}` override still detected → guard not neutered

## Round 2 — planning-doc contract fallout from the v1.53 close

Watching CI on `0ce75413` revealed the "Docs and bash contracts" job still red, now on a
**different** step: **Stable-core posture contract** (`verify_stable_core_posture.sh`). Root
cause: the GSD complete-milestone workflow **deletes `.planning/REQUIREMENTS.md`**, but this
repo treats it as a *permanent public-anchor file* — three merge-blocking contracts depend on
standing literals in the planning docs (the documented "planning-doc contract invariants"
gotcha). The close also reworded two standing needles.

Fixes:

- **Restored `.planning/REQUIREMENTS.md`** as a "fresh" file retaining standing
  `POS-01..03` + collapsed shipped-milestone one-liners (now incl. v1.53 shipped 33/33,
  archived) + Out of Scope. The full v1.53 functional reqs stay archived in
  `milestones/v1.53-REQUIREMENTS.md`. (Matches the v1.47/v1.50 clear-then-recreate precedent.)
- **`.planning/ROADMAP.md`** — re-added the literal `No broad feature milestone is currently
  open.` (roadmap-hygiene needle dropped by the close's `<details>` splice).
- **`.planning/PROJECT.md`** — re-hyphenated `stable-core / demand-driven expansion` (close had
  reworded it to "stable core", breaking the stable-core-posture needle).

Verified: **all 14 bash contracts** in the Docs/bash CI job pass locally (exit 0).

## Round 3 — second format gate (accrue_admin) + sandbox-pollution false alarm

With the Docs/bash job green, the **Release gate** matrix failed at **"Accrue admin
format"** — a *separate* format step from round 1's "Accrue format" (core). Core had
fully passed (format→compile→test→credo→dialyzer→docs→audit), confirming the gate runs
admin steps only after core is green.

- **`accrue_admin/test/accrue_admin/live/webhook_live_test.exs`** — `mix format`
  (stray blank line in a multi-line assert; pre-existing from `ede1354d`, Phase 188-08).
- Pre-flight before pushing: ran admin `compile --warnings-as-errors` (clean), `credo
  --strict` (no issues), full `mix test` suite. The suite first showed **3 failures**
  (`query_modules_test.exs:231` etc. with `connect-e2e@example.com`/`acct_e2e_edge` rows)
  — the documented **prior-session Playwright sandbox-pollution** gotcha. Dropping +
  recreating the test DB cleared it → **320 tests / 0 failures**. CI starts fresh, so it
  was never affected. Also confirmed `accrue_portal` format clean.

## Round 4 — Host integration gate: ExUnit copy drift

With format gates green, the required **Host integration** gate (`scripts/ci/accrue_host_uat.sh`
→ host `mix verify.full`) failed at its `bounded_mix_tests` phase: two `examples/accrue_host`
tests asserted the OLD org-billing denial copy, but `7bb642b2` (feat 191-05) changed the
canonical copy. Fixed to reference `AccrueAdmin.Copy.Locked.owner_access_denied()` (drift-proof);
also updated the skipped denial e2e spec. Verified locally: 3 tests/0 failures.

## Round 5 — Host integration gate: browser_playwright phase

Fixing round 4 let the gate advance to its `browser_playwright` phase, which failed on
`e2e/phase13-canonical-demo.spec.js` (the sole e2e failure — CI reported "1 failed"). Two
v1.53-driven drifts in that one spec:

1. **Webhook-replay confirm copy** (`:205`) — `single_replay_confirmation/2` now embeds the
   dynamic webhook id ("Replay webhook `<id>` for the active organization: ... Continue?").
   Switched the assertion to a regex on the stable explanatory tail.
2. **Audit-row locator strict-mode violation** (`:75`) — v1.53 added a bulk row-**select**
   column to the events table, so `getByRole("cell", {name: "admin.webhook.replay.completed"})`
   matched both the select-button cell and the value cell. Added `exact: true`. (Not a
   regression — replay completed and the audit row was present.)

Local verification (set up a working host e2e env: `deps.get`, test DB, chromium):
- Full host mix suite: **194 tests / 0 failures** (clean DB).
- `phase13 @phase15-trust` spec: **passes in isolation** (8.6s), twice.
- Other 9 e2e specs were already green on CI ("1 failed" = phase13 only); a full local
  e2e run OOM-killed my machine (chromium+BEAM, `exit 137`) — an environment limit, not a
  test failure, and irrelevant to CI's clean runner.

## Result

- Round 1 — `0ce75413`: `mix format` core test + harden CMP-05 `xargs` guards (GNU-vs-BSD).
- Round 2 — `93e8eeb9`: restore planning-doc contract invariants (REQUIREMENTS.md +
  ROADMAP/PROJECT standing needles) broken by the v1.53 close.
- Round 3 — `9313082b`: `mix format` accrue_admin webhook_live_test.
- Round 4 — `8fe8f091`: host denial-copy assertions → canonical `Copy.Locked`.
- Round 5 — host `phase13` e2e: replay-confirm regex + audit-cell `exact: true`.

Each push surfaced the next failure the prior `set -e` / earlier-phase step had masked — all
five were pre-existing red on `main` from Phases 188–191, stacked and serialized. Final CI
run watched to confirm fully green.
