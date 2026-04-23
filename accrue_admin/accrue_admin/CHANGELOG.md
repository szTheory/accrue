# Changelog

## [0.4.0](https://github.com/szTheory/accrue/compare/accrue_admin-v0.3.1...accrue_admin-v0.4.0) (2026-04-23)


### Features

* **27-01:** add AccrueAdmin.Copy for money index empty states ([6868918](https://github.com/szTheory/accrue/commit/686891814db4a2802ae6e46a585dd46365c89fce))
* **27-01:** delegate DataTable empty defaults to Copy ([b006870](https://github.com/szTheory/accrue/commit/b006870d181f5f927cc0f0be82743014d5291498))
* **27-01:** wire money index LiveViews to AccrueAdmin.Copy ([297cc64](https://github.com/szTheory/accrue/commit/297cc64ef3b18fb0eefbbb430a4ce0d7d4b7f339))
* **27-02:** add Copy.Locked and money detail copy helpers ([34fe808](https://github.com/szTheory/accrue/commit/34fe8081ad3c4af2ddca1261fbb87ce45b7a444c))
* **27-02:** migrate invoice and charge detail flashes to Copy ([0992f1e](https://github.com/szTheory/accrue/commit/0992f1ef35e1be56f24bcbf709e94bec22dd1b1e))
* **27-02:** migrate subscription and customer detail copy to Copy ([ce5c4cd](https://github.com/szTheory/accrue/commit/ce5c4cd05d27872dc076e9203dd207c58035a7d4))
* **27-03:** centralize webhook operator copy in Copy / Locked ([c2f251a](https://github.com/szTheory/accrue/commit/c2f251a07553b309f2d97e0d074cfe149d1ded7a))
* **29-02:** fixed sidebar overlay when shell nav open on mobile ([3f0a04a](https://github.com/szTheory/accrue/commit/3f0a04a15c34574794552840ea7d30bcb2ac7db3))
* **29-02:** wire mobile shell nav toggle and Escape ([0d97358](https://github.com/szTheory/accrue/commit/0d9735819cc5b6330a692d5d52bbf255208e22d4))
* **31-02:** add Copy accessors for step-up modal chrome ([61657f6](https://github.com/szTheory/accrue/commit/61657f681e97cc9bf15f848ddbf5535528135217))
* **31-02:** route step-up modal chrome through AccrueAdmin.Copy ([1acb110](https://github.com/szTheory/accrue/commit/1acb11003ca9240bcea82d2013757c7ce0599fe8))
* **34-01:** add AccrueAdmin.ScopedPath URL builder (OPS-01) ([78dd6cc](https://github.com/szTheory/accrue/commit/78dd6cc4677e6c86ec08f9320822748906bca591))
* **34-01:** link dashboard KPI cards with scoped paths (OPS-01) ([a54da4c](https://github.com/szTheory/accrue/commit/a54da4c38c3e08e573aeaf9ac0a2b1bb428f2bd2))
* **34-02:** link customer invoice rows to invoice detail (OPS-02) ([7974b38](https://github.com/szTheory/accrue/commit/7974b380a78497114778891cd628e2b1a35e017c))
* **34-02:** scope invoice breadcrumbs incl. customer crumb (OPS-02) ([afdd59b](https://github.com/szTheory/accrue/commit/afdd59bb263a9c626f86f05bce5d165825c0ec15))
* **34-03:** centralize admin nav items in AccrueAdmin.Nav (OPS-03) ([f59a243](https://github.com/szTheory/accrue/commit/f59a243576b538fb33efe92fce0d76e9973ae140))
* **35-01:** add DashboardLive copy functions to AccrueAdmin.Copy ([65090f9](https://github.com/szTheory/accrue/commit/65090f90877762a5ae1687ae948e2d7db831a5fc))
* **35-01:** route DashboardLive chrome and KPI copy through AccrueAdmin.Copy ([abade27](https://github.com/szTheory/accrue/commit/abade27c491497f09d164d1bef0619cb3c856db4))
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
* **a11y:** complete phase 28 accessibility hardening ([b60d6dd](https://github.com/szTheory/accrue/commit/b60d6dd142be40a564f6e8a868734dd5bb697760))
* **admin:** UX-01 invoices and charges index signal chips ([9b486cd](https://github.com/szTheory/accrue/commit/9b486cd9a8d0493eb1d5a9cecc0e420103ab8932))
* **admin:** UX-01 label-scale chips on customers index ([6ec0ff2](https://github.com/szTheory/accrue/commit/6ec0ff24d81b4d5b4f4c902d1d95e64787e7e6e7))
* **admin:** UX-01 subscription index billing signal chips ([0dc5c53](https://github.com/szTheory/accrue/commit/0dc5c539be9609d227701f7fb5c894911643b6c7))
* **admin:** UX-02 single ax-page on money detail screens ([188c887](https://github.com/szTheory/accrue/commit/188c887852ce87c103ad425563e044668c791d09))
* **admin:** UX-03 webhook list and detail typography parity ([23731cd](https://github.com/szTheory/accrue/commit/23731cd0a8818b1530d84b39c19200f6f48acdea))
* **phase-53:** auxiliary Copy for Connect/events and VERIFY-01 breadth ([605a92b](https://github.com/szTheory/accrue/commit/605a92b53444edcf248a1a225cedf051d18ed83d))


### Bug Fixes

* **accrue_admin:** satisfy ExDoc --warnings-as-errors on CI ([46534e5](https://github.com/szTheory/accrue/commit/46534e545ee5798e5ad16c32ecf87d0e9a4e08f5))
* **ci:** keep package [@version](https://github.com/version) aligned with published Hex ([13bfece](https://github.com/szTheory/accrue/commit/13bfece3a7325ace974bc119b3699321781e9d51))
* **ci:** restore accrue and accrue_admin [@version](https://github.com/version) to 0.2.0 ([2d15aa8](https://github.com/szTheory/accrue/commit/2d15aa84641da2bdd947b8ba1b1b59ef32c3c792))

## [0.3.1](https://github.com/szTheory/accrue/compare/accrue_admin-v0.3.0...accrue_admin-v0.3.1) (2026-04-20)


### Bug Fixes

* **ci:** keep package [@version](https://github.com/version) aligned with published Hex ([13bfece](https://github.com/szTheory/accrue/commit/13bfece3a7325ace974bc119b3699321781e9d51))
* **ci:** restore accrue and accrue_admin [@version](https://github.com/version) to 0.2.0 ([2d15aa8](https://github.com/szTheory/accrue/commit/2d15aa84641da2bdd947b8ba1b1b59ef32c3c792))
* **monorepo:** align accrue 0.3.0 with accrue_admin for CI lockstep ([017b38b](https://github.com/szTheory/accrue/commit/017b38bf73b7725b5da6fb6b26cebc8c2a3a7d6a))

## [0.3.0](https://github.com/szTheory/accrue/compare/accrue_admin-v0.2.0...accrue_admin-v0.3.0) (2026-04-20)


### Features

* **07-admin-ui-accrue-admin-08:** add admin asset build workflow and docs ([4894633](https://github.com/szTheory/accrue/commit/48946339552fa6558a844dee5c98708556a4c995))
* **07-admin-ui-accrue-admin-08:** add compile-gated dev admin surfaces ([ecc631f](https://github.com/szTheory/accrue/commit/ecc631fefbbb139849592dea9249d37c93ac2157))
* **09-05:** finish accrue_admin release docs surface ([7d60398](https://github.com/szTheory/accrue/commit/7d60398b79fa486ca9aecae84d9b63a76e6d2a25))
* **15-02:** harden responsive browser trust coverage ([60e4984](https://github.com/szTheory/accrue/commit/60e498483a6e84bf5950c778fa06d7eeed741fc8))
* **19-04:** surface admin tax risk state ([f41d539](https://github.com/szTheory/accrue/commit/f41d53996223cd62ef1b3623985f05a690aed778))
* **20-03:** thread admin owner scope through mount session ([349c6ab](https://github.com/szTheory/accrue/commit/349c6ab86abbb1e0c43e3df52041ba45fd30609c))
* **20-04:** enforce owner-aware admin loaders ([2568995](https://github.com/szTheory/accrue/commit/25689955e56099d916be8853ee86e8a5e0522cf6))
* **20-05:** deny scoped customer and subscription detail routes ([fa13ca1](https://github.com/szTheory/accrue/commit/fa13ca1388794917bcebea567a287b713d600c1b))
* **20-05:** scope admin event feeds to the active organization ([0084d8e](https://github.com/szTheory/accrue/commit/0084d8eee742ca0b696ca46b525688f9c6eb5f5c))
* **20-06:** gate webhook replay on owner proof ([b909dff](https://github.com/szTheory/accrue/commit/b909dff9a8768e97fff5311fab60766bb0e79069))
* v1.4 ecosystem stability, demo visuals, and admin browser bundle ([647e683](https://github.com/szTheory/accrue/commit/647e68308857d6e1e82422afd783b177e55be7d8))


### Bug Fixes

* **09-06:** clear release readiness blockers ([ffe3507](https://github.com/szTheory/accrue/commit/ffe350739b707960d701d326cf42a099bef20934))
* **12-07:** activate strict package docs verifier ([68e300a](https://github.com/szTheory/accrue/commit/68e300acae1187b44ff1d41880c63da954a25d8d))
* **19:** resolve tax rollout review findings ([a36d0ea](https://github.com/szTheory/accrue/commit/a36d0ea3b2177fcbc5c5b42ecc0699630868859c))
* **20:** close admin organization scope gaps ([fabea14](https://github.com/szTheory/accrue/commit/fabea1448e2cf0a33dfab0405c4527c241046b1a))
* **20:** resolve org billing review findings ([061b818](https://github.com/szTheory/accrue/commit/061b8186d106e5bb364193a0179ecf7c92956ec1))
* **ci:** keep package [@version](https://github.com/version) aligned with published Hex ([13bfece](https://github.com/szTheory/accrue/commit/13bfece3a7325ace974bc119b3699321781e9d51))
* **ci:** restore accrue and accrue_admin [@version](https://github.com/version) to 0.2.0 ([2d15aa8](https://github.com/szTheory/accrue/commit/2d15aa84641da2bdd947b8ba1b1b59ef32c3c792))
* clear ci release blockers ([4dd3382](https://github.com/szTheory/accrue/commit/4dd33823c926831ef4650a7106d72c5072cac278))
* correct hexdocs package readmes ([066483d](https://github.com/szTheory/accrue/commit/066483d236b415579a178827a4cdd45bfb5911f9))
* migrate e2e database from correct path ([c12a3f4](https://github.com/szTheory/accrue/commit/c12a3f4bb96e82771daa58fba89a84449f68bdcf))
* **monorepo:** align accrue 0.3.0 with accrue_admin for CI lockstep ([017b38b](https://github.com/szTheory/accrue/commit/017b38bf73b7725b5da6fb6b26cebc8c2a3a7d6a))
* stabilize ci release gate ([edc639d](https://github.com/szTheory/accrue/commit/edc639d7027b58658991d705f4f6764beeac8ce8))
