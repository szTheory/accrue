---
phase: 218-apple-observation-and-repair
plan: "03"
adapter: accrue_owned_jason_otp_public_key
decision: reject
---

# Apple verifier adapter admission

`app_store_server_library` was rejected by the blocking Plan 218-02 decision. It was not installed, evaluated, vendored, copied, or otherwise introduced here. The selected implementation is the private `Accrue.Entitlements.Apple.Verifier.Production` fallback using the existing direct `Jason` dependency and OTP `:public_key` only.

| D-05 gate | Command / evidence | Result |
|---|---|---|
| Package legitimacy | `218-02-SUMMARY.md` records `rejected` | fail — fallback selected |
| API shape and replacement insulation | `mix test test/accrue/entitlements/apple_verifier_test.exs` | pass — private behaviour only |
| Independent outer/nested verification | focused hostile corpus | pass |
| Ordered x5c/root/time/purpose | `AppleVerifierTest` runs the checked-in `production_transaction/1` ES256 leaf-first chain through `Production.verify_transaction/2`; malformed/root/header cases remain separately closed | pass |
| Critical-header / algorithm rejection | focused hostile corpus | pass |
| No supervision or provider side effects | implementation review; pure functions only | pass |
| Recursive privacy | inspect/error corpus; no raw JWS output | pass |
| License/dependency tree | `mix deps.audit`; no dependency changes | pass |
| Dependency lock unchanged | `shasum mix.exs mix.lock` before/after | pass |

## Deterministic decision

**Reject candidate; select `accrue_owned_jason_otp_public_key`.** The rejection is deterministic because the prerequisite human legitimacy decision is recorded as `rejected`; no failed or unproven candidate gate may admit it. The fallback retains all D-05/D-06 checks and relies on host-owned root/configuration inputs.
