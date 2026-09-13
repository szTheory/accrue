---
phase: "229"
slug: "repository-truth-recovery-safety"
status: open
threats_open: 3
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
| T-229-12 | Repudiation | Unavailable/green evidence | high | mitigate | Explicit unavailable facts must retain normalized request provenance; the plural Markdown projection currently drops it. | open |
| T-229-13 | Denial of Service | Remote/process bounds | medium | mitigate | Fixed requests, pagination/item limits, subprocess timeout, and bounded buffers. | closed |
| T-229-14 | Spoofing | Final remote evidence | high | mitigate | Independent verifier must enforce and render repository/time/request/full-SHA provenance; plural facts currently render an undefined request. | open |
| T-229-15 | Tampering | Final capture ordering | high | mitigate | Committed manifest digest anchor, owner/mode checks, actual bundle verification/list-heads, all 109 ref/object matches, and zero-adapter-call failure fixtures. | closed |
| T-229-16 | Information Disclosure | Final artifacts | high | mitigate | Recursive privacy controls and exact JSON-to-Markdown byte verification. | closed |
| T-229-17 | Repudiation | Documentation semantics | medium | mitigate | Executable documentation checks pin read-only commands, exact identity/SHA, bounds, and provider distinction. | closed |
| T-229-G05-01 | Tampering | Recovery output identities | high | mitigate | Physical parent validation, pairwise alias/touch rejection, exclusive publication, and final bundle verification. | closed |
| T-229-G05-02 | Elevation of Privilege | Ref restoration metadata | high | mitigate | Structured argv restoration without shell evaluation, including hostile valid-ref fixtures. | closed |
| T-229-G05-03 | Information Disclosure | Private scratch inventories | high | mitigate | Exact invocation-owned cleanup traps cover success and failure paths. | closed |
| T-229-G05-04 | Repudiation | Public recovery record | medium | mitigate | One retained bundle digest drives and validates the final published triplet. | closed |
| T-229-G06-01 | Spoofing | Recovery manifest repository | high | mitigate | Manifest repository identity is checked before bundle, attestation, or adapter access. | closed |
| T-229-G06-02 | Tampering | GitHub API adapter | high | mitigate | Fixed GET-only endpoint registry, shell-disabled argv, and exact repository binding. | closed |
| T-229-G06-03 | Denial of Service | Pagination and process output | high | mitigate | Page, item, timeout, and buffer bounds fail explicitly on overflow. | closed |
| T-229-G06-04 | Information Disclosure | Worktree and API evidence | high | mitigate | Physical paths and raw payloads are discarded before allowlisted normalization. | closed |
| T-229-G06-05 | Repudiation | Empty and unavailable facts | medium | mitigate | Confirmed empty plural results remain distinct from typed unavailable observations. | closed |
| T-229-G07-01 | Tampering | Strict recovery verification | high | mitigate | Independent exact-set comparison covers manifest, bundle heads, encoded refs, and inventory. | closed |
| T-229-G07-02 | Elevation of Privilege | Rendered restore procedure | high | mitigate | Tested POSIX quoting and argv data restore hostile refs without evaluated input. | closed |
| T-229-G07-03 | Spoofing | Complete category evidence | high | mitigate | Flag-specific negative mutations prove identity, availability, SHA, and set semantics. | closed |
| T-229-G07-04 | Information Disclosure | Renderer and verifier inputs | high | mitigate | Private inputs stay runtime-only and recursive checks exclude them from committed artifacts. | closed |
| T-229-G08-01 | Spoofing | Branch and workflow selection | high | mitigate | Wrapper defaults pin main/CI and resolve the selected run to a full SHA. | closed |
| T-229-G08-02 | Repudiation | Completed run exit status | high | mitigate | Exact repository/SHA output precedes a stable non-zero exit for every non-success conclusion. | closed |
| T-229-G08-03 | Denial of Service | Compatibility watch | high | mitigate | Maximum timeout and poll bounds remain enforced through wrapper defaults. | closed |
| T-229-G08-04 | Tampering | Monitor operation registry | high | mitigate | Executable wrapper fixtures retain the list/view-only operation registry. | closed |
| T-229-G09-01 | Tampering | Original recovery capsule | high | mitigate | Anchored manifest and bundle digests, owner/mode, heads, refs, and additive attestation are rechecked. | closed |
| T-229-G09-02 | Spoofing | Final remote evidence | high | mitigate | Actual fixed-repository GET attempts carry ISO time, complete SHA sets, or explicit unavailability. | closed |
| T-229-G09-03 | Information Disclosure | Canonical artifacts | high | mitigate | Recursive privacy controls and byte reproduction passed on the final artifacts. | closed |
| T-229-G09-04 | Repudiation | Final phase handoff | high | mitigate | The complete reviewed regression chain is recorded in the final summary. | closed |
| T-229-G09-05 | Denial of Service | Live recapture | medium | mitigate | Final capture retains collector subprocess, pagination, item, timeout, and buffer bounds. | closed |
| T-229-G10-01 | Tampering | Final artifact reconciliation | high | mitigate | Final-boundary artifact snapshots are compared after collection before success. | closed |
| T-229-G10-02 | Repudiation | Symlink target identity | high | mitigate | Preservation hashes raw link bytes, including newline and non-UTF-8 fixtures. | closed |
| T-229-G10-03 | Information Disclosure | Protected artifact metadata | high | mitigate | Public evidence remains allowlisted and private capsule inputs remain runtime-only. | closed |
| T-229-G10-04 | Elevation of Privilege | Filesystem traversal | medium | mitigate | Physical containment and raw-byte-safe path handling fail closed. | closed |
| T-229-G11-01 | Spoofing | Plural remote pagination | high | mitigate | Pull request, release, and Actions collection proves terminal pagination. | closed |
| T-229-G11-02 | Denial of Service | Pagination bounds | high | mitigate | Page and item limits fail explicitly before partial evidence is accepted. | closed |
| T-229-G11-03 | Tampering | Terminal page evidence | high | mitigate | Complete page request sets are recorded and independently verified. | closed |
| T-229-G11-04 | Information Disclosure | Remote response handling | medium | mitigate | Raw provider payloads are normalized to allowlisted fields. | closed |
| T-229-G12-01 | Denial of Service | CI watch deadline | high | mitigate | One absolute deadline bounds every poll and detail request. | closed |
| T-229-G12-02 | Spoofing | Viewed run attribution | high | mitigate | Viewed run identity is bound to the selected run, workflow, repository, and SHA. | closed |
| T-229-G12-03 | Repudiation | CI terminal result | medium | mitigate | Terminal status and bounded provenance are emitted deterministically. | closed |
| T-229-G12-04 | Tampering | CI operation registry | high | mitigate | Only the fixed read-only list/view operation set is accepted. | closed |
| T-229-G13-01 | Spoofing | Active repository authority | high | mitigate | Strict verification reconciles the live repository against independent authorities. | closed |
| T-229-G13-02 | Tampering | Canonical ref evidence | high | mitigate | Complete refs, tags, worktrees, and ship windows are structurally and semantically checked. | closed |
| T-229-G13-03 | Repudiation | Command provenance | high | mitigate | Only allowlisted same-repository endpoints and exact requests are accepted. | closed |
| T-229-G13-04 | Information Disclosure | Path privacy | high | mitigate | Absolute, URI, UNC, control-character, and private-path leakage probes fail closed. | closed |
| T-229-G13-05 | Elevation of Privilege | Verification subprocesses | medium | mitigate | Verification uses shell-disabled subprocesses and test-owned temporary directories. | closed |
| T-229-G14-01 | Repudiation | Strict verification documentation | high | mitigate | Executable documentation requires all runtime-only private authority inputs. | closed |
| T-229-G14-02 | Tampering | Final handoff invariants | high | mitigate | Fixed-chain before/after snapshots reject capsule and workspace drift. | closed |
| T-229-G14-03 | Spoofing | Canonical JSON/Markdown provenance | high | mitigate | Exact terminal-page request provenance must survive into both canonical artifacts; plural Markdown rows currently lose it. | open |
| T-229-G14-04 | Information Disclosure | Final handoff output | high | mitigate | Runtime-only authority and recursive privacy checks prevent private-path disclosure. | closed |
| T-229-G14-05 | Elevation of Privilege | Attestation publication | medium | mitigate | A single pre-authorized mode-0600 attestation is created exclusively after invariant checks. | closed |

*Status: open — three high-severity threats block completion.*

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
| 2026-09-13 | 39 | 39 | 0 | gsd-security-auditor after gap closure and final recapture |
| 2026-09-13 | 61 | 58 | 3 | gsd-security-auditor after second gap closure |

---

## Sign-Off

- [x] All threats have a disposition
- [x] Accepted risks documented (none)
- [ ] `threats_open: 0` confirmed
- [ ] `status: verified` set in frontmatter

**Approval:** blocked pending remediation of T-229-12, T-229-14, and T-229-G14-03
