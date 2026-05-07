# v1.36 Feature Research — Dual-Provider Core Completion

## Table Stakes

- Customer update must be either fully first-party or explicitly unsupported; staged leftovers are drift.
- Cancellation support must describe the shipped path honestly, especially where Braintree supports immediate cancel but not broader lifecycle parity.
- Public docs, support matrix, and runtime capability labels must say the same thing.
- Deterministic proof must guard every promoted contract row.

## Differentiators

- A capability-explicit support story is a differentiator versus false-parity gateway libraries.
- Fake-first merge-blocking proof keeps the dual-provider surface maintainable without requiring live-provider CI.

## Anti-Features

- Do not expand into scheduling, invoice preview, pause/resume parity, or new provider classes just because lifecycle code paths are nearby.
- Do not leave “staged” language on rows that are already being presented as shipped support.
