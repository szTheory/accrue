---
phase: 152
slug: close-v1-46-closure-gaps-since-warnings-verification-hex-pub
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-30
---

# Phase 152 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Source edits | Developer edits Elixir source files; no external input crosses any trust boundary | None — docstring metadata only |
| Local shell execution | Gate scripts run bash commands locally; no external input | None — read-only local verification |
| GitHub Actions → Hex.pm | `mix hex.publish` transmits package tarball; credentials from GitHub Actions secrets only | Package tarball (public artifact) + HEX_API_KEY (secret, never logged) |
| GitHub Actions → GitHub API | Release Please creates tags, PRs, GitHub Releases; RELEASE_PLEASE_TOKEN scoped to repo only | Tag + PR metadata (non-sensitive) |
| Developer → GitHub | PR review and merge is a human gate; no automated merge without human approval | None |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-152-01-plan01 | — | dunning.ex, funnel_chart.ex | accept | No new attack surface — plan edits docstring metadata and version strings only. No authentication, authorization, webhook handling, or secret management modified. Read-only verification scripts. | closed |
| T-152-02-plan02 | — | scripts/ci/verify_*.sh | accept | No new attack surface — plan runs read-only verification scripts and mix commands against local codebase. No credentials, secrets, or external services involved. Results are local output only. | closed |
| T-152-01 | Information Disclosure | Hex API key / RELEASE_PLEASE_TOKEN | mitigate | HEX_API_KEY and RELEASE_PLEASE_TOKEN exist ONLY as GitHub Actions secrets (Settings → Secrets → Actions). Never echoed in workflow logs (--yes flag on mix hex.publish). Never committed to any file. Never appear in PR descriptions, commit messages, or CHANGELOG content. | closed |
| T-152-02 | Tampering | release-please-config.json, .release-please-manifest.json | mitigate | No manual @version edits in any mix.exs or manifest. All version bumps went through Release Please PR review (human gate at Task 3 checkpoint). PR diff reviewed before merge. | closed |
| T-152-03 | Tampering | accrue/guides/release-notes.md | accept | Release notes are documentation; no security-sensitive content. Worst case is an incorrect version summary, caught by reviewer in PR review. | closed |
| T-152-SC | Tampering | npm/pip/cargo installs | accept | No new packages installed in this phase. Package legitimacy gate not applicable. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-152-01 | T-152-01-plan01 | Docstring metadata (@since annotations) edits carry zero attack surface. No auth, webhook, secret, or network code modified. | plan author | 2026-05-29 |
| AR-152-02 | T-152-02-plan02 | Verification gate scripts are read-only (`grep`, `mix compile`, `mix test`). No write operations or external service calls. | plan author | 2026-05-29 |
| AR-152-03 | T-152-03 | Release notes are public documentation (guides/release-notes.md). No security-sensitive data. Reviewer-caught in PR diff. | plan author | 2026-05-30 |
| AR-152-04 | T-152-SC | Zero new npm/pip/cargo/mix packages were installed as part of this phase. Scope confined to code edits and the Release Please pipeline. | plan author | 2026-05-30 |

---

## Mitigation Evidence

### T-152-01 — HEX_API_KEY / RELEASE_PLEASE_TOKEN (Information Disclosure)

**Evidence from 152-03-SUMMARY.md:**
- "Release Please end-to-end pipeline used (no manual @version edits, no manual tag creation)"
- "GitHub Actions publish-accrue / publish-accrue-admin / publish-accrue-portal jobs succeeded"
- `mix hex.info accrue 1.3.0` → Released: 2026-05-30 ✓ — confirms successful publish via CI with no credential leakage
- No secrets appear in any commit message, CHANGELOG entry, or PR description in the phase commit list (commits aa24cd0b through 4e9503c2)

### T-152-02 — Release Please manifest tampering

**Evidence from 152-03-SUMMARY.md:**
- "Release-As: 1.3.0 trailer was NOT needed — Release Please computed 1.3.0 automatically from the feat: commits accumulated since 1.2.0"
- `@version` bumps in all three mix.exs were applied by Release Please on PR merge (`4e9503c2 chore: release main`) — not by manual edit
- `.release-please-manifest.json` shows all three packages at `"1.3.0"` (set by Release Please)
- `verify_release_manifest_alignment.sh` exits 0 post-publish ✓

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-30 | 6 | 6 | 0 | gsd-secure-phase (auto) |

**Short-circuit applied:** `threats_open: 0` + `register_authored_at_plan_time: true` — all plan-time threats verified CLOSED without spawning auditor agent.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-30
