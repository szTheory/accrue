# Phase 244 — UI Review

**Audited:** 2026-10-10  
**Baseline:** Approved [244-UI-SPEC.md](244-UI-SPEC.md), six design checks passed with one non-blocking inventory-provenance flag  
**Screenshots:** Not captured for Phase 244. Existing browser assertions and asset evidence were reviewed; cached Playwright PNGs in the workspace show unrelated invoice, subscription, and recovery screens and were excluded.  
**Interaction captures:** Not captured in this audit. Existing Phase 244 results document keyboard/touch disclosure behavior; unavailable-read and accepted-replay/failed-read browser states remain explicitly unobserved.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Producer-backed labels, scoped action names, and neutral unknown-key fallback; edge classification remains unresolved. |
| 2. Visuals | 3/4 | Existing page hierarchy is retained; no relevant screenshot was available for direct visual comparison. |
| 3. Color | 3/4 | Semantic light/dark tokens and keyboard focus are used; screenshots and full surface-ratio inspection are absent. |
| 4. Typography | 3/4 | Source follows the incumbent type roles; direct rendered size and wrapping could not be inspected for these routes. |
| 5. Spacing | 3/4 | Changed evidence styling uses the declared spacing tokens and the 320px assertion passed; no relevant screenshot was available. |
| 6. Experience Design | 2/4 | Webhook disclosure behavior is well evidenced, but Event detail lazy disclosures and critical read-failure states lack browser proof. |

**Overall: 17/24**

---

## Top 3 Priority Fixes

1. **Verify Event detail disclosure state through its LiveView patch** — operators may lose the section they just opened while its evidence loads — apply the existing `PreserveDisclosure` behavior to the Event detail Activity disclosure and cover keyboard/touch open and close in the isolated browser fixture.
2. **Verify the Raw payload disclosure through its load patch** — the same native disclosure contract applies, but this control also lacks the preservation hook and browser proof — preserve its open/closed intent and exercise it through a real patch.
3. **Keep read-failure and accepted-replay uncertainty browser coverage explicitly open** — source tests assert read-only recovery and accepted/unknown wording, but the rendered states remain unobserved — add isolated failure fixtures only when they can induce these states without changing preview data; until then retain the unobserved status.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **PASS evidence:** `BillingEvent` maps only producer-confirmed keys to distinct labels and uses neutral “Billing event” / “Event details unavailable” fallbacks for unknown or malformed values ([billing_event.ex:6](../../../accrue_admin/lib/accrue_admin/copy/billing_event.ex:6)).
- **PASS evidence:** Home uses the contract CTA “View events” and the exact scoped event destination; the timeline action is “Open event” ([dashboard_live.ex:65](../../../accrue_admin/lib/accrue_admin/live/dashboard_live.ex:65)). The phase inventory records the rendered destination and owner scope.
- **PASS evidence:** Event read failure says its identity and related evidence are unknown until the read succeeds, and labels the action “Retry read” ([event_live.ex:130](../../../accrue_admin/lib/accrue_admin/live/event_live.ex:130)). Replay copy distinguishes request acceptance from delivery completion ([webhook_live.ex:725](../../../accrue_admin/lib/accrue_admin/live/webhook_live.ex:725)).
- **WARNING:** One STATE-01 edge remains unclassified, as recorded in the phase inventory. No extra wording or outcome meaning should be inferred for that edge.

### Pillar 2: Visuals (3/4)

- **PASS evidence:** The targeted Home, Events, event detail, and webhook views reuse the existing Admin hierarchy and timeline/detail components; the changes add operator labels and evidence access without introducing a new layout ([dashboard_live.ex:54](../../../accrue_admin/lib/accrue_admin/live/dashboard_live.ex:54), [events_live.ex:72](../../../accrue_admin/lib/accrue_admin/live/events_live.ex:72), [event_live.ex:145](../../../accrue_admin/lib/accrue_admin/live/event_live.ex:145), [webhook_live.ex:210](../../../accrue_admin/lib/accrue_admin/live/webhook_live.ex:210)).
- **PASS evidence:** The phase browser record binds checkout `33242617…`, browser state, routes, and delivered CSS/JS digests. Its assertions verify scoped navigation and evidence placement.
- **WARNING:** No Phase 244 screenshot was available to inspect hierarchy, card density, or focal balance directly. The images in cached Playwright reports are unrelated routes and are not evidence for these screens.

### Pillar 3: Color (3/4)

- **PASS evidence:** The affected styles use semantic surfaces, borders, text, and accent variables, including `--ax-elevated`, `--ax-sunken`, `--ax-muted`, and `--ax-accent-readable` ([app.css:1125](../../../accrue_admin/assets/css/app.css:1125), [app.css:1873](../../../accrue_admin/assets/css/app.css:1873)).
- **PASS evidence:** The 33242617 browser run checked light and dark theme values and confirmed served CSS/JS bytes match package and compiled assets. The inventory records CSS SHA-256 `b40ac1dc…` and JS SHA-256 `e228bac9…`.
- **WARNING:** Those checks establish token selection and asset identity, not the rendered 60/30/10 surface distribution or contrast of every text/status combination. No relevant screenshots were available for that visual check.

### Pillar 4: Typography (3/4)

- **PASS evidence:** Theme tokens define the contract’s compact/body sizes and declared type roles ([theme.css:17](../../../accrue_admin/assets/css/theme.css:17), [theme.css:85](../../../accrue_admin/assets/css/theme.css:85)). Timeline labels and technical evidence use the incumbent label and monospace styling ([app.css:1833](../../../accrue_admin/assets/css/app.css:1833), [app.css:1841](../../../accrue_admin/assets/css/app.css:1841)).
- **PASS evidence:** Exact event timestamps render with ISO 8601 precision and offset ([event_live.ex:445](../../../accrue_admin/lib/accrue_admin/live/event_live.ex:445)); the phase browser assertion checked a sub-second timestamp.
- **WARNING:** Rendered wrapping and text-size hierarchy could not be inspected from a relevant image. The 320px browser assertion proves no horizontal document overflow for the tested webhook evidence, not typography quality across all target screens.

### Pillar 5: Spacing (3/4)

- **PASS evidence:** Timeline cards and evidence use declared spacing tokens (`--ax-space-sm`, `--ax-space-md`, and `--ax-space-lg`) rather than arbitrary pixel spacing ([app.css:1833](../../../accrue_admin/assets/css/app.css:1833), [app.css:1841](../../../accrue_admin/assets/css/app.css:1841), [app.css:1918](../../../accrue_admin/assets/css/app.css:1918)).
- **PASS evidence:** Phase 244’s 320px touch assertion checked document width against viewport width, evidence visibility, and selectable exact values; the inventory records the passing run.
- **WARNING:** The browser assertion is targeted to webhook evidence. Other selected surfaces and vertical rhythm were not visually inspected from phase-specific screenshots.

### Pillar 6: Experience Design (2/4)

- **PASS evidence:** Webhook Activity uses native `details`/`summary` and the `PreserveDisclosure` hook. The recorded browser checks include keyboard and touch activation, focus retention, open/close through a LiveView patch, evidence selection, and scoped event/source-webhook navigation ([webhook_live.ex:278](../../../accrue_admin/lib/accrue_admin/live/webhook_live.ex:278), [preserve_disclosure.js:1](../../../accrue_admin/assets/js/hooks/preserve_disclosure.js:1)).
- **PASS evidence:** Before replay confirmation, the browser proof verified the step-up boundary and unchanged webhook status, dispatch jobs, and replay/audit events. It did not dispatch a replay.
- **WARNING:** Event detail Activity and Raw payload are lazy native disclosures that trigger LiveView events but do not attach `PreserveDisclosure` ([event_live.ex:177](../../../accrue_admin/lib/accrue_admin/live/event_live.ex:177), [event_live.ex:195](../../../accrue_admin/lib/accrue_admin/live/event_live.ex:195)). Their open/closed state through loading patches was not covered by the phase browser proof. This is a contract verification gap; this audit does not claim a reproduced failure.
- **WARNING:** Event-unavailable/retry and accepted-replay-followed-by-failed-read states were not rendered in the browser. Focused LiveView tests cover the read-only retry and uncertain outcome behavior, but do not establish rendered browser behavior. The inventory correctly leaves both browser states unobserved.

---

## Files Audited

- `.planning/phases/244-operator-language-and-evidence/244-UI-SPEC.md`
- `.planning/phases/244-operator-language-and-evidence/244-CONTEXT.md`
- `.planning/phases/244-operator-language-and-evidence/244-INVENTORY.md`
- `.planning/phases/244-operator-language-and-evidence/244-01-PLAN.md` through `244-03-PLAN.md`
- `.planning/phases/244-operator-language-and-evidence/244-01-SUMMARY.md` through `244-03-SUMMARY.md`
- `accrue_admin/lib/accrue_admin/copy/billing_event.ex`
- `accrue_admin/lib/accrue_admin/components/timeline.ex`
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex`
- `accrue_admin/lib/accrue_admin/live/events_live.ex`
- `accrue_admin/lib/accrue_admin/live/event_live.ex`
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex`
- `accrue_admin/assets/css/theme.css`
- `accrue_admin/assets/css/app.css`
- `accrue_admin/assets/js/hooks/preserve_disclosure.js`
- `examples/accrue_host/e2e/phase244-operator-evidence.spec.js`
