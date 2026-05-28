# Phase 148: Cross-currency widening + recovery-rate API + public docs + adopter-proof - Context

**Gathered:** 2026-05-28
**Status:** Ready for discussion

<domain>
## Phase Boundary

This phase freezes the public analytics surface for the v1.4.0 publish. The primary technical change is a BREAKING widening of the `recovered_vs_lost_mrr/1` return shape from single-currency `%{recovered_cents, lost_cents}` to a multi-currency map, accompanied by UI updates to map these over `KpiCard`s in `RecoveryLive`.

Additionally, this phase adds the `recovery_rate/1` API and completes the required public documentation (in `guides/analytics.md` and `@moduledoc`) and ensures our `examples/accrue_host` has deterministic-clock seeds and matrices proving out the UI.

**Scope anchor — what ships:**
- `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` widened to return `%{recovered: [%{currency: "usd", cents: N}, ...], lost: [...]}` (DAN-07).
- `Accrue.Analytics.Dunning.recovery_rate/1` returns `%{rate: 0.0..1.0 | nil, recovered: N, total_concluded: N}` (DAN-06).
- `AccrueAdmin.Live.Analytics.RecoveryLive` loops over currencies to render `KpiCard` elements dynamically for recovered and exhausted MRR.
- `guides/analytics.md` containing performance guides (the 100k events rule), `@spec` guarantees, open-shape map warnings, and cutoff-date explanation ("Showing data since YYYY-MM-DD") (DAN-14).
- `Accrue.Analytics.Dunning` `@moduledoc` expanded, with all public APIs carrying `@since "1.4.0"` (DAN-15).
- `examples/accrue_host` gets deterministic-clock seed wiring and adopter-proof matrix row linkage (DAN-16).
</domain>

<decisions>
## Implementation Decisions

(To be finalized in discussion phase)

- **Cross-currency widening API shape**: Return shape is defined as `%{recovered: [%{currency: "usd", cents: N}, ...], lost: [...]}`. Grouping must occur per currency in Postgres, returning lists of maps.
- **KPI Card Layout in Admin UI**: When rendering multi-currency MRR cards, `RecoveryLive` will need to render a pair of (Recovered, Exhausted) cards per currency. For the vast majority (single-currency), it should seamlessly show exactly one pair. 
- **`recovery_rate/1` query shape**: Will likely consume counts of recovered and exhausted events (or delegate to `funnel/1`) and return the arithmetic rate `recovered / (recovered + exhausted)`.
- **Docs cutoff date UI badge**: Will it just be docs explaining the edge case, or a badge rendered somewhere in `RecoveryLive`? (Phase 144 D-06 states: "P144 only documents in the funnel `@doc`; UI badge ships with the guide" in Phase 148).
</decisions>

<canonical_refs>
## Canonical References

### Phase scope + requirements
- `.planning/REQUIREMENTS.md` §"Public API & Core Math (DAN)" DAN-06, DAN-07, DAN-14, DAN-15, DAN-16.
- `.planning/ROADMAP.md` §"Phase 148" — goal + 5 success criteria.

### Live code touchpoints
- `accrue/lib/accrue/analytics/dunning.ex` — modify `recovered_vs_lost_mrr/1`, add `recovery_rate/1`, expand `@moduledoc`.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — modify KPI card rendering to handle a list of currencies.
- `guides/analytics.md` — new documentation file.
- `scripts/verify_package_docs.sh` — verify analytics guide needle.
- `examples/accrue_host/priv/repo/seeds.exs` — add deterministic-clock seed wiring.
</canonical_refs>
