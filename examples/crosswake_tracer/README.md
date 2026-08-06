# Crosswake feasibility tracer

This directory is a local-path conformance and feasibility consumer of
`../../packages/accrue-offline-client`. It imports `AccrueOfflineClientCore` through
the standalone package; it is not the distributable package and contains no second
verifier or cache authority.

Run its dependency check with:

```sh
swift test --package-path examples/crosswake_tracer
swift package --package-path examples/crosswake_tracer describe
```

The package tests, this consumer, generic iPhoneOS SDK compilation, and simulator
observations are deterministic evidence only. They do not establish Crosswake bridge
or physical-device proof and cannot change the checked-in capability report.

## Capability evidence

`capability-report.json` remains `feasibility_blocked` until every listed capability
has its required evidence. The separately authorized physical-device artifact is
[physical-device-evidence.md](physical-device-evidence.md). Package verification
never writes either evidence file.

The host owns authenticated transport, StoreKit, lifecycle, content policy, and UI.
Only verified newer server allow proofs or signed denials can replace offline cache
state; stale continuity is limited to downloaded study and local progress and never
creates new value.
