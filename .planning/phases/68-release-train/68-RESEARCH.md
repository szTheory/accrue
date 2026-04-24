# Phase 68: Release train — Research

**Date:** 2026-04-23  
**Question:** What do we need to know to plan REL-01..REL-03 well?

## Summary

Phase **68** ships **`accrue` / `accrue_admin` 0.3.1** through existing **Release Please** automation (`release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`). No new release architecture is in scope per **`68-CONTEXT.md`**.

### Publish ordering (REL-01)

- **`publish-accrue`** runs when `needs.release.outputs.accrue_release_created == 'true'`, checks out `accrue_sha`, verifies `@version` via `grep`, dry-run + `mix hex.publish --yes`.
- **`publish-accrue-admin`** has `needs: [release, publish-accrue]` and `if:` ensures admin only runs when `publish-accrue` succeeded when core also released (`needs.publish-accrue.result == 'success'` branch). Admin job exports `ACCRUE_ADMIN_HEX_RELEASE=1` for the admin package’s Hex gate in `mix.exs`.
- **Lockstep fallback** in the Release Please job sets `accrue_admin_release_created=true` when manifest versions match but RP only created the core GitHub Release — prevents silent skip of admin publish.

### Changelog + version boundary (REL-02)

- **Release Please** (`release-type: elixir`) bumps **`mix.exs` `@version`** and injects numbered sections into **`accrue/CHANGELOG.md`** and **`accrue_admin/CHANGELOG.md`** per config paths.
- **`main`** today still shows **`## Unreleased`** / **`## [Unreleased]`** above last tagged sections — at **merge of the release PR**, RP moves content into **`0.3.1`** sections; executor must verify **no duplicate “shipped work” left only under Unreleased** at tag time (human checklist + **`68-VERIFICATION.md`**).

### Tags + Hex evidence (REL-03)

- Tags are **`accrue-v{version}`** and **`accrue_admin-v{version}`** per workflow `write_release_outputs` and `include-component-in-tag`.
- Durable proof per **D-02**: **Hex package URL**, **git tag URL**, **changelog blob at tag** (not `main` branch), UTC timestamp — **not** Actions run URLs as primary evidence.

### Partial publish recovery

- **`RELEASING.md`** already documents retry admin, manual `publish-hex.yml`, revert window — align any new prose with **D-03** (never revert good core because admin lagged).

## RESEARCH COMPLETE

## Validation Architecture

Phase validation mixes **automated** repo checks (grep, `mix test` where applicable) and **manual registry checks** after publish (HTTP to hex.pm / GitHub tags — no secret material).

| Dimension | Approach |
|-----------|----------|
| **Local deterministic gate** | `cd accrue && mix test --warnings-as-errors` + `bash scripts/ci/verify_package_docs.sh` per **`RELEASING.md`** — run before merge and after doc edits in this phase. |
| **Doc/runbook fidelity** | `rg`-verifiable strings in **`RELEASING.md`** tying default merge path, publish order, and changelog hygiene to workflow filenames. |
| **Post-ship registry** | Maintainer fills **`68-VERIFICATION.md`** URL-first table; acceptance uses full `https://` links to **hex.pm/packages/...**, **`github.com/.../releases/tag/...`**, and **`github.com/.../blob/<tag>/.../CHANGELOG.md`**. |
| **Sampling** | After each plan wave: re-run targeted `rg` checks from plan acceptance criteria; after Hex publish: one pass of Hex + tag URLs in verification table. |

Nyquist note: there is **no new ExUnit feature** for Hex; **Dimension 8** (release proof) is satisfied by **`68-VERIFICATION.md`** + documented **`mix`** commands, not a synthetic webhook test.
