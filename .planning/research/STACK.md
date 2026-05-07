# v1.36 Stack Research — Dual-Provider Core Completion

## Scope

This milestone is brownfield contract closure work, not a new infrastructure bet. The required stack is already in the repo:

- `accrue/lib/accrue/processor/capabilities.ex` for public support labels
- `accrue/lib/accrue/processor/{fake,stripe,braintree}.ex` for adapter truth
- `accrue/lib/accrue/billing.ex` and `accrue/lib/accrue/billing/subscription_actions.ex` for facade semantics
- `accrue/test/**` and `examples/accrue_host/test/**` for deterministic proof
- `.planning/processor-support-matrix.md` plus package/example-host docs for contract mirrors

## Integration Additions

No new libraries or dependencies are recommended.

## What To Change

- Promote staged support labels only where runtime support already exists and is intended to be first-party.
- Keep capability labeling as the SSOT for public support language.
- Extend existing ExUnit and example-host proof lanes instead of introducing new tooling.

## What Not To Add

- No new processor adapters.
- No new docs verification framework beyond the existing shell/ExUnit drift gates.
- No abstraction layer meant to generalize out-of-slice lifecycle features.
