# Changelog

## Unreleased

### Telemetry

* **`meter_reporting_failed` metadata `source`:** rename `:inline` to `:sync` for synchronous `report_usage/3` failures so the closed set is `:sync | :reconciler | :webhook` everywhere (code, docs, default metrics). Update host dashboards or attach handlers that matched on `:inline`.

### Documentation

* Harden the telemetry guide ops catalog (evergreen heading, Primary owner column, Hex vs `main` doc contract), correct OpenTelemetry examples (including meter reporting + ops failure cross-link), add an ops event contract test, and emit `[:accrue, :ops, :webhook_dlq, :dead_lettered]` when webhook dispatch exhausts retries.

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
