---
phase: 38
status: passed
verified: "2026-04-21"
---

# Phase 38 verification

## Must-haves (plans)

| Plan | Evidence |
|------|-----------|
| 38-01 | `## Pow-oriented checklist (ORG-07)` in `accrue/guides/organization_billing.md`; Pow cross-link in `accrue/guides/auth_adapters.md`; needles in `organization_billing_guide_test.exs`. |
| 38-02 | `## Custom organization model (ORG-08)` with Anti-pattern table and subsections (LiveView/`on_mount`, context functions, webhook replay, `actor_id`); extended needles in the same test module. |

## Roadmap success criteria

1. **Pow recipe** — ORG-07 checklist covers `Pow.Plug.current_user/1`, membership-gated `fetch_current_organization`, `MyApp.Auth.Pow` config pointer, community-maintenance posture; no `:pow` dependency added.
2. **Custom org model** — ORG-08 maps obligations to **public**, **admin**, **webhook replay**, and **export**; links ORG-03 canonical requirements URL used elsewhere in the guide.
3. **Traceability** — REQUIREMENTS.md ORG-07 / ORG-08 marked complete with this phase.

## Automated checks run

```bash
cd accrue && mix compile --warnings-as-errors
cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs
cd accrue && MIX_ENV=test mix docs
```

## human_verification

None required (documentation and contract tests only).

## Gaps

None.
