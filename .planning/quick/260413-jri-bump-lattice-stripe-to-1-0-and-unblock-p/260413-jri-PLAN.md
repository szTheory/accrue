---
phase: quick
plan: 260413-jri
type: execute
wave: 1
depends_on: []
files_modified:
  - accrue/mix.exs
  - accrue/mix.lock
  - CLAUDE.md
  - .planning/ROADMAP.md
  - .planning/STATE.md
autonomous: true
requirements: []
---

<objective>
Bump `lattice_stripe` from `~> 0.2` to `~> 1.0` in `accrue/mix.exs`, verify the accrue test suite still compiles and passes cleanly, and retire all "lattice_stripe 0.3 Billing blocker" language from planning artifacts (CLAUDE.md, ROADMAP.md, STATE.md) so Phase 3 is unblocked.

Purpose: lattice_stripe 1.0.0 shipped 2026-04-13 with full Billing (Subscription/SubscriptionItem/SubscriptionSchedule/Invoice/InvoiceItem/Price/Product/Coupon/PromotionCode) + Payments + Connect coverage. The "external Phase 0" sequencing cliff that gated Phase 3 no longer exists and must be removed from all planning artifacts to prevent stale signaling.

Output: lattice_stripe pinned to `~> 1.0`, baseline test suite green (197 tests + 20 properties, 0 failures), Phase 3 status flipped from "Blocked" to "Not started", residual BillingMeter + BillingPortal.Session gaps documented under Phase 4.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
@CLAUDE.md
@.planning/STATE.md
@.planning/ROADMAP.md
@accrue/mix.exs
</context>

<tasks>

<task type="auto">
  <name>Task 1: Bump lattice_stripe to ~> 1.0 and verify baseline tests</name>
  <files>accrue/mix.exs, accrue/mix.lock</files>
  <action>
Edit `accrue/mix.exs` line 48: change `{:lattice_stripe, "~> 0.2"},` to `{:lattice_stripe, "~> 1.0"},`. Leave all other deps untouched.

Then run dep resolution and the baseline verification commands from the accrue directory:
1. `cd accrue && mix deps.get` — resolves to lattice_stripe 1.0.0 (or highest published 1.x), writes updated `mix.lock`.
2. `cd accrue && mix compile --warnings-as-errors` — MUST exit 0. lattice_stripe 1.0 preserves the 0.2 API surface Accrue uses (LatticeStripe.Customer CRUD, construct_event!/4, %LatticeStripe.Event{}, generate_test_signature/3) per upstream research, so no code changes should be required.
3. `cd accrue && mix test` — MUST show `197 tests, 20 properties, 0 failures` (baseline from Phase 2 completion).

If compile or tests fail, audit these call sites for 1.0 API shifts before attempting any code edits:
- `accrue/lib/accrue/processor/stripe.ex` (LatticeStripe.Customer create/update/retrieve/delete)
- `accrue/lib/accrue/processor/stripe/error_mapper.ex` (error struct shapes)
- `accrue/lib/accrue/webhook/signature.ex` (LatticeStripe.Webhook.construct_event!/4)
- `accrue/lib/accrue/webhook/event.ex` (%LatticeStripe.Event{} struct fields)
- `accrue/lib/accrue/webhook/ingest.ex`
- `accrue/test/support/webhook_fixtures.ex` (LatticeStripe.Webhook.generate_test_signature/3)

Research confirmed all of these exist in 1.0 with identical signatures — this audit list is a safety net only.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix deps.get && mix compile --warnings-as-errors && mix test</automated>
  </verify>
  <done>
accrue/mix.exs shows `{:lattice_stripe, "~> 1.0"},`; `mix compile --warnings-as-errors` exits 0; `mix test` reports `197 tests, 20 properties, 0 failures`; `accrue/mix.lock` shows a lattice_stripe 1.x entry.
  </done>
</task>

<task type="auto">
  <name>Task 2: Retire Phase 3 blocker language across planning artifacts</name>
  <files>CLAUDE.md, .planning/ROADMAP.md, .planning/STATE.md</files>
  <action>
Make three surgical edits across three files. Use the Edit tool (not Write) since these are targeted updates to existing documents.

**Edit 1 — CLAUDE.md (`:lattice_stripe` row in the Core Technologies — accrue package table):**

Current row reads:
```
| `:lattice_stripe` | `~> 0.2` | Stripe API wrapper | Sibling lib, currently **0.2.0**. Use `~> 0.2` so Accrue tracks lattice_stripe minor bumps without breaking on 0.3 (which will bring Billing/Subscription resources — that will be a coordinated Accrue version bump). CRITICAL: lattice_stripe does NOT yet cover Subscription/Price/Product/Invoice/Meter — those must land in lattice_stripe before Accrue's billing phases can ship. Flag in roadmap as a cross-repo dependency. |
```

Replace with:
```
| `:lattice_stripe` | `~> 1.0` | Stripe API wrapper | Sibling lib, v1.0.0 stable (shipped 2026-04-13) with full Billing (Subscription/SubscriptionItem/SubscriptionSchedule/Invoice/InvoiceItem/Price/Product/Coupon/PromotionCode) + Payments + Connect coverage. Use `~> 1.0` to track 1.x patch/minor releases. BillingMeter/MeterEvent and BillingPortal.Session are pending in lattice_stripe 1.1 and block Accrue Phase 4 requirements BILL-11 and CHKT-02 only. |
```

Also scan the `## Flags for Roadmap Consumer` section at the bottom of CLAUDE.md: if it mentions a "lattice_stripe 0.3 Billing blocker" flag, remove that line. If the section doesn't mention it (it may be empty or already clean), leave it alone.

**Edit 2 — .planning/ROADMAP.md:**

(a) Delete the entire `## External Dependency: Phase 0 — lattice_stripe 0.3 Billing` section (currently lines 7–13: the header plus the Status/Scope/Blocks/Does NOT block/Fallback block). The next heading `## Phases` should follow directly after `## Overview`.

(b) In the `## Overview` paragraph (line 5), remove the trailing sentence fragments about the external cliff. Specifically, rewrite the paragraph's ending so it no longer says "The single sequencing cliff is external: lattice_stripe 0.3 must add Subscription/Invoice/Price/Product/Meter coverage before Phase 3 can begin. Phases 1 and 2 proceed immediately in parallel with that upstream work, against the Fake processor." Replace that ending with: "The Fake Processor is **primary test surface** from day one — not a test afterthought — and the Money value type lands in Phase 1 so no schema is ever built with a bare-integer amount."

(c) In the Phase 1 bullet (line 21), remove the trailing "(can start in parallel with external Phase 0)" parenthetical.

(d) In the Phase 3 bullet (line 23), remove "(requires lattice_stripe 0.3)" trailing text.

(e) In the Phase 3 Details section (line 74), change `**Depends on**: Phase 2, **external Phase 0** (lattice_stripe 0.3 Billing)` to `**Depends on**: Phase 2`.

(f) In the Phase 1 Details section (line 35), change `**Depends on**: Nothing (first phase; runs in parallel with external Phase 0)` to `**Depends on**: Nothing (first phase)`.

(g) Append to the end of the Phase 4 Details Success Criteria block (after criterion 6 "A coupon or promotion code applied..." on line 96, before `**Plans**: TBD` on line 97) a new line:
```
**Residual lattice_stripe gaps:** BillingMeter/MeterEvent (blocks BILL-11 metered billing) and BillingPortal.Session (blocks CHKT-02 Customer Portal) are not in lattice_stripe 1.0 — decision at Phase 4 planning: upstream contribution vs in-tree %LatticeStripe.Request{} fallback. Upstream work is in-flight in a parallel lattice_stripe session targeting 1.1 release.
```

(h) In the Progress table (line 176), change the Phase 3 row `Blocked on lattice_stripe 0.3` → `Not started`.

(i) In the `## Progress` Execution Order paragraph (line 170), remove "Phase 3 blocks on external Phase 0 (lattice_stripe 0.3) landing." The sentence should end after "1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9."

**Edit 3 — .planning/STATE.md:**

(a) In the `### Blockers/Concerns` section, delete the entire first bullet starting with `**External Phase 0 (lattice_stripe 0.3 Billing):**` — remove the full paragraph (line 74). Leave the Release Please v4 bullet and ChromicPDF bullet untouched.

(b) In the `### Decisions` section, update the first bullet:
`- [Roadmap]: 9-phase topological structure; Phase 1 can start in parallel with external Phase 0 (lattice_stripe 0.3)` → `- [Roadmap]: 9-phase topological structure; topological execution 1→9`

After all edits, run the following greps to confirm cleanup (all must return zero hits):
- `grep -r "0.3 Billing" .planning/ CLAUDE.md accrue/lib accrue/test`
- `grep -rn "Blocked on lattice_stripe" .planning/`
- `grep -rn "external Phase 0" .planning/ CLAUDE.md`
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue && ! grep -rn "0.3 Billing" .planning/ CLAUDE.md && ! grep -rn "Blocked on lattice_stripe" .planning/ && ! grep -rn "external Phase 0" .planning/ CLAUDE.md && grep -q 'lattice_stripe, "~> 1.0"' accrue/mix.exs</automated>
  </verify>
  <done>
CLAUDE.md lattice_stripe row shows `~> 1.0` with the new rationale; ROADMAP.md has no "External Dependency: Phase 0" section, Phase 3 depends only on Phase 2 and shows "Not started" status, Phase 4 details include the residual lattice_stripe gaps note; STATE.md Blockers section no longer contains the lattice_stripe 0.3 bullet; all three grep sentinel searches return empty.
  </done>
</task>

</tasks>

<verification>
Full quick task verification (run from `/Users/jon/projects/accrue`):
1. `cd accrue && mix compile --warnings-as-errors` → exit 0
2. `cd accrue && mix test` → `197 tests, 20 properties, 0 failures`
3. `grep -rn "0.3 Billing" .planning/ CLAUDE.md accrue/lib accrue/test` → no hits
4. `grep -rn "Blocked on lattice_stripe" .planning/` → no hits
5. `grep -rn "external Phase 0" .planning/ CLAUDE.md` → no hits
6. `grep 'lattice_stripe' accrue/mix.exs` → shows `~> 1.0`
</verification>

<success_criteria>
- accrue/mix.exs pins lattice_stripe `~> 1.0`
- Baseline test suite is green (no regressions from 0.2 → 1.0 API)
- CLAUDE.md Core Technologies table reflects lattice_stripe 1.0 reality and calls out residual 1.1-pending gaps scoped to Phase 4
- ROADMAP.md has no external Phase 0 section, Phase 3 is "Not started" depending only on Phase 2, Phase 4 documents residual gaps for BILL-11/CHKT-02
- STATE.md Blockers/Concerns no longer lists the lattice_stripe 0.3 blocker
- Single commit: `chore(deps): bump lattice_stripe to ~> 1.0 and unblock Phase 3`
</success_criteria>

<output>
Single atomic commit touching: accrue/mix.exs, accrue/mix.lock, CLAUDE.md, .planning/ROADMAP.md, .planning/STATE.md.
</output>
