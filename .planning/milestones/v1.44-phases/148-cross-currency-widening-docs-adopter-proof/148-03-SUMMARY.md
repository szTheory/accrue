# Plan 03 Summary

**Objective**: Draft the new `guides/analytics.md` and expand the `@moduledoc` on `Accrue.Analytics.Dunning` to freeze the public API surface.

**Execution Details**:
- Created `accrue/guides/analytics.md` detailing:
  - The public API surface with open-shape map contracts (`recovered_vs_lost_mrr`, `funnel`, `recovery_rate`).
  - Window semantics acting on outcome-timestamp attribution in UTC.
  - The per-currency contract (no FX conversion).
  - Cutoff-date semantics and legacy dunning tracking behavior.
  - A performance guide suggesting a JSONB expression index for `mrr_value_cents` when crossing 100k events.
  - Admin-Auth limitations with escape hatches for host applications.
- Expanded the `@moduledoc` on `Accrue.Analytics.Dunning` to introduce the module and link to the new `guides/analytics.md`. Added `@since "1.4.0"` to the new functions.
- Updated `scripts/ci/verify_package_docs.sh` to enforce the presence of `100k events` and `Cutoff-Date Semantics` in `guides/analytics.md`.
- Verified HexDocs compilation via `mix docs` and ran the CI script successfully.

**Verification**:
- `bash scripts/ci/verify_package_docs.sh` completed successfully.
- `mix docs` compiles without failure.

**Next Steps**: Proceed to Plan 04 to wire up deterministic-clock dunning events and prove out the dashboard in the Adopter Proof Matrix.