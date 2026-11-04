# Phase 252: Production-backed Subscription Stories - Pattern Map

**Mapped:** 2026-10-26
**Files analyzed:** 17 implementation/test responsibilities
**Analogs found:** 14 / 17 (several are partial matches; missing analogs are called out below)

All analog paths below were verified with git ls-files and are tracked source. No installed dependency source or ignored runtime mirror is named. There is no root AGENTS.md and CLAUDE.md reports no project skills. The approved requirements, 252-RESEARCH.md and 252-UI-SPEC.md are the scope authority. New root/module filenames left open by research are labeled as planner choices.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| accrue_admin/lib/accrue_admin/live/subscription_live.ex | LiveView/controller | request-response | same module; accrue_admin/test/accrue_admin/live/subscription_live_test.exs | exact |
| accrue_admin/lib/accrue_admin/components/<subscription summary area>.ex (if extracted as a new module) | component | transform, request-response render | accrue_admin/lib/accrue_admin/components/detail.ex | role-match |
| storybook/components/subscription_detail.story.exs | component/story | transform, request-response render | same story (current static copy is an anti-pattern); accrue_admin/e2e/admin-storybook-a11y-phase200.spec.js | role-match |
| dev_support/ui_scenarios/<subscription facts source>.exs (root/path is a planning choice) | model/utility | transform | none | none |
| storybook/_support/<scenario adapter>.ex or test/support/<scenario adapter>.ex | utility | transform | storybook/components/subscription_detail.story.exs | partial |
| accrue_admin/test/<scenario validation test>.exs | test | transform | accrue/test/accrue/billing/subscription_test.exs | role-match |
| accrue_admin/test/<scenario Repo test>.exs and optional test/support/<Repo adapter>.ex | test/utility | CRUD, database I/O | accrue_admin/test/accrue_admin/live/subscription_live_test.exs | role-match |
| storybook/_support/<coverage manifest>.ex and its ExUnit contract test | utility/test | transform | accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs | role-match |
| accrue_admin/e2e/<subscription story render spec>.spec.js | test | request-response, browser render | accrue_admin/e2e/admin-storybook-a11y-phase200.spec.js | role-match |
| accrue_admin/test/support/e2e_server.ex | utility | process, database, HTTP I/O | same module | exact |
| accrue_admin/playwright.config.js | config | process, HTTP request-response | same config | exact |
| accrue_admin/test/<lab preflight/reset isolation test>.exs | test | process, database I/O | accrue_admin/test/accrue_admin/live/subscription_live_test.exs | partial |
| examples/accrue_host/priv/repo/seeds/phase248_cleanup_edge.exs and its cleanup contract test | utility/test | CRUD, database I/O | same seed; scripts/ci/phase248_heldout_isolation.test.mjs | role-match |
| accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs and accrue_admin/mix.exs | test/config | package, compile and route boundaries | same test and config | exact |
| scripts/ci/verify_phase252_ci_contract.test.mjs (name proposed in research) and .github/workflows/ci.yml | test/config | path classification, workflow admission | scripts/ci/verify_phase200_ci_contract.sh; same workflow | role-match |

Keep DB-free story rendering, disposable-Repo conformance and DB-backed endpoint startup as separate proof lanes. A story adapter should not grow into a shared fixture framework. Paths in angle brackets above are planner choices, not locked filenames.

## Pattern Assignments

### Production subscription area

**Files:** accrue_admin/lib/accrue_admin/live/subscription_live.ex; new production summary/facts/actions component if extracted.

**Analogs:** accrue_admin/lib/accrue_admin/live/subscription_live.ex (production renderer and eligibility owner); accrue_admin/lib/accrue_admin/components/detail.ex (reusable HEEx building blocks).

The existing LiveView composes the actual title/status/ID and summary list. Keep Copy, ScopedPath, lifecycle and action eligibility in the production path; the story should provide real Subscription and Customer assigns to that renderer.

**Production composition** (subscription_live.ex, lines 287-301):

~~~elixir
        <Detail.summary_card
          title={subscription_title(@subscription, @customer)}
        >
          <:status>
            <StatusBadge.status_badge status={@subscription.status} label={lifecycle_health_label(@subscription)} tone={lifecycle_tone(@subscription.status)} />
          </:status>
          <:facts>
            <IdBadge.id_badge id="subscription-summary-id" id_value={@subscription.processor_id || @subscription.id} label="Copy subscription ID" copy_label="subscription ID" variant="plain" />
          </:facts>
        </Detail.summary_card>

        <Detail.summary_list
          rows={summary_rows(@subscription, @customer, @admin_mount_path, @current_owner_scope)}
          class="ax-summary-list-compact"
        />
~~~

**Summary row data** (same file, lines 846-886): summary_rows/4 starts with production lifecycle and setup-gap rows, then customer, plan/price, period, cancellation, renewal/end and MRR facts. It builds the customer link with ScopedPath.build/3 and hidden action context with Copy.action_hidden_context/2. Preserve optional quantity and dunning additions at lines 889-892. “Unavailable” values and ordered caveats stay sourced from production projection helpers per the UI contract.

**Action presentation and eligibility** (same file, lines 317-349 and 1478-1508):

~~~elixir
              <button
                :if={action_available?(@subscription, "swap_plan")}
                type="button"
                class="ax-button ax-button-primary"
                phx-click="open_action_drawer"
                phx-value-action_type="swap_plan"
                data-ax-primary-action
                aria-label={action_aria_label("swap_plan", @subscription)}
              >
                <%= action_label("swap_plan") %>
              </button>
              <DropdownMenu.action_menu
                label="More actions"
                groups={action_menu_groups(@subscription)}
                id="subscription-action-menu"
              />
~~~

action_available?/2 delegates swap-plan to swap_plan_available?/1; cancellation requires non-Braintree, active, not canceled and not canceling; resume requires a non-Braintree paused or canceling subscription. Keep those decisions in the production owner when extracting the area; do not re-implement eligibility in story data or templates.

**Reusable semantic component** (components/detail.ex, lines 73-99): Detail.summary_list/1 renders a dl, rows as dt/dd, and an action only when it has a label and href/event. Its visually hidden context follows the visible action label once. summary_card/1 at lines 115-127 provides the h1, status slot and facts slot. Reuse these semantics rather than copying markup.

**Copy and owner-scoped links:**

~~~elixir
# accrue_admin/lib/accrue_admin/copy.ex, lines 194-200
def action_hidden_context(action_label, opts) do
  resource = option(opts, :resource, "billing record")
  object = option(opts, :object, "this record")

  "#{String.trim(to_string(action_label))} #{resource} for #{object}"
end
~~~

~~~elixir
# accrue_admin/lib/accrue_admin/scoped_path.ex, lines 47-67
def build(mount_path, suffix, owner_scope, params \\ %{})

def build(mount_path, suffix, %OwnerScope{} = owner_scope, params) do
  build(mount_path, suffix, Map.from_struct(owner_scope), params)
end

def build(mount_path, suffix, %{mode: :organization, organization_slug: slug}, params)
    when is_binary(slug) do
  mount_path <> suffix <> "?" <> URI.encode_query(Map.put(params, "org", slug))
end
~~~

The detail currently passes mount path and current_owner_scope to scoped links and summary rows. Preserve that interface. The UI contract fixes hidden context for plan and renewal Change links; apply the shared Copy builder once per action, without changing global copy.

### Subscription story and variation proof

**Files:** storybook/components/subscription_detail.story.exs; coverage manifest/contract; focused Playwright spec.

**Story analog:** storybook/components/subscription_detail.story.exs, lines 17-39, declares variations, while lines 42-89 build local summary rows/action groups and static customer/date facts. Those local rows, provider pruning and hard-coded actions describe the current mismatch; replace them with stable IDs active, scheduled_cancellation and incomplete_evidence, scenario-backed records and the production area. Do not copy the fake markup or story-local eligibility.

**Coverage contract analog:** accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs, lines 11-43 derives expected rows from the live registry and checks variation IDs, DOM IDs and applicable/N/A states rather than hard-coding a total. Use the derived-contract style for the new map/manifest, adding reachable, uncovered and not-applicable states and visible gaps.

**Rendered browser analog:** accrue_admin/e2e/admin-storybook-a11y-phase200.spec.js, lines 25-45 discovers mounted Storybook URLs, visits each URL, verifies assets and asserts actual Storybook content is visible for each theme. Its helper is accrue_admin/e2e/phase200-storybook-helpers.js, lines 19-59. This is a useful browser/render pattern, but it discovers links in the DOM; it does not yet reconcile compiled story variations or prove every direct variation URL.

The tracked codebase has no analog for a manifest generated from the compiled PhoenixStorybook tree plus each actual variation ID. Treat installed package APIs mentioned in 252-RESEARCH.md as technical guidance, not tracked source analogs. The generated manifest must retain actor, job, facts source, production renderer and static-render proof lane; browser assertions must load every direct URL and see its expected scenario identity in rendered content. Metadata alone is insufficient. The approved UI spec requires 3 states x 2 explicit widths (320 and 1280 CSS px) x 2 themes, with evidence per case (12 cases).

### Scenario facts and domain validation

**Files:** new root DB-free subscription fact source; narrow story/test/seed adapters; pure scenario validator/tests.

There is no existing plain shared UI scenario source in the package or Storybook tree. Keep new facts outside production compile/package roots as required by SCEN-01/LAB-02. Research leaves the exact root and module open. Facts need stable string IDs, actor, billed owner, provider, lifecycle, fixed clock and subscription item data. Existing test Factory data is DB-backed and is not a substitute for the shared DB-free facts source.

**Domain rule owners:** accrue/lib/accrue/billing/subscription.ex, accrue/lib/accrue/money.ex, accrue/lib/accrue/processor/capabilities.ex and accrue/lib/accrue/clock.ex.

~~~elixir
# accrue/lib/accrue/billing/subscription.ex, lines 124-132
def changeset(subscription_or_changeset, attrs \\ %{}) do
  subscription_or_changeset
  |> cast(attrs, @cast_fields)
  |> validate_required(@required_fields)
  |> Metadata.validate_metadata(:metadata)
  |> optimistic_lock(:lock_version)
  |> foreign_key_constraint(:customer_id)
end
~~~

Subscription.statuses/0 is the canonical enum list (lines 117-119); call it rather than copying enum values into fixture-only policy. The production canceling?/1 predicate (lines 177-194) compares period end against Accrue.Clock.utc_now/0. Set the Fake clock before validation/rendering of scheduled cancellation.

~~~elixir
# accrue/lib/accrue/money.ex, lines 49-67
def new(amount_minor, currency)
    when is_integer(amount_minor) and is_atom(currency) do
  _ = exponent!(currency)
  %__MODULE__{amount_minor: amount_minor, currency: currency}
end

def new(amount, _currency) when is_float(amount) do
  raise ArgumentError, "Accrue.Money.new/2 does not accept floats ..."
end
~~~

Use integer minor units and supported currency atoms. Provider/action decisions use Capabilities.support_label/1 and supports?/2; its labels distinguish native, bounded first-party, testing/local-only and unsupported cases (capabilities.ex, lines 70-105, 170-180). Add only cross-record/chronology checks that domain owners do not provide. Invalid enum, orphan, provider, amount and timestamp controls must fail before rendering.

**Test style analog:** accrue/test/accrue/billing/subscription_test.exs is the nearest domain ExUnit convention. Keep pure validation cases database-free and explicit per invariant; do not make the shared fact module depend on Repo or Admin/Storybook.

### Disposable Repo proof and cleanup

**Files:** narrow scenario persistence adapter and Repo integration test; update held-out cleanup negative control.

**Repo test analog:** accrue_admin/test/accrue_admin/live/subscription_live_test.exs, lines 53-81, uses Accrue.Test.Factory, updates through TestRepo, and preloads customer/subscription items before the test. This is DB-backed setup, not the requested shared-facts adapter. Keep the new adapter limited to insert/reload; assert customer -> subscription -> item relationships after reloading and prove an invalid relationship is rejected by the actual DB.

**Schema constraint source:** accrue/priv/repo/migrations/20260412100002_create_accrue_billing_schemas.exs, lines 51-85 makes subscription customer_id required and unique processor/processor_id; lines 89-119 makes item subscription_id required and adds the per-processor ID unique index. Use real migrations in an explicitly disposable TestRepo lane.

**Guarded cleanup source:** examples/accrue_host/priv/repo/seeds/phase248_cleanup_edge.exs, lines 7-18 requires the held-out lane and checks DB/role/address against OrdinarySeedBoundary. Lines 56-77 checks each expected child owner and aborts if the customer has a child outside the exact owned ID set, then lines 79-81 delete only those owned rows. Preserve these environment/database and exact-child checks.

**Negative-test style:** scripts/ci/phase248_heldout_isolation.test.mjs, lines 31-43 asserts an invalid sandbox setting rejects before any fixture operation; lines 45-70 checks setup/cleanup ordering. Extend the real cleanup proof with an unrelated child and assert both refusal and row preservation. The current contract test alone does not prove row preservation.

### Storybook registry and actual variation routes

**Files:** new development/test-only manifest generator and manifest contract test; new Playwright direct-route render spec.

Use accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs as the derived-registry contract pattern and the Phase 200 browser spec above for authenticated mounted route and rendered-content assertions. Generate from actual compiled story leaves and actual variation IDs, then compare generated entries to actual rendered results. Include group variations. Keep manifest fields separate from visible UI copy.

No tracked analog combines compiled Storybook variation enumeration, stable direct URL generation and per-variation iframe/render identity checks. Existing browser discovery and metadata coverage are partial matches; neither can be credited as that proof. Keep manifest tooling in dev/test/story support, behind the existing dev-only Storybook boundary.

### Safe lab startup and process/database isolation

**Files:** accrue_admin/test/support/e2e_server.ex; accrue_admin/playwright.config.js; new review-lab preflight and isolation test.

The current harness is a starting point to wrap/harden, not a safe review-lab policy:

~~~elixir
# accrue_admin/test/support/e2e_server.ex, lines 50-70
case TestRepo.__adapter__().storage_up(TestRepo.config()) do
  :ok -> :ok
  {:error, :already_up} -> :ok
end

case TestRepo.start_link(pool: Ecto.Adapters.SQL.Sandbox) do
  {:ok, _pid} -> :ok
  {:error, {:already_started, _pid}} -> :ok
end
~~~

The endpoint also accepts an already-started process at lines 95-99; the port is read from ACCRUE_ADMIN_E2E_PORT at lines 102-104. The Playwright config (lines 30-35) sets reuseExistingServer to the inverse of CI, so an occupied local server is accepted. A distinct port alone does not establish ownership.

The review launcher should check for a fresh explicit disposable DB/namespace and free loopback port, record its own PID/command/DB/port, and fail closed on unknown pre-existing state. The reset negative control must place a marker in the review DB, reset the ordinary lane, then reload the marker unchanged. Keep this evidence separate from DB-free component rendering.

### Production/package boundaries and CI owner

**Files:** extend package/route tests and compile/package checks; CI path contract and workflow admission assertions.

**Boundary analog:** accrue_admin/test/accrue_admin/dev/storybook_asset_test.exs, lines 30-57, checks Storybook assets are in dev routes but absent from a prod-like router, verifies PhoenixStorybook remains dev/test-only, and preserves disabled dev Storybook mounts in examples/accrue_host. accrue_admin/mix.exs, lines 31-33 compiles story support only in dev/test, and lines 55-60 allowlists package content. Extend these owners with production compile/package-content assertions that exclude scenario facts and adapters; do not weaken kitchen or canonical host mount checks.

**CI owner analog:** .github/workflows/ci.yml, lines 10-18 names admin-phase200-guardrails as a merge-blocking owner, and lines 22-27 admit all pull requests without path filters. The job begins at line 1242. scripts/ci/verify_phase200_ci_contract.sh, lines 92-105 verifies required files/job commands and extracts the job body. Extend the project-root contract with consumed-root positives and an unrelated-root negative, while asserting workflow admission and the named owner. An in-job selector cannot prove admission on its own. The separate Browser UAT workflow omits root story/scenario paths; it is not the approved CIQ-01 owner.

## Shared Patterns

### Production policy ownership
**Sources:** accrue_admin/lib/accrue_admin/live/subscription_live.ex:287-301,317-349,846-892; accrue_admin/lib/accrue_admin/components/detail.ex:73-127; accrue_admin/lib/accrue_admin/copy.ex:194-200; accrue_admin/lib/accrue_admin/scoped_path.ex:47-67.
**Apply to:** extracted production area and every static story. Preserve production status/facts/actions, formatting/copy, action eligibility, accessible hidden context and owner-scoped destinations. Only factual scenario input should be story-selected.

### Evidence-lane separation
**Sources:** accrue_admin/test/accrue_admin/live/subscription_live_test.exs:53-81; accrue_admin/test/support/e2e_server.ex:6-20; 252-RESEARCH.md:90-159.
**Apply to:** scenario, Repo and browser coverage. Pure validation is not DB persistence; a Storybook render is not a mounted LiveView action; the DB-backed E2E server is not DB-free rendering.

### Fail-closed test/lab boundaries
**Sources:** examples/accrue_host/priv/repo/seeds/phase248_cleanup_edge.exs:7-18,56-81; scripts/ci/phase248_heldout_isolation.test.mjs:31-70; accrue_admin/test/support/e2e_server.ex:50-70.
**Apply to:** Repo/seed and lab tests. Check environment and DB identity before mutation, limit cleanup to exact owned IDs/children, and include a negative control proving refusal and preservation.

### Executable acceptance
**Source:** CLAUDE.md:201-208.
**Apply to:** all machine-verifiable acceptance, including the tracer-like first slice. Require deterministic unit, integration, contract or browser assertions in merge-blocking CI; do not substitute a manual checkpoint.

## No Analog Found

| File or responsibility | Role | Data Flow | Reason |
|---|---|---|---|
| Root DB-free Cadence subscription facts source | model/utility | transform | No plain shared scenario source exists; current test factories write Repo records. Use approved facts contract and keep location outside package compile/package roots. |
| Compiled PhoenixStorybook variation manifest with direct URL/render reconciliation | utility/test | transform, browser request-response | Tracked coverage checks registry metadata and current browser scans mounted links, but neither proves each actual compiled variation was rendered. Dependency source is not a tracked project analog. |
| Review-lab PID/command/DB/port ownership preflight and independent reset marker proof | utility/test | process and database I/O | Existing E2E startup accepts already-existing DB/processes and local Playwright server reuse; no safe review-lab owner exists yet. |

## Metadata

**Analog search scope:** accrue_admin production components/LiveViews and tests; root Storybook components; core billing domain and migrations; Admin E2E support/config; phase248 cleanup/CI contracts; GitHub Actions CI owner.
**Tracked-source gate:** every named analog verified with git ls-files; no gitignored capability mirrors or installed dependency files are referenced as codebase analogs.
**Pattern extraction date:** 2026-10-26
