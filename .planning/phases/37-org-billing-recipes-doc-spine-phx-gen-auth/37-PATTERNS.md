# Phase 37 — Pattern Map

Analogs for doc and installer edits.

## Guide contract tests

| New / touched guide | Analog | Excerpt pattern |
|---------------------|--------|-----------------|
| `guides/organization_billing.md` | `accrue/test/accrue/docs/community_auth_test.exs` | `File.read!/1` + `assert guide =~` stable substrings |
| Installer strings | `grep print_auth_guidance` in `accrue.install.ex` | `report/1` lines are user-visible |

## Doc style

| Pattern | Reference |
|---------|-----------|
| Hub + deep links | `guides/quickstart.md` → links to focused guides |
| Auth adapter SSOT | `guides/auth_adapters.md` `MyApp.Auth.PhxGenAuth` module block |
| Sigra optional framing | `guides/sigra_integration.md` opening paragraphs |

## Example host modules (citation-only in markdown)

- `examples/accrue_host/lib/accrue_host/accounts/organization.ex`
- `examples/accrue_host/lib/accrue_host/accounts/user.ex`
- `examples/accrue_host/lib/accrue_host/billing.ex`
