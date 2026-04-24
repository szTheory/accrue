---
phase: 68
slug: release-train
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-23
---

# Phase 68 — Validation Strategy

> Release train: mostly **maintainer + registry** verification; local **Mix** gates for doc/runbook edits.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir Mix / ExUnit + bash CI helpers |
| **Config file** | `accrue/mix.exs` (package app), host scripts under `scripts/ci/` |
| **Quick run command** | `cd accrue && mix test --warnings-as-errors` (from repo root) |
| **Full suite command** | Same as quick for phase-scoped doc changes; optional `bash scripts/ci/verify_package_docs.sh` when docs scripts touched |
| **Estimated runtime** | ~2–15 minutes depending on cold vs warm `_build` |

---

## Sampling Rate

- **After every task commit touching `RELEASING.md`:** Run acceptance `rg` / `mix test` lines from that task.
- **After wave 1 (plans 01):** `cd accrue && mix test --warnings-as-errors` from repo root.
- **Before closing REL-03:** `68-VERIFICATION.md` table populated with live URLs post-publish.
- **Max feedback latency:** Bounded by CI for actual Hex publish (out of band for planner).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 68-01-01 | 01 | 1 | REL-01 | T-68-01 | No secrets in runbook edits | grep | `rg -n 'publish-accrue-admin' .github/workflows/release-please.yml` | ✅ | ⬜ pending |
| 68-01-02 | 01 | 1 | REL-01 | T-68-02 | Default path is human merge | grep | `rg -F 'Default:' RELEASING.md` (after task adds phrase) | ✅ | ⬜ pending |
| 68-01-03 | 01 | 1 | REL-02 | T-68-03 | Changelog hygiene prose only | grep | `rg -F 'Unreleased' RELEASING.md` in new section | ✅ | ⬜ pending |
| 68-02-01 | 02 | 2 | REL-03 | — | URL-only public refs | manual | Open each URL in browser or `curl -I` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no new test stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hex shows **0.3.1** | REL-02, REL-03 | Registry is off-repo | Visit `https://hex.pm/packages/accrue` and `https://hex.pm/packages/accrue_admin` — confirm latest release version. |
| Git tags exist | REL-03 | GitHub UI / API | Visit `https://github.com/szTheory/accrue/releases` — confirm tags `accrue-v0.3.1` and `accrue_admin-v0.3.1` (or shipped version). |
| Changelog at tag | REL-02 | Must pin to tag ref | From release tag, open `accrue/CHANGELOG.md` and `accrue_admin/CHANGELOG.md` on GitHub blob URL — confirm **0.3.1** section exists and **Unreleased** does not still describe shipped items only. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify **or** explicit manual-only row above
- [ ] Sampling continuity: doc tasks use `rg` between commits
- [ ] Wave 0 — N/A (covered by existing Mix)
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` retained through execution; flip frontmatter **`status`** to **approved** when ship + verification table complete

**Approval:** pending until Hex publish + `68-VERIFICATION.md` complete
