# Phase 241 UI Audit Corrections

**Date:** 2026-10-10  
**Scope:** Subscription detail corrections from `241-UI-REVIEW.md`; no audit review rewrite and no phase advance.

## Closed findings

| Finding | Closure | Evidence |
|---|---|---|
| Subscription identity title rendered 22px/950 | Uses the incumbent 24px title role at weight 600; no type-scale migration. | Mounted host computed `fontSize: 24px`, `fontWeight: 600`; see `evidence/phase237-exemplar/manifest.json`. |
| Summary facts compressed at 2px | Main summary gap, fact row gap, and label/value gap render at the approved 4px rung. Long fact text retains `overflow-wrap:anywhere`. The later facts rule already supplied the 4px row gap and was kept as the effective rule. | Mounted host computed main/facts/fact gaps are 4px; desktop and 320px captures are in `evidence/phase237-exemplar/`. |
| Action heading compressed at 1px | Action header gap now uses the existing 4px rung. | Mounted host computed `actionHeader.gap: 4px`. |
| Duplicate amber Recovery CTA in no-campaign state | No-campaign renders one canonical scoped `ax-link`; warning status remains in the dunning state. Removed the obsolete warning-colored local button rules. | Mounted host asserts exactly one link, its `ax-link` class and scoped Recovery destination. Subscription LiveView test also asserts one rendered label. |

The approved unavailable-fact copy remains unchanged. The mounted no-campaign fixture confirms `price_basic` and says its current period is not shown; no unavailable value is converted to zero.

## Verification

- `MIX_ENV=test mix test test/accrue_admin/live/subscription_live_test.exs`: **39 passed, 0 failed**.
- `mix accrue_admin.assets.build`: **passed** using a temporary npm cache after the default cache returned `EPERM`; generated package CSS/JS are tracked outputs. No dependency manifest changed.
- Admin `MIX_ENV=test mix compile --warnings-as-errors`: **passed**.
- Admin `MIX_ENV=test mix test`: **646 passed, 0 failed**.
- Host `MIX_ENV=test mix compile --warnings-as-errors`: **passed**.
- Mounted-host Phase 237 owner, fresh `CI=1`, one worker: **1 passed**. It served the package CSS/JS bytes, checked the no-campaign unique link and computed subscription styles, and captured both 1280px and 320px subscription views in Phase 241 evidence.
- Focused Phase 241 package browser cases: Phase 191 review matrix **1 passed**; Phase 199 invoice destination and text/reflow cases **2 passed**. The text/reflow check now snapshots and applies its 2× font sizes in the same browser evaluation that measures them, preventing a LiveView root replacement from invalidating the baseline; finite measurements and the 2× assertion remain required.
- Exact rerun of the two Phase 191 cases that failed in the broader package run, across desktop and mobile: **12 passed**.

## Limits and other run results

- The broad Phase 191 package run completed with **26 passed, 2 failed**. The failures were a step-up outside-click dismissal assertion and a mobile responsive helper timeout. Both exact owners passed in the isolated 12-case rerun. No unrelated repair was made.
- The first broad Phase 199 `@phase241` run was **1 passed, 1 failed** because the Recovery list’s replaced `main` node lost the saved font baseline and produced `NaN`. After making measurement atomic, the same two focused cases passed **2/2**.
- The browser run used the mounted deterministic host and Chromium on macOS. The 320px screenshot is a viewport capture; it is not a physical-device, actual browser-zoom, assistive-technology speech, or live-provider claim.
- Interaction capture remained disabled by the existing project setting. Captures are current deterministic host evidence, not Phase 243 Linux goldens.

## Evidence files

- `evidence/phase237-exemplar/manifest.json`
- `evidence/phase237-exemplar/subscription-detail.png`
- `evidence/phase237-exemplar/subscription-detail-narrow.png`
- `evidence/phase237-exemplar/invoice-collection.png`
- `evidence/phase237-exemplar/invoice-review.png`
- `evidence/phase237-exemplar/recovery.png`
