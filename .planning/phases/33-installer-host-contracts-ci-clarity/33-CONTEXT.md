# Phase 33: Installer, host contracts + CI clarity — Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning  
**Source:** Roadmap + REQUIREMENTS (no separate discuss-phase; scope locked from ADOPT-04..06)

<domain>

## Phase boundary

Deliver **honest installer rerun documentation**, **doc/script drift detection** for moved anchors, and **CI language clarity** (merge-blocking Fake lanes vs advisory Stripe test-mode lanes) **without** renaming stable GitHub Actions **job ids** (`release-gate`, `host-integration`, `live-stripe`, etc.).

Depends on **Phase 32** (adoption discoverability / Proof section) being complete.

</domain>

<decisions>

## Implementation decisions

### Installer reruns (ADOPT-04)

- **Locked:** Public contract for `mix accrue.install` reruns is already stated in `accrue/guides/upgrade.md` (`## Installer rerun behavior` and `## Generated code is host-owned`). Phase work **aligns** `first_hour.md`, host-facing README snippets, and troubleshooting cross-links so evaluators see the same semantics the **ExUnit** installer tests enforce (`accrue/test/mix/tasks/accrue_install_test.exs`, tags `install_templates`, `install_conflicts`).
- **Locked:** If implementation behavior and docs still disagree after audit, **prefer** fixing docs to match code; only if product intent changes, update code **and** tests in the same change set.

### Doc drift (ADOPT-05)

- **Locked:** Prefer extending **existing** gates: `scripts/ci/verify_package_docs.sh`, targeted `accrue/test/accrue/docs/*_test.exs`, and any script Phase 32 already wires in CI—before adding new standalone bash scripts.
- **Locked:** Any new `require_fixed` / assertion strings must be **grep-stable** (exact substrings, no prose churn).

### CI clarity (ADOPT-06)

- **Locked:** YAML **`jobs.<id>`** keys stay stable: at minimum `release-gate`, `host-integration`, `live-stripe` (see `.github/workflows/ci.yml` comments). Display `name:` fields may clarify *test mode* vs *live* but must not contradict job id semantics.
- **Locked:** `annotation-sweep.sh` must continue to target **merge-blocking** jobs only; advisory jobs stay out of the sweep list unless workflow explicitly changes (not in this phase).

</decisions>

<canonical_refs>

## Canonical references

### Installer + tests

- `accrue/lib/mix/tasks/accrue.install.ex` — installer entrypoint and summary taxonomy  
- `accrue/test/mix/tasks/accrue_install_test.exs` — rerun, fingerprint, conflict contracts  
- `accrue/guides/upgrade.md` — installer rerun public contract  
- `accrue/guides/first_hour.md` — first-run teaching path  

### CI + proof

- `.github/workflows/ci.yml` — job ids, `continue-on-error`, schedule/cron behavior  
- `guides/testing-live-stripe.md` — advisory `live-stripe` lane  
- `scripts/ci/annotation_sweep.sh` — which job names are release-facing for annotations  

### Doc contracts (Phase 32 lineage)

- `scripts/ci/verify_package_docs.sh` — fixed-string doc gates  
- `scripts/ci/verify_verify01_readme_contract.sh` — VERIFY-01 host README contract  

</canonical_refs>

<specifics>

## Specific ideas

- Add a **short** “rerun” pointer from `first_hour.md` to `upgrade.md#installer-rerun-behavior` so the teaching path does not imply “re-run is undefined.”
- Optionally mirror one sentence in `examples/accrue_host/README.md` **only** if it fits the host README’s Proof/verification IA without duplicating the whole upgrade guide.

</specifics>

<deferred>

## Deferred ideas

- Changing installer **product** semantics (new flags, new default overwrite rules) — out of scope unless ADOPT-04 audit finds a **bug**; then file explicitly in `33-VERIFICATION.md` manual steps before coding.

</deferred>

---

*Phase: 33-installer-host-contracts-ci-clarity*
