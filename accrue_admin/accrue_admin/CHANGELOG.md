# Changelog

## [0.4.0](https://github.com/szTheory/accrue/compare/accrue_admin-v0.3.1...accrue_admin-v0.4.0) (2026-04-26)


### Features

* **088-01:** add :mailglass_admin dev+test path dep to accrue_admin/mix.exs ([3463891](https://github.com/szTheory/accrue/commit/34638918ab6806977b5afed04bb5954d37a04a08))
* **088-02:** mount mailglass_admin_routes at /dev/mail in accrue_admin router ([99928de](https://github.com/szTheory/accrue/commit/99928de3dc4b19a2d209671a2e15878587754224))
* **48-01:** add Copy helpers for meter reporting failures KPI ([a8ba81c](https://github.com/szTheory/accrue/commit/a8ba81c84bbccbb9886cd107b283f6bd45be2b14))
* **48-01:** add failed meter event count to dashboard stats ([4c3cf80](https://github.com/szTheory/accrue/commit/4c3cf802c389b19c87fb90fd88b593ea1d371d1d))
* **48-01:** show meter reporting failures KPI first on dashboard ([af2f01b](https://github.com/szTheory/accrue/commit/af2f01b03f3c3a4f5e8862c39998a1e7d042a74a))
* **49-01:** add subscription drill copy helpers for ADM-02 ([95643f3](https://github.com/szTheory/accrue/commit/95643f3cd58fb021cad426def09fe20c50d8b863))
* **49-01:** ScopedPath breadcrumbs and related billing on SubscriptionLive ([8c245ad](https://github.com/szTheory/accrue/commit/8c245ada8676e13b07b96935ff0f7d2de610935e))
* **50-02:** add AccrueAdmin.Copy.Subscription for SubscriptionLive strings ([a2fbde6](https://github.com/szTheory/accrue/commit/a2fbde65383b4e7992654224c0dc4a691ab02e06))
* **50-02:** defdelegate subscription detail copy to Copy.Subscription ([2b283ed](https://github.com/szTheory/accrue/commit/2b283ed22ff524b6b4845c920abe03e6bbc6f7b2))
* **50-03:** add mix accrue_admin.export_copy_strings for VERIFY-01 ([d15a509](https://github.com/szTheory/accrue/commit/d15a509c44ddb20b9494272dfaf5ee95f3234874))
* **52-03:** add AccrueAdmin.Copy.Coupon and Copy.PromotionCode modules (AUX-01/02) ([de32144](https://github.com/szTheory/accrue/commit/de3214427f9eb0a72246ab5eebe422565b4fc251))
* **52-03:** defdelegate coupon and promotion_code copy through AccrueAdmin.Copy facade ([74d07e4](https://github.com/szTheory/accrue/commit/74d07e49b2bc79d96300d1732d4d32d5b081582a))
* **54-02:** add AccrueAdmin.Copy.Invoice for ADM-08 ([3c48a4f](https://github.com/szTheory/accrue/commit/3c48a4f08f3fd1ab0d3a627c86102a54daaf35c9))
* **54-02:** Copy-back InvoiceLive operator chrome (ADM-08) ([c392875](https://github.com/szTheory/accrue/commit/c3928753d0980474f5d211d433bb095ac7536d11))
* **54-02:** Copy-back InvoicesLive operator chrome (ADM-08) ([8b0d174](https://github.com/szTheory/accrue/commit/8b0d174ec381d136b914d18e2df95fda73b1acee))
* **55-01:** VERIFY-01 invoice Playwright + copy export; scope DataTables ([f9cfac5](https://github.com/szTheory/accrue/commit/f9cfac557a2971328f9788f884eac45c6efa92d3))
* **76-02:** add Copy.CustomerPaymentMethods and facade delegates ([f27f42c](https://github.com/szTheory/accrue/commit/f27f42c1af67c696d2c6571f917dd7b36a9875c2))
* **76-02:** route payment_methods tab strings through AccrueAdmin.Copy ([a1bcf7d](https://github.com/szTheory/accrue/commit/a1bcf7d2389312f1eec458ede4ec1458ce738005))
* **phase-53:** auxiliary Copy for Connect/events and VERIFY-01 breadth ([605a92b](https://github.com/szTheory/accrue/commit/605a92b53444edcf248a1a225cedf051d18ed83d))


### Bug Fixes

* **accrue_admin:** satisfy ExDoc --warnings-as-errors on CI ([46534e5](https://github.com/szTheory/accrue/commit/46534e545ee5798e5ad16c32ecf87d0e9a4e08f5))
* mix format auto-fix for v1.29 Mailglass commits ([#16](https://github.com/szTheory/accrue/issues/16)) ([18c2627](https://github.com/szTheory/accrue/commit/18c2627d6d07eea4a221c06c464478d523cda106))
