# INV-01 — Route matrix

> **Stub.** Populate during `/gsd-plan-phase 25` or execution. Structure and rules are locked in `25-CONTEXT.md` (D-02).

**Snapshot:** _pending_ @ _sha_  
**Production method:** e.g. `cd examples/accrue_host && mix phx.routes` with documented `allow_live_reload` value.  
**Scope statement:** _(LiveView `live_session` routes only vs include static `get` routes — pick one per D-02 discretion.)_

## Shipping `live_session` routes

| Admin-relative path | LiveView module | Notes |
|---------------------|-----------------|-------|
| _TBD_ | _TBD_ | |

## Dev-only routes (`allow_live_reload: true`)

| Path | LiveView / purpose | Notes |
|------|---------------------|-------|
| _TBD_ | _TBD_ | Absent when host sets `allow_live_reload: false` |

## Host mount reference

| Property | Value |
|----------|-------|
| Example host mount | _TBD_ (e.g. `/billing`) |
| `allow_live_reload` in reference config | _TBD_ |
