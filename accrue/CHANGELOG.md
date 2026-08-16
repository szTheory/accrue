# Changelog

## Unreleased

### Features

* Bump the `lattice_stripe` dependency to `~> 2.0` while resolving the current 2.x lock line across the linked package family.
* Add the optional, default-off advisory Stripe-native entitlement refresh for diagnostics and admin read surfaces. The local plan-to-feature map remains the only Accrue grant gate, so advisory Stripe data never changes entitlement grants, controller plugs, or LiveView guards.
* Support `Accrue.Entitlements.StripeSync.refresh/2`, the optional `Accrue.Processor.list_active_entitlements/2` callback and public facade, and the deterministic `Accrue.Processor.Fake.put_entitlements/2` test helper for adopter proof.
* Share one webhook/pull reconciliation path with the shared reconcile/isolation proof, keeping Stripe-native cache writes observational and auditable.
* Record that `fetch_entitled/2` remains closed: Accrue will not add a Stripe-backed grant predicate because local billing state stays authoritative for access decisions.

### Bug Fixes

* Restore Chimeway Phase 98 privacy-safe recipient compatibility: dunning notifications persist a stable opaque customer reference, while `invoice.paid` termination continues to use that same reference as its signal actor.

## [1.4.0](https://github.com/szTheory/accrue/compare/accrue-v1.3.0...accrue-v1.4.0) (2026-06-01)


### Features

* **155-01:** add livemode omission fixture option ([e808e4c](https://github.com/szTheory/accrue/commit/e808e4c2e920fbfc45630c92618119382d755df6))
* **155-01:** expose entitlement summary webhook metrics ([d659bba](https://github.com/szTheory/accrue/commit/d659bbaa0faa8578bf0668f84c11ebcf44dfc4c9))


### Bug Fixes

* **152:** WR-04 rewrite group_into_arcs/1 from O(n²) to O(n) ([e14a2a0](https://github.com/szTheory/accrue/commit/e14a2a08e202974ba5ecdea79f27c1a2b3494b1b))
* **154-01:** correct advisory cache write path ([443f303](https://github.com/szTheory/accrue/commit/443f3035f271b7a6f4447b363806aab29e0ac741))
* **156-01:** normalize unloaded entitlement billables ([47ab4bb](https://github.com/szTheory/accrue/commit/47ab4bb330715725e01155f84dc0e088c739a5bf))
* **160:** close stable-core review findings ([cf06e16](https://github.com/szTheory/accrue/commit/cf06e167aa5ddea3bbaf6f346dd53473ad5fe2a1))
* **160:** close version posture review findings ([ff16407](https://github.com/szTheory/accrue/commit/ff164071931fd994ab0ee6acd5fa00f607ffa61e))

## [1.3.0](https://github.com/szTheory/accrue/compare/accrue-v1.2.0...accrue-v1.3.0) (2026-05-30)

**1.0.0 — Stable.** This release commits Accrue to v1.x API stability for the documented integration surface: generated `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `Accrue.Auth`, and `Accrue.ConfigError`. Breaking changes on that surface go through deprecation, not silent reshuffles. Internal schemas, workers, and demo helpers are not part of the contract. See `accrue/README.md` Stability, `accrue/guides/upgrade.md`, `accrue/guides/maturity-and-maintenance.md`, and root `RELEASING.md` for the v1.x stability commitment and post-1.0 cadence.

Observability and integrator docs for **Stripe Checkout** on `Accrue.Billing` ship together: grep **`guides/telemetry.md#billing-checkout-session-create`**, re-run **`bash scripts/ci/verify_package_docs.sh`** / **`bash scripts/ci/verify_adoption_proof_matrix.sh`**, and keep **First Hour** + **`examples/accrue_host`** observability copy aligned with **`checkout_session_facade_test.exs`**.

### Billing

* Add `Accrue.Billing.create_checkout_session/2` and `create_checkout_session!/2`, delegating to `Accrue.Checkout.Session` under `[:accrue, :billing, :checkout_session, :create]` with allowlisted span metadata (no checkout URL, `client_secret`, or raw attrs); see `guides/telemetry.md#billing-checkout-session-create` and `test/accrue/billing/checkout_session_facade_test.exs`.
* Add `Accrue.Billing.create_billing_portal_session/2` and `create_billing_portal_session!/2`, delegating to `Accrue.BillingPortal.Session` with `[:accrue, :billing, :billing_portal, :create]` telemetry; see `guides/telemetry.md`.
* Add `Accrue.Billing.list_payment_methods/2` and `list_payment_methods!/2` for processor-backed payment method listing (with optional validated list filters); installer `billing.ex.eex` delegates the same surface for host facades.

### Telemetry

* **`meter_reporting_failed` metadata `source`:** rename `:inline` to `:sync` for synchronous `report_usage/3` failures so the closed set is `:sync | :reconciler | :webhook` everywhere (code, docs, default metrics). Update host dashboards or attach handlers that matched on `:inline`.

### Documentation

* **INT-13:** extend **First Hour**, **`examples/accrue_host/README.md`**, and **`examples/accrue_host/docs/adoption-proof-matrix.md`** with **`Accrue.Billing.create_billing_portal_session/2`**, **`[:accrue, :billing, :billing_portal, :create]`**, anchor **`guides/telemetry.md#billing-billing-portal-create`**, and **`billing_portal_session_facade_test.exs`** — Customer Portal facade parity alongside checkout in the integrator spine.
* Align **First Hour**, **`examples/accrue_host/README.md`**, **`examples/accrue_host/docs/adoption-proof-matrix.md`**, **`guides/telemetry.md`**, and **`guides/operator-runbooks.md`** with **`Accrue.Billing.create_checkout_session/2`** and the **`[:accrue, :billing, :checkout_session, :create]`** span (anchor **`#billing-checkout-session-create`**); operator Stripe triage stays pointer-depth only (no Checkout error matrix).
* Harden the telemetry guide ops catalog (evergreen heading, Primary owner column, Hex vs `main` doc contract), correct OpenTelemetry examples (including meter reporting + ops failure cross-link), add an ops event contract test, and emit `[:accrue, :ops, :webhook_dlq, :dead_lettered]` when webhook dispatch exhausts retries.

### CI

* Extend **`verify_package_docs.sh`** and **`verify_adoption_proof_matrix.sh`** merge-blocking needles for **billing portal** facade literals (**`create_billing_portal_session/2`**, **`[:accrue, :billing, :billing_portal, :create]`**, **`billing-billing-portal-create`** / **`billing_portal_session_facade_test.exs`**) alongside checkout.
* Extend **`verify_package_docs.sh`** and **`verify_adoption_proof_matrix.sh`** merge-blocking needles for checkout facade + billing-span literals co-evolving with golden-path docs.

### Features

* **144-01:** add Dunning.funnel/1 with DISTINCT-tuple GROUP BY (DAN-01) ([146680f](https://github.com/szTheory/accrue/commit/146680f7274cad8df1e2d45d39d88483122ddcdf))
* **144-01:** wrap recovered_vs_lost_mrr/1 cast in JSONB safe-cast (DAN-08) ([02b7e93](https://github.com/szTheory/accrue/commit/02b7e93d7768acf7a6c34dda348d660e764a812b))
* **144-02:** snapshot campaign_anchor onto dunning.exhausted payload (DAN-02) ([891e22e](https://github.com/szTheory/accrue/commit/891e22e10c72d8f0f71f5ad034d20578aa614f6b))
* **144-02:** snapshot campaign_anchor onto dunning.recovered payload (DAN-02) ([d384c47](https://github.com/szTheory/accrue/commit/d384c475decdc6e56dceb492bab7322ec685987b))
* **146-01:** add in_active_dunning_campaign/1 query composer to Accrue.Billing.Query ([e1a4895](https://github.com/szTheory/accrue/commit/e1a48959d80177ba2f2aa106e26492eb693c78bf))
* **146-01:** refactor emit_campaign_started/1 to /2 with invoice_id enrichment ([f97105d](https://github.com/szTheory/accrue/commit/f97105df68099664b402f85d46c6d5d16d1261ab))
* **146-02:** add at_risk_subscriptions tests + fix UUID::text casts in query ([9573961](https://github.com/szTheory/accrue/commit/9573961111b113ce1c02ee7b61793dbde5bfaec4))
* **146-02:** implement at_risk_subscriptions/1 + apply_campaign_window/2 ([e930854](https://github.com/szTheory/accrue/commit/e93085487faaae22815f61f6562e6ffefba602f6))
* **147-01:** implement campaign_timeline and campaign_timeline_grouped with tests ([96bcae2](https://github.com/szTheory/accrue/commit/96bcae22f941b684bc8c648e7008ce6a8606522e))
* **149-01:** add Accrue.Dunning.requires_attention?/1 ([eb24c1d](https://github.com/szTheory/accrue/commit/eb24c1d271599a79659a4c032165792d62437d2a))
* **58-02:** add DunningNotifier workflow/2 and rendering/2 for 48h escalation ([ad9ff10](https://github.com/szTheory/accrue/commit/ad9ff10b32f42f7a55258019bf69b394e4f37778))
* **58-03:** emit invoice.paid Outcome Signal and wire recovery path ([0e95e5f](https://github.com/szTheory/accrue/commit/0e95e5f54039b30609fbf542838ae5d0c79b9273))
* **analytics:** implement invoices_for_campaign/2 for dunning timeline ([244e6da](https://github.com/szTheory/accrue/commit/244e6da15a7e3410ddca11a4089cef441c8304e7))
* **analytics:** phase 143 - MRR calculation and dunning analytics context ([57ce35b](https://github.com/szTheory/accrue/commit/57ce35b4ac99834b011c2c5824aa76deff5ed71d))
* **v1.42:** complete Ad-hoc Invoices & Adopter Confidence milestone ([452995e](https://github.com/szTheory/accrue/commit/452995e3327220ff3b50023f82871354ec3d0f2c))


### Bug Fixes

* **146:** resolve CR-01 GROUP BY bug, CR-02 failure reason display, WR-01/02/03 ([142f21b](https://github.com/szTheory/accrue/commit/142f21baa8b45a92f81f5c0b6c99c41ffe973e3a))
* **151-01:** resolve ENT-10 scoping collisions in webhook handler ([209dce9](https://github.com/szTheory/accrue/commit/209dce983aff2047975fd1cf0dd5334762187b24))
* **151-03:** resolve test coverage blockers ([21f5d6e](https://github.com/szTheory/accrue/commit/21f5d6e205eef2ad523f5d621338c5f1e6118838))
* **152-01:** correct 7 [@since](https://github.com/since) annotations in dunning.ex to canonical [@doc](https://github.com/doc) since: "1.3.0" ([88d1646](https://github.com/szTheory/accrue/commit/88d16460a9d09c776046e3c3ead9ccc13dfef8cb))
* **152-03:** clear accrue test-file compile warnings for --warnings-as-errors ([b206aa7](https://github.com/szTheory/accrue/commit/b206aa7abba587388daef2ce08d3611280667a9b))
* **152-03:** drop obsolete cancel_signals key from Chimeway dunning workflow ([f4acb4b](https://github.com/szTheory/accrue/commit/f4acb4b94ad1f47603eb20b93f56ebd66f53807a))

## [1.2.0](https://github.com/szTheory/accrue/compare/accrue-v1.1.2...accrue-v1.2.0) (2026-05-26)


### Features

* **123-01:** add :entitlements config schema, accessor + boot collision guard ([01cc314](https://github.com/szTheory/accrue/commit/01cc3146c8c26d8839639c293c79e21b8a338b6a))
* **123-02:** retain entitlement OTel attributes (ENT-05) ([264b525](https://github.com/szTheory/accrue/commit/264b52572b7b0b9a1628ac4e79b265b5e80d5d44))
* **123-03:** build Accrue.Entitlements public gate API ([29a2715](https://github.com/szTheory/accrue/commit/29a27157b4b2273887e5417a0b14ab0293163473))
* **123-03:** define Entitlements.Plan struct + Resolver behaviour ([5c78a99](https://github.com/szTheory/accrue/commit/5c78a99474f3f4d89119550ae7b8b436fcb9a93a))
* **123-03:** implement LocalMap resolver (read-only active-subs fold) ([3833423](https://github.com/szTheory/accrue/commit/38334230998d4951f291c86faed8844baa0454d1))
* **123-04:** add 4 entitlement gate defdelegates on Accrue + reconcile plural event name ([fb55e00](https://github.com/szTheory/accrue/commit/fb55e00f2df8c2b27e459928f34f7f3e261060d3))
* **124-01:** add billable/on_deny/deny_path entitlements guard config ([c80f254](https://github.com/szTheory/accrue/commit/c80f254649083124205e180561108439f1ec6c6f))
* **124-01:** allowlist :surface in the OTel attribute bridge ([d176650](https://github.com/szTheory/accrue/commit/d1766505db71d3912987799e4fd026c2b0732245))
* **124-01:** thread additive surface: opt onto the entitlements :check span ([4527bd3](https://github.com/szTheory/accrue/commit/4527bd3d8f7d4bc5380c640d02861c1a49e23431))
* **124-02:** build Accrue.Entitlements.Guard shared decision engine ([c4726bc](https://github.com/szTheory/accrue/commit/c4726bc235b45263dd33ca19d95446ad404a66b4))
* **124-03:** Accrue.Plug.RequireEntitlement controller guard (ENT-06) ([6ec7906](https://github.com/szTheory/accrue/commit/6ec7906a38ee990e0700da5038effda69523d1b0))
* **124-03:** require_feature/1 + require_plan/1 router macros (ENT-06) ([3fb098d](https://github.com/szTheory/accrue/commit/3fb098d00d6f5f85cadbd3805cca385c0028dd86))
* **124-04:** add cond-compiled Accrue.Live.Entitlements on_mount guard ([2e020e6](https://github.com/szTheory/accrue/commit/2e020e686e8678c577826faabb72294ca42af3f7))
* **125-01:** add entitlements capability group (code labels + 3 adapters) ([bb36e88](https://github.com/szTheory/accrue/commit/bb36e8844292b77ea51b1dfe0e0248bf8f599633))
* **125-01:** extend drift gate + add Fake-lane provider-honesty proof ([30012a3](https://github.com/szTheory/accrue/commit/30012a32258b8ed6da92b8422e1b41594b73bd0d))
* **125-02:** add entitling?/1 predicate + Query.entitling/1 twin + truth table ([8de9401](https://github.com/szTheory/accrue/commit/8de9401e5c0a7d3fd3b5afe892a43e6dce15786e))
* **125-02:** retarget LocalMap.fold_active/1 base fetch to Query.entitling/1 ([beaa688](https://github.com/szTheory/accrue/commit/beaa688fe5bdd9793188f38fcbe6acbb76164438))
* **125-03:** add past_due_grace config knob + pure within_grace?/2 helper ([e666c35](https://github.com/szTheory/accrue/commit/e666c35987f30d41db8d1de98337fdafd8857b26))
* **125-03:** grace telemetry reasons + truth-table footnote + e2e coverage ([c3e240b](https://github.com/szTheory/accrue/commit/c3e240b7aaac7e39e10aac4630d347257b96ebbe))
* **125-03:** grace-widen fragment + conditional fold widening + :grace_plans ([89aa139](https://github.com/szTheory/accrue/commit/89aa13990458b47e94d23d4d857c4bc6f3ac5c66))
* **126-01:** add two [@doc](https://github.com/doc) false admin seam delegations on LocalMap ([a3f9f0d](https://github.com/szTheory/accrue/commit/a3f9f0db838b87b68aaf765fc198c84ce771ab85))
* **126-01:** implement Accrue.Entitlements.Admin.resolve_for_customer/1 ([8ae57ea](https://github.com/szTheory/accrue/commit/8ae57ea8270c5009022b490532578f8cc57d8c41))
* **127-01:** add accrue_entitlement_summaries schema + migration ([e84939e](https://github.com/szTheory/accrue/commit/e84939ed6a5baf46bd1721b05d3006dbf43193ee))
* **127-01:** add stripe_native_sync config enum + accessors ([324af5e](https://github.com/szTheory/accrue/commit/324af5e80eda9cc925de1486c5497821b90e9a0e))
* **127-02:** config-gated entitlement-summary reducer (D-04/06/07/09) ([ee38cfb](https://github.com/szTheory/accrue/commit/ee38cfb4f989ada9ee8f0a678c494c89e79bbc75))
* **127-02:** on-change ledger (D-08) + read-only StripeSync seam (D-11) ([759a7c2](https://github.com/szTheory/accrue/commit/759a7c2c7e09287d550b8e3a8b4f9a5332b27908))
* **127-03:** add entitlements.stripe_native_sync capability row + tighten drift gate ([f800997](https://github.com/szTheory/accrue/commit/f80099753afefff4f23d9beeec4072484120e298))
* **128-01:** add dunning campaign config schema, validators, accessors ([3a7fb82](https://github.com/szTheory/accrue/commit/3a7fb822b91a7dbc930574102d237e0d272e8026))
* **128-02:** add campaign anchor field, cast entry, and predicate (D-08) ([565a7eb](https://github.com/szTheory/accrue/commit/565a7eb632eb8856e2e5c95fd90f03edbc4600ee))
* **128-02:** add nullable dunning_campaign_started_at anchor migration ([116b500](https://github.com/szTheory/accrue/commit/116b5008c86cc48244f3a04f0cfb90b848a97aae))
* **128-03:** implement Accrue.Dunning.Campaign pure step resolver ([e934775](https://github.com/szTheory/accrue/commit/e934775c6e7a047e2beafafd4afd7eba894d3c70))
* **128-04:** add DunningActionRequired + DunningFinalNotice step emails ([38b2775](https://github.com/szTheory/accrue/commit/38b2775aa3fe7b15f01641b3f5001e15934b0c53))
* **128-04:** dedup :invoice_payment_failed at enqueue + Mailglass backstop ([f021497](https://github.com/szTheory/accrue/commit/f0214979b8acf3c10f2364c859f6255b8fa9b5d6))
* **128-05:** implement Accrue.Workers.DunningStep (D-10, D-11, D-16) ([84cac38](https://github.com/szTheory/accrue/commit/84cac3847e9f3ec59d5ef7913ce3eb0a8c0b2069))
* **128-06:** D-09 first-transition elector + day-0 enqueue + D-15 REPLACE gate (DUN-02) ([72714d4](https://github.com/szTheory/accrue/commit/72714d4803ff655f43d9d3da3fd98e81e986b9ce))
* **128-06:** D-12 cancel-on-recovery (in-transaction anchor-clear + post-commit cancel) (DUN-05) ([f71ae41](https://github.com/szTheory/accrue/commit/f71ae41680f5269474e4e65045729b6899a1c7f2))
* **129-01:** emit four dunning lifecycle events (ledger + telemetry) ([683e862](https://github.com/szTheory/accrue/commit/683e862e318a73946784ddd466fc015169f70e5b))
* **129-01:** register four dunning events across the drift-gate triad ([ddadb33](https://github.com/szTheory/accrue/commit/ddadb334a0331efc84d34e2dd7d8ec0e4b5b0c6d))
* **129-02:** add recovered_vs_lost/1 ledger-fold counter ([2cd78f7](https://github.com/szTheory/accrue/commit/2cd78f7bb951b6ed55faabe98c75636ed3f74fc2))
* **130-01:** add dunning capability group to Capabilities + three adapters ([0009c2b](https://github.com/szTheory/accrue/commit/0009c2bc9322541a5b22a1e80e1fd148f8d7c723))
* **131-02:** add :engine config key and dunning_engine/0 accessor (DUN-03 D-03) ([89a728a](https://github.com/szTheory/accrue/commit/89a728a407728326473cd9e73f62fb53af820ea9))
* **131-02:** define Accrue.Dunning.Engine behaviour (DUN-03 D-01) ([5efb529](https://github.com/szTheory/accrue/commit/5efb529f2a6d745ceaf1f4f5b9714f0ca373f1b2))
* **131-03:** create Accrue.Dunning.Engine.Oban behaviour implementation ([7dbe3e3](https://github.com/szTheory/accrue/commit/7dbe3e34d4fa66b1841da70a369c65d938fa8c99))
* **131-03:** route default_handler.ex seams through Config.dunning_engine() ([61466f2](https://github.com/szTheory/accrue/commit/61466f2cd754a22dbb62e288c846a32b86dcf63f))
* **131-04:** add conditionally-compiled Chimeway dunning engine adapter ([b380e08](https://github.com/szTheory/accrue/commit/b380e08ac346fc5b26355b4ad3445cb14795eaef))
* **133-01:** add pg_trgm and search indices migration ([db227df](https://github.com/szTheory/accrue/commit/db227dff7efd30d32e79ae0cdf464db9bb4f9715))
* **133-01:** expose unified search API in billing facade ([7c31c68](https://github.com/szTheory/accrue/commit/7c31c686c6d5bb4ea619f37d8e143414244e5841))
* **133-01:** implement billing search service ([8ac6bff](https://github.com/szTheory/accrue/commit/8ac6bffd51d9c6de030d809164ddd2f83db8b4e7))


### Bug Fixes

* **123:** CR-01 fail closed (no raise) on non-stringable :id ([f829506](https://github.com/szTheory/accrue/commit/f829506ccefcf62d76940b196e975b1efc9ae8ef))
* **123:** WR-01 deterministic cross-plan quota merge (union, max) ([35fb7f0](https://github.com/szTheory/accrue/commit/35fb7f07597821c24afc7230bb18e9412e052353))
* **123:** WR-04 exclude ended subscriptions from entitlements read path ([d9cde69](https://github.com/szTheory/accrue/commit/d9cde69e02af3a3a45be99d9f7f17f38aca13947))
* **124:** stash resolved billable on :live surface (CR-01) ([aecd640](https://github.com/szTheory/accrue/commit/aecd6400ed3a2c8b3385c1992f6489d7c9837526))
* **126:** WR-01 exclude :expired grace rows from unmapped drift detection ([3970521](https://github.com/szTheory/accrue/commit/397052109bc47a25d088f26035d1db2139cfbbb3))
* **127:** make entitlement-summary reducer reachable on the real webhook path (CR-01) ([34ecc32](https://github.com/szTheory/accrue/commit/34ecc32eca0a9052eb479b5c510efaea1a8350b1))
* **127:** seed telemetry.md fixture for package docs verifier test ([9b47fa8](https://github.com/szTheory/accrue/commit/9b47fa83e2eeab436d349df30fd7d41dce12f637))
* **128:** CR-01 give dunning step-2/step-3 emails delivery-level idempotency ([e340718](https://github.com/szTheory/accrue/commit/e3407184fe8a748e7a5ea9ba9dce1301cdd684c8))
* **128:** CR-02 stop dunning a terminal (:unpaid) subscription ([6765238](https://github.com/szTheory/accrue/commit/67652386bb85a7c3db0bf0ccda5770cba9880803))
* **128:** restore deleted :mailer env in config_test (full-suite isolation) ([8ff5ec3](https://github.com/szTheory/accrue/commit/8ff5ec332fe48c94196507dc8ec02ab9b9d5c9e9))
* **128:** WR-01 derive dunning grace_days/campaign defaults from one source ([5512ae8](https://github.com/szTheory/accrue/commit/5512ae87f84da139edfb3fb2092ca21fdf0a3289))
* **128:** WR-02 end the journey when a delivered step left the live cadence ([75f8502](https://github.com/szTheory/accrue/commit/75f8502a7470376490b5ecf57f80e7b8e5e52cfd))
* **128:** WR-03 read Accrue.Clock in dunning_source/2 for determinism ([54d3428](https://github.com/szTheory/accrue/commit/54d34289d994652e451fbb2d0b2f0c01b5024244))
* **128:** WR-04 use schema-valid :dunning values in test fixtures ([0eb7c39](https://github.com/szTheory/accrue/commit/0eb7c395fb6a59b8aaf46e309f8c3543389fa6bf))
* **128:** WR-05 narrow safe_deliver/2 catch and enrich dispatch telemetry ([6743dab](https://github.com/szTheory/accrue/commit/6743dab9fb2fd11fa506a9319f6718ea3b9547fb))
* **128:** WR-06 correct property-test moduledoc boundary semantics ([494c477](https://github.com/szTheory/accrue/commit/494c4774acdcd3f4073b90bad8a203954114e1b3))
* **130:** CR-01 Fake.capabilities/0 smart_retry_alignment false not true ([a132c9f](https://github.com/szTheory/accrue/commit/a132c9f29891dc5d54769ce7716cf90165b96835))
* **130:** CR-02 use Map.get in translate_customer_payment_methods to avoid KeyError ([ef07977](https://github.com/szTheory/accrue/commit/ef079773ed1e7cdcdcdb86e86952f443a6ce949c))
* **130:** WR-01 replace float division in money_string/1 and create_refund/2 with integer arithmetic ([d75d547](https://github.com/szTheory/accrue/commit/d75d54762e587bfb70e4169bb0103d9d209b7a2d))
* **130:** WR-02 add plain-map passthrough clause to translate_resource/1 in stripe.ex ([7d5f213](https://github.com/szTheory/accrue/commit/7d5f2136a252cf19a0daec8692b18254eecb98cd))
* **130:** WR-04 make telemetry handler names unique in dunning journey test to prevent duplicate-attach errors ([e0db86d](https://github.com/szTheory/accrue/commit/e0db86ddbaf4d1f8113f046f3f4e2cd44d75546a))

## [1.1.2](https://github.com/szTheory/accrue/compare/accrue-v1.1.1...accrue-v1.1.2) (2026-05-08)


### Bug Fixes

* remove dead portal checkout dialyzer fallback ([60c0ce3](https://github.com/szTheory/accrue/commit/60c0ce35052fdbd3848442065a5e07b20cac3a09))
* restore ops metrics parity across release gates ([d272b6b](https://github.com/szTheory/accrue/commit/d272b6b41cf3bdd895d9644042a232648a73a8b1))
* restore telemetry ops inventory and stable meter-event tests ([abdbf6f](https://github.com/szTheory/accrue/commit/abdbf6f9af0db1abb4f3b238c9c3c335eeb8ee60))
* trigger 1.1.2 patch release for docs contract alignment ([1e4d970](https://github.com/szTheory/accrue/commit/1e4d9709c03bb6a98f2f24d88be6e1d601994552))

## [1.1.1](https://github.com/szTheory/accrue/compare/accrue-v1.1.0...accrue-v1.1.1) (2026-05-08)


### Miscellaneous Chores

* **accrue:** Synchronize accrue-monorepo versions

## [1.1.0](https://github.com/szTheory/accrue/compare/accrue-v1.0.0...accrue-v1.1.0) (2026-05-08)


### Features

* **098-01:** implement payment method CRUD for braintree ([717e7d7](https://github.com/szTheory/accrue/commit/717e7d7178e9d835195aef9881ba3ea67a45ac8f))
* **099-01:** implement canonical refund facade and Braintree callbacks ([9f3d081](https://github.com/szTheory/accrue/commit/9f3d08126c0a2fc6c991c9f96db599c6e9b29fb2))
* **099-02:** implement braintree refund convergence and narrow proration support ([b1df372](https://github.com/szTheory/accrue/commit/b1df372f2ddba3d111b98ec6750747a25a1295f3))
* **100-01:** disable braintree portal capability ([47e8ce3](https://github.com/szTheory/accrue/commit/47e8ce34d24b6feefaa940533c186dc86c0506d9))
* **100-01:** fail cleanly in billing facade on unsupported gateways ([10410e2](https://github.com/szTheory/accrue/commit/10410e2b5c5b2a1006bfe2813b939aba3d171e21))
* **101-01:** lock local checkout session contract ([e3fc56a](https://github.com/szTheory/accrue/commit/e3fc56ab0cbc336445de19b6fc1e4ef55bf2319a))
* **101-03:** align braintree local portal adapter contract ([b6791f9](https://github.com/szTheory/accrue/commit/b6791f98bc228afb2ce55c5cb91823b7d5c71dda))
* **101-08:** wire portal checkout completion pipeline ([ce86b7b](https://github.com/szTheory/accrue/commit/ce86b7bb9352baf48a6fb79dd13da990cf01e450))
* **102-01:** add local discount mapping domain ([a64d25c](https://github.com/szTheory/accrue/commit/a64d25c08a933595a9861ce75d6a5888294d8ac7))
* **102-02:** emit discount mapping drift telemetry ([125151a](https://github.com/szTheory/accrue/commit/125151a60a0a06d2ec158f12e5c941a60f028208))
* **102-02:** enforce braintree discount mappings in subscribe ([a74e931](https://github.com/szTheory/accrue/commit/a74e931ed2101a76eb0262f19babae063a587462))
* **103-01:** add metering definition and renewal contracts ([c80a83c](https://github.com/szTheory/accrue/commit/c80a83c9fa1ab95187a26afc81303b1b9e698d60))
* **103-02:** implement metered renewal invoice authoring ([bc77e2d](https://github.com/szTheory/accrue/commit/bc77e2d9f94eb2db65d0292e7a4d83011ef5acc4))
* **103-03:** implement metered renewal settlement ([6c668b1](https://github.com/szTheory/accrue/commit/6c668b10ed43bf05e0c84dca585a48c7fe98dda1))
* **103-04:** implement metered renewal backstop telemetry ([aabda22](https://github.com/szTheory/accrue/commit/aabda22831bfd5ecfb8c1618dd3b11f2f74d0ba8))
* **112-01:** promote bounded customer update contract ([1b4f623](https://github.com/szTheory/accrue/commit/1b4f62352b4dd61d2cddcd6aff7c9eb4cf0ed4ca))
* **112-02:** promote customer update support truth ([12ae9ac](https://github.com/szTheory/accrue/commit/12ae9ac4fbabafe66970caaa1f095d9606806bd1))
* **112-03:** add host customer update helper ([a64b259](https://github.com/szTheory/accrue/commit/a64b259efa1f469f564f77b49d1bac80703576f3))
* **113-01:** promote immediate cancellation support truth ([1c55f1e](https://github.com/szTheory/accrue/commit/1c55f1ef48ebe74a48e2342a2aef62c896290578))
* **118-01:** promote quantity and item support contract ([3cb03fc](https://github.com/szTheory/accrue/commit/3cb03fc02f184dcc931705eada906ed8cc40b71b))
* **118-03:** add thin host plan change seam ([3e84edd](https://github.com/szTheory/accrue/commit/3e84edd765c82e7ff5215ab5ac0cc72d9a958f06))
* **119:** close subscription change support contract ([03e6c9b](https://github.com/szTheory/accrue/commit/03e6c9b9ae2520f9566fba43e3adb3b9513bdf8a))
* **94-01:** lock processor support posture ([5cedca6](https://github.com/szTheory/accrue/commit/5cedca6741180ce9a4b8b3e0c38e2e29d5f8a1ca))
* **96-01:** branch subscribe/3 for braintree at processor seam ([85e44f6](https://github.com/szTheory/accrue/commit/85e44f687b952a1b8b50aee60b7f85c62132e459))
* **processor:** harden phase 95 support contract ([1ca55ec](https://github.com/szTheory/accrue/commit/1ca55ecffacf811e584b9f8ce583ae9a4fa3e9b6))


### Bug Fixes

* **092-01:** keep package changelogs at package root ([ee8792f](https://github.com/szTheory/accrue/commit/ee8792ff7632252958ae2fee82aa8ba2faeff38c))
* **098:** close review findings and normalize locks ([e277987](https://github.com/szTheory/accrue/commit/e2779872e11443bf1036c92904159cd66c18dc3a))
* **098:** support braintree host customer flow ([7b8275d](https://github.com/szTheory/accrue/commit/7b8275d9789e8267008e05958b7c77579238e1ca))
* **102:** compensate reserved mappings on gateway failure ([e34c795](https://github.com/szTheory/accrue/commit/e34c795f611db52ff7f0bc1a3de81d66048d510a))
* **102:** release reservations on pre-gateway failures ([a6fbee7](https://github.com/szTheory/accrue/commit/a6fbee75f283ca5a8f8249a7c4a475831a940f42))
* **102:** reserve discount mappings before braintree create ([22db22c](https://github.com/szTheory/accrue/commit/22db22c76f5b46d277185b4ce29a70a1ba9bd825))
* **112-02:** lock customer update proof bundle ([29528fa](https://github.com/szTheory/accrue/commit/29528fa292707e3d2710f03bfab60135524d0279))
* **112:** preserve metadata merge semantics ([63fa708](https://github.com/szTheory/accrue/commit/63fa708cb65ee63e74dd1dc7619c61cf511e392d))
* **113-01:** lock cancellation semantics behind facade and adapter proof ([fca2dff](https://github.com/szTheory/accrue/commit/fca2dffdf1677a6e87e509856b15d7f1061bb56e))

## [0.3.1](https://github.com/szTheory/accrue/compare/accrue-v0.3.0...accrue-v0.3.1) (2026-04-22)

### Miscellaneous Chores

* **accrue:** Synchronize accrue-monorepo versions

## [0.3.0](https://github.com/szTheory/accrue/compare/accrue-v0.2.0...accrue-v0.3.0) (2026-04-20)

### Bug Fixes

* **ci:** keep package `mix.exs` `@version` aligned with published Hex ([13bfece](https://github.com/szTheory/accrue/commit/13bfece3a7325ace974bc119b3699321781e9d51))
* **ci:** restore accrue and accrue_admin `mix.exs` `@version` to 0.2.0 ([2d15aa8](https://github.com/szTheory/accrue/commit/2d15aa84641da2bdd947b8ba1b1b59ef32c3c792))
* **monorepo:** align accrue 0.3.0 with accrue_admin for CI lockstep ([017b38b](https://github.com/szTheory/accrue/commit/017b38bf73b7725b5da6fb6b26cebc8c2a3a7d6a))

## [0.2.0](https://github.com/szTheory/accrue/compare/accrue-v0.1.2...accrue-v0.2.0) (2026-04-19)


### Features

* **12-05:** add installer preflight diagnostics ([d2f55a5](https://github.com/szTheory/accrue/commit/d2f55a5890ca81f73708fcd3a2d36562519e1b48))
* **12-05:** add shared setup diagnostics for boot and webhook failures ([47bc87c](https://github.com/szTheory/accrue/commit/47bc87cb162142d3c91603acf29245c09104fb1b))
* **13-02:** enforce canonical demo docs parity ([dff967a](https://github.com/szTheory/accrue/commit/dff967a9c19355e2568afb90225e4d27c09b90d7))
* **13-02:** narrow package docs shell invariants ([d8058fa](https://github.com/szTheory/accrue/commit/d8058fa0fd397eb1a9506a537678eb99a4754016))
* **15-01:** add trust leakage and release gate guardrails ([7de4df6](https://github.com/szTheory/accrue/commit/7de4df6a9efb10c0e83d7d082c285ba33758f1de))
* **18-01:** add subscription automatic tax option ([0eb7c00](https://github.com/szTheory/accrue/commit/0eb7c003b6da9d9a643254c8a4cfbb3030d11f2d))
* **18-02:** add fake automatic tax payload parity ([4fcb736](https://github.com/szTheory/accrue/commit/4fcb736a8579f64046086a22c07a22cf70933a43))
* **18-03:** add automatic tax billing columns ([a4d6b19](https://github.com/szTheory/accrue/commit/a4d6b19e1d13bdb845a47119691f47504f35d2f0))
* **18-03:** project automatic tax billing state ([d04e7dc](https://github.com/szTheory/accrue/commit/d04e7dcf647d58b3e5acb271d674d8f4d08e6ce4))
* **18-04:** add checkout automatic tax contract ([ce4b5cb](https://github.com/szTheory/accrue/commit/ce4b5cbe832231dcb72e159c370ef47d70b1ece3))
* **19-01:** add deterministic fake tax location failures ([2cd27d8](https://github.com/szTheory/accrue/commit/2cd27d8cd6df2cf35076f5e48f892da80e95069d))
* **19-01:** add stable stripe tax location errors ([50ad8d2](https://github.com/szTheory/accrue/commit/50ad8d2173bb602a6f140d918c6f8ec40f73387d))
* **19-02:** add public customer tax location update API ([f87de8c](https://github.com/szTheory/accrue/commit/f87de8c7fc7c173747542de75e10d0353d2f44a4))
* **19-03:** add tax rollout safety observability columns ([f896f3a](https://github.com/szTheory/accrue/commit/f896f3ab6bc63d9890d59e6b37d4d644d196dcfd))
* **19-03:** reconcile tax rollout failure state ([06a96b6](https://github.com/szTheory/accrue/commit/06a96b6cb94a7bcac80df60c416b77e817c4140e))
* **accrue:** refine config, Connect, webhooks, telemetry; fix Hex smoke ([8fef57d](https://github.com/szTheory/accrue/commit/8fef57d8c3ac6a8ea5e197f0f1f33d05110f774a))
* **host,docs,ci:** adoption proof matrix and VERIFY-01 clarity ([10b5e20](https://github.com/szTheory/accrue/commit/10b5e2032b8f63c3b833311b010e838ce894dbb5))
* v1.4 ecosystem stability, demo visuals, and admin browser bundle ([647e683](https://github.com/szTheory/accrue/commit/647e68308857d6e1e82422afd783b177e55be7d8))


### Bug Fixes

* **10-04:** prove generated billing facade and installer idempotence ([57ba5be](https://github.com/szTheory/accrue/commit/57ba5be0967b78cf99c6ee16c0cab72b02a51b0d))
* **12-03:** implement installer rerun conflict contract ([00356b0](https://github.com/szTheory/accrue/commit/00356b0df2bbefe6a0837d22cbdd24fb75491267))
* **12-07:** activate strict package docs verifier ([68e300a](https://github.com/szTheory/accrue/commit/68e300acae1187b44ff1d41880c63da954a25d8d))
* **12-09:** let preflight honor runtime auth adapter config ([0b3692c](https://github.com/szTheory/accrue/commit/0b3692c5c3f27310caf8ea61531a186d00f7f0e3))
* **12-09:** scope webhook preflight to the mounted route ([e01207f](https://github.com/szTheory/accrue/commit/e01207fa5b82f3e3463bbdcec74842c3dcb4c506))
* **12-09:** surface migration inspection failures as setup diagnostics ([31c673f](https://github.com/szTheory/accrue/commit/31c673ff3db4cc09c62d91697f0c1a22914c072e))
* **12-10:** align webhook config guidance with runtime contract ([e40cc9e](https://github.com/szTheory/accrue/commit/e40cc9eceb3cc426246aed9c77d493bd1b051b16))
* **13-01:** delegate host uat wrapper to verify.full ([65a0205](https://github.com/szTheory/accrue/commit/65a02054a0deee6c7cbfda70e054e17a6b64ee05))
* **13:** remove docs helper default warnings ([c792ecc](https://github.com/szTheory/accrue/commit/c792ecc9d40f6a05d06f352d2ffd91cd3c7a4c9b))
* **13:** WR-02 guard docs order helpers against missing labels ([41e4344](https://github.com/szTheory/accrue/commit/41e43442e12804c23c24a5e6d6aedcdac986837b))
* **19:** resolve tax rollout review findings ([a36d0ea](https://github.com/szTheory/accrue/commit/a36d0ea3b2177fcbc5c5b42ecc0699630868859c))
* **test:** preserve Fake connect state across BillingCase resets ([9189d7d](https://github.com/szTheory/accrue/commit/9189d7d3722b5764907f758bca701e6e83f423e8))

## [0.1.2](https://github.com/szTheory/accrue/compare/accrue-v0.1.1...accrue-v0.1.2) (2026-04-16)


### Bug Fixes

* correct hexdocs package readmes ([066483d](https://github.com/szTheory/accrue/commit/066483d236b415579a178827a4cdd45bfb5911f9))

## [0.1.1](https://github.com/szTheory/accrue/compare/accrue-v0.1.0...accrue-v0.1.1) (2026-04-16)


### Bug Fixes

* clear ci release blockers ([4dd3382](https://github.com/szTheory/accrue/commit/4dd33823c926831ef4650a7106d72c5072cac278))
* stabilize ci release gate ([edc639d](https://github.com/szTheory/accrue/commit/edc639d7027b58658991d705f4f6764beeac8ce8))
