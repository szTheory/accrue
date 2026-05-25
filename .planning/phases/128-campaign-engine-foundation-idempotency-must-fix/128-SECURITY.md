---
phase: 128
slug: campaign-engine-foundation-idempotency-must-fix
status: verified
threats_open: 0
asvs_level: 2
created: 2026-05-25
---

# Phase 128 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Register authored at plan time (all six PLAN.md files carried a `<threat_model>` block); this audit verified each declared mitigation exists in the implemented code — no retroactive STRIDE.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| host config → boot | Host-supplied `:dunning` cadence config crosses into the running system at app boot. A mis-config must fail loud, not silent. | Cadence step list (atoms + integer offsets), grace days |
| Stripe webhook retry → enqueue | Stripe re-fires `invoice.payment_failed` on every Smart Retry (weeks 1-4); each crosses into Accrue's mailer/campaign enqueue. Duplicate/unbounded sends are the threat. | Invoice/subscription IDs, event payload |
| webhook reducer → DB (anchor) | `dunning_campaign_started_at` is elected/cleared by the webhook reducer. Concurrent/duplicate webhooks race the first-transition write. | UTC timestamp anchor |
| Oban job args (JSONB) → worker | `campaign_started_at`/`step_key`/IDs arrive as JSON strings from `oban_jobs.args`. Must not be atomized; parse defensively. | Scalar IDs + ISO8601 timestamp string |
| email assigns → Oban args (JSONB) | Assigns persisted to `oban_jobs.args` must be scalar-only and PII-free. | ID references only |
| worker → email adapter | Worker delivers via `Accrue.Mailer.deliver/2`; must stay outside any transaction. | Rendered email |
| recovery webhook → cancel query | A recovery transition triggers a bulk job cancel; a stale/out-of-order recovery must not cancel the wrong campaign, and a cancel failure must not undo the committed anchor-clear. | `campaign_started_at` cancel key |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-128-01 | Tampering/DoS-adjacent (boot config) | `Accrue.Config` cadence parsing | mitigate | `validate_dunning_campaign_grace!/1` raises `Accrue.ConfigError` when `last_step.after_days > grace_days` (`config.ex:1110`, wired `:1058`); intra-list invariants reject empty-when-enabled + non-increasing offsets (`config.ex:1228`) | closed |
| T-128-02 | DoS (atom-table) | `key`/`template` atoms in step list | accept | `:atom`-typed host compile-time config (`config.ex:7-11`); 0 untrusted `String.to_atom` | closed |
| T-128-03 | Tampering/data integrity | anchor cast surface | mitigate | START is a sibling `update_all` that never touches `lock_version` (`default_handler.ex:1146`); cast exercised only by recovery-CLEAR (`:822`); `subscription.ex` ships no start-on-changeset path | closed |
| T-128-04 | Information Disclosure | anchor column contents | accept | `:utc_datetime_usec` only (`subscription.ex:66`), no PII/secrets | closed |
| T-128-05 | DoS (negative/huge delay) | `schedule_in` computation | mitigate | `max(0, ...)` clamp (`campaign.ex:92`); resolver total over all inputs | closed |
| T-128-06 | Tampering (purity drift) | resolver side effects | mitigate | purity grep gate (`Repo.`/`Oban.`/`Accrue.Clock`) = 0; `now` injected (`campaign.ex:79-94`) | closed |
| T-128-07 | DoS/cost (notification spam) | `:invoice_payment_failed` enqueue | mitigate | Oban `unique` keys `[:type, :invoice_id]`, `period: :infinity`, `:completed` in states (`mailer/default.ex:78-86`) + delivery-level backstop (`mailer.ex:352`) | closed |
| T-128-08 | Information Disclosure | email assigns in `oban_jobs.args` | mitigate | `only_scalars!/1` walks assigns and raises on any struct (`mailer/default.ex:98`), invoked before enqueue (`:34`) | closed |
| T-128-09 | Tampering | dedup key collision | mitigate | `keys: [:type, :invoice_id]` includes `:type`; keyed on non-null `invoice_id` not nullable `invoice_number` (`mailer/default.ex:82`) | closed |
| T-128-10 | DoS/cost (duplicate step send) | `DunningStep` enqueue | mitigate | `unique_opts/0` keys `[:subscription_id, :step_key, :campaign_started_at]`, `period: :infinity`, `:completed` (`dunning_step.ex:135-142`) | closed |
| T-128-11 | DoS (atom-table exhaustion) | `campaign_started_at` arg parse | mitigate | `DateTime.from_iso8601/1` (`dunning_step.ex:83`); 0 atomization in worker | closed |
| T-128-12 | Information Disclosure | step assigns in args | mitigate | Scalar-only args/assigns (`dunning_step.ex:120-167`) routed through `Mailer.deliver/2` → `only_scalars!/1` | closed |
| T-128-13 | Tampering (zombie campaign) | step `perform/1` | mitigate | Cancel-guard FIRST reloads live state; `{:cancel, :recovered}` on not-past_due / nil-anchor / deleted (`dunning_step.ex:85-100`, `:152-154`) | closed |
| T-128-14 | Tampering/race (TOCTOU first transition) | `maybe_bump_past_due_since/2` elector | mitigate | Atomic `update_all WHERE is_nil(dunning_campaign_started_at)` (`default_handler.ex:1145`); `count==1` enqueues day-0, `count==0` no-ops (`:1148-1151`); concurrent-race test green | closed |
| T-128-15 | Tampering (restart/orphan/duplicate) | repeated failure webhooks in-window | mitigate | Later in-window failure finds anchor set → `count==0` → no second start (`default_handler.ex:1148-1151`); D-16 step `unique` backstop | closed |
| T-128-16 | Tampering (stale recovery cancels fresh) | `maybe_finalize_dunning_campaign/2` cancel | mitigate | `cancel_all_jobs` keyed on `campaign_started_at` captured before the clear (`default_handler.ex:819`, `:878`); keying test proves isolation | closed |
| T-128-17 | DoS-adjacent (webhook SLO <100ms p99) | elector on webhook path | mitigate | Single PK-scoped `update_all` (no held lock) + async `Oban.insert`; no sync email on webhook path (`default_handler.ex:1145`, `:1168`) | closed |
| T-128-18 | DoS/cost (double day-0 email) | D-15 gate | mitigate | REPLACE gate skips standalone `:invoice_payment_failed` dispatch when campaign enabled (`default_handler.ex:1661-1665`) | closed |
| T-128-19 | DoS/availability (global suppression regression) | `unique` keys arg resolution | mitigate | `invoice_id` promoted TOP-LEVEL only when binary non-empty (`mailer/default.ex:53-64`); nil/"" → `unique: false` (`:78-88`) + backstop `{:error, :missing_invoice_id}` (`mailer.ex:354-355`) | closed |
| T-128-20 | Availability (zombie if cancel fails / partial recovery write) | recovery anchor-clear vs bulk cancel | mitigate | Anchor-clear commits in-transaction atomic with status write (`default_handler.ex:821-823`); bulk cancel runs post-commit, outside the txn, `rescue`-wrapped (`:854`, `:883-889`); per-step guard self-cancels | closed |
| T-128-SC | Tampering (supply chain) | npm/pip/cargo installs | n/a | No `mix.exs`/`mix.lock`/`package.json`/`Cargo.*`/`requirements.txt` changed across `be9d7ad8~1..HEAD`; `tech-stack.added: []` in all six SUMMARYs | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-128-01 | T-128-02 | Campaign step `key`/`template` atoms originate from host compile-time `:accrue` config (`@step_schema`), never from webhook/DB/runtime input. No `String.to_atom` on untrusted data in the config path — atom-table exhaustion is not reachable. | gsd-security-auditor | 2026-05-25 |
| AR-128-02 | T-128-04 | `dunning_campaign_started_at` stores a single `:utc_datetime_usec` UTC instant. It carries no PII, payment data, or secrets; disclosure reveals only when a campaign began. | gsd-security-auditor | 2026-05-25 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-25 | 21 | 21 | 0 | gsd-security-auditor (verify-existence, register authored at plan time) |

**Mitigation proof:** 6 properties, 54 tests, 0 failures (`--seed 0`).

**Audit note (not a finding):** `mailer.ex` contains `String.to_existing_atom/1` calls (`:55`, `:530`) — the bounded, VM-already-interned variant on the type string and known assign keys, outside the T-128-11 surface (the `DunningStep` worker's JSONB `campaign_started_at` parse, verified at 0). No `## Threat Flags` section appeared in any Phase 128 SUMMARY; 128-04's "Threat Mitigations Confirmed" maps only to registered IDs.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-25
