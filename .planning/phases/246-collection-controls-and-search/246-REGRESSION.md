# Phase 246 Regression Gate

At source `d1c467cd`, the three prior Phase245 host files (ordinary story, seed and idempotency) passed: 13 tests, zero failures. Existing ExMoney startup, generated-operation-ID and seed-module reload warnings remain.

Phase245 route inventory passed; baseline verifier self-test passed its positive and four negative custody cases. Its historical capture manifest correctly rejects current source as stale: Phase246 intentionally changed those sources. Historical images and digests were preserved, not rewritten or represented as fresh evidence. Current rendered proof remains in Phase246 captures and the planned Phase248 integrated pass.

Final Admin suite at the same source: `mix test --warnings-as-errors --seed 0` passed 718 tests, zero failures.
