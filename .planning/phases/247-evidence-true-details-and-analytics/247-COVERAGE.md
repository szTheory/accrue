# Phase 247 source and UI coverage ledger

This ledger is a planning acceptance map. Every row is an executor obligation; completion is recorded in task summaries and VALIDATION.md. There are 47 UI-SPEC considerations, all resolved as explicit. The repeated criterion text remains attached to each independently named surface.

## Goal and requirements

| Source | Coverage |
|---|---|
| ROADMAP goal: readable, investigative, actionable existing details and recovery with exact qualified evidence | 247-01 through 247-08 |
| TIME-01 | 247-01, 247-02, 247-03, 247-08; mounted 247-07 |
| LANG-02 | 247-04, 247-05, 247-06; mounted 247-07 |
| STATE-02 | 247-04, 247-05, 247-06; mounted 247-07 |
| DETAIL-01 | 247-04; mounted 247-07 |
| DETAIL-02 | 247-04, 247-05; mounted 247-07 |
| METRIC-01 | 247-06; mounted 247-07 |

## Locked decision audit

| Decision | Implementing plans |
|---|---|
| D-01 | 247-01, 247-02, 247-03, 247-08 |
| D-02 | 247-01, 247-02, 247-03, 247-08 |
| D-03 | 247-04, 247-05, 247-06 |
| D-04 | 247-04, 247-05, 247-06 |
| D-05 | 247-04, 247-05 |
| D-06 | 247-04 |
| D-07 | 247-04 |
| D-08 | 247-02, 247-05 |
| D-09 | 247-06 |
| D-10 | 247-06 |
| D-11 | 247-01, 247-02, 247-04 |
| D-12 | every owning test, then 247-07 |

## Research constraints and owners

| Source item | Plan |
|---|---|
| Existing Phoenix LiveView/AppShell/Detail/JsonViewer/KpiCard/WindowSelector patterns | 247-01/02/04/06 |
| Native Intl formatting and Clipboard promise; exact ISO preserved separately | 247-01/02 |
| All 20 timestamp consumers enumerated in RESEARCH Existing Owners and Consumers, including WebhookLive tracer | 247-01/03/08 |
| Existing replay action-time authorization and owner/step-up/confirmation guards | 247-04 |
| Existing recovery Dunning formulas, currency distinctions, UTC bounds and owner scope | 247-06 |
| Node, ExUnit and mounted Playwright proof at tested source/served assets | 247-01/02/07 |
| No package installation, external API integration, data schema or query redesign | all plans |

## UI-SPEC considerations

| # | Element/category | Owning plan | Exact explicit acceptance |
|---|---|---|---|
| 1 | TIME/empty | 247-01/02 | Absent instants have no copy control; missing metadata is unavailable; empty history has one explanation; empty analytics yields no invented currency group; replay missing eligibility cannot expose an eligible action. |
| 2 | TIME/loading | 247-01/02 | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| 3 | TIME/error | 247-01/02 | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| 4 | TIME/partial | 247-01/02 | Missing time/fee/plan/snapshot/history is explicitly unavailable or absent, never inferred pending/misconfiguration; actual zero stays distinct; each present authorized value remains readable. |
| 5 | TIME/overflow | 247-01/02 | Long IDs, ISO values, JSON and currency groups wrap or scroll within their container with no horizontal page overflow at320px; copy retains full values. |
| 6 | TIME/long-text | 247-01/02 | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |
| 7 | NAV/loading | 247-05 | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| 8 | NAV/error | 247-05 | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| 9 | NAV/overflow | 247-05 | Long IDs, ISO values, JSON and currency groups wrap or scroll within their container with no horizontal page overflow at320px; copy retains full values. |
| 10 | NAV/long-text | 247-05 | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |
| 11 | DETAIL/empty | 247-05 | Absent instants have no copy control; missing metadata is unavailable; empty history has one explanation; empty analytics yields no invented currency group; replay missing eligibility cannot expose an eligible action. |
| 12 | DETAIL/loading | 247-05 | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| 13 | DETAIL/error | 247-05 | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| 14 | DETAIL/populated | 247-05 | Record identity, concise observed status, supported next action and exact secondary evidence read in that order; per-currency recovered/exhausted values retain query output. |
| 15 | DETAIL/partial | 247-05 | Missing time/fee/plan/snapshot/history is explicitly unavailable or absent, never inferred pending/misconfiguration; actual zero stays distinct; each present authorized value remains readable. |
| 16 | DETAIL/overflow | 247-05 | Long IDs, ISO values, JSON and currency groups wrap or scroll within their container with no horizontal page overflow at320px; copy retains full values. |
| 17 | DETAIL/zero-one-many | 247-05 | Zero/one/many history and currency rows retain readable hierarchy without synthesized records or combined currencies. |
| 18 | DETAIL/long-text | 247-05 | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |
| 19 | REPLAY/empty | 247-04 | Absent instants have no copy control; missing metadata is unavailable; empty history has one explanation; empty analytics yields no invented currency group; replay missing eligibility cannot expose an eligible action. |
| 20 | REPLAY/loading | 247-04 | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| 21 | REPLAY/error | 247-04 | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| 22 | REPLAY/partial | 247-04 | Missing time/fee/plan/snapshot/history is explicitly unavailable or absent, never inferred pending/misconfiguration; actual zero stays distinct; each present authorized value remains readable. |
| 23 | REPLAY/long-text | 247-04 | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |
| 24 | HISTORY/empty | 247-04 | Absent instants have no copy control; missing metadata is unavailable; empty history has one explanation; empty analytics yields no invented currency group; replay missing eligibility cannot expose an eligible action. |
| 25 | HISTORY/loading | 247-04 | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| 26 | HISTORY/error | 247-04 | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| 27 | HISTORY/populated | 247-04 | Record identity, concise observed status, supported next action and exact secondary evidence read in that order; per-currency recovered/exhausted values retain query output. |
| 28 | HISTORY/partial | 247-04 | Missing time/fee/plan/snapshot/history is explicitly unavailable or absent, never inferred pending/misconfiguration; actual zero stays distinct; each present authorized value remains readable. |
| 29 | HISTORY/overflow | 247-04 | Long IDs, ISO values, JSON and currency groups wrap or scroll within their container with no horizontal page overflow at320px; copy retains full values. |
| 30 | HISTORY/zero-one-many | 247-04 | Zero/one/many history and currency rows retain readable hierarchy without synthesized records or combined currencies. |
| 31 | HISTORY/long-text | 247-04 | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |
| 32 | JSON/empty | 247-04 | Absent instants have no copy control; missing metadata is unavailable; empty history has one explanation; empty analytics yields no invented currency group; replay missing eligibility cannot expose an eligible action. |
| 33 | JSON/loading | 247-04 | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| 34 | JSON/error | 247-04 | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| 35 | JSON/populated | 247-04 | Record identity, concise observed status, supported next action and exact secondary evidence read in that order; per-currency recovered/exhausted values retain query output. |
| 36 | JSON/partial | 247-04 | Missing time/fee/plan/snapshot/history is explicitly unavailable or absent, never inferred pending/misconfiguration; actual zero stays distinct; each present authorized value remains readable. |
| 37 | JSON/overflow | 247-04 | Long IDs, ISO values, JSON and currency groups wrap or scroll within their container with no horizontal page overflow at320px; copy retains full values. |
| 38 | JSON/zero-one-many | 247-04 | Zero/one/many history and currency rows retain readable hierarchy without synthesized records or combined currencies. |
| 39 | JSON/long-text | 247-04 | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |
| 40 | METRICS/empty | 247-06 | Absent instants have no copy control; missing metadata is unavailable; empty history has one explanation; empty analytics yields no invented currency group; replay missing eligibility cannot expose an eligible action. |
| 41 | METRICS/loading | 247-06 | Keep explicit UTC before client formatting; clipboard success appears only after resolution; history and analytics pending state belongs only to the active read; replay review preserves existing in-flight handling. |
| 42 | METRICS/error | 247-06 | Clipboard absent/rejected writes expose a selectable exact UTC/manual copy fallback with no success; read errors identify unavailable evidence and only supported retry/return; malformed time never becomes an invented instant. |
| 43 | METRICS/populated | 247-06 | Record identity, concise observed status, supported next action and exact secondary evidence read in that order; per-currency recovered/exhausted values retain query output. |
| 44 | METRICS/partial | 247-06 | Missing time/fee/plan/snapshot/history is explicitly unavailable or absent, never inferred pending/misconfiguration; actual zero stays distinct; each present authorized value remains readable. |
| 45 | METRICS/overflow | 247-06 | Long IDs, ISO values, JSON and currency groups wrap or scroll within their container with no horizontal page overflow at320px; copy retains full values. |
| 46 | METRICS/zero-one-many | 247-06 | Zero/one/many history and currency rows retain readable hierarchy without synthesized records or combined currencies. |
| 47 | METRICS/long-text | 247-06 | Long labels/keys/IDs/manual fallback text reflow at320px without covering actions; 44px interactive targets remain reachable by keyboard and touch. |

## Spec-less edge probe

The deterministic report at /tmp/accrue247-edge-probe.json has seven applicable rows: five unclassified and two LANG-02 unresolved. None was auto-promoted to verified acceptance. TIME-01, STATE-02, DETAIL-01, DETAIL-02 and METRIC-01 remain flagged assumptions for targeted owning tests in 247-01/02/04/05/06. LANG-02 empty/null navigation is resolved explicitly by 247-05: missing parent/destination data yields no fabricated link; a single real parent produces one link. LANG-02 encoding is resolved explicitly by 247-05: labels are Unicode strings rendered/escaped by HEEx; identifier equality and exact copy use source bytes, with long grapheme text wrapping at 320px. If the executor cannot demonstrate either criterion, report it as unverified rather than silently pass.

## Prohibition recall

Adversarial recall considered false copy success, invented status, cash/churn overclaim, cross-owner summary leakage, broken replay auth, truncated exact evidence, broad new export and routine layout regressions. Precision keeps user-facing values boundaries in the descriptor-less plan prohibitions: do not present inferred billing outcomes as observed; do not state replay acceptance as completed delivery; do not describe recurring revenue as saved cash or confirmed churn. Generic authorization/security candidates refer to the ASVS threat register and scoped regression tests; they are not minted as extra prohibition descriptors. No fabricated wired checks or automatic dismissal.

## Timestamp source inventory for execution

The post-conversion source audit covered every owner named in RESEARCH: dashboard, charges, Connect account/list, coupon/list, customer, event/list, invoice/list, promotion code/list, subscription/list, webhook/list, campaign detail, at-risk table, and campaign timeline. Timestamp controls now cover visible DateTime values in dashboard, Connect, coupon, customer, event, invoice, promotion-code, and subscription detail/list; webhook detail/list; campaign detail/timeline; and the at-risk table. Charges has no visible timestamp field. Where a record appears in desktop and card layouts, each control has a surface-specific ID. Campaign boundary summaries and timeline rows also use separate IDs.

Plan 247-08's initial five owners are covered in `subscriptions_live.ex`, `webhooks_live.ex`, `analytics/campaign_live.ex`, `components/at_risk_table.ex`, and `components/campaign_timeline.ex`. The audit additionally found visible formatted instants in the webhook detail's Received/Processed summary, dispatch lifecycle, and Activity timeline. These now use source DateTime values with the shared control; the subscription detail's audit summary sentence no longer repeats a formatted timestamp already shown in its timestamp control. Its audit rows and shared timeline already retain exact timestamp controls. No ad hoc `Calendar.strftime`, `DateTime.to_string`, or date/time presentation formatter remains in the enumerated owners.

Serialization and non-instant cases remain explicit: `FilterChipBar.present_value/1` serializes date/time filter criteria as ISO query values; webhook event evidence keeps its `Recorded:` value as an exact ISO forensic string inside the expandable evidence block; subscription list date-only or non-DateTime fallback values remain plain text. Analytics window bounds and query parameters remain UTC and unchanged. These are serialization/filter/evidence paths, not localized timestamp presentation controls.

## Plan 247-07 current-revision proof

### Post-review acceptance coverage

The bounded review corrections have direct evidence: browser checks measure Local/UTC visibility and 44px geometry at 320px and verify persisted selection; disclosure checks observe visible chevron changes and keyboard toggling; detail heading checks enforce 20px/600; recovery copy and nav alignment have owner assertions; replay review asserts one cancel control, dismissal/focus return, and no submission. Timestamp source tests use an explicitly constructed +05:00 DateTime, assert normalized UTC ISO and retained microseconds without TZDB. Final Admin suite is 728/728; focused browser owners 44/44; Node time tests 7/7. Final two browser lanes and the 16-image proof validator pass. WR-01 is closed in `247-REVIEW-DISPOSITION.md`; UI findings are addressed additively in `247-UI-REVIEW-DISPOSITION.md`.

| Requirement / decision | Executed owner | Evidence | Result |
|---|---|---|---|
| TIME-01, LANG-02, STATE-02, DETAIL-01, DETAIL-02, METRIC-01; D-12 | `phase247-current-proof.spec.js`, `verify_phase247_render_proof.mjs` | 16 individually inspected full-page captures, source-bound manifest, ordinary + isolated held-out lanes, wide/narrow and light/dark | pass |
| Responsive recovery currency pairs | Recovery owner geometry assertions at 1280px and 320px | Actual DOM pair/group geometry plus overflow assertion in the mounted proof | pass |
| Replay confirmation behavior | Held-out replay review route | Confirmation state captured; no submission performed | pass |
| Threat T-247-07 | Focused tests, owner-scoped route setup, source/asset validator | Source SHA `60cbf06331c2`; served CSS and JS hashes verified; held-out owner selected through UI | mitigated |

The rendered review is in `captures/phase247-current-proof/VISUAL-REVIEW.md`. The held-out fixture has only two dead webhook deliveries and no separate eligible blocked-detail state; the detail Activity and raw-payload panels are empty for its selected record. This limit is recorded in both the manifest's scenario checks and visual review. Phase 248 retains integrated scenario selection and end-to-end proof.

## Deferred and excluded

Phase 248 owns scenario selection and integrated milestone proof. No billing/provider feature, Portal, new Admin room, migration, dependency or remote publication belongs here. Protected Phase 243 preview and earlier 245/246 captures are read-only history.
