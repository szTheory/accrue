---
slug: adopter-proof-gaps
title: "Adopter-proof gaps — headline JTBDs built in core but not proven in the example host"
status: open
created: 2026-05-24
updated: 2026-05-24
---

# Thread: Adopter-proof gaps (built-in-core ≠ proven-in-host)

## Goal

Close the gap between "shipped in core, tested at unit level" and "demonstrated
end-to-end in the canonical `examples/accrue_host`" for the headline jobs-to-be-done.
Surfaced by the 2026-05-24 post-v1.39 assessment. These are **adopter-confidence**
gaps, not correctness defects — but the example host is the canonical "see it work"
proof surface (VERIFY-01 / adoption-proof-matrix posture), so a v1.39 headline JTBD
that the host never exercises is a real evaluation weakness.

## Context

*Created 2026-05-24. Verified by grepping `examples/accrue_host`.*

- **Entitlements (the v1.39 headline JTBD) has ZERO usage in the example host** —
  `entitled?` / `Accrue.Plug.RequireEntitlement` / `Accrue.Live.Entitlements` are
  fully built + unit-tested in core, but `grep entitlement examples/accrue_host` = 0
  hits. The host never gates a route, page, or feature. The flagship "gate access on
  what they paid for" loop step is not provable in the demo.
- **Metered/usage billing not exercised by host** — `report_usage` is never called in
  `examples/accrue_host/lib` (built + guided in `guides/metering.md`, not demonstrated).
- **Checkout-session not exercised directly by host** — `create_checkout_session` is
  owned by `accrue_portal`; the host never calls it on the facade.
- **Recovery crons ship dormant** — `Accrue.Jobs.DunningSweeper` and
  `Accrue.Jobs.DetectExpiringCards` are host-wired-optional and the example host wires
  neither (no Oban cron in host router/application). So "recovery" features are invisible
  unless an adopter reads the guide and adds the crontab. (The dunning milestone should
  wire the default campaign into the host — see [[dunning-depth-milestone-prep]].)
- **Admin "entitlements tab" is a read-only panel inside `customer_live.ex`, not a
  standalone tab** (copy delegations `accrue_admin/copy.ex:503`). Doc/milestone wording
  implying a dedicated tab overstates it (display-only, no mutation). Confidence: MEDIUM
  (confirmed module refs; did not render the template).

## References

- `examples/accrue_host/lib/accrue_host/billing.ex` (what the host actually exercises)
- `accrue/lib/accrue/entitlements.ex`, `accrue/lib/accrue/plug/require_entitlement.ex`, `accrue/lib/accrue/live/entitlements.ex`
- `examples/accrue_host/docs/adoption-proof-matrix.md` (the proof-posture contract)
- `accrue_admin/lib/accrue_admin/copy.ex:503` (entitlements panel copy)

## Next Steps

- Decide the home for these: a small dedicated "adopter-proof refresh" phase, or fold
  the entitlements-in-host demo + dunning-in-host wiring into the dunning milestone's
  example-host work.
- Most leverage: add an entitlement-gated route/page to `examples/accrue_host` so the
  v1.39 headline JTBD is provable end-to-end, and add a matrix row.
- Governed by stop rules S1/S5 — but the entitlements proof gap is arguably a P1
  (the milestone shipped a headline capability the canonical demo doesn't show), not
  speculative polish. Worth a maintainer call on whether it needs a sourced request.
