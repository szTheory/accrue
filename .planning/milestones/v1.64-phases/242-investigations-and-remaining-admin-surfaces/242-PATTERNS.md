# Phase 242: Investigations and Remaining Admin Surfaces - Pattern Map

**Mapped:** 2026-10-10  
**Files analyzed:** likely implementation and proof owners grouped by existing family (planner confirms exact edits)  
**Analogs found:** all identified owners have a tracked incumbent

Scope comes from 242-CONTEXT.md D-01–21 and 242-RESEARCH.md Validation Architecture / Requested source files, narrowed by 242-UI-SPEC.md named surfaces. Phase 240/241 contracts are incumbent; final Linux goldens and stable Fake-backed preview are Phase 243. This map records source patterns only; mounted/browser/runtime claims require fresh evidence in execution.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/scoped_path.ex` | utility | transform / request-response | same file; `scoped_path_test.exs` | exact |
| `accrue_admin/lib/accrue_admin/queries/events.ex`, `webhooks.ex`, `coupons.ex`, `promotion_codes.ex`, `connect_accounts.ex` | utility (query) | request-response | same family modules and tests | exact |
| `accrue_admin/lib/accrue_admin/live/events_live.ex`, `webhooks_live.ex`, `coupons_live.ex`, `promotion_codes_live.ex`, `connect_accounts_live.ex` | controller (LiveView) | request-response | corresponding collection LiveView; `EventsLive` | exact |
| `accrue_admin/lib/accrue_admin/live/event_live.ex`, `webhook_live.ex`, `coupon_live.ex`, `promotion_code_live.ex`, `connect_account_live.ex` | controller (LiveView) | request-response | corresponding detail LiveView; `EventLive` / `PromotionCodeLive` | exact |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | component | request-response / async | same file; `global_search_test.exs` | exact |
| `accrue_admin/assets/js/hooks/command_palette.js` | utility (hook) | event-driven | same hook; `command_palette_test.mjs` | exact |
| `accrue_admin/lib/accrue_admin/live/dashboard_live.ex`, `components/app_shell.ex`, `components/sidebar.ex`, `components/topbar.ex` | controller / components | request-response | same shell and dashboard modules | exact |
| `accrue_admin/lib/accrue_admin/copy.ex`, `copy/billing_event.ex`, `copy/coupon.ex`, `copy/promotion_code.ex`, `copy/connect.ex` | utility (copy) | transform | same Copy families | exact |
| `accrue_admin/lib/accrue_admin/copy/locked.ex` | utility (locked copy) | transform | same module and contract tests | exact |
| `accrue_admin/test/accrue_admin/scoped_path_test.exs`, `test/accrue_admin/queries/events_test.exs`, family LiveView tests | test | request-response | same tests | exact |
| `accrue_admin/test/accrue_admin/live/{events_live,event_live,webhooks_live,webhook_live,coupons_live,coupon_live,promotion_codes_live,promotion_code_live,connect_accounts_live,connect_account_live,webhook_replay}_test.exs` | test | request-response | corresponding route tests | exact |
| `accrue_admin/test/accrue_admin/components/global_search_test.exs`, `accrue_admin/test/js/command_palette_test.mjs` | test | event-driven / async | same test owners | exact |
| `accrue_admin/test/accrue_admin/copy/billing_event_test.exs`, `connect_test.exs` and existing Copy tests | test | transform | corresponding Copy tests | exact |
| `accrue_admin/e2e/admin-page-flow-phase191.spec.js`, `admin-interaction-overlay-phase199.spec.js`; `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js`, `phase234-search-completion.spec.js` | test (browser) | request-response / event-driven | corresponding incumbent mounted scenarios | role-match |

All analogs named above are git-tracked. The tracked-source gate was checked with `git ls-files` for the source, test and host E2E paths; no `.gsd` mirror paths are cited.

## Pattern Assignments

### Scoped list return: five destination families

**Analog:** `accrue_admin/lib/accrue_admin/scoped_path.ex` (tracked)

Use the existing validated destination API and its pair contract. Add finite route/key allowlist and safe fallback entries for Events, Webhook Deliveries, Coupons, Promotion Codes and Connect. Keep decoder/encoder parity grounded in each destination query decoder; don't preserve unconsumed query values. The API rebuilds with current mount/owner and derives label from the same suffix/params.

**Validated path/label pattern** (lines 78–109):
```elixir
def return_destination(mount_path, raw_return_path, owner_scope, expected_customer_id, fallback_suffix)
    when is_binary(mount_path) and is_binary(fallback_suffix) do
  case validate_return_path(mount_path, raw_return_path) do
    {:ok, suffix, params} -> destination(mount_path, suffix, params, owner_scope)
    :error -> destination(mount_path, fallback_suffix, %{}, owner_scope)
  end
end

defp destination(mount_path, suffix, params, owner_scope) do
  %{path: build(mount_path, suffix, owner_scope, params), label: return_label(suffix, params)}
end
```

**Validation boundary** (lines 140–159, 163–183): rejects external/scheme-relative URLs, fragments, backslashes, malformed escapes and duplicate keys; only allowed keys survive. Caller owner is never trusted: rebuilt output uses `owner_scope`. Add the five family labels alongside current labels, preserving label/path identity. Where a relationship return is allowed, enforce matching detail identity like the existing expected-customer behavior (lines 91–103), rather than accepting a foreign relation.

### Query decoders and collection list/detail consumers

**Tracked analogs:** `accrue_admin/lib/accrue_admin/queries/events.ex`, `webhooks.ex`, `coupons.ex`, `promotion_codes.ex`, `connect_accounts.ex`; matching collection/detail LiveViews and tests.

**Event query core** (`queries/events.ex`, lines 60–87):
```elixir
def list(opts \\ []) do
  filter = Keyword.get(opts, :filter, %{})
  limit = Behaviour.normalize_limit(opts)
  cursor = Behaviour.decode_cursor(opts)
  owner_scope = Keyword.get(opts, :owner_scope)
  query = Event |> filter_query(filter) |> Behaviour.apply_cursor(@time_field, cursor)
  case owner_scope do
    %OwnerScope{mode: :organization} = scope ->
      query |> organization_page(scope, limit) |> Behaviour.paginate(limit, @time_field)
    _ -> query |> scope_query(owner_scope) |> limit(^Enum.max([limit + 1, 2]))
             |> select_event_rows() |> Repo.all() |> Enum.map(&Map.delete(&1, :data))
             |> Behaviour.paginate(limit, @time_field)
  end
end
```

Preserve each of the five current decoders' exact supported filter/lens keys, normalization and scope flow. UI-SPEC examples are not exhaustive allowlists. Collection LiveViews follow `EventsLive`: aliases to query/copy/shared components; `mount/3` resolves admin shell and owner scope, builds owner-scoped list/table paths, then `handle_params/3` assigns parsed params and refreshes data; filter events patch through `DataTableNav.patch_with_filters/3`. See `events_live.ex` lines 1–69. Verify actual filtered row membership in query and LiveView fixtures. Retain distinct initial empty, filtered empty, partial and unavailable states.

**Detail/read/evidence pattern:** `event_live.ex` lines 20–55 distinguishes unavailable, not found/inaccessible, and successful scoped reads; successful mount assigns exact related items and initializes lazy activity/raw flags. Lines 58–90 repeat the read on explicit retry, preserve unavailable state, and route inaccessible reads through locked owner denial. Render uses summary facts then details/disclosure (`event_live.ex` lines 121–154). Coupon, promotion-code, webhook and Connect details are closer family-specific analogs for parent, delivery, and fee policy relations; preserve each link only when the scoped relation is actually available. Do not fabricate reciprocal links for missing/inaccessible relations.

### Webhook delivery replay and selected set

**Analogs:** `accrue_admin/lib/accrue_admin/live/webhooks_live.ex`, `webhook_live.ex`; supporting tracked proof owner `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs`.

**Bulk review/safety pattern** (`webhooks_live.ex`, lines 115–164): dismissal clears pending review; confirmation consumes the already-captured `ids`, routes through `StepUp.require_fresh/3`, then executes against freshly read owner-scoped rows and reports the result. `replay_scoped_rows/2` (lines 166–240) distinguishes selected/eligible/attempted/queued/skipped/failed and records row-level outcomes; inaccessible rows skip and failed reads remain failures. Retain exact selected IDs across review and refuse silently changed selection/scope.

**Single replay pattern** (`webhook_live.ex`, lines 122–151, 561–608): prepare only when current eligibility is allowed, cancel just clears drawer; confirm uses fresh step-up; execution rereads `Webhooks.detail/2`, rechecks `replayable?/1`, calls existing `DLQ.requeue` behind an owner predicate, then records/refreshes. Distinguish enqueue acknowledgment from processing success and preserve unknown/reread-failure outcomes. Locked audit/result language belongs to `Copy.Locked`, not view-local rewrites.

### Coupon, promotion-code and source relationship details

**Analogs:** `coupon_live.ex` and `promotion_code_live.ex` (tracked). Promotion-code parent links are identity-bound: `promotion_code_live.ex` lines 144–163 conditionally link `@promotion_code.coupon.id`; when the parent isn't present, render the explicit missing-parent body. Coupon's reciprocal related resources (`coupon_live.ex` lines 407–423) build owner-scoped list paths and constrain its event path by `subject_type` and `subject_id`. Keep the resource types exact and list context bounded; no arbitrary detail-origin stack. These views use lazy activity/raw data disclosures and family-specific Copy owners.

### Connect local fee policy review

**Analog:** `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` (tracked).

`mount/3` loads under current owner and assigns account, related items and closed disclosure/review state (lines 30–55). Fee form changes run `apply_override_preview/2`; save reuses that validation, captures the validated payload, and asks `StepUp.require_fresh/3` with an account-bound action (lines 58–103). The existing form uses explicit percent/fixed/min/max/preview input labels and `phx-change` + `phx-submit` (`connect_account_live.ex` lines 378–428). Keep Stripe readiness/capability as stored provider observations; fee policy is local. Existing policy summary fields and default-vs-override logic are the semantics owner. Dismissal clears pending state without save. Do not move fee/domain validation into HEEx or copy billing into a generalized action framework.

### Global search: async generation, scope and active result

**Analogs:** `accrue_admin/lib/accrue_admin/components/global_search.ex`, `assets/js/hooks/command_palette.js`; tracked tests `global_search_test.exs` and `command_palette_test.mjs`.

LiveComponent search increments a generation, captures query and owner, runs bounded result lookup asynchronously, and accepts updates only if generation, query and current owner all still match (`global_search.ex` lines 40–60, 115–140). Owner change clears query/results/failures and advances generation (lines 62–79); retry runs current query. Preserve three existing groups and partial successes.

The hook owns focus containment/restoration and key navigation (`command_palette.js` lines 4–70, 84–95, 151–180). The current `updated()` resets `activeIndex` to 0 and `setupItems()` derives item list; Arrow keys update active index and class, while Enter activates that item. Pointer hover currently has no corresponding active-index reconciliation in this source. This is a source observation to guide implementation, not a claim about current mounted behavior. Make pointer, arrows, visible active state, accessible semantics and Enter use one selected actual result after patch/replacement; respect real anchor/link semantics.

### Home, navigation and Copy owners

**Analogs:** tracked `dashboard_live.ex`, `components/app_shell.ex`, `sidebar.ex`, `topbar.ex` are their own incumbents. Preserve their existing static route families/current Home composition and owner-aware path builder. Do not infer runtime-active navigation correctness from source alone; route/state coverage and mounted consumer fixtures are the proof owners.

Copy work belongs to `copy.ex` and family modules `copy/billing_event.ex`, `copy/coupon.ex`, `copy/promotion_code.ex`, `copy/connect.ex`; use exact model/provider terms in diagnostic slots, operator vocabulary in routine strings. `copy/locked.ex` is immutable contractual wording. Concrete example (`copy/locked.ex`, lines 22–38):
```elixir
def replay_drawer_title, do: "Confirm webhook replay"

def single_replay_confirmation(webhook_id, opts) do
  owner_scope = opts |> Keyword.get(:owner_scope, "the active organization") |> to_string()
  "Replay webhook #{webhook_id} for #{owner_scope}: This will requeue the webhook delivery and record an admin audit event. Confirm replay."
end
```

### Proof owners and fixtures

Use existing focused owners listed in `242-RESEARCH.md` Validation Architecture: `scoped_path_test.exs`; Events query test plus each existing family list/detail LiveView test; `webhook_replay_test.exs`; Connect LiveView + Copy tests; `global_search_test.exs` + Node `command_palette_test.mjs`; tracked family Copy tests. There are not separate query-test files for every family in the current test tree; extend the incumbent consumer owner. Mounted consumer owners are tracked `accrue_admin/e2e/admin-page-flow-phase191.spec.js`, `admin-interaction-overlay-phase199.spec.js` and host `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js`, `phase234-search-completion.spec.js`. Existing host fixture owners are not a license to add a parallel registry or claim current mounted results. Build package assets and record source, fixture, compiled/built and served-byte provenance separately from exercised behavior. Phase 243 retains final reviewed Linux goldens/feedback preview.

## Shared Patterns

### Fresh owner and mount scope

**Source:** `accrue_admin/lib/accrue_admin/scoped_path.ex`; collection/detail LiveViews. Derive scope from Admin's already-resolved shell/session. Construct list, relation, and return destinations from configured mount plus current owner. Never accept URL owner as authority. Inaccessible reads/relationships remain inaccessible and must not yield plausible unrelated links.

### Truthful state and domain language

**Source:** family `Copy` modules, `Copy.Locked`, and detail LiveViews. Keep event ≠ webhook delivery ≠ replay enqueue ≠ resulting billing event. Preserve exact diagnostics, model identifiers and locked replay/audit text. Distinguish unavailable from no records and filtered no-match. Don't infer freshness from Connect observation fields.

### Validation and mutation boundary

**Source:** `webhook_live.ex`, `webhooks_live.ex`, `connect_account_live.ex`. Presentation can preview and explain, while final owner/eligibility/target/actor checks, step-up, duplicate guard, persistence and audit remain in incumbent mutation owners. A dismissed review clears pending state; it cannot dispatch.

## No Analog Found

None for the scoped implementation/proof candidates. Search pointer synchronization is an extension of an existing hook; use that incumbent, while verifying actual behavior under the existing mounted fixture.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/{live,queries,components,copy}`, `accrue_admin/assets/js/hooks`, package tests/E2E, and `examples/accrue_host/e2e`.  
**Files scanned:** targeted named source owners and their owner tests; stopped after matching family analogs.  
**Tracked-path check:** `git ls-files -- <path>` returned each cited source/test path; all referenced files are tracked.  
**Pattern extraction date:** 2026-10-10
