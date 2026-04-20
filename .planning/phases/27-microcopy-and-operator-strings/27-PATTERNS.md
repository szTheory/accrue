# Phase 27 — Pattern map

**Purpose:** Closest analogs in-repo for COPY migration work.

## Analog: centralized defaults

| Target | Analog | Excerpt / rule |
|--------|--------|----------------|
| `DataTable` empty defaults | `data_table.ex` L24–25 | Today hard-coded strings — replace with calls into `AccrueAdmin.Copy` per CONTEXT D-01 |

## Analog: module-attribute operator strings

| Target | Analog | Excerpt / rule |
|--------|--------|----------------|
| Webhook replay / denial | `webhook_live.ex` L16–20 | `@owner_access_denied`, `@replay_blocked`, … — lift **verbatim** to `Copy.Locked` |

## Analog: per-index overrides

| Target | Analog | Excerpt / rule |
|--------|--------|----------------|
| Money indexes | `customers_live.ex` L123–124 | `empty_title=` / `empty_copy=` on `<.live_component DataTable` — replace attribute values with `Copy.*` functions |

## Analog: custom flash list

| Target | Analog | Excerpt / rule |
|--------|--------|----------------|
| `push_flash` helper | `webhook_live.ex` `push_flash/3` | Local flash list pattern — keep mechanism; swap message sources to `Copy` |

## Tests

| Target | Analog | Excerpt / rule |
|--------|--------|----------------|
| LiveView copy | `26-01-PLAN.md` tasks | `mix test` + `assert html =~` / Floki for stable needles |
