# Phase 244 Candidate Inventory

## Mounted confirmation before edits

**Observed:** 2026-10-11 UTC, existing feedback preview `http://accrue-host-phase243-preview.localhost/admin`, signed-in global operator session, Chrome desktop at its existing viewport, system theme. Read-only navigation covered Home, Events, event `10`, failed/dead Webhooks, and dead delivery `19100000-0000-4000-8000-00000000a008`. The checkout revision at observation was `22f725b4eb43e89567579007ca0f6db4310dbaad`. No preview data was changed.

The preview's current rendered DOM exposed no source revision or CSS/JS asset URLs through the available browser accessibility view. The browser blocked the `view-source:` scheme; no alternate access was used. Revision-bound asset identity will be captured from the isolated host browser fixture on the tested checkout revision. The mounted Home only had `customer.created` and `subscription.created` rows, so `customer.updated` itself was not present in the feedback fixture.

**Isolated resolution:** The required host Playwright fixture ran against the separate native PostgreSQL `accrue_host_test` database (preview remains on Docker volume `accrue-host_pgdata`, database `accrue_host_dev`; preview process was stopped). It used a disposable `customer.updated` event under the existing scoped organization, at `/admin/events/2961?org=accrue-e2e-alpha`, viewport 1280×900, system theme. Tested checkout revision: `5a0876f939de0bbc57a91f8a09a119e1e2b69891`. Served CSS `/admin/assets/css-b69a4acf8c2ca8f17e93e4179dd7597a`, SHA-256 `089878ed3cba5377be66c12c1958d728873d327c4666c7ec293e21cc8188633e` (129813 bytes); JS `/admin/assets/js-12dea6a487034e08eb55a389ec473a5a`, SHA-256 `36974c751ef3c9df6f40a2ff7fa09c04d85819dac2de74804d8438f6c3be3085` (161130 bytes). Served, package, and compiled asset bytes matched. The browser confirmed the Home label, scoped event route, exact stored key, customer ID, and `2026-10-10T23:59:59.123456Z` detail time.

## Bounded candidate dispositions

| Candidate / route and observed state | Disposition | Mounted evidence | Owning source and test |
|---|---|---|---|
| Home recent activity, `/admin`, rows 11–6 | **Change** | Titles are raw `subscription.created` / `customer.created`; body has scoped record type and ID; each row links to event detail. The target `customer.updated` key is absent from this preview. | `accrue_admin/lib/accrue_admin/live/dashboard_live.ex`; `accrue_admin/test/accrue_admin/live/dashboard_live_test.exs` |
| Home destination, `/admin` | **Change** | “Open event ledger” points to `/admin/events`; destination is the Events list. | `dashboard_live.ex`; `dashboard_live_test.exs` |
| Events list, `/admin/events`, mixed seeded rows | **Change** | Event cell displays raw types (including `customer.created`, `subscription.created`, `dunning.recovered`); exact keys and scoped row links are present. Visible timestamps show minute precision. | `accrue_admin/lib/accrue_admin/live/events_live.ex`; `accrue_admin/test/accrue_admin/live/events_live_test.exs` |
| Event detail, `/admin/events/10?return=%2Fadmin%2Fevents` (`customer.created`) | **Change** | Raw type appears in title/breadcrumb/fields; subject ID and linked customer are visible; Recorded and Recorded time show `Oct 10, 2026 18:38 UTC` (minute precision). Payload and Activity use existing disclosures. | `accrue_admin/lib/accrue_admin/live/event_live.ex`; `accrue_admin/test/accrue_admin/live/event_live_test.exs` |
| Related webhook activity, `/admin/webhooks/19100000-0000-4000-8000-00000000a008` (Dead; zero derived events) | **Unobserved** | The mounted record has zero derived events, so it cannot establish event-label parity or outcome wording for related activity. Delivery status remains explicitly separate from derived-event count. | `accrue_admin/lib/accrue_admin/live/webhook_live.ex`; `accrue_admin/test/accrue_admin/live/webhook_live_test.exs` |
| Event read unavailable/retry | **Unobserved** | No read failure was induced in the preserved feedback preview. Source branch states identity/evidence are unknown until read succeeds; “Retry” re-reads. | `event_live.ex`; `accrue_admin/test/accrue_admin/live/event_live_test.exs` |
| Replay outcome branches | **Unobserved** | No replay action was taken in the feedback preview. Existing route showed a replay-eligible Dead delivery, but queueing it would mutate preview state. | `accrue_admin/lib/accrue_admin/live/webhook_live.ex`; `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs` |

## Vocabulary and destination map

| Stored value / control | Meaning supported by producer or route | Operator wording | Exact evidence / destination boundary |
|---|---|---|---|
| `customer.updated` | Processor-backed customer update is projected locally and records this event in the same transaction. | Customer updated | Keep exact event key, linked record ID, and full recorded time available in scoped event detail. |
| `customer.local_updated` | Local-only host maintenance update. | Customer record updated locally | Must not imply a processor update. |
| `webhook.received` | Inbound webhook delivery was recorded. | Webhook received | Receipt is not processing completion. |
| `webhook.replay_requested` | Replay request accepted/queued and request audit recorded. | Webhook replay requested | Request is not processing success. |
| Unknown nonempty key | No checked producer semantics. | Billing event | Exact raw key remains selectable/searchable. |
| Missing/malformed event key or timestamp | No key/time evidence is available. | Event details unavailable / Time unavailable | Never fabricate an ID, key, or current time. |
| Home Events action | Routes to scoped `/admin/events`. | View events | Keep existing owner scope. |
| Event “Retry” | Re-fetches event read. | Retry read | Does not replay a webhook. |
| “Replay webhook” | Existing explicit delivery mutation. | Replay webhook | Preserve existing confirmation, step-up, job and audit evidence. |

## Source contracts

- `customer.updated` producer: `accrue/lib/accrue/billing.ex:973-1035`.
- Local customer update producer: `accrue/lib/accrue/billing.ex:1037-1064`.
- Webhook receipt and replay request producers: `accrue/lib/accrue/webhook/ingest.ex:129-141`; `accrue/lib/accrue/webhooks/dlq.ex:141-169`.
- Feedback-preview preservation boundary: `examples/accrue_host/README.md:298-341`. The preview's sentinel, dispatch, audit and database custody were left untouched.

