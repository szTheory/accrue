# Architecture Research

**Domain:** Adding adoption surfaces + admin operator flows to existing Accrue monorepo  
**Researched:** 2026-04-21  
**Confidence:** HIGH

## Existing Architecture (do not regress)

- **Packages:** `accrue/` (core, LiveView-free), `accrue_admin/` (LiveView dashboard), `examples/accrue_host` (proof host).  
- **Proof pipeline:** Fake-backed ExUnit + Playwright VERIFY-01; optional advisory `live-stripe` / `mix test.live`.  
- **Admin UI:** `AccrueAdmin.Router`, `ax-*` layout/components, `AccrueAdmin.Copy`, theme tokens in CSS.  
- **Auth / tenancy:** Host-owned billables; Sigra-first patterns in host example for org scope—admin queries must stay row-scoped.

## Integration Points for v1.7

| Area | Integration | New vs modified |
|------|-------------|-----------------|
| Admin **home** | Likely root LiveView or dashboard module under `accrue_admin` | Modified / extended routes |
| **Navigation** | Router + layout sidebar | Modified labels/order only where required by OPS reqs |
| **Docs** | `guides/`, package READMEs, `examples/accrue_host/docs/` | Modified cross-links; may add short “start here” sections |
| **CI** | `.github/workflows/ci.yml`, verify shell scripts | Modified comments + doc references; avoid changing job IDs if `act` / docs depend on them |

## Suggested Build Order (maps to phases)

1. **Doc graph + discoverability** — lowers confusion before code churn.  
2. **Installer + README / CI contracts** — keeps proof reproducible while docs move.  
3. **Operator home + drill + nav** — user-visible admin improvements last so links in docs stay valid through earlier phases.  
4. **Summary surfaces + Copy tests** — finalize literals and a11y-sensitive labels once routes stable.

## Sources

- `.planning/PROJECT.md` — monorepo + security constraints  
- Phase 20/21 UI-SPEC paths under `.planning/phases/` (archived with v1.6 work)  

---
*Architecture research for: Accrue v1.7*
