---
phase: "245"
slug: "rendered-baseline-and-realistic-preview"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-11"
---

# Phase 245 — Security

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Local seed command to Compose/Repo | Wrong target can mutate protected data. | Synthetic billing records and database state |
| Seed data to billing interpretation | Fixtures can imply unsupported processor outcomes. | Billing status, relationships, amounts, and events |
| Authenticated route to local capture | Browser content becomes persistent evidence. | Scoped fixture records and operator session |
| Source and HTTP assets to reviewer claim | Stale builds can misrepresent rendered code. | Source, served assets, and screenshot digests |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and evidence | Status |
|-----------|----------|-----------|----------|-------------|-------------------------|--------|
| T-245-01 | Tampering | Ordinary seed target DB | high | mitigate | `ordinary.exs:4-40` checks the connected Repo database, role, DB address, exact Compose name, skip-seeds setting, and Fake processor. `scripts/ci/seed_phase245_ordinary.sh:10-40` verifies the named network, volume, and live DB fingerprint, then brackets the seed command with Phase 243 custody snapshot and preservation check. | closed |
| T-245-02 | Information disclosure | Browser capture/manifest | medium | mitigate | `playwright.phase245.config.js:21-25` disables automatic trace and failure screenshots; `phase245-admin-baseline.spec.js:74-86,234,473` checks manifest source paths and excludes credential/session field names before writing fixture capture manifests. | closed |
| T-245-03 | Tampering | Showcase billing evidence | medium | mitigate | `ordinary_preview_seed_test.exs:42-189` and `ordinary_preview_story_contract_test.exs:37-205` assert identities, relationships, stored money, UTC chronology, and linked event data. `245-ORDINARY-STORIES.md:16-27` classifies missing provider evidence. | closed |
| T-245-04 | Repudiation | Ordinary story claims | low | mitigate | Each narrative row in `245-ORDINARY-STORIES.md:5-14` names stable seed IDs and an assertion in `ordinary_preview_seed_test.exs` or `ordinary_preview_story_contract_test.exs`. | closed |
| T-245-05 | Information disclosure | Route screenshots/manifest | high | mitigate | `phase245-admin-baseline.spec.js:51-53` checks the runtime Fake processor; both the invoice tracer at lines 183-184 and independently runnable bulk capture at lines 253-259 invoke it before screenshot directories or PNGs are written. The test at lines 115-118 accepts Fake and rejects Stripe. Both capture paths apply the manifest secret-field guard before writing (`:243`, `:482`); the Playwright config disables automatic trace and failure screenshots. | closed |
| T-245-06 | Spoofing | Visual evidence provenance | medium | mitigate | `phase245-admin-baseline.spec.js:140-168,282-298` records source revision/digests, requested HTTP asset digests, and PNG hashes. `verify_phase245_baseline.mjs:183-206` rejects dirty or stale source digests, PNG mismatches, and package/compiled/served asset mismatch. The 24-capture clean manifest at revision `e90e1436` passes verification. | closed |
| T-245-07 | Elevation of privilege | Scoped route inspection | medium | mitigate | `phase245-admin-baseline.spec.js:130-137,245-254` uses the operator login and mounted routes; `accrue_admin/lib/accrue_admin/auth_hook.ex:11-32` resolves owner scope and halts on failure. `phase245-admin-baseline.spec.js:89-103,309-335` rejects redirected or mismatched route identity. | closed |
| T-245-SC | Tampering | Package install | low | accept | No new package installation is needed for this phase; the existing repository-pinned tools are used. See accepted risk below. | closed — accepted risk |

The three plans repeat T-245-SC; it is counted once. ASVS L1 verification checks whether the declared controls are present at their cited locations. No threats remain open under the `high` blocking threshold. The summaries have no `## Threat Flags` entries.

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-245-SC | T-245-SC | The phase uses repository-pinned tools and introduces no package installation. All three Phase 245 plans declare this low-severity supply-chain risk accepted. | Phase 245 plan authors | 2026-10-11 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-11 | 8 | 7 | 1 | GSD security auditor, ASVS L1 |
| 2026-10-11 | 8 | 8 | 0 | GSD security auditor, ASVS L1 re-audit |

Read-only verification: `node scripts/ci/verify_phase245_baseline.mjs --self-test` passed its positive fixture and four negative controls; the full coverage, manifest, and findings verifier passed. The refreshed manifest records 24 captures from clean source revision `a8d39ea4`. The focused Fake guard test exercises Fake acceptance and Stripe rejection. The refreshed browser run passed 5/5 checks, and the Phase 243 custody assertion passed. This re-audit did not mutate the database or rerun the browser.

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risks are documented.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** Verified 2026-10-11.
