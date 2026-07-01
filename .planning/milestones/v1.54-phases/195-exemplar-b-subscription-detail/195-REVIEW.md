---
phase: 195-exemplar-b-subscription-detail
reviewed: 2026-06-26T12:34:47Z
depth: standard
files_reviewed: 32
files_reviewed_list:
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/js/app.js
  - accrue_admin/assets/js/hooks/overlay.js
  - accrue_admin/assets/js/hooks/scroll_lock.js
  - accrue_admin/e2e/admin-spec-detail-phase195.spec.js
  - accrue_admin/e2e/spike-overlay-portal.spec.js
  - accrue_admin/lib/accrue_admin/components/detail.ex
  - accrue_admin/lib/accrue_admin/components/detail_drawer.ex
  - accrue_admin/lib/accrue_admin/components/dropdown_menu.ex
  - accrue_admin/lib/accrue_admin/components/overlay.ex
  - accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/subscription.ex
  - accrue_admin/lib/accrue_admin/layouts.ex
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex
  - accrue_admin/package.json
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/accrue_admin.js
  - accrue_admin/storybook/_support/registry_story.ex
  - accrue_admin/test/accrue_admin/components/overlay_components_test.exs
  - accrue_admin/test/accrue_admin/live/charge_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/step_up_test.exs
  - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
  - accrue_admin/test/js/dropdown_test.mjs
  - accrue_admin/test/js/scroll_lock_test.mjs
  - examples/accrue_host/e2e/generated/copy_strings.json
  - storybook/components/action_menu.story.exs
  - storybook/components/detail.story.exs
  - storybook/components/overlay.story.exs
  - storybook/components/subscription_detail.story.exs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
result: pass
approval: approved
---

# Phase 195: Code Review Report

**Reviewed:** 2026-06-26T12:34:47Z
**Depth:** standard
**Files Reviewed:** 32
**Status:** approved

## Narrative Findings (AI reviewer)

No Critical, Warning, or Info findings remain in the reviewed Phase 195 scope.

## Summary

Re-reviewed Phase 195 after commits `9de92260`, `5c063330`, and `c4e196b0`. The prior malformed action event blockers are resolved:

- Missing, non-binary, and unsupported `action_type` payloads now fail closed through guarded `handle_event/3` clauses.
- Supported action payloads now validate optional string params, `pause_behavior`, and `proration` before staging.
- Proration conversion now uses the explicit `@proration_atoms` allowlist instead of `String.to_existing_atom/1`.
- Regression coverage exercises crafted supported action params with valid `action_type` and malformed auxiliary values.

The prior copy export warning is also resolved: the public `AccrueAdmin.Copy` delegates exist, the export allowlist includes the drawer/provider/preview/item copy used by this phase, the generated fixture JSON contains those keys, and fixture tests compare the generated strings against `Copy`.

The Phase 193 overlay spike regression gate is aligned with Phase 195's permanent layout-level portal root: Proof 2 now expects exactly one empty `#ax-overlay-root` to persist after navigation while asserting injected `#ax-spike-*` children and `data-spike-fixture` state do not orphan.

## Verification Reviewed

Post-fix verification reported after commit `5c063330`:

```text
mix test test/accrue_admin/live/subscription_live_test.exs
17 tests, 0 failures

mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/live/step_up_test.exs
37 tests, 0 failures

node --test test/js/dropdown_test.mjs test/js/scroll_lock_test.mjs
8 tests passed

mix compile --warnings-as-errors
passed

bash scripts/ci/verify_package_docs.sh
passed

npm run e2e:phase195
8/8 passed
```

Additional verification reported after commit `c4e196b0`:

```text
env -u NO_COLOR npx playwright test e2e/spike-overlay-portal.spec.js --timeout=60000 --workers=1
8 passed
```

---

_Reviewed: 2026-06-26T12:34:47Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
