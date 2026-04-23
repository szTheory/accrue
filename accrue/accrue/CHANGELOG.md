# Changelog

## [0.4.0](https://github.com/szTheory/accrue/compare/accrue-v0.3.1...accrue-v0.4.0) (2026-04-23)


### Features

* **37-03:** print org billing and auth guide paths from installer ([f10109f](https://github.com/szTheory/accrue/commit/f10109fa6e63f56fb2a364f66051392124e39216))
* **39-03:** ORG-09 guide spine and ExUnit matrix script smoke ([3cb7574](https://github.com/szTheory/accrue/commit/3cb7574b19f92a3aae0c9e172b4bb6db049fee9a))
* **40:** telemetry guide truth, ops contract, and DLQ dead-letter emit ([e6dc647](https://github.com/szTheory/accrue/commit/e6dc6479a2c4d1c902a754f92c328674cd2310ab))
* **43-03:** add Accrue.Test.meter_events_for/1 Fake facade (MTR-03) ([a511f8f](https://github.com/szTheory/accrue/commit/a511f8f10a965a4f77e950a93ce0aec53c5da70b))
* **44:** meter failure telemetry choke and webhook ctx ([bf106ed](https://github.com/szTheory/accrue/commit/bf106ed4d81ea31b20d6cd13801575c78234c8b8))
* **56-01:** Billing façade list_payment_methods with billing span ([e822bab](https://github.com/szTheory/accrue/commit/e822bab5778cf0126162a4291ba176e7fd802caa))
* **56-01:** PaymentMethodActions list_payment_methods via processor ([a11abb2](https://github.com/szTheory/accrue/commit/a11abb2cdd7b539c32cf41ee8480de30da6dc015))


### Bug Fixes

* **44:** bound meter_reporting_failed error text for sync and reconciler ([7f0f16c](https://github.com/szTheory/accrue/commit/7f0f16c3fb8be71f8d2be4e52436c5282345642a))
* **56-01:** keep Stripe list filters out of processor HTTP opts ([ff50eb5](https://github.com/szTheory/accrue/commit/ff50eb55843d6ed57847503f61f1634f59c454d7))
* **ci:** dialyzer-clean Oban workers + stabilize PM list test ([627550e](https://github.com/szTheory/accrue/commit/627550e976858509f96eb8cbddf4de0ac4125612))
* **dialyzer:** remove unreachable clauses in auth, invoices, webhooks ([5bf6052](https://github.com/szTheory/accrue/commit/5bf6052393515476531598c14055ff51fbc3ad6d))
* **docs:** satisfy ExDoc --warnings-as-errors in CI ([e77d0a0](https://github.com/szTheory/accrue/commit/e77d0a0095697587cdff070e473e3579eda3f33b))

## [0.3.1](https://github.com/szTheory/accrue/compare/accrue-v0.3.0...accrue-v0.3.1) (2026-04-20)


### Miscellaneous Chores

* **accrue:** Synchronize accrue-monorepo versions

## [0.3.0](https://github.com/szTheory/accrue/compare/accrue-v0.2.0...accrue-v0.3.0) (2026-04-20)


### Bug Fixes

* **ci:** keep package [@version](https://github.com/version) aligned with published Hex ([13bfece](https://github.com/szTheory/accrue/commit/13bfece3a7325ace974bc119b3699321781e9d51))
* **ci:** restore accrue and accrue_admin [@version](https://github.com/version) to 0.2.0 ([2d15aa8](https://github.com/szTheory/accrue/commit/2d15aa84641da2bdd947b8ba1b1b59ef32c3c792))
* **monorepo:** align accrue 0.3.0 with accrue_admin for CI lockstep ([017b38b](https://github.com/szTheory/accrue/commit/017b38bf73b7725b5da6fb6b26cebc8c2a3a7d6a))
