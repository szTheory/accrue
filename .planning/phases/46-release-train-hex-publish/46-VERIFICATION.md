---
status: passed
phase: 46-release-train-hex-publish
verified: 2026-04-22
---

# Phase 46 verification

## Automated (implementation / REL-02 script)

| Check | Result |
|-------|--------|
| `rg -n 'pull_request' .github/workflows/release-pr-automation.yml` | No matches (dispatch-only REL-01 workflow) |
| `bash scripts/ci/verify_release_manifest_alignment.sh` | Pass |
| `rg -n 'release-manifest-ssot' .github/workflows/ci.yml` | Present; `annotation-sweep` lists job in `needs` and `annotation_sweep.sh` args |
| Plan acceptance greps (`46-0{1,2,3}-PLAN.md` criteria) | Pass at authoring time |
| `cd accrue && mix test --warnings-as-errors` | **Fails in this workspace** — six `Accrue.Docs.*` tests require missing `.planning` trust/expansion files; one flaky `FactoryTest` DB sandbox checkout. **Unrelated to Phase 46 file edits.** |

## Must-haves (from plans)

- **REL-01:** `release-pr-automation.yml` is **`workflow_dispatch`** only; `RELEASING.md` documents the same maintainer path + partial Hex recovery with FAQ link.
- **REL-02:** `verify_release_manifest_alignment.sh` enforces manifest ↔ both `mix.exs` `@version` + lockstep; **`release-manifest-ssot`** blocks merge in CI.
- **REL-04:** D-12 fill-in template below exists for first real train evidence (placeholders retained by design).

## Human verification

Hex publish evidence (`mix hex.info`, live PR URLs) is **maintainer-filled after a real train** — placeholders in the D-12 sections remain until then.

---

This file is the **D-12 evidence index card** for a completed **Phase 46** release train: short links and reproducible command blocks, not log dumps. Fill **`REPLACE_ME_*`** / **`TODO_*`** after the real ship.

**REL IDs covered here:** **REL-01** (human-gated merge path), **REL-02** (manifest ↔ `mix.exs` SSOT), **REL-04** (tags + Hex corroboration). Cross-check the maintainer runbook in **`RELEASING.md`**.

## 1. Release / phase identifier

- **Phase:** 46 — Release train & Hex publish
- **REL:** REL-01, REL-02, REL-04
- **Milestone / intent (comms only):** `REPLACE_ME_MILESTONE_NOTE`

## 2. Release Please PR and merge commit

- **Combined Release Please PR:** `REPLACE_ME_PR_URL`
- **Merge commit SHA:** `REPLACE_ME_MERGE_SHA`
- **Notes:** Confirm the PR was **human-reviewed** before merge (REL-01); do not treat green CI alone as approval.

## 3. Git tags for this train

Release Please publishes from tags shaped as:

- **`accrue-v{VERSION}`** — e.g. `accrue-vREPLACE_ME_VERSION`
- **`accrue_admin-v{VERSION}`** — e.g. `accrue_admin-vREPLACE_ME_VERSION`

Record the resolved tag names after the run: `TODO_TAG_ACCRUE=`, `TODO_TAG_ACCRUE_ADMIN=`.

## 4. Hex registry corroboration (REL-04)

Run locally (requires network; uses your Hex user config, not repo secrets):

```bash
mix hex.info accrue
mix hex.info accrue_admin
```

Paste one-line **Released** / version confirmation into notes if desired; keep this file as **links + commands**, not full CLI transcripts.

## 5. Changelog anchors

- **`accrue/CHANGELOG.md`** — section header for shipped version: `REPLACE_ME_ACCRUE_CHANGELOG_ANCHOR`
- **`accrue_admin/CHANGELOG.md`** — section header for shipped version: `REPLACE_ME_ADMIN_CHANGELOG_ANCHOR`

## 6. CI evidence (merge commit)

Link the GitHub Actions run(s) for **`REPLACE_ME_MERGE_SHA`** (or the merge PR’s latest green run) and call out:

- **`release-manifest-ssot`** — manifest ↔ `@version` gate (REL-02)
- **`release-gate`** — required deterministic matrix
- **Workflow file:** `.github/workflows/release-please.yml` — tag + publish jobs for this train

`REPLACE_ME_CI_RUN_URLS`

## 7. Minimal consumer smoke

Generic check that a Phoenix app can resolve the pair (adjust app name / path as needed):

```bash
# Example: path deps from a throwaway app — replace ___ with your checkout path
mix new consumer_smoke --sup
cd consumer_smoke
# {:accrue, path: "___/accrue"}, {:accrue_admin, path: "___/accrue_admin"}
```

Or document **`mix hex.outdated`** / resolver proof against published versions after Hex publish (`TODO_SMOKE_NOTES`).

## 8. Version coupling (admin ↔ core)

For the shipped line **V = `REPLACE_ME_VERSION`**, consumers should pin compatible ranges, for example:

```elixir
{:accrue, "~> REPLACE_ME_MAJOR_MINOR"}
{:accrue_admin, "~> REPLACE_ME_MAJOR_MINOR"}
```

Confirm **`accrue_admin`**’s **`{:accrue, ...}`** in **`accrue_admin/mix.exs`** matches the same train (lockstep dual package).

## 9. Support and security posture

- Prefer **retire + forward-fix** over silent half-pairs when recovery is needed; see **`RELEASING.md`** → **Partial Hex publish recovery** and [Hex FAQ](https://hex.pm/docs/faq).
- Security-sensitive issues: see repository **`SECURITY.md`**.
- **Posture bullets:** `TODO_SUPPORT_BULLET_1`, `TODO_SUPPORT_BULLET_2`

---

_Last updated: REPLACE_ME_DATE — template authored in Phase 46 plan 03._
