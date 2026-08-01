# Crosswake feasibility tracer

This Swift package records the host-owned client boundary that a pinned Crosswake shell/core must prove before Accrue accepts mobile runtime coupling. It does not add Crosswake to Accrue and does not infer an undocumented bridge API.

## Run the checked-in checks

```sh
swift test --package-path examples/crosswake_tracer
jq -e '([.capabilities[].status] | all(. == "proven")) or .overall_status == "feasibility_blocked"' examples/crosswake_tracer/capability-report.json
cd accrue && mix test
```

The Swift command tests the client/device reducer. The ExUnit command is the repository-wide server contract check; its result is merge-blocking independently and is not read by this report.

## Evidence lanes

Each capability needs its listed evidence kinds before its row may be `proven`:

- Native compile/unit: host-boundary, durable-state, and high-water checks.
- Crosswake bridge compile/unit: authenticated transport, StoreKit purchase with `appAccountToken`, transaction updates, current entitlements, restore, network coalescing, and reconnect.
- Simulator advisory: StoreKit or Keychain observations useful during development but never sufficient for runtime feasibility.
- Dated physical device: Secure Enclave non-exportability and nonce proof, `ThisDeviceOnly` migration exclusion, lifecycle recovery, termination during atomic replacement, authenticated shell transport, and reconnect.

Record redacted physical-device results in [physical-device-evidence.md](physical-device-evidence.md). A device observation is submitted to the server as evidence; it never grants a local entitlement.

## Result rule

The report is `proven` only when every required capability occurs exactly once, has all required evidence kinds, and is `proven`. A missing pinned Crosswake source, documented bridge, or dated device proof produces `feasibility_blocked`. Scene and network changes may only coalesce an authenticated reconciliation; a verified newer server allow or signed denial is the only replacement authority.

`capability-report.json` is restricted to client/device feasibility. It contains no server/vector/JWS contract-test status and does not convert an independent test failure into a feasibility reason.
