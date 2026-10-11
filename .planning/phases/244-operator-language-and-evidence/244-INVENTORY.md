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

## Plan 244-03 final confirmation

**Tested revision:** checkout `36f69a5a3a5a5732d54fa9629f72bbc8d62f481c` (the task-1 implementation commit). The browser spec state was additionally bound by `ownerSpecSha256=e698c1600b5cdcabd32e1da9ff57bdc29058007f28c8932a186f22b55deb044a`; the running browser verified this exact spec against that checkout. Fixture: disposable `HOST-BROWSER-VERIFY01`, scoped to `accrue-e2e-alpha`; seeded `customer.updated` evidence links to the existing Dead webhook. Preview custody remained unchanged and stopped; tests used only the isolated native PostgreSQL `accrue_host_test` database and proof server on port 4101.

| Final candidate / state | Disposition | Rendered and durable evidence | Owner |
|---|---|---|---|
| Home → Events | **Change confirmed** | “View events” href and click both resolve to `/admin/events?org=accrue-e2e-alpha`. | `dashboard_live.ex`; `phase244-operator-evidence.spec.js` desktop assertion |
| Home customer activity → event detail | **Change confirmed** | Scoped link opened `/admin/events/3017?org=accrue-e2e-alpha`; exact `customer.updated` key, customer ID and `2026-10-10T23:59:59.123456Z` were visible. | `dashboard_live.ex`, `event_live.ex`; desktop assertion |
| Webhook related activity → event detail → source webhook | **Adequate, confirmed** | Both desktop and touch runs opened exact scoped routes. Desktop: webhook `94c244c5-8a1f-44ed-b05e-b4f255be8e46`, event `3018`; mobile: webhook `12699534-4c5a-4e2c-9bca-200de275cb9b`, event `3021`. Stored event key, event ID, actor, subject, webhook ID and full recorded time were present; reverse source-webhook href retained organization scope. | `webhook_live.ex`, `event_live.ex`; desktop/mobile assertions |
| Replay confirmation → step-up | **Adequate, confirmed** | Before confirmation the drawer identified seeded processor event `evt_host_browser_replay`. Confirm opened “Step-up required”; before cancellation the durable facts remained status `dead`, one pre-existing `discarded` dispatch job, and no replay-request or replay-completed audit event. The before/after state/job/event fact records were identical. No replay was dispatched. | `webhook_live.ex`; replay tests and desktop/mobile browser assertions |
| Accepted replay and failed follow-up read; read-retry handler | **Change confirmed in focused LiveView tests; browser state unobserved** | Focused tests verify accepted queue/job remains accepted while current status is unknown after failed reread, and `Retry read` only rereads without another dispatch. No read outage was induced in the mounted host browser; the browser proof does not claim this state was rendered. | `webhook_live.ex`, `event_live.ex`; `webhook_replay_test.exs`, `webhook_live_test.exs`, `event_live_test.exs` |
| Unknown STATE-01 edge | **Unobserved / unresolved** | The plan's edge probe remains unclassified. No check or meaning was fabricated; verifier review is required. | Independent verification |

**Browser runs:** the final desktop subset passed 2/2 at 1280×900; the final touch subset passed 1/1 at 320×800 with `isMobile` and `hasTouch`. Both used the `chromium-desktop` project as the narrow touch settings live in the named test. System theme rendered in the desktop event-route assertion; webhook evidence was checked with both `light` (`--ax-base #FAFBFC`, `--ax-primary #111418`) and `dark` (`--ax-base #0f1318`, `--ax-primary #f4f7fa`) tokens. The main touched-view route was `/admin/webhooks/{fixture-id}?org=accrue-e2e-alpha`, with event detail `/admin/events/{event-id}?org=accrue-e2e-alpha`.

**Asset identity:** CSS browser URL `/admin/assets/css-6ebaf9c9f37c09482f27a19c7df02b0b`, SHA-256 `b40ac1dc7bb6a09ac7bccedb10ac1856ea9cbad212d69ce11db054a22807b952` (129964 bytes); JavaScript browser URL `/admin/assets/js-bda4f3f51aa85229e5eae0b9ebef2ea7`, SHA-256 `e228bac9b978a658b37e96b9aa833fe6e8a87358447d00d93e616f55f5667c26` (161648 bytes). For both assets, the HTTP response, checked-in package file, and isolated compiled proof-build bytes matched. This identifies what the browser actually received; it does not claim CSS/JS source changes in this plan.

**First failures and recovery:** the first desktop batch passed the Home route test but exposed tuple serialization in the new read-only job-fact helper. After changing its select result to JSON-safe maps, the drawer assertion exposed that the rendered confirmation names the processor event ID rather than the internal database UUID; the assertion was corrected to the seeded visible processor ID. The final desktop confirmation then passed 2/2. The first mobile startup exceeded the configured 120-second clean proof-build limit; the partial build was reused under the same isolated proof ID after confirming the stale PID marker's process was absent, and the final mobile test passed 1/1. No preview process or database was started or changed. Full Admin regression: `cd accrue_admin && mix test` — 688 tests, 0 failures.

**Final vocabulary and destination map:** “View events” → scoped Events list; “Open event” → scoped exact event detail; “Retry read” → read-only event/history refetch; “Replay webhook” → explicit confirmation then existing step-up boundary; “Webhook replay requested” → accepted request only, not delivery success. Stored event keys and exact evidence remain available at scoped detail. Existing `Copy.Locked` phrases remain unchanged.

**Verifier flags retained (not mechanically proved):** `STATE-01` edge classification is unclassified. The three descriptor-less prohibitions remain unresolved: (1) do not imply a replay was processed/completed when evidence proves only request/queue acceptance; (2) do not invite another billing mutation as a generic retry while post-acceptance observation is uncertain; (3) do not expose raw payload or sensitive fields on Home while making exact authorized evidence discoverable. Independent verifier review remains required.

