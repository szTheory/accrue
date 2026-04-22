# Phase 45 — Pattern map (doc alignment)

**Inputs:** `45-CONTEXT.md`, `45-RESEARCH.md`

## Analog guides (tone + structure)

| Target | Closest existing pattern | Excerpt / rule |
|--------|---------------------------|----------------|
| Thin new topic guide | `accrue/guides/testing.md` “Usage metering (Fake)” | Short section, points to ExDoc for options, links `telemetry.md` for failures |
| Ops + metrics contract | `accrue/guides/telemetry.md` | Single catalog table; “first actions” / span sections below |
| Procedural triage | `accrue/guides/operator-runbooks.md` mini-playbooks | Numbered steps; links back to telemetry for tuple definitions |

## Files to create / modify

| Path | Role |
|------|------|
| `accrue/guides/metering.md` | **New** — MTR-07 spine (public / internal / processor) |
| `accrue/guides/telemetry.md` | **Edit** — semantics block under ops table (MTR-08) |
| `accrue/guides/operator-runbooks.md` | **Edit** — extend `meter_reporting_failed` playbook (MTR-08) |
| `accrue/lib/accrue/billing.ex` | **Optional** — `@report_usage_doc` “See also” to metering guide |
| `accrue/guides/testing.md` | **Optional stretch** — link to `metering.md` when present |
| `accrue/README.md` | **Optional stretch** — one line to testing/metering per D-12 |

## ExDoc / mix

- `accrue/mix.exs` `extras: ["README.md" | Path.wildcard("guides/*.md")]` — new `guides/metering.md` is picked up automatically; **no mix.exs change** unless a non-wildcard layout is introduced later.

## Code references (accuracy only; no logic edits in Phase 45)

- `accrue/lib/accrue/billing/meter_events.ex` — `failure_source` types, guarded telemetry
- `accrue/lib/accrue/billing/meter_event_actions.ex` — sync narrative
- `accrue/lib/accrue/jobs/meter_events_reconciler.ex` — reconciler intro line
- `accrue/lib/accrue/webhook/default_handler.ex` — webhook meter error path (concept)

---

## PATTERN MAPPING COMPLETE
