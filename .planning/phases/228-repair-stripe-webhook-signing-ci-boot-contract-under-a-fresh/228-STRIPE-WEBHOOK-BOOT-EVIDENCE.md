# Phase 228 Stripe webhook boot evidence

## Readiness and authority

- status: `readiness_not_authorized`
- owner: maintainer
- fresh run ceiling: exactly one first-attempt `workflow_dispatch` with `run_live_stripe:true`
- additional dispatch authorized: `false`
- next action: Plan `228-02` must confirm repository configuration and obtain an explicit authorize-or-decline decision

No dispatch, retry, rerun, or replacement is authorized by this record. The tuple below is deliberately unconsumed and cannot be presented as provider proof.

## Evidence tuple

The verifier reads only the marked block. Every named field is present exactly once. Plan 228-03 replaces readiness-only empty values with one allowed terminal tuple after explicit authorization; unknown, duplicate, or conflicting fields are invalid.

<!-- evidence-record:start -->
- status: `readiness_not_authorized`
- owner: `maintainer`
- repaired_sha: `a76b7653533d6f9428fe276a55c9b5dbcd54d14a`
- dispatch_at: ``
- observed_at: ``
- workflow: `CI`
- event: `workflow_dispatch`
- input_run_live_stripe: `true`
- run_id: ``
- run_attempt: ``
- run_url: ``
- job_name: ``
- job_status: ``
- job_conclusion: ``
- preflight_step_status: ``
- preflight_step_conclusion: ``
- suite_step_status: ``
- suite_step_conclusion: ``
- finalizer_step_status: ``
- finalizer_step_conclusion: ``
- artifact_step_status: ``
- artifact_step_conclusion: ``
- raw_run_conclusion: ``
- raw_job_conclusion: ``
- proof_state: ``
- reason_code: ``
- selected_count: ``
- passed_count: ``
- failed_count: ``
- skipped_count: ``
- manifest_present: ``
- manifest_selected_count: ``
- manifest_passed_count: ``
- manifest_failed_count: ``
- manifest_skipped_count: ``
- manifest_started_at: ``
- manifest_finished_at: ``
- finalizer_result: ``
- artifact_present: ``
- created_run: `false`
- consumed: `false`
- rejection_class: ``
- retry: `false`
- authority_closed: `false`
- outcome: `pending_authorization`
<!-- evidence-record:end -->

## Exact-once schema

The identity group is `repaired_sha`, `dispatch_at`, `observed_at`, `workflow`, `event`, `input_run_live_stripe`, `run_id`, `run_attempt`, `run_url`, and the stable `job_name`. The job/step group records status and conclusion independently for the job, preflight, suite, finalizer, and artifact-upload steps. The terminal group records both raw conclusions, `proof_state`, `reason_code`, all four proof counts, manifest presence, all four manifest totals, manifest timestamps, finalizer result, `live-stripe-proof` artifact presence, created/consumed state, rejection class, retry, authority closure, and outcome.

Counts are non-negative integers and `selected_count` equals passed plus failed plus skipped. When a manifest is present, its totals byte-for-byte agree with the proof counts and its finish timestamp does not precede its start timestamp. A created run is consumed exactly once, is attempt 1, uses an immutable repository run URL, has no retry, and closes authority.

## Allowed terminal tuples

| Branch | Required populated facts | Required empty facts | Outcome rule |
|---|---|---|---|
| Created run, proved | Full run/job/step identity; raw run and job `success`; positive selected count equal to passed; zero failed/skipped; valid matching manifest; successful finalizer; `live-stripe-proof` present | rejection class | Only `proved` / `complete_provider_evidence` may claim proved. |
| Created run, configuration incomplete | Full run/job/step identity; failure conclusions; zero proof counts; successful always-run artifact retention | all manifest totals/timestamps; rejection class | `misconfigured` / `configuration_incomplete`; never proved. |
| Created run, invalid or absent manifest | Full run/job/step identity; failure conclusions; zero proof counts; always-run finalizer/artifact facts | all manifest totals/timestamps; rejection class | `misconfigured` / `manifest_invalid`; never proved. |
| Created run, zero selected or unaccounted skipped | Full identity and valid matching manifest; zero selected or positive skipped count respectively; failure conclusions; artifact present | rejection class | `misconfigured` with the matching canonical reason; never proved. |
| Created run, selected assertions failed | Full identity and valid matching manifest; failure fact; artifact present | rejection class | `failed` / `selected_assertions_failed`; never proved. |
| Created run, blocked | Full identity; exact raw `cancelled`, `timed_out`, `action_required`, or other non-success conclusion; matching canonical reason; artifact present | rejection class | `blocked` with `job_cancelled`, `job_timed_out`, `job_action_required`, or `job_did_not_complete`; never proved. |
| No run created | Sanitized intent (`repaired_sha`, bounded dispatch/observation times, `CI`, `workflow_dispatch`, `run_live_stripe:true`), allowed rejection class, `created_run:false`, `consumed:false`, no retry, closed authority | Every run/job/step/conclusion/count/manifest/finalizer/artifact/proof-only field | `no_run_rejected`; never proved. |

`skipped` / `intentional_bypass` is outside the Phase 228 schema and blocks validation. It is structurally impossible in the repaired mandatory-provider workflow: `run_live_stripe` is its only dispatch input, a true manual dispatch executes the input-gated live-stripe job, and the always-run provider finalizer receives no bypass flag or bypass-reason argument.

## Sanitization and history boundary

This record may contain only the field names and sanitized statuses above. It excludes credential values, raw provider logs, request or webhook payloads, actors, endpoint identifiers, and configuration-presence details. Values from protected configuration must never be interpolated, printed, serialized, passed as command arguments, or stored in artifacts.

[Phase 227's terminal rollback record](../227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md) is historical context only. Its bytes, classifications, and exhausted restoration authority remain unchanged; Phase 228 does not revise or reuse them.
