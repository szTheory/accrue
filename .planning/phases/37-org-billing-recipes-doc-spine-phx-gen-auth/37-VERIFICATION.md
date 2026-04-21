---
phase: 37
status: passed
verified: "2026-04-21"
---

# Phase 37 verification

## Must-haves (plans)

| Plan | Evidence |
|------|-----------|
| 37-01 | `accrue/guides/organization_billing.md` + `organization_billing_guide_test.exs`; `MIX_ENV=test mix docs` succeeds. |
| 37-02 | Hub in `auth_adapters.md`; escape hatch in `sigra_integration.md`; `community_auth_test.exs` + `sigra_integration_guide_test.exs`. |
| 37-03 | Installer `print_auth_guidance/1` non-Sigra branch; README + quickstart + `finance-handoff.md`; extended org billing doc tests. |

## Roadmap success criteria

1. **Linked from auth_adapters and/or sigra_integration** — satisfied with tests locking anchors and ordering.
2. **ORG-05 / ORG-06** — narrative spine + phx.gen.auth checklist in `organization_billing.md`; trace to REQUIREMENTS remains in planning layer.
3. **No new Hex dependencies** — satisfied (docs/tests only).

## Automated checks run

```bash
cd accrue && mix compile --warnings-as-errors
cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs \
  test/accrue/docs/community_auth_test.exs \
  test/accrue/docs/sigra_integration_guide_test.exs
cd accrue && MIX_ENV=test mix docs
```

## human_verification

None required (documentation and contract tests only).

## Gaps

None.
