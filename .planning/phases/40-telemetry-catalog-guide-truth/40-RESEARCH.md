# Phase 40 — Technical research

**Phase:** 40 — Telemetry catalog + guide truth  
**Question:** What do we need to know to plan OBS-01 / OBS-03 / OBS-04 well?

## Findings

### 1. Ops inventory vs code (baseline 2026-04-21)

- `rg '\\[:accrue,\\s*:ops'` across `accrue/lib` yields **13 distinct ops shapes** matching the v1.9 gap audit §1 table: revenue_loss, dunning_exhaustion, incomplete_expired, charge_failed, meter_reporting_failed, webhook_dlq (dead_lettered | replay | prune), pdf_adapter_unavailable, events_upcast_failed, connect_account_deauthorized, connect_capability_lost, connect_payout_failed.
- **`guides/telemetry.md`** already includes **all 13** in the main ops table (rows 55–67 in current `main`), plus narrative for `operation_id`, Connect/PDF `:telemetry.execute` vs `Ops.emit/3`, and runbook column through Connect — the **pre–v1.9 audit “No” gaps are already closed in the guide text**.
- **`Accrue.Telemetry.Ops` moduledoc** lists the same 13 canonical tuples and links to the guide — drift between Ops list and guide table is **currently aligned**.

**Planning implication:** Phase 40 is **not** “add missing rows”; it is **truth hardening** (headings, firehose/OTel honesty, contract tests, audit supersession trail) per `40-CONTEXT.md`.

### 2. Firehose vs ops (OBS-03)

- Guide already has `## Namespace split` and `### Firehose and diagnostic events` with billing span pattern, webhooks, mail/PDF bullets, and explicit “keep paging on ops” guidance.
- **Gap vs decisions:** Heading `## Ops events in v1.0` is **not evergreen** (D-15). Firehose subsection should stay **taxonomy + policy** — no full billing enumeration (D-13).

### 3. OpenTelemetry examples (audit §4 + D-14)

- **`accrue.webhooks.dlq.replay`** in the OTel examples list is **misleading**: DLQ replay emits **`[:accrue, :ops, :webhook_dlq, :replay]`** via `Ops.emit/3` / `:telemetry.execute` in ops namespace — it is **not** a `span/3` billing/webhook span name. Same class of issue for any example shown as OTel that is not produced by `Accrue.Telemetry.span/3` → `Accrue.Telemetry.OTel.span/3`.
- **Verified billing span:** `Accrue.Billing.report_usage/3` uses `span_billing(:meter_event, :report_usage, ...)`, producing telemetry `[:accrue, :billing, :meter_event, :report_usage, :start|...]` and OTel name **`accrue.billing.meter_event.report_usage`** — **should appear** as the canonical meter example (pairs narratively with ops `meter_reporting_failed`).
- **`Accrue.Telemetry` moduledoc** domain list is **narrower** than the guide’s OTel section (`checkout`, `billing_portal` appear in guide but not in `Telemetry` moduledoc) — reconcile per D-14 / D-12.

### 4. Contract-test strategy (D-07, D-11)

- **Avoid** normative `file:line` in the guide; **do** add an ExUnit module under `accrue/test/accrue/telemetry/` that:
  - Maintains a **single sorted allowlist** of ops event **suffix paths** (atoms or lists) as the executable contract,
  - Asserts every `[:accrue, :ops | suffix]` emitted from `accrue/lib` is covered (via static read + regex, or explicit registry module — planner chooses least brittle),
  - Asserts `guides/telemetry.md` contains a markdown table row for each allowlisted event (grep for backtick-wrapped event representation).
- Failing output should name **`guides/telemetry.md`** and the test allowlist file as remediation targets.

### 5. Gap audit reconciliation (OBS-04)

- After guide + tests ship, append **`SUPERSEDED`** block to `.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md` with **date + PR link** and pointer to `guides/telemetry.md` ops catalog heading (D-05, D-06).
- Guide footer line “Last reconciled with v1.9 gap audit §1: …” closes the trust loop for operators reading GitHub-rendered Markdown.

## Pitfalls

- **Do not** duplicate full measurement/metadata schema in `Ops` moduledoc (D-03).
- **Do not** enumerate every `[:accrue, :billing, …]` action in Phase 40 (D-13).
- **Do not** treat ExDoc-only changes as sufficient for OBS-01 — Hex readers use **`guides/telemetry.md`**.

## Validation Architecture

Phase 40 validation is **documentation + ExUnit contract** driven:

| Dimension | Strategy |
|-----------|----------|
| Correctness | `cd accrue && mix test test/accrue/telemetry/` (new contract module + existing `billing_span_coverage_test.exs` unchanged) |
| Drift control | Ops allowlist test fails when new `[:accrue, :ops` emit lands without guide + allowlist update |
| Manual | Spot-read `guides/telemetry.md` OTel section for “aspirational” vs “verified” labeling after edits |

**Quick command:** `cd accrue && mix test test/accrue/telemetry/ops_event_contract_test.exs` (path finalized in PLAN 03).  
**Full suite (pre-merge):** `cd accrue && mix test`

Sampling: run quick test after each plan wave; full `mix test` before phase verify-work.

---

## RESEARCH COMPLETE
