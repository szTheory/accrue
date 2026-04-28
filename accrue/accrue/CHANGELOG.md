# Changelog

## [0.4.0](https://github.com/szTheory/accrue/compare/accrue-v0.3.1...accrue-v0.4.0) (2026-04-26)


### Features

* **080-01:** add Billing.create_checkout_session facade (BIL-06) ([7a8c6d3](https://github.com/szTheory/accrue/commit/7a8c6d3df8026e19cb6fe4d818305a4f08534077))
* **088-01:** add :mailglass path dep to accrue/mix.exs ([69257d7](https://github.com/szTheory/accrue/commit/69257d7bc51d61fc7b28c988d6af37c220bdeb58))
* **089-01:** add Mailglass email pipeline seam ([66cce2f](https://github.com/szTheory/accrue/commit/66cce2f8ea6732bfb5e13be585cd506eba5e348d))
* **40:** telemetry guide truth, ops contract, and DLQ dead-letter emit ([e6dc647](https://github.com/szTheory/accrue/commit/e6dc6479a2c4d1c902a754f92c328674cd2310ab))
* **43-03:** add Accrue.Test.meter_events_for/1 Fake facade (MTR-03) ([a511f8f](https://github.com/szTheory/accrue/commit/a511f8f10a965a4f77e950a93ce0aec53c5da70b))
* **44:** meter failure telemetry choke and webhook ctx ([bf106ed](https://github.com/szTheory/accrue/commit/bf106ed4d81ea31b20d6cd13801575c78234c8b8))
* **56-01:** Billing façade list_payment_methods with billing span ([e822bab](https://github.com/szTheory/accrue/commit/e822bab5778cf0126162a4291ba176e7fd802caa))
* **56-01:** PaymentMethodActions list_payment_methods via processor ([a11abb2](https://github.com/szTheory/accrue/commit/a11abb2cdd7b539c32cf41ee8480de30da6dc015))
* **78-01:** add Billing portal session facade on Accrue.Billing ([2f3272c](https://github.com/szTheory/accrue/commit/2f3272c3bb4fd4842321251a85c44bb02d280203))
* **90-01:** port first mail templates to Mailglass ([2cc6e0b](https://github.com/szTheory/accrue/commit/2cc6e0b9fa1c814026e8abbba6aab632a99ed352))
* **90-02:** port invoice and discount mailers to Mailglass ([38e130f](https://github.com/szTheory/accrue/commit/38e130f846255523b7d420039fc9c9ece4050a66))
* **90-03:** retire legacy MJML assets and preview docs ([1a6a51a](https://github.com/szTheory/accrue/commit/1a6a51a196ca3f44477242e2b2e2cdef5133e9e2))


### Bug Fixes

* **44:** bound meter_reporting_failed error text for sync and reconciler ([7f0f16c](https://github.com/szTheory/accrue/commit/7f0f16c3fb8be71f8d2be4e52436c5282345642a))
* **56-01:** keep Stripe list filters out of processor HTTP opts ([ff50eb5](https://github.com/szTheory/accrue/commit/ff50eb55843d6ed57847503f61f1634f59c454d7))
* **ci:** dialyzer-clean Oban workers + stabilize PM list test ([627550e](https://github.com/szTheory/accrue/commit/627550e976858509f96eb8cbddf4de0ac4125612))
* **dialyzer:** remove unreachable clauses in auth, invoices, webhooks ([5bf6052](https://github.com/szTheory/accrue/commit/5bf6052393515476531598c14055ff51fbc3ad6d))
* **docs:** satisfy ExDoc --warnings-as-errors in CI ([e77d0a0](https://github.com/szTheory/accrue/commit/e77d0a0095697587cdff070e473e3579eda3f33b))
* mix format auto-fix for v1.29 Mailglass commits ([#16](https://github.com/szTheory/accrue/issues/16)) ([18c2627](https://github.com/szTheory/accrue/commit/18c2627d6d07eea4a221c06c464478d523cda106))
