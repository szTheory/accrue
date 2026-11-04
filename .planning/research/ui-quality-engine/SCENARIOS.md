# UI quality engine: personas, jobs, and realistic scenarios

**Date:** 2026-10-26. **Status:** research and proposal, not approved milestone scope.
**Evidence:** source inspection and primary-source documentation only. No browser, seed execution, accessibility, performance, or visual acceptance is claimed here.

## Recommendation

Extend the current Cadence evaluation host with a small shared catalogue of **reachable billing situations**. Organize review by actor and job, then expose each situation through the actual components at the smallest useful composition tier. Keep adopter product profiles, human actors, billing states, and environmental conditions separate. Combine them deliberately where the combination changes the UI or an important behavior; do not multiply every dimension.

Use five proposed adopter profiles as realism checks, not five separate demo applications. Start by implementing only the empty/new and growing-team profiles for one subscriptions journey. Existing ordinary and held-out scenarios remain distinct. The rest are rolling coverage targets.

## Existing evidence and gaps

| Existing asset | Source evidence | Disposition |
|---|---|---|
| Current users and ownership boundaries | `PRODUCT.md`, Users / Operating Context: adopter developer, equal-primary operator and engineer, and customer billing manager; host owns auth, memberships, Repo and runtime secrets | ADOPT. Product persona is not the same as authenticated actor or billed entity |
| Six historical operator jobs | `.planning/research/v1.51-admin-ui-depth-design.md:36`: founder health glance; support customer lookup; finance invoice queue; recovery; developer webhook investigation; audit | ADOPT jobs, refresh route names and reachability against current code. Do not copy historical paths literally |
| Five customer lifecycle accounts plus a separate operator | `examples/accrue_host/priv/repo/seeds/hero_accounts.exs:20`: healthy, past-due, canceled, enterprise, trialing; operator deliberately has no org/subscription/dunning events | EXTEND. These are lifecycle examples inside one fictional host, not five adopter industries or five authorization roles |
| Background density | `examples/accrue_host/priv/repo/seeds/background_data.exs:8` creates 100 accounts, with random UUIDs, Faker data, and up to 90 days of history | EXTEND with deterministic selected scenario data. Do not declare all demo data deterministic; ordinary seed skips repeated background insertion using event existence |
| Seed separation | Ten files under `examples/accrue_host/priv/repo/seeds/` (`rg --files ... | wc -l`); `ordinary.exs:214` onward retains normal data and excludes old Phase191 stress rows; `phase248_cleanup_edge.exs` guards five exact held-out identities | ADOPT safety boundaries, never broaden cleanup to every row sharing a prefix |
| Realism checks already exist | `examples/accrue_host/test/ordinary_preview_story_contract_test.exs`: Unicode identity, repeatable payment-method assignment, coupon/redemption consistency, subscription markers, UTC precision, coherent invoice/payment event relationships | EXTEND; this is a substantial starting point, not an empty fixture system |
| Separate integration fixture owners | `accrue_admin/test/support/e2e_fixtures.ex` (1,183 lines), `accrue_portal/test/support/fixtures.ex` (200 lines), and host seed scripts | EXTEND through small adapters; do not create a global fixture framework that depends on all three applications |
| Component registry | `accrue_admin/lib/accrue_admin/dev/component_registry.ex` (2,153 lines) already defines applicable and N/A states, specimens and group contracts | EXTEND with situation IDs and caller evidence. Preserve existing N/A reasons where true |
| Generated descriptions lack situations | `accrue_admin/storybook/_support/registry_story.ex:125` generates family / variant / specimen-label descriptions | EXTEND to actor + job + situation. Primitive token demonstrations may reference a real enclosing situation instead of inventing a person for each button |
| Existing composed subscription example | `storybook/components/subscription_detail.story.exs` has populated, Braintree-pruned and dunning-active states, but defines its own example render and fixed July 2026 date | REPLACE incrementally with the real shared presentation once extracted; these three variations do not prove current mounted detail parity |

Counts above are file/source counts at this working tree, not executed scenario coverage.

### Known documentation and fixture drift

`PRODUCT.md`, Evidence on Hand says mixed-account Portal resolution is a “refinement target, not a claim of implemented mixed-account Portal support.” However `.planning/PROJECT.md:1051` records the Phase233 shipped decision: “Use one generic Portal for personal and host-selected organization/custom billables, with optional resolution and fresh action authorization.” Treat this as documentation drift to reconcile in a later authorized change, not evidence that a new Portal implementation is required. Verify current `accrue_portal` code before writing its scenarios.

The historical hero account comments and dunning event snapshots do not themselves prove a coherent current retry cycle: `hero_accounts.exs:233` onward creates recovered/exhausted and older active histories; the v1.67 future-requirements list explicitly defers recovery demo-history integrity. A new scenario should model one documented campaign anchor and its timeline, then test that relationship, rather than importing all historical seed claims as truth.

## Proposed adopter profiles

All names, scales and usage are **synthetic design assumptions**, not reported customer adoption or performance promises. Use these profiles to select useful cases within current supported billing behavior.

| ID / fictional product | Hosting / billing shape | Volume and script mix | Failure profile and people/jobs | Distinct coverage; limits |
|---|---|---|---|---|
| `launch` — new Cadence team workspace | Hosted B2B; organization-owned billable | Zero customers/subscriptions initially; one first workspace; short English labels | Founder/operator checks whether anything needs attention; customer owner starts supported billing setup | True first-run empty state versus filtered-empty versus unavailable. No fabricated invoices or invented onboarding capability |
| `team` — Cadence collaboration service | Hosted multi-tenant B2B; organization billable, individual human actors | 100-account representative demo scale; 1/25/26 result boundaries; plausible long company names and accented names | Support finds one customer, inspects subscription, reviews cancel-renewal consequence; organization manager manages only its own billing | Routine successful work, page boundary, related-resource navigation, owner/actor distinction. Reuse current host and catalog |
| `learner` — personal language-study subscription | Hosted B2C; user billable | One subscription per selected learner; short/long personal names; Japanese and Arabic names embedded in current English UI; USD and JPY as separate real records | Customer finds invoices and supported payment-management path; support investigates one failed renewal | Personal ownership, zero-decimal amounts and mixed-script identity. No claim of translated UI, full RTL layout, mobile-store integration, or locale-driven currency conversion |
| `operations` — finance/reconciliation SaaS | Hosted B2B; organization billable | Power-user work queue with many records and a bounded large count; mixed USD/JPY invoice sets, exact long identifiers | Finance operator clears an invoice queue; engineer follows webhook → event → customer; periodic partial failure or stale observation | Currency-qualified aggregates, dense but navigable work, exact evidence and safe power-user affordances. Do not invent accounting, reconciliation, exports, or provider actions not present in the UI |
| `self_hosted` — privately deployed team knowledge tool | Single-tenant Phoenix deployment; one organization billable, separately authorized operator | One customer/org, few plans, long deployment/org name; ordinary English plus Unicode user identity | Maintainer investigates missing/stale webhook evidence or browser disconnect; billing manager views local evidence | Low-volume configured-host boundary, single-tenant scope and reconnect behavior. Self-hosting is a host deployment profile; it does not imply offline money movement, new licensing, or a new billing rail |

Use the current Fake processor for deterministic story/persistence evaluation. Provider-specific presentation cases can represent Stripe or Braintree when capability metadata and actual caller behavior support them; a Fake render never proves upstream provider behavior. No separate industry should be added unless it introduces an unrepresented job, state, ownership model or content class.

## Actors and jobs stay independently curated

Maintain the six established Admin jobs as role lenses, plus customer owner/authorized manager and customer read-only member. An engineering power user and a first-time support operator can examine the same record through the same UI. Persona labels must not grant privileges.

For each scenario, record `actor_kind`, `billable_kind`, `actor_to_billable_relation`, `operator_access`, current owner scope, supported actions and the canonical job. Do not equate `Organization` ownership with a universal tenant column: the locked project decision (`PROJECT.md:1068`) preserves globally owned catalogue data and exact parent/child relationships. Domain ownership belongs to the actual schema.

“New account” means two separate states where relevant: a brand-new host with no billing data, and an existing host with a customer that has no subscription. A filtered queue with zero matches is neither. A failed read must not masquerade as any empty state.

## One data source, narrow adapters

Proposed repo-only location: `dev_support/ui_scenarios/`, outside package `lib`, `priv`, package file allowlists and production compile paths. Start with a handful of ordinary Elixir `.exs` data constructors and a documented loader invoked by dev/test hosts; a helper directory and explicit host loading are enough. Do not add a dependency or package to share fixtures. During implementation, prove each consumer's paths and compile environment before settling the exact directory.

Define **scenario facts**, not rendered markup or copied business rules:

```elixir
%{
  id: "team.subscription.cancel_renewal.review",
  profile: :team,
  actor: %{kind: :operator, permission: :authorized},
  job: :review_subscription_cancellation,
  clock: ~U[2026-10-01 12:00:00Z],
  situation: :active_cancel_at_period_end_review,
  facts: %{customer: customer_facts, subscription: subscription_facts},
  source: %{caller: "AccrueAdmin.Live.SubscriptionLive", state: :staged},
  assertions: [:target_visible, :period_end_visible, :consequence_specific]
}
```

The exact schema is a proposal. Stable string IDs avoid test IDs coupled to specimen order. Atom fields are closed literals from checked-in code; never atomize untrusted input.

Adapters have different responsibilities:

1. **Story adapter:** turns facts into structs/assigns accepted by the real presentational component; no Repo, user session, provider call, router or broad mocks. Use real copy/formatting helpers. Return deterministic IDs and labels.
2. **Persistence adapter:** maps those facts into the host/test Repo, preserving actual foreign keys and schema-prefix behavior. Exercise existing changesets/facades as appropriate; avoid replaying payment effects merely to seed a screenshot. Use fixed namespace-owned identities and a bounded fixed clock; assert resulting facts match the source.
3. **Mounted behavior adapter:** supplies session, scope, Fake operation scripts and real event transitions. It verifies authorization, lifecycle, cursor semantics, navigation and reconnect behavior that a presentation story cannot establish.

Only migrate shared high-value data; leave narrowly scoped unit factories independent when sharing would add coupling. Keep scenario helpers dev/test-only in every consuming Mix project, and add a package/release exclusion check rather than relying on naming convention. Never relocate runtime email fixtures in `accrue/lib/accrue/emails/fixtures.ex` just because they contain the word “fixtures”; their product role differs.

## Invariants and independent checks

Use the current schema and domain helpers as the semantic authority. Add a small handwritten structural validator only for relationships that cross records or are not exposed by existing public validation. Reuse existing property-test tooling for bounded generated cases; do not add a schema-validation dependency.

| Invariant family | Required checks | Where to prove it |
|---|---|---|
| Structural and identity | Closed status/operation enums; unique stable fixture IDs; required record fields; existing foreign IDs; explicit actor versus billable; same provider across linked billing records when the real model requires it | Fast DB-free validation, plus actual Repo constraints in a narrow conformance test |
| Lifecycle and time | Model only supported transitions; ordered period/trial/cancel/dunning markers; fixed UTC clock and preserved precision; accepted/queued/processed/confirmed outcomes kept distinct; campaign anchors match every campaign event | DB-free relation checks + existing transition changesets + mounted transition tests |
| Money | Integer minor units; real currency code; currency-aware formatting; JPY has no invented fractional cents; totals/paid/remaining/discounts consistent with the modeled billing reason; aggregate currencies never summed without qualification | Real money helpers and fixture conformance; no duplicate conversion algorithm |
| Relationships | Invoice/customer/subscription alignment; default payment method belongs to customer; coupon/promotion eligibility and redemption counts coherent; exact webhook/event linkage | Extend current ordinary story contracts; DB constraints remain DB-backed |
| Authority | Human permission is distinct from record ownership; authorized/read-only/denied are real host policy outcomes; revoked or switched account cannot mutate stale target | Real mounted LiveView/Portal checks; isolated visual state is illustrative only |
| Environment | Ordinary preview separated from stress data; Fake-only persistence where currently required; seed writes refused outside disposable lanes; teardown cannot remove unrelated children | Existing seed-boundary and exact cleanup tests with negative controls |
| Privacy | Fictional names and reserved example domains; test-only card brands/last-four, no PAN/CVC; no copied production payloads, session material, processor secrets or logs | Source review and existing hygiene guards; never include personal data as a negative-control literal |

Ecto explicitly separates pre-insert validations from database constraints; `.valid?` alone cannot establish uniqueness or foreign-key validity. Keep a narrow persisted conformance path for each scenario adapter rather than claiming DB-free validation proves all invariants. [Ecto.Changeset: validations and constraints](https://ecto.hexdocs.pm/Ecto.Changeset.html).

Prove the validator rejects deliberately invalid variants: unknown enum, orphan customer ID, wrong provider, inconsistent amount, reversed timestamp, stale action target and foreign cleanup child. A validator that accepts all current fixtures is not sufficient evidence.

## First vertical slice: find a subscription and understand its next action

Start with the production-owned summary/action area of `/subscriptions/:id`, then its incoming `/subscriptions` toolbar/worklist (`accrue_admin/lib/accrue_admin/router.ex:75`). This slice exercises identity, lifecycle, exact money, next-action eligibility and detail hierarchy before adding list state. Current detail staging already exists in `SubscriptionLive`; the story must use the shared presentation extracted from that owner, not clone its markup. List rendering includes a stateful DataTable, so story extraction must stop at the real state boundary and retain mounted tests. Do not synthesize a mixed-tenant record graph just to make a visually busy story; foreign identity and context-switch cases belong to explicit negative mounted tests using their existing ownership fixtures.

| Case / situation | Smallest useful story | Area or page context | Real behavior still verified mounted |
|---|---|---|---|
| New host, no subscriptions | EmptyState + appropriate existing action | Subscriptions empty page with correct shell/context | Empty query and supported destination; no synthetic creation action |
| Support finds one active customer | Identity + status + exact amount row | Filter/search controls + one-row worklist, then detail summary | Current owner scope, actual query and related-resource destination |
| No matches after filtering | Filter controls + clear action | Filtered-empty area visibly retains constraints | Apply/clear semantics, URL params and focus after patch |
| 25 results / 26th record | Row group and pagination footer | Worklist populated and last/next page state | Real cursor validity and no duplicates/missing records |
| Active, renewal already scheduled to stop | Lifecycle summary and precise period-end timestamp | Detail primary action/status band | Eligibility, supported resume path where real, current target |
| Review cancel renewal | Consequence copy + review panel | Detail with the actual staged review | Step-up, revalidation after stale state, one dispatch and truthful result |
| Braintree capability-limited record | Pruned action group | Detail actions with actual guidance | Actual provider support; Fake render does not certify Braintree calls |
| Read unavailable or disconnected | Error/retry or connection notice only when real | Worklist/detail retains what is actually known | Real failed query/disconnect/reconnect, no fake empty “success” |
| Plausible long company/name + ID + JPY | Identity/money/timestamp group | Narrow row/card and detail summary | Correct copy value, currency, related identity |

Use current 320/375/768/1024/1440 viewport evidence as a starting sample; add breakpoint-adjacent widths only when CSS or a named defect gives them value. Both explicit themes are required; system-theme selection and reduced motion are orthogonal targeted checks. Scenario descriptions name the human job and situation. They need not repeat every environmental parameter in their title.

### International text is data, not a localization claim

Include credible short/long names with accents, CJK and Arabic; emoji only where current user-input rules permit it. Distinguish internal fixed labels from externally supplied data: an absurd sidebar label is often a naming defect, while a long organization name may be valid. Use realistic boundary lengths based on actual schema limits and caller usage; retain unbreakable identifiers and long-but-valid emails because they are plausible. The current host already checks “Atelier Café.”

Keep the English interface unless localization is separately scoped. A single Arabic customer name tests mixed-direction inline content, not a complete RTL product. Where unknown-direction user content is embedded, W3C recommends directional isolation using `bdi` or an existing wrapper with `dir="auto"`; verify exact identifiers and punctuation remain usable. [W3C inline bidirectional text](https://www.w3.org/International/articles/inline-bidi-markup/Overview.en.php?changelang=en).

## Reachability and pruning contract

Every scenario records: stable ID; human job; owning production component; caller/route; triggering domain or event state; assumptions/capability; fixture source; expected visible evidence/action; review date; evidence class (`source-mapped`, `mounted-proved`, or explicit `presentation-only`). The catalogue can be a small checked-in Elixir data map extended from current registry metadata; it does not need a second hand-maintained JSON inventory.

Prune a state when the domain forbids it, no current caller can pass it, it duplicates the same visible/behavioral equivalence class, or its job has been retired. Record the reason and surviving replacement ID in a compact retirement log. Preserve regression provenance and update named CI references in the same change. Do not delete a meaningful legacy failure case merely because the present implementation usually prevents it: malformed/unavailable upstream data and the error boundary itself may still be reachable.

Reachability cannot be established by `rg` alone. Trace the caller and validation boundary; for nontrivial async/auth cases, require an existing mounted test or add one during implementation. Stories that intentionally demonstrate component API behavior beyond current callers should be marked as API-contract examples rather than quietly counted as product scenarios.

Avoid introducing a compulsory scenario for every value in the status enum on every page. A primitive can show all legitimate status styles; a whole-page scenario should exist only when it changes the human task, permitted action, layout, evidence or safety outcome.

## Rolling sequence and exit criteria

1. **Immediate — one useful journey.** Refresh the role/job map against current code; reconcile known doc drift; define five profile briefs but implement only `launch`/`team` facts. Extract the production Subscription summary/action area first, then toolbar/table presentation, supply the cases above, and prove one persisted/mounted conformance path. Exit: reviewers can locate and inspect this job at component, group, area and real-page levels; no copied page UI, impossible data or production fixture leakage.
2. **Near term — extend the same mechanism.** Customer investigation → invoices/payments, then recovery/webhook diagnosis. Add `learner`/`operations` cases only as each creates a distinct supported situation. Port useful registry specimens and retire demonstrably stale clones after callers/tests migrate. Exit: each existing high-frequency job has mapped happy/empty/error/boundary cases and a real navigation handoff.
3. **Mid term — customer and host variations.** Add Portal personal/organization/read-only/switch cases against the shipped context contract; include the single-tenant host profile and configurable mount paths. Reuse scenario facts across surfaces without erasing their different actors, tone or host branding. Exit: supported cross-surface journeys preserve billed identity, permission and return destination.
4. **Long term — demand-driven curation.** A new adopter incident, domain state or design finding adds a scenario only if it distinguishes a missing equivalence class. Each milestone prunes obsolete cases and refreshes the actor/job map. Track scenario maintenance time, distinct caller coverage and defects caught, not raw story count. No permanent “simulate every SaaS industry” programme.

## Adversarial review and rejected alternatives

| Tempting approach | Why it fails here | Chosen compromise |
|---|---|---|
| Five to seven separate industry demos | Repeats identical billing states, multiplies seed upkeep, implies unsupported product features | Five profile briefs, one existing host, implement only distinct cases |
| Replace all factories with one source | Unit tests become coupled to a large cross-package graph; small semantic tests lose clarity | Shared facts for real multi-surface situations; narrow factories remain local |
| Treat fixture validity as changeset `.valid?` | Database constraints and lifecycle history are not proved | Layer structural validation, persisted conformance and mounted transitions |
| Run a DB and Fake API behind every story | Slow iteration; hides composition faults; makes a screenshot dependent on mutable global state | DB-free presentation plus explicit mounted behavior tests |
| Extract every LiveView render in advance | Broad refactor without user value; may damage streams, change tracking, event targets or state ownership | Extract only the first job's reusable presentation, then expand with measured benefit |
| Show error/loading/denied on every component | Many states have no legitimate caller or job, creating misleading product affordances | Record applicable/N/A and source evidence; real async boundaries own loading |
| Delete historical stress rows globally | Risks ordinary preview or unrelated data, violates exact cleanup decision | Preserve current disposable lanes and bounded teardown authority |
| Rename domain concepts to improve copy freely | Can erase distinctions between accepted, queued, updated and confirmed, or violate locked wording | Use existing Copy/voice owners; exact technical evidence remains available |
| Claim UI quality from valid synthetic records | Correct facts do not prove hierarchy, navigation, typography or usability | Inspect real renders at relevant sizes/themes; retain bounded human taste review |

Phoenix's own test guidance distinguishes single component render checks from mounted interaction tests: `render_component` renders a LiveComponent once; event interaction uses a mounted LiveView. That supports retaining both layers rather than declaring Storybook a replacement for behavioral proof. [Phoenix.LiveViewTest source and guidance](https://github.com/phoenixframework/phoenix_live_view/blob/main/lib/phoenix_live_view/test/live_view_test.ex).

## Decisions requiring the owner

No new strategic decision is needed to recommend this bounded plan. The owner already specified realistic data, compositional coverage, mobile-first quality, both themes and minimal dependencies. New product capabilities, a rebrand, retirement of adopter-visible surfaces, or changes to host authorization policy would require separate decisions and are not implied by this proposal.
