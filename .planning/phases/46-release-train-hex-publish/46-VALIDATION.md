---
phase: 46
slug: release-train-hex-publish
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-22
---

# Phase 46 — Validation Strategy

> Per-phase validation contract for the **release train** (docs, GitHub Actions, shell gates). No dedicated ExUnit suite; CI matrix remains the regression backstop.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash + GitHub Actions (existing `CI` workflow) |
| **Config file** | `.github/workflows/ci.yml` |
| **Quick run command** | `bash scripts/ci/verify_release_manifest_alignment.sh` |
| **Full suite command** | `bash scripts/ci/verify_release_manifest_alignment.sh` (same — gate is O(1)) |
| **Estimated runtime** | under 5 seconds |

---

## Sampling Rate

- **After every task touching manifest, mix.exs, workflows, or the new script:** Run `bash scripts/ci/verify_release_manifest_alignment.sh`
- **After every plan wave:** Re-run the script + confirm `rg` checks in plan acceptance still pass
- **Before `/gsd-verify-work`:** `release-manifest-ssot` (or equivalent step) green on the merge PR; **`46-VERIFICATION.md`** filled for the shipped train

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|---------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 46-01-01 | 01 | 1 | REL-01 | T-46-01 | No secrets in YAML edits; no PAT in docs | script | `rg pull_request .github/workflows/release-pr-automation.yml`; exit **1** (no matches) after plan 01 | ⬜ pending |
| 46-01-02 | 01 | 1 | REL-01 | — | Docs use Fake / no live keys | grep | `rg -n 'HEX_API_KEY|RELEASE_PLEASE_TOKEN' RELEASING.md` only in “secrets” guidance, not literals | ⬜ pending |
| 46-02-01 | 02 | 1 | REL-02 | T-46-02 | Script reads only tracked files | script | `bash scripts/ci/verify_release_manifest_alignment.sh` exits **0** | ⬜ pending |
| 46-02-02 | 02 | 1 | REL-02 | — | CI job non-elevated | workflow | `rg -n 'release-manifest-ssot' .github/workflows/ci.yml` ≥ 1 | ⬜ pending |
| 46-03-01 | 03 | 1 | REL-04 | — | Verification doc links public URLs only | manual | `46-VERIFICATION.md` contains all **D-12** section headings | ⬜ pending |

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements** — no new Mix project or test framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hex shows published versions | REL-04 | Needs `HEX_API_KEY` / network | After merge: run `mix hex.info accrue` and `mix hex.info accrue_admin`; paste one-line version into `46-VERIFICATION.md` |
| Git tags at merge SHA | REL-04 | Registry outside CI | `git rev-list -n 1 accrue-vX.Y.Z` equals documented merge SHA |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented manual steps
- [ ] Sampling continuity: manifest script after SSOT edits
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter after wave 1 green

**Approval:** pending
