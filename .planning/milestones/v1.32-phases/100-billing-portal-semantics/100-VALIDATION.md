# Phase 100: Billing Portal Semantics - Validation

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/accrue/billing/billing_portal_session_facade_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROC-20 | Braintree capabilities correctly map `billing_portal: %{create: false}` | unit | `mix test test/accrue/processor/braintree_test.exs` | ✅ Wave 0 |
| PROC-20 | `create_billing_portal_session/2` returns targeted `APIError` if unsupported | unit | `mix test test/accrue/billing/billing_portal_session_facade_test.exs` | ✅ Wave 0 |

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements. We only need to add specific test cases within existing files.