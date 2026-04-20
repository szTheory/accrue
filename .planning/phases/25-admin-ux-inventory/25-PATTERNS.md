# Phase 25 — Pattern map (analogs)

**Purpose:** Closest existing artifacts and code for INV executors.

| New / updated artifact | Role | Closest analog | Notes |
|------------------------|------|----------------|-------|
| `25-INV-01-route-matrix.md` | Route inventory | `accrue_admin/lib/accrue_admin/router.ex` | Macro-expanded routes; dev block is `if dev_routes?` |
| `25-INV-01-route-matrix.md` | Host mount example | `examples/accrue_host/lib/accrue_host_web/router.ex:90` | `accrue_admin "/billing", ... allow_live_reload: false` |
| `25-INV-02-component-coverage.md` | Kitchen subset | `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | Aliases list = kitchen coverage set |
| `25-INV-02-component-coverage.md` | Production usage | `accrue_admin/lib/accrue_admin/live/**/*.ex` | `rg AccrueAdmin.Components.` |
| `25-INV-03-spec-alignment.md` | Spec obligations | `20-UI-SPEC.md`, `21-UI-SPEC.md` | Heading-based pointers |
| `README.md` | Index | This folder’s existing `README.md` | Update status line when INV stubs filled |

## Code excerpts (reference)

**Dev-only routes (source — not in `mix phx.routes` when `allow_live_reload: false`):**

```75:81:accrue_admin/lib/accrue_admin/router.ex
          if dev_routes? do
            live("/dev/clock", AccrueAdmin.Dev.ClockLive, :index)
            live("/dev/email-preview", AccrueAdmin.Dev.EmailPreviewLive, :index)
            live("/dev/webhook-fixtures", AccrueAdmin.Dev.WebhookFixtureLive, :index)
            live("/dev/components", AccrueAdmin.Dev.ComponentKitchenLive, :index)
            live("/dev/fake-inspect", AccrueAdmin.Dev.FakeInspectLive, :index)
          end
```

---

## PATTERN MAPPING COMPLETE
