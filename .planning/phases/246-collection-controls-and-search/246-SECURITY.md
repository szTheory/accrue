---
phase: "246"
slug: collection-controls-and-search
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-11"
---

# Phase 246 — Security

Independent ASVS level 1 review at `e1a65408`; high severity blocking threshold. Authored register: nine unique threats; all mitigations verified. No accepted risks or unregistered summary threat flags.

## Trust Boundaries

Browser filters cross into owner-scoped queries; asynchronous search crosses into owner-scoped results; scoped records cross into table/clipboard output; local browser capture crosses into retained evidence.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|---|
| T-246-01 | Tampering | Invoice transitions | high | mitigate | data_table_nav.ex merges scope; queries/invoices.ex applies owner scope; invoices_live.ex scoped removal | closed |
| T-246-02 | Information disclosure | Result count | medium | mitigate | invoices_live.ex scoped summary; data_table.ex visible row count | closed |
| T-246-03 | Tampering | Collection transitions | high | mitigate | data_table_nav.ex preserves scope; patch_with_filters; owner_scope.ex session/request resolution | closed |
| T-246-04 | Information disclosure | Search and relationships | high | mitigate | charges/events/promotion_codes queries preserve exact scoped predicates; events owner-boundary tests | closed |
| T-246-05 | Information disclosure | Stale search results | high | mitigate | global_search.ex checks generation/query/owner and invalidates on scope change | closed |
| T-246-06 | Spoofing | Active result | medium | mitigate | command_palette.js single activeIndex for paint/ARIA/activation; mounted search test | closed |
| T-246-07 | Information disclosure | Clipboard | high | mitigate | Scoped rows; IdBadge escaped exact attributes; Clipboard hook; five repaired identity regression checks | closed |
| T-246-08 | Tampering | Browser evidence | medium | mitigate | Phase246 capture-only paths, source/asset/image hashes; authenticated SQL Sandbox route | closed |
| T-246-SC | Tampering | Package installs | high | mitigate | No dependency manifest/lock changes between 5afc63b1 and e1a65408 | closed |

## Additional Boundary Evidence

The ordinary seed checks the actual database, role and server address before mutation, Compose identity and Fake processor configuration. After code review CR-01, `9a508f53` additionally requires the test connection actual address to be IPv4/IPv6 loopback; missing/public addresses, wrong role and wrong database fail closed. The focused boundary test passed. Phase191 cleanup is limited to named Fake fixture namespaces and their related rows. Protected Phase243 custody remains preserved. No credentials were printed during review.

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Date | Total | Closed | Blocking open | Reviewer |
|---|---|---|---|---|
| 2026-10-11 | 9 | 9 | 0 | gsd-security-auditor |

## Sign-Off

All threats have dispositions; mitigations verified; `threats_open: 0`; status verified. Review established source controls at ASVS1, not a new end-to-end security exercise.
