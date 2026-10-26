# Phase 244: Operator Language and Evidence - Research

**Researched:** 2026-10-10  
**Domain:** Phoenix LiveView Admin copy, event evidence, and truthful operation outcomes  
**Confidence:** HIGH for source/test semantics; LOW for current mounted output (preview unavailable through this session)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Activity wording
- **D-01:** Use explicit, meaning-backed operator labels for known event/state types through the incumbent Copy owner. Read the event producer and outcome contract before choosing a label: a locally recorded update, requested processor operation, received delivery, and completed operation have different meanings. Do not infer semantics by replacing punctuation or title-casing arbitrary keys.
- **D-02:** Retain the exact key independently from its display label. For unrecognized types, use a neutral fallback such as “Billing event” with the exact key available; do not classify an unfamiliar type as failure, lost history, or a completed action. Nil/malformed values receive honest missing-data treatment without fabricated identifiers. Exact final strings and mapping membership are planner discretion after source and rendered confirmation.
- **D-03:** Reuse the same label meaning across the targeted Home, event list/detail, and related activity consumers that actually share the underlying event. Avoid divergent page-local translations or a mapping of every possible provider event without evidence. Primary scanning language serves billing/support operators; established billing terms remain where they affect decisions. Historical activity must not imply current customer/provider state.

### Technical evidence and hierarchy
- **D-04:** Keep affected object, observed outcome, material uncertainty, and supported next action visible. Put secondary technical evidence in existing native disclosure or detail fields when it crowds primary scanning. Retain visible identity/context needed to distinguish records. Choose by the surface's task; no universal collapsed-fields policy or new inspector.
- **D-05:** Exact event key, relevant record identifiers, and timestamps remain discoverable at the investigation point. Preserve full available timestamp precision and timezone in an accessible evidence location; minute/relative summaries alone do not satisfy exact evidence. Home may use compact time while the existing detail/disclosure carries the complete value. Do not label absent time as current or invent freshness.
- **D-06:** Evidence must work with keyboard and touch and remain selectable; reuse incumbent copy controls where appropriate. Never make tooltip/hover the only access path. Disclosure names identify their contents, preserve native activation/focus behavior, and handle long identifiers on narrow screens. Do not add controls to every row just for uniformity.
- **D-07:** Preserve fresh owner scope and existing authorized projection. Humanizing a label does not approve adding raw payloads, sensitive fields, new reads, new links, logging, or mutation. Keep raw payload in its existing authorized detail context; do not duplicate it on Home. Missing or inaccessible relationships stay explicit and do not produce unrelated plausible links.

### Outcomes, recovery, and destination names
- **D-08:** Prefer concise observed outcome plus a supported next step, with technical limitation in contextual evidence where needed. Distinguish completed, requested/queued, failed, blocked, and unable-to-confirm using actual available evidence. Do not invent a cause, blame filters/configuration for service failures, or soften uncertainty into success.
- **D-09:** If observation fails after a mutation request, preserve uncertainty and direct the operator to an existing supported reread/investigation path before suggesting another mutation. A read retry and replay/resend are different actions. Do not offer a generic retry that could duplicate billing work. This phase changes presentation only; if correct wording needs new domain behavior, document the gap for separate scope.
- **D-10:** Repeated navigation/page/breadcrumb/action names agree with their existing destination/effect. Maintain a small vocabulary/destination table in the phase's focused planning inventory, not a new global taxonomy. Preserve payment versus exact Charge evidence, event versus webhook delivery, and requested versus completed. Keep Copy.Locked and legal/audit/provider meaning intact. Redundant implementation narration can be shortened without losing consequential limitations.

### Focused delivery, automation, and stopping rules
- **D-11:** Home recent activity and inline Home wording are initial source-confirmed candidates; event detail and webhook related activity are likely same-meaning consumers. They are not a blanket fix list. Planning first confirms current mounted route/state output, records each candidate as change/adequate/unobserved with owning source and test, then selects coherent slices. STATE-01 requires real targeted outcome coverage, not just static label edits. Do not add a new broad research phase or all-route audit.
- **D-12:** Attach each recurring claim to its cheapest faithful existing owner: Copy tests for mapping/fallback and parity; owning LiveView tests for rendered labels, identity, exact evidence and supported branches; existing browser tests for real disclosure/navigation, focus, long-ID layout, narrow/wide and effective light/dark where affected. Include unknown keys, missing facts, sub-minute timestamps, stale/unavailable observations, and destination/effect assertions. Avoid tests that merely freeze paragraphs, blanket banned-word lint, broad AI detectors, relaxed exclusions, and duplicate matrices.
- **D-13:** Preserve state/job/dispatch/audit evidence for mutation/outcome claims. A clicked button, screenshot inventory, or displayed success sentence alone does not prove the operation. Bind each passing result to its tested revision, route/state/fixture, viewport/theme and served assets when relevant. Record initial failures honestly. Use the current build/parity and acceptance owners; plan exact commands rather than inheriting historical green results.
- **D-14:** Use one batched rendered review, one corrective batch, and one confirmation round per coherent slice. Reopen only for a named defect or evidence that invalidates the decision. Subjective comprehension informs agent review; do not invent a mandatory owner acceptance loop for mechanically decidable claims. Stop research at diminishing returns; no further fanout is needed unless new evidence exposes a genuine decision.
- **D-15:** Prefer a small local helper or modest explicit duplication over a new dependency/abstraction when it keeps ownership clear. Consolidate semantics that must agree at an existing owner. No new dependency is justified by this discussion; copy-paste preference does not authorize duplicating billing, money, scope, or authorization logic.

### the agent's Discretion
The maintainer delegated all three areas: exact wording, small mapping/helper shape, confirmed consumer selection, detail placement within existing components, focused test selection, and implementation decomposition. Recommendations above are adopted under that delegation. Ask only if new evidence reveals a real product fork or an external action beyond existing authorization. This discussion does not authorize implementation by itself; the next workflow is phase planning.

### Deferred Ideas (OUT OF SCOPE)
None newly proposed. Previously excluded diagnosis/new rooms, Portal work, redesign and broad tooling remain outside this phase. Any domain correctness gap discovered during wording work requires explicit separate disposition.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LANG-01 | On targeted existing Admin screens, operators understand primary activity/state labels without decoding keys and labels remain faithful. | Shared BillingEvent Copy owner and confirmed event producer semantics; Home/event list/detail/activity consumer map. |
| STATE-01 | Copy reports only evidenced outcomes, action effect, and safe next step. | Webhook replay source and tests distinguish queue acceptance, failed/unknown, and reread uncertainty; event read failure has an owning LiveView branch. |
| EVID-01 | Human labels retain access to exact event keys, record identifiers, and timestamps. | Home timeline, event detail fields, native disclosures, and existing identity/time tests are candidate owners; precision gap needs targeted assertion. |
| CONS-01 | Repeated headings/action names agree with actual destinations/effects. | Dashboard and event/webhook route consumers plus replay/read controls; vocabulary table below. |
</phase_requirements>

## Summary

This is a bounded existing-surface cleanup in `accrue_admin`; there is no reason to add a package or test framework. `[VERIFIED: accrue_admin/lib/accrue_admin/copy/billing_event.ex:4-125]` The current source uses raw event types as Home timeline titles and event detail titles; the event list uses the type as its event cell. The event detail already carries actor, subject, source webhook, and recorded-time fields, while the Home timeline carries subject summary and a link to event detail. These establish concrete source candidates, but the supplied feedback preview could not be opened in this session, so none is asserted as current mounted output.

The domain contract makes naive title casing unsafe. `[VERIFIED: accrue/lib/accrue/billing.ex:973-1035; accrue/lib/accrue/billing.ex:1037-1064; accrue/lib/accrue/webhook/ingest.ex:129-141; accrue/lib/accrue/webhooks/dlq.ex:141-169]` The processor-backed `customer.updated` path calls the processor, projects the response, and then records the event; `customer.local_updated` is documented as local-only host maintenance. `webhook.received` records receipt, and `webhook.replay_requested` is recorded after queue insertion, not after successful processing. Reuse a shared semantic mapping only for event types whose producers are checked; keep the exact stored type, identifiers, and timestamp alongside the readable label.

**Primary recommendation:** First make a read-only review of the current preview routes/states and record each bounded candidate as change, adequate, or unobserved. Then change only confirmed defects through existing Copy/LiveView owners, with focused ExUnit assertions against rendered output and underlying event/job/dispatch evidence for outcome claims.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Event label semantics | API / Backend | Frontend Server (SSR) | Producers define meaning; Copy maps known keys for presentation. |
| Recent activity and event evidence | Frontend Server (SSR) | Database / Storage | LiveViews render scoped event reads and existing detail data. |
| Replay/read outcome presentation | Frontend Server (SSR) | API / Backend | Webhook LiveView displays existing dispatch/replay state; DLQ and Oban/DB evidence determine whether queueing happened. |
| Accessible evidence disclosure | Browser / Client | Frontend Server (SSR) | Native `details`/`summary` and responsive rendering are exercised in browser tests; LiveView supplies content. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `AccrueAdmin.Copy` / Phoenix LiveView | Existing project versions | Shared Admin copy and mounted pages | The approved incumbent ownership path; no new dependency. `[VERIFIED: accrue_admin/lib/accrue_admin/copy/billing_event.ex:1-125; accrue_admin/lib/accrue_admin/live/dashboard_live.ex:1-135]` |
| ExUnit / Phoenix.LiveViewTest | Existing project versions | Copy and rendered behavior tests | Existing Copy and page tests are authoritative recurring owners. `[VERIFIED: accrue_admin/test/accrue_admin/live/event_live_test.exs:68-190]` |

No new package is proposed; package legitimacy audit is not applicable.

## Bounded Candidate Inventory and Owners

The status column is a **source-only initial disposition**. Mounted status remains **unobserved** for every candidate because neither browser route access nor a safe preview observation was available. Planning must make the read-only mounted confirmation before edits.

| Candidate / bounded route | Source-only status | Current source and behavior | Owning test / focused verification |
|---|---|---|---|
| Home recent activity (`/admin`) title, context, and time | Change candidate | `DashboardLive` sets title to `event.type`, body to subject/type/id summary, metadata to `Audit event`, and link to event detail; timestamp is rendered to minute precision. `[VERIFIED: accrue_admin/lib/accrue_admin/live/dashboard_live.ex:91-126]` | `accrue_admin/test/accrue_admin/live/dashboard_live_test.exs`; assert readable known type plus exact key, record identity, and exact timestamp available by disclosure/detail path. |
| Event list event cell | Unobserved; assess | `EventsLive` delegates event cell to `event_cell/4`; filter identity remains exact type. Avoid changing query/filter values while humanizing display. `[VERIFIED: accrue_admin/lib/accrue_admin/live/events_live.ex:134-157]` | `accrue_admin/test/accrue_admin/live/events_live_test.exs`; retain exact key and filter behavior while asserting label for confirmed keys and neutral unknown fallback. |
| Event detail title, fields, timestamp | Change candidate | Detail title/breadcrumb and `Type` field use exact raw type; `format_datetime/1` emits minute precision in UTC. `event_detail_fields/1` already includes actor/subject/source webhook/recorded time. `[VERIFIED: accrue_admin/lib/accrue_admin/live/event_live.ex:130-160; accrue_admin/lib/accrue_admin/live/event_live.ex:230-260; accrue_admin/lib/accrue_admin/live/event_live.ex:445-446]` | `accrue_admin/test/accrue_admin/live/event_live_test.exs`; test exact key, linked identifiers, seconds/fractional seconds and timezone, missing timestamps, native disclosure keyboard operation. |
| Webhook derived related activity | Unobserved; assess same semantic mapping | Webhook detail separately presents webhook delivery status and derived ledger activity. Do not label a related event as the webhook delivery itself. `[VERIFIED: accrue_admin/lib/accrue_admin/live/webhook_live.ex:200-300]` | `accrue_admin/test/accrue_admin/live/webhook_live_test.exs`; preserve distinction among delivery, derived event, and current status. |
| Event detail read unavailable/retry | Adequate source branch; mounted unobserved | Existing unavailable copy explicitly says identity/related evidence are unknown and control retries the read. `[VERIFIED: accrue_admin/lib/accrue_admin/live/event_live.ex:130-136]` | `event_live_test.exs` read-failure retry case: unavailable before retry, record restored after read succeeds; keep no mutation evidence. |
| Webhook replay outcomes | Adequate source/contract coverage; review wording, mounted unobserved | Existing tests inspect audit event and dispatch job state for requested queue, blocked step-up, skipped/denied/failed/unknown, pre-dispatch read failure, and post-enqueue reread unknown. `[VERIFIED: accrue_admin/test/accrue_admin/live/webhook_replay_test.exs:85-115; :189-207; :391-510]` | `webhook_replay_test.exs`; extend only if chosen copy changes; assert a read retry is not replay and unknown processing is not success. |
| Home inline scope wording and “Open event ledger” | Change candidate | Link goes to `/events` under existing owner scope; visible text says “Open event ledger,” while related page vocabulary uses Events/Event log. `[VERIFIED: accrue_admin/lib/accrue_admin/live/dashboard_live.ex:39-66]` | `dashboard_live_test.exs`; assert scoped href and text accurately name Events destination. |

### Event meaning and vocabulary/destination map

| Stored value / control | Producer or effect | Suggested planning language | Boundary |
|---|---|---|---|
| `customer.updated` | Processor-backed customer update, projected locally, then event recorded | “Customer updated” (only if mounted confirmation agrees) | This records a completed local projection path; exact event key remains visible. `[VERIFIED: accrue/lib/accrue/billing.ex:973-1035]` |
| `customer.local_updated` | Local-only host maintenance update | “Customer record updated locally” | Do not imply processor update. `[VERIFIED: accrue/lib/accrue/billing.ex:1037-1064]` |
| `webhook.received` | Inbound webhook was recorded | “Webhook received” | Receipt is not processing completion. `[VERIFIED: accrue/lib/accrue/webhook/ingest.ex:129-141]` |
| `webhook.replay_requested` | Replay job was accepted/queued and request audit was recorded | “Webhook replay requested” / “queued” only as evidence supports | Not “replayed” or “processed.” `[VERIFIED: accrue/lib/accrue/webhooks/dlq.ex:141-169]` |
| Unknown event key | No checked producer semantics | Neutral “Billing event”; exact key shown | No guessed action/failure/completion. `[ASSUMED]` final fallback string is discretionary. |
| Home “Open event ledger” | Navigates to scoped `/events` list | “View events” or “Open events” | Exact final string delegated; scoped URL is authoritative. `[VERIFIED: accrue_admin/lib/accrue_admin/live/dashboard_live.ex:62-66]` |
| Event detail “Retry” / webhook “Retry” | Re-fetches current record/history | “Retry read” or “Reload history” | Must not be confused with webhook replay action. `[VERIFIED: accrue_admin/lib/accrue_admin/live/event_live.ex:59-63; accrue_admin/lib/accrue_admin/live/webhook_live.ex:96-112]` |
| “Replay webhook” | Prepares a mutation requiring existing confirmation/step-up | “Replay webhook” | This is a deliberate delivery action; don't reuse as read recovery. `[VERIFIED: accrue_admin/lib/accrue_admin/live/webhook_live.ex:134-160; accrue_admin/lib/accrue_admin/live/webhook_live.ex:236-242]` |

## Architecture Patterns

### Shared semantic mapping with exact evidence retained

**What:** Put only producer-verified known event labels in `AccrueAdmin.Copy.BillingEvent`; leave query values, persisted types and authorization untouched. Have display data carry both a readable label and exact key so detail and timeline consumers cannot lose investigation evidence. Keep unknown/missing type handling explicit.

**When to use:** Home, events list, event detail, and related activity only where the same underlying event is rendered.

**Existing seam:** `Timeline.timeline/1` renders title, time, body, detail disclosure and destination link. It currently names the disclosure “Inspect details”; if reused for exact event evidence, its summary text should identify the actual contents. `[VERIFIED: accrue_admin/lib/accrue_admin/components/timeline.ex:15-48]`

### Outcome language follows evidence

**What:** For action results, describe queue acceptance, processing, and successful completion separately. A post-mutation reread failure keeps accepted action evidence but marks processing/current status unknown. The current test proves this distinction by asserting the audit data and uncertainty copy after an accepted enqueue whose detail reread fails. `[VERIFIED: accrue_admin/test/accrue_admin/live/webhook_replay_test.exs:455-479]`

**Avoid:** Replacing distinct `retry_read`, `prepare_replay`, and `confirm_replay` effects with one generic “Retry” action. Do not create extra mutations or reads to improve wording.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Event vocabulary | Generic punctuation/title-case transform or exhaustive provider event dictionary | Small source-backed `Copy.BillingEvent` clauses and neutral unknown fallback | The producer contract varies among local mutation, processor-backed update, webhook receipt, request, and completion. |
| Activity evidence disclosure | New inspector or duplicate raw payload | Existing Timeline native `details` and EventLive detail fields/disclosure | Existing authorized data and interaction owners already exist. |
| Replay/read recovery | New retry or resend behavior | Existing read retry and replay actions with their current state/job/audit evidence | Prevents duplicate billing work and false completion claims. |

## Common Pitfalls

1. **Title casing event keys.** It makes opaque values prettier without grounding meaning and can turn “requested” into an implied completed action. Check producers and retain exact keys.
2. **Replacing exact values with labels.** Exact `event.type` is currently useful for searching/filtering and audit investigations. Keep the raw value independently visible.
3. **Calling a queue request a completed operation.** `webhook.replay_requested` and queue acceptance do not prove processing success; preserve unknown-after-reread and partial outcomes.
4. **Minute-only evidence.** Current Home and event detail format timestamps at minute precision. Capture sub-minute, timezone, missing-value cases; do not fabricate precision.
5. **Confusing read retry and replay.** Event/webhook `retry_read` re-fetches; replay controls can create a dispatch. Labels and destinations must say which.
6. **Source-only acceptance.** Phase context explicitly requires current rendered confirmation. Existing source/test results and the feedback preview README do not establish present browser output or asset identity.

## Code Examples

The following is a shape recommendation, not a locked API. Final names and mappings require current mounted confirmation. `[ASSUMED]`

```elixir
def event_label("customer.updated"), do: "Customer updated"
def event_label("customer.local_updated"), do: "Customer record updated locally"
def event_label("webhook.received"), do: "Webhook received"
def event_label("webhook.replay_requested"), do: "Webhook replay requested"
def event_label(value) when is_binary(value) and value != "", do: "Billing event"
def event_label(_), do: "Event details unavailable"
```

The raw key should still be rendered as separate evidence (for example `Event key: customer.updated`), and identifiers/timestamps must come from existing scoped records. Avoid copying raw payload to Home.

## State of the Art

No external stack or package choice is needed. This phase follows the incumbent Phoenix/LiveView, Copy module, ExUnit and browser testing patterns already used by the project. Source-backed requirements prefer actual outcome evidence and exact investigation data over visual copy polish alone.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Exact fallback label for an unknown non-empty type can be “Billing event.” | Code Examples / vocabulary map | Planner must settle final text and confirm it doesn't mislead. |
| A2 | Current feedback preview renders the source candidates described in the inventory. | Candidate inventory | The current mounted view is unobserved; the plan must inspect it before edits. |
| A3 | Native disclosure and visible exact key can satisfy touch/keyboard/selectability without changing component APIs. | Architecture Patterns | Confirm in rendered browser tests, including narrow viewport and long IDs. |

## Open Questions

1. Which of the source candidates are visible defects on the current feedback preview, and which are already corrected by shipped v1.64 work?
   - What we know: source still has raw event titles and minute-formatted timestamps in the examined checkout.
   - What's unclear: the current served revision/assets and mounted route/state output.
   - Recommendation: first planned task performs one bounded read-only review of `/admin`, Events, event detail, and webhook detail/related activity; record each as change, adequate, or unobserved with revision/route/state evidence.
2. Which additional event keys have stable, source-verified operator labels worth including?
   - What we know: producer examples above demonstrate materially different semantics.
   - What's unclear: exact in-scope event rows in the current seeded preview.
   - Recommendation: map only keys encountered on confirmed targeted surfaces; defer unseen keys to neutral fallback.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit with Phoenix.LiveViewTest; existing Playwright browser suite for mounted behavior. `[VERIFIED: accrue_admin/test/accrue_admin/live/event_live_test.exs:1-20; accrue_admin/package.json:1-18]` |
| Config file | `accrue_admin/mix.exs`; `accrue_admin/playwright.config.js` for browser tests. |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/copy/billing_event_test.exs test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhook_replay_test.exs` |
| Full suite command | `cd accrue_admin && mix test` (regression only; does not substitute for mounted browser review). |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| LANG-01 | Known producer-backed event labels render consistently while raw key remains searchable; unknown and nil types stay neutral/honest. | unit + LiveView | `cd accrue_admin && mix test test/accrue_admin/copy/billing_event_test.exs test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs` | Yes; extend these. |
| STATE-01 | Completed, queued/requested, failed, blocked, pre-dispatch unknown, and post-acceptance reread-unknown outcomes align with job/dispatch/audit evidence and safe next action. | LiveView/integration | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/event_live_test.exs` | Yes; replay tests already check these boundaries. |
| EVID-01 | Exact key, scoped record identifiers, seconds/fraction/timezone, and missing time are accessible; long identifiers remain usable. | LiveView + browser | `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/live/event_live_test.exs test/accrue_admin/live/events_live_test.exs` | Yes; add missing precision and exact evidence cases. |
| CONS-01 | Repeated names and actions agree with destination/effect; read retry cannot be mistaken for replay. | LiveView + browser | `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/live/event_live_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhook_replay_test.exs` | Yes; extend href/effect assertions. |

### Meaningful Boundary Cases

- Known key with checked producer; exact key remains available after humanization.
- Unknown non-empty key, nil/malformed key, and absent subject or actor identifiers without invented values.
- Timestamp with nonzero seconds/fraction and timezone; nil timestamp; compact Home time paired with exact detail evidence.
- Unavailable read then successful read retry; no mutation/dispatch caused by retrying observation.
- Replay requested and job accepted; blocked eligibility/step-up; explicit queue failure; mixed bulk outcomes; unclassifiable enqueue exception; pre-dispatch read unavailable; accepted enqueue followed by unreadable status.
- Destination assertions for scoped `/events`, event detail, webhook detail, and distinct read retry versus replay confirmation.
- Browser confirmation for native disclosure activation/focus, text selection/copy, long IDs at narrow width, and any affected effective light/dark and wide layout.

### Wave 0 Gaps

- Add semantic Copy mapping/fallback parity assertions if missing.
- Add event key and sub-minute timestamp assertions at the actual rendered owners.
- Add or extend browser assertions only for mounted behaviors changed (native disclosure, navigation, narrow long-ID handling, and affected theme/layout).
- No new framework or CI lane. A failing/unavailable preview observation is a confirmation checkpoint before implementation; it is not covered by these ExUnit commands.

## Security Domain

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | yes | Preserve existing Admin login and webhook replay step-up behavior. |
| V3 Session Management | yes | No session changes; maintain current LiveView authorization context. |
| V4 Access Control | yes | Keep owner-scoped reads, validated relationships, and existing destinations. |
| V5 Input Validation | yes | Display labels must not alter event filters, route parameters, or persisted keys. |
| V6 Cryptography | no change | No cryptographic code in scope; preserve webhook signature handling. |

Threat focus: leaking raw webhook payload/sensitive fields to Home, turning missing or cross-scope relationships into plausible links, or suggesting a duplicate replay after uncertain observation. Keep exact evidence inside the same authorized detail context.

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists in the repository. Relevant executable project constraints from `CLAUDE.md`: use the GSD workflow for repo changes; machine-verifiable behavior must use deterministic automated tests and not a recurring manual UAT gate; a check that finds nothing must demonstrate a positive control; do not run destructive git commands while work is uncommitted. `[VERIFIED: CLAUDE.md:198-207; CLAUDE.md:216-239]`

## Environment Availability

The only external observation dependency is the already-running local feedback preview. The supplied `http://127.0.0.1:56466/admin` URL was not available as a browser tab, and this session's browser bridge could not create/open it; mounted route output, served asset identity, revision, viewport, and theme are therefore **unobserved**. No startup, reset, reseed, or product test was run. The preview README warns that `make reset` removes the preview's volumes and says warm recovery uses the same Compose instance with `ACCRUE_HOST_SKIP_SEEDS=1 make up`; do not invoke recovery as part of a read-only first inspection. `[VERIFIED: examples/accrue_host/README.md:298-341]`

## Sources

### Primary (HIGH confidence)
- `accrue/lib/accrue/billing.ex` — processor-backed vs local customer update semantics.
- `accrue/lib/accrue/webhook/ingest.ex` and `accrue/lib/accrue/webhooks/dlq.ex` — received vs replay-requested event producers.
- `accrue_admin/lib/accrue_admin/copy/billing_event.ex`, `live/dashboard_live.ex`, `live/events_live.ex`, `live/event_live.ex`, `live/webhook_live.ex`, `components/timeline.ex` — current copy/render behavior.
- `accrue_admin/test/accrue_admin/live/*` and `test/accrue_admin/copy/billing_event_test.exs` — current automated behavior/evidence owners.
- `examples/accrue_host/README.md` — documented preview custody and safe recovery boundaries.
- `.planning/phases/244-operator-language-and-evidence/244-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `CLAUDE.md` — approved scope, test and delivery constraints.

### Secondary (MEDIUM confidence)
- No additional external sources needed. Earlier discussion linked GOV.UK, GOV.UK Design System, W3C ARIA APG and Department for Education plain-language guidance; these inform only presentation choices and do not replace repo contracts.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing owners read directly; no dependency work proposed.
- Architecture: HIGH — producer and LiveView source read directly.
- Pitfalls: HIGH — state distinctions and test evidence confirmed in source/tests.
- Mounted appearance: LOW — browser session could not open the supplied preview URL.

**Research date:** 2026-10-10  
**Valid until:** 2026-11-09 for stable source contracts; mounted status must be rechecked before planning edits.
