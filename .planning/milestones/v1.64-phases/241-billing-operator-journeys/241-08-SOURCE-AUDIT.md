# Phase 241 gap-closure source audit — Plan 08

**Scope:** Current `241-VERIFICATION.md` has one actionable gap (truth 25, action-control spacing). Plans 01–07 and their summaries remain the completed implementation of the original phase. This audit checks the full plan set, including Plan 08; it does not reopen already satisfied JRN behavior.

| Source | ID or item | Covering plans | Status |
|---|---|---|---|
| GOAL | Truthful scoped billing destinations, bounded returns, Recovery continuity and action reviews | 01–07; 08 closes the shared presentation truth | COVERED |
| REQ | JRN-01 exact invoice result membership and label | 01, 07 | COVERED |
| REQ | JRN-02 validated filtered returns | 02, 03, 07 | COVERED |
| REQ | JRN-03 scoped Recovery/campaign return | 04, 07 | COVERED |
| REQ | JRN-04 self-contained billing reviews and evidence-specific results | 05, 06, 07 | COVERED |
| RESEARCH | ScopedPath/decoder parity, actual invoice membership and route labels | 01–04 | COVERED |
| RESEARCH | Review facts, exact money, fresh authorization and result distinctions at existing action owners | 05–07 | COVERED |
| RESEARCH | Existing browser owners, package build, mounted assets and bounded evidence layers | 07, 08 | COVERED |
| RESEARCH | Package-versus-host Playwright ownership open question | 07 summary resolution; 08 research marker and package owner | COVERED |
| CONTEXT | D-01–D-04 subscription facts, invoice links and local versus scope counts | 01 | COVERED |
| CONTEXT | D-05–D-07 validated returns and safe current scope | 02, 03 | COVERED |
| CONTEXT | D-08–D-09 Recovery window and historical timeline distinction | 04 | COVERED |
| CONTEXT | D-10–D-15 action reviews, safety, exact money and outcomes | 05–07 | COVERED |
| CONTEXT | D-16–D-17 incumbent roles and local dependency preference | 01–07; 08 corrects action spacing | COVERED |
| CONTEXT | D-18–D-20 recurring proof, asset provenance and bounded named-defect reopening | 07, 08 | COVERED |
| CONTEXT | Phase 242 D-20/D-21 mounted confirmation, provenance and named-defect reopening budget | 08 | COVERED |
| GAP | Truth 25: `.ax-detail-actions-row` 3px and `.ax-detail-action-band .ax-page-actions` 2px violate the 4px action-group rhythm | 08 | COVERED |

**Excluded by source scope:** Deferred Ideas in `241-CONTEXT.md`, Phase 243 reviewed Linux goldens and Fake feedback preview, and Phase 240's separately reported audit warnings. No new package or API integration is planned. The decision-coverage gate reads 20/20 tracked Phase 241 decisions across the full plan set; JRN-01–04 stay requirement-satisfied in current verification.
