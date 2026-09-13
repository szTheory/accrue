---
phase: "229"
slug: "repository-truth-recovery-safety"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-13"
---

# Phase 229 — Security

> Verified threat register for recovery-safe repository and CI observation tooling.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Local repository → private recovery capsule | Freezes refs and typed artifact evidence before observation | Ref names/object IDs, artifact hashes, restore metadata |
| Private capsule → committed inventory | Projects only allowlisted recovery facts | Digests, encoded refs, sanitized pre/post evidence |
| Repository tooling → GitHub | Executes fixed read-only observation requests | Repository identity, full SHAs, bounded run/job facts |
| Live observation → maintainer evidence | Records available or explicit-unavailable facts deterministically | Timestamped request provenance and sanitized results |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-229-01 | Tampering | Ref preservation ordering | high | mitigate | Freeze all `refs/**`; verify encoded preservation refs and actual bundle membership. | closed |
| T-229-02 | Information Disclosure | Inventory schema and renderer | high | mitigate | Recursive allowlists, relative-path validation, and sanitized deterministic projection. | closed |
| T-229-03 | Elevation of Privilege | Shell/Git arguments | high | mitigate | Strict option parsing, quoted argv, full-object validation, and fixed namespaces. | closed |
| T-229-04 | Repudiation | Recovery proof | medium | mitigate | Private mappings plus timestamped, typed, exact-hash pre/post attestation. | closed |
| T-229-05 | Tampering | GitHub command registry | high | mitigate | Only fixed read-only `gh run list/view` operations are registered and audited. | closed |
| T-229-06 | Spoofing | Run/SHA attribution | high | mitigate | Fixed repository and full-SHA validation; no-match and ambiguity fail closed. | closed |
| T-229-07 | Denial of Service | Watch polling | high | mitigate | Positive bounded poll interval, absolute timeout, and deterministic timeout exit. | closed |
| T-229-08 | Information Disclosure | Failure summaries | medium | mitigate | Bounded allowlisted job/step fields; raw logs, actors, tokens, and payloads omitted. | closed |
| T-229-09 | Spoofing | Remote facts | high | mitigate | Repository, ISO time, normalized GET request, and full SHA required. | closed |
| T-229-10 | Tampering | Recovery-to-observation ordering | high | mitigate | Manifest, bundle, refs, and artifacts validate before any remote adapter call. | closed |
| T-229-11 | Information Disclosure | Committed evidence | high | mitigate | Field/path allowlists, escaping, negative privacy controls, and byte reproduction. | closed |
| T-229-12 | Repudiation | Unavailable/green evidence | high | mitigate | Explicit unavailable facts without substitution; Actions and provider proof remain separate. | closed |
| T-229-13 | Denial of Service | Remote/process bounds | medium | mitigate | Fixed requests, pagination/item limits, subprocess timeout, and bounded buffers. | closed |
| T-229-14 | Spoofing | Final remote evidence | high | mitigate | Independent verifier enforces repository/time/request/full-SHA provenance. | closed |
| T-229-15 | Tampering | Final capture ordering | high | mitigate | Committed manifest digest anchor, owner/mode checks, actual bundle verification/list-heads, all 109 ref/object matches, and zero-adapter-call failure fixtures. | closed |
| T-229-16 | Information Disclosure | Final artifacts | high | mitigate | Recursive privacy controls and exact JSON-to-Markdown byte verification. | closed |
| T-229-17 | Repudiation | Documentation semantics | medium | mitigate | Executable documentation checks pin read-only commands, exact identity/SHA, bounds, and provider distinction. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-13 | 17 | 15 | 2 | gsd-security-auditor |
| 2026-09-13 | 17 | 16 | 1 | gsd-security-auditor after bundle verification remediation |
| 2026-09-13 | 17 | 17 | 0 | gsd-security-auditor after manifest integrity anchoring |

---

## Sign-Off

- [x] All threats have a disposition
- [x] Accepted risks documented (none)
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-13
