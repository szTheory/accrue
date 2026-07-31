---
phase: 214
slug: docs-truth-reconciliation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-31
verified: 2026-07-31
---

# Phase 214 — Security

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Repository prose → integrator decisions | Current documentation must not promote advisory Stripe data into entitlement authority. | Version, capability, and authorization guidance |
| `ROOT_DIR` → fixed repository paths | Tests may redirect the verifier to an isolated fixture tree. | Filesystem root only; no executable input |
| Parsed package versions → state selection | Package source text controls pre-release versus generated-candidate validation. | Stable SemVer strings |
| Release Please candidate → merge/release CI | Generated versions and changelog sections must advance as one linked release. | Three package versions and changelogs |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-214-01 | Tampering | Current entitlement/JTBD/support prose | high | mitigate | Package-doc assertions and mutation fixtures enforce default-off observational semantics and local grant authority. | closed |
| T-214-02 | Repudiation | Dated planning/seed/archive evidence | medium | mitigate | Current-surface scope is enumerated; verification distinguishes dated evidence and confirms no historical rewrite. | closed |
| T-214-03 | Spoofing | Adoption proof claims | medium | mitigate | Adoption and support mirrors name the executable package-doc, support-matrix, and isolation gates. | closed |
| T-214-04 | Information Disclosure | Documentation-only changes | low | accept | No credential or runtime payload is introduced; repository-local public metadata only. | closed |
| T-214-05 | Spoofing | Admin/portal release entries | high | mitigate | Candidate fixtures require compatibility-only companion sections and substantive ownership in core. | closed |
| T-214-06 | Tampering | ExDoc `since` metadata | high | mitigate | Exact-location package-doc assertions and stale/missing/over-badged fixtures cover the four public surfaces. | closed |
| T-214-07 | Repudiation | Release Please ownership | medium | mitigate | Checked-in 1.4.0 requires Unreleased ownership; generated candidates require aligned numbered sections. | closed |
| T-214-08 | Elevation of Privilege | Release authorization wording | high | mitigate | Release-note and package-doc gates reject claims that advisory sync affects grants, plugs, or LiveView guards. | closed |
| T-214-09 | Tampering | Parsed versions and state selection | high | mitigate | Strict stable SemVer validation and three-package equality run before state selection; malformed fixtures fail. | closed |
| T-214-10 | Elevation of Privilege | `ROOT_DIR` override | high | mitigate | Verifier uses quoted, fixed repository-relative paths and no `eval`, `source`, or dynamic commands; spaced-root fixture passes. | closed |
| T-214-11 | Spoofing | Incomplete linked candidate | high | mitigate | Every non-1.4.0 aligned candidate requires matching numbered sections and correct ownership in all packages. | closed |
| T-214-12 | Repudiation | Numbered changelog ownership | medium | mitigate | Premature numbering fails in checked-in state; aligned generated candidates pass through the same production verifier. | closed |
| T-214-13 | Denial of Service | Valid future candidate blocked | high | mitigate | 1.5.0 and 1.6.0 generated-candidate fixtures prove the gate does not require per-release code edits. | closed |
| T-214-14 | Information Disclosure | Verifier diagnostics | low | accept | Diagnostics expose only bounded invariant, package, and validated version labels—not contents or secrets. | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-214-01 | T-214-04 | Phase changes public repository documentation and metadata only; no sensitive runtime data crosses the boundary. | project plan | 2026-07-31 |
| AR-214-02 | T-214-14 | Bounded package/version diagnostics are necessary for unattended CI remediation and contain no secrets. | project plan | 2026-07-31 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-31 | 14 | 14 | 0 | GSD ASVS-1 verification |

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risks are documented.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-07-31
