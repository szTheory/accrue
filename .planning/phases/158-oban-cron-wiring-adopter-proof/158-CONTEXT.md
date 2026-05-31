# Phase 158: Oban Cron Wiring Adopter Proof - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Make `examples/accrue_host` prove, with a deterministic host-level test, that Accrue's required Oban cron workers and queue configuration are wired in the example host. The proof should teach the adopter-safe crontab append pattern without adding new runtime behavior.

- **In scope:** update `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` so it fails when required cron workers or queues are missing from the host's real base Oban config; add a concise append-merge comment beside the host `Oban.Plugins.Cron` crontab; mirror the teaching in the adoption-proof matrix without duplicating the snippet.
- **Out of scope:** new Oban workers, new queues, new billing or dunning behavior, installer expansion, broad README rewrites, new public APIs, and behavior-heavy worker tests that duplicate core `accrue` job coverage.

</domain>

<decisions>
## Implementation Decisions

### Config proof shape
- **D-01:** `recovery_wiring_test.exs` must inspect the real base host config, not accept `config/test.exs` runtime overrides as sufficient proof. The current `plugins: false` / `queues: false` branch is valid test-env safety, but it is not a PRF-03 pass signal.
- **D-02:** Use the idiomatic Oban config-testing pattern: read `examples/accrue_host/config/config.exs` with `Config.Reader.read!/2`, extract `[:accrue_host, Oban]`, validate with `Oban.Config.validate/1`, then assert the required queues and `Oban.Plugins.Cron` entries.
- **D-03:** Keep test-env runtime safety separate. It is acceptable to assert that `Application.fetch_env!(:accrue_host, Oban)` has `plugins: false`, `queues: false`, and `testing: :manual`, but that assertion must not replace the base-config wiring proof.
- **D-04:** Do not extract a new shared `AccrueHost.ObanConfig` helper in this phase. It adds indirection for a small adopter-proof closeout and risks teaching a pattern adopters will not copy.

### Queue contract
- **D-05:** Reconcile the roadmap wording to the actual worker truth during planning. This is not a scope expansion; it corrects proof semantics so the test proves what the cron workers need.
- **D-06:** Separate queue categories explicitly:
  - **Core runtime required queues:** `accrue_webhooks`, `accrue_mailers`.
  - **Cron-wiring required queues:** `accrue_dunning`, `accrue_meters`, `accrue_scheduled`.
  - **Optional host queue:** `accrue_pdf`, required only when the host uses the PDF worker path.
- **D-07:** The Phase 158 test should assert the queue set that makes this host's Accrue background story honest: at minimum `accrue_webhooks`, `accrue_mailers`, `accrue_dunning`, `accrue_meters`, and `accrue_scheduled`. The roadmap/requirements text currently omits `accrue_dunning`; the planner should update wording or verification notes so the accepted contract no longer gives false confidence.
- **D-08:** Cron workers to assert in `Oban.Plugins.Cron`: `Accrue.Jobs.DunningSweeper`, `Accrue.Jobs.DetectExpiringCards`, `Accrue.Jobs.MeterEventsReconciler`, and `Accrue.Jobs.MeteredRenewalReconciler`.

### Proof depth
- **D-09:** Make config-contract assertions the primary proof. The test should fail if the cron workers or queue keys are absent from the base config.
- **D-10:** Keep runtime smoke minimal. At most one no-op host-call smoke is acceptable if it adds confidence without fixture setup; do not retain or expand a broad behavior smoke suite in this phase.
- **D-11:** Prefer moving behavior-heavy confidence to existing core job tests. `examples/accrue_host` should prove host wiring and copyable config, not duplicate the job internals.
- **D-12:** If a smoke call remains, choose the least brittle no-op path and make it secondary to the config assertions. Do not add database state choreography, clock advancement, webhook stubs, or `Oban.drain_queue/1` loops here.

### Append-merge teaching
- **D-13:** Put the canonical append-merge teaching beside the `Oban.Plugins.Cron` crontab in `examples/accrue_host/config/config.exs`.
- **D-14:** The comment should warn adopters to append Accrue entries to their existing crontab rather than replacing it. Include a small shape such as `crontab: existing_cron_jobs() ++ [ ...Accrue entries... ]`.
- **D-15:** Add a concise adoption-proof matrix note pointing to `config/config.exs` as the canonical snippet. Do not duplicate the full snippet in README or multiple docs unless a future support signal shows README-only readers keep missing it.
- **D-16:** Do not add a README callout in this phase. It would create a third maintenance surface for a small config-copy footgun.

### the agent's Discretion
- The planner may choose whether to split config assertions into helper functions inside `recovery_wiring_test.exs`, as long as no new production helper module is introduced.
- The planner may keep one existing smoke test if it is stable and cheap, but should remove any pass path where disabled test plugins/queues are treated as proof of production wiring.
- The planner may update roadmap/requirements wording if needed to reconcile the missing `accrue_dunning` queue, because that correction aligns the acceptance criteria with the existing worker modules rather than changing product scope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/ROADMAP.md` §"Phase 158: Oban Cron Wiring Adopter Proof" - phase goal and success criteria; note the queue wording needs reconciliation with actual worker queues.
- `.planning/REQUIREMENTS.md` §"Adopter-Proof: Oban Crons" - PRF-03 locked requirement; planner should preserve intent while correcting queue truth.
- `.planning/STATE.md` §"Current Position" and §"Key Planning Decisions for v1.47" - confirms Phase 158 is independent adopter-proof closure.
- `.planning/PROJECT.md` §"Core Value" and §"Current Milestone: v1.47 ENT-10 Polish + Adopter-Proof Completeness" - Accrue's day-one Phoenix SaaS billing DX and adopter-proof posture.

### Research and prompt corpus
- `.planning/research/SUMMARY.md` §"Adopter-Proof: Oban Cron" - existing research on cron proof scope.
- `.planning/research/STACK.md` §"Oban Cron Adopter-Proof Pattern" and §"Oban Cron Proof" - config-inspection pattern and no-new-library conclusion.
- `.planning/research/PITFALLS.md` §"Oban Cron Adopter-Proof" - append-vs-replace crontab footgun and suggested prevention.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - adopter-first "done enough" lens: proof/CI honesty, idiomatic Elixir/Phoenix, DX, least surprise, and avoiding speculative scope.

### Prior phase context
- `.planning/phases/157-metered-usage-adopter-proof/157-CONTEXT.md` - closest prior proof pattern: narrow host-level adopter proof, facade/config truth, no broad behavior duplication.
- `.planning/phases/156-entitlements-gating-adopter-proof/156-CONTEXT.md` - adopter-proof pattern: fail closed, keep docs/comments concise, and prove the real host integration seam.
- `.planning/phases/157-metered-usage-adopter-proof/157-01-SUMMARY.md` - confirms Phase 158 can build independently on remaining Oban cron adopter-proof scope.

### Source files
- `examples/accrue_host/config/config.exs` - canonical host Oban config and append-merge comment target.
- `examples/accrue_host/config/test.exs` - disables queues/plugins and sets `testing: :manual`; this is test safety, not production wiring proof.
- `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` - primary test to upgrade for PRF-03.
- `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs` - richer dunning behavior proof; avoid duplicating its behavior depth.
- `examples/accrue_host/docs/adoption-proof-matrix.md` - concise PROOF-06 matrix pointer target.
- `examples/accrue_host/README.md` - existing recovery/maintenance pointer; do not expand unless planner finds a verifier requirement.
- `accrue/lib/accrue/jobs/dunning_sweeper.ex` - `use Oban.Worker, queue: :accrue_dunning`.
- `accrue/lib/accrue/jobs/detect_expiring_cards.ex` - `use Oban.Worker, queue: :accrue_scheduled`.
- `accrue/lib/accrue/jobs/meter_events_reconciler.ex` - `use Oban.Worker, queue: :accrue_meters`.
- `accrue/lib/accrue/jobs/metered_renewal_reconciler.ex` - `use Oban.Worker, queue: :accrue_meters`.
- `accrue/lib/accrue/webhook/dispatch_worker.ex` - core runtime `accrue_webhooks` queue.
- `accrue/lib/accrue/workers/mailer.ex` - core runtime `accrue_mailers` queue.

### External primary docs
- `https://oban.hexdocs.pm/testing_config.html` - Oban config testing with `Config.Reader.read!` and `Oban.Config.validate/1`.
- `https://oban.hexdocs.pm/testing.html` - Oban testing modes and why test jobs/plugins should not run unexpectedly.
- `https://oban.hexdocs.pm/testing_queues.html` - queue integration testing and `Oban.drain_queue/1` guidance.
- `https://oban.hexdocs.pm/Oban.Config.html` - public `Oban.Config.validate/1` contract.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/accrue_host/config/config.exs` already declares the required host queues and all four cron workers in one `Oban.Plugins.Cron` block.
- `examples/accrue_host/config/test.exs` already expresses the safe test posture: queues/plugins disabled with `testing: :manual`.
- `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` already names `DetectExpiringCards`, `MeterEventsReconciler`, and `MeteredRenewalReconciler`; it needs to add `DunningSweeper` and stop treating disabled test plugins as wiring proof.
- `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs` already covers richer dunning campaign behavior on `accrue_dunning`, so Phase 158 should not re-prove that path.

### Established Patterns
- Example-host adopter proofs are narrow, deterministic, and tied to the host integration seam.
- Oban test env commonly disables queues/plugins to avoid background DB activity under Ecto SQL Sandbox; config validation should inspect the intended config separately.
- Accrue favors proof honesty over checklist wording. If the written queue list is stale or incomplete, the planner should correct it rather than enshrine a false pass.
- Copyable config lessons belong at the callsite, with docs/matrix references rather than repeated snippets.

### Integration Points
- `recovery_wiring_test.exs` should read base config and assert:
  - `Oban.Config.validate(oban_config) == :ok`
  - `Oban.Plugins.Cron` exists
  - crontab includes `DunningSweeper`, `DetectExpiringCards`, `MeterEventsReconciler`, `MeteredRenewalReconciler`
  - queues include `accrue_webhooks`, `accrue_mailers`, `accrue_dunning`, `accrue_meters`, `accrue_scheduled`
- `config.exs` should get the append-merge note immediately above the `crontab:` list.
- `adoption-proof-matrix.md` should update the Recovery wiring row to include `DunningSweeper`, all cron queues, and the append-merge pointer.

</code_context>

<specifics>
## Specific Ideas

- Four advisor subagents converged on the same shape: config-contract-first proof, runtime test safety kept separate, queue wording reconciled to actual worker bindings, and concise docs at the copy/paste surface.
- Current Oban docs support reading static config in a test and validating it with `Oban.Config.validate/1`; this is a better fit than making `MIX_ENV=test` runtime env pretend to be production wiring.
- Ecosystem lesson: successful framework examples keep one canonical schedule/config source and assert dispatch/wiring separately from job behavior. Rails/Laravel-style schedulers and Oban/Phoenix examples work best when the schedule declaration is obvious and copyable; duplicated prose increases drift.

</specifics>

<deferred>
## Deferred Ideas

- A broader installer or First Hour update for all host-required Oban queues may be useful later if support evidence shows adopters miss the queue taxonomy, but Phase 158 should stay focused on the example-host cron proof.
- A production helper module for reusable Oban config fragments is deferred. It is not needed for this closeout and would add abstraction before there is enough repeated host config surface.

### Reviewed Todos (not folded)
- **ENT-10 advisory-cache code-review follow-ups (WR-05 + INFO)** - Reviewed and not folded. It matched Phase 158 weakly through generic Oban/webhook terms, but advisory-cache correctness was already handled by Phases 154 and 155. Phase 158 remains scoped to Oban cron adopter proof.

</deferred>

---

*Phase: 158-Oban-Cron-Wiring-Adopter-Proof*
*Context gathered: 2026-05-31*
