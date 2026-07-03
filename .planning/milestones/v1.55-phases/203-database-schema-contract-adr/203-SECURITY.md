---
phase: 203
slug: database-schema-contract-adr
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-02
---

# Phase 203 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Maintainer/executor -> ADR artifact | Human and agent interpretation becomes a durable support-contract document. | Local planning evidence and schema-contract decisions. |
| ADR artifact -> future implementation planning | Phase 204 ranks DB hardening based on this document. | Handoff rows, risk framing, non-goals, and verification guidance. |
| ADR artifact -> adopters/support readers | Schema-placement wording can influence production upgrade behavior even though Phase 203 changes no runtime code. | Public-support contract language for `billing`, explicit `public`, and future hardening scope. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-203-01 | Tampering | `203-DB-SCHEMA-CONTRACT-ADR.md` current contract | mitigate | ADR evidence covers `billing`, explicit `public`, compile-time `Accrue.Schema`, `Accrue.Migration`, and `search_path` non-reliance; `203-VERIFICATION.md` records the markdown smoke checks and key-link checks. | closed |
| T-203-02 | Repudiation | Compatibility and upgrade warning | mitigate | ADR requires pin-before-recompile language for `public` and `billing`, plus the host-owned data migration boundary; verification report marks DB-01 and DB-02 satisfied. | closed |
| T-203-03 | Information Disclosure | Evidence citations | accept | Accepted because the ADR cites local file paths and mechanisms only; Phase 203 added no secrets, database data, credentials, runtime logs, endpoints, or file access paths. | closed |
| T-203-04 | Denial of Service | Future implementation handoff | mitigate | ADR labels Phase 204 hardening rows as advisory follow-up work and explicitly avoids implying unimplemented guards or a default rename. | closed |
| T-203-SC | Tampering | npm/pip/cargo installs | accept | Accepted as not applicable: no package-manager install tasks exist in this documentation-only plan. | closed |

*Status: open - closed*
*Disposition: mitigate (implementation required) - accept (documented risk) - transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-203-01 | T-203-03 | Local source-path citations are necessary ADR evidence and do not expose secrets or runtime data. | GSD security gate | 2026-07-02 |
| AR-203-02 | T-203-SC | Package-manager tampering is not applicable because Phase 203 performed no install or dependency work. | GSD security gate | 2026-07-02 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-02 | 5 | 5 | 0 | gsd-secure-phase |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-02
