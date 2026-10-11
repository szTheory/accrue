# Deferred Phase 246 UI Findings

The final Impeccable detector pass over the modified Admin UI also reported these existing patterns in `accrue_admin/assets/css/app.css`. Their declarations are outside this plan's diff; no broad typography or unrelated status-card redesign was included.

| Finding | Location | Reason deferred |
| --- | --- | --- |
| `side-tab`: thick left border using warning token | line 3819 | Existing warning-state treatment, outside changed selectors. |
| `side-tab`: thick left border using danger token | line 5032 | Existing danger-state treatment, outside changed selectors. |
| `side-tab`: thick left border using strong border token | line 5252 | Existing card decoration, outside changed selectors. |
| `overused-font`: Geist | line 7 | Existing project-wide typeface; a typography change requires separate design review. |
| `overused-font`: Geist Mono | line 14 | Existing project-wide mono typeface; a typography change requires separate design review. |
