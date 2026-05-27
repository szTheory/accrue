# Changelog

## Unreleased

**1.0.0 — Stable.** Released in lockstep with `accrue` 1.0.0. The supported integration surface for the admin package is `AccrueAdmin.Router` and the documented mount/scope helpers; see `accrue/CHANGELOG.md` and `accrue/guides/maturity-and-maintenance.md` for the v1.x stability commitment that governs both packages.

### Host-visible copy (accrue_admin)

- Webhook replay confirmations, bulk DLQ prompts, and related operator strings now live in `AccrueAdmin.Copy` / `AccrueAdmin.Copy.Locked` (Phase 27). Hosts that snapshot admin flash or HEEx literals should diff package tests when upgrading.

## [1.2.0](https://github.com/szTheory/accrue/compare/accrue_admin-v1.1.2...accrue_admin-v1.2.0) (2026-05-26)


### Features

* **126-02:** add Copy.Entitlements submodule, defdelegates, export allowlist ([4fa9094](https://github.com/szTheory/accrue/commit/4fa90942351c810bf62c1103b2823e2c8847e5a5))
* **126-02:** add read-only entitlements tab to CustomerLive ([474505d](https://github.com/szTheory/accrue/commit/474505d1656a123904a3d42ffb1fcd65f171c17e))
* **129-04:** add dunning panel Copy strings (defs + delegates) ([d49fe88](https://github.com/szTheory/accrue/commit/d49fe88f9ddbb70ab4f04d09e05db61a821756f1))
* **129-04:** render read-only dunning-state ax-card + next-action/badge helpers ([b47ed88](https://github.com/szTheory/accrue/commit/b47ed88da333876c0fec3d638e5db18ac366f6e0))


### Bug Fixes

* **126:** CR-01 guard entitlements resolution against render-time crash (IN-01) ([0544d73](https://github.com/szTheory/accrue/commit/0544d73347e2910d0ed4fd2bed5e330f195d5fdc))
* **126:** WR-02 clean empty-state for drift-only customers ([8f9ff9b](https://github.com/szTheory/accrue/commit/8f9ff9bba1993c907951a4f329de5303e09c71ec))
* **126:** WR-04 compute entitlements result into socket assign for render purity ([63b9596](https://github.com/szTheory/accrue/commit/63b959612e74365b3e4e5ea47aa96a9c24a6c7fc))

## [1.1.2](https://github.com/szTheory/accrue/compare/accrue_admin-v1.1.1...accrue_admin-v1.1.2) (2026-05-08)


### Bug Fixes

* trigger 1.1.2 patch release for docs contract alignment ([1e4d970](https://github.com/szTheory/accrue/commit/1e4d9709c03bb6a98f2f24d88be6e1d601994552))

## [1.1.1](https://github.com/szTheory/accrue/compare/accrue_admin-v1.1.0...accrue_admin-v1.1.1) (2026-05-08)


### Miscellaneous Chores

* **accrue_admin:** Synchronize accrue-monorepo versions

## [1.1.0](https://github.com/szTheory/accrue/compare/accrue_admin-v1.0.0...accrue_admin-v1.1.0) (2026-05-08)


### Features

* **098-02:** add admin payment method operator controls ([03b4bd0](https://github.com/szTheory/accrue/commit/03b4bd0659d6f070d4f4d31aa895559b73007eb9))
* **099-03:** implement LiveView charge detail refund capabilities ([cb1d44f](https://github.com/szTheory/accrue/commit/cb1d44fd2bd7e75ba0d9df0abf5512d0d2adf617))
* **118-02:** add admin subscription change actions ([9430313](https://github.com/szTheory/accrue/commit/94303131d5a2b78fa923bb9ac367dc4dde8e1fac))
* **119:** close subscription change support contract ([03e6c9b](https://github.com/szTheory/accrue/commit/03e6c9b9ae2520f9566fba43e3adb3b9513bdf8a))


### Bug Fixes

* **092-01:** keep package changelogs at package root ([ee8792f](https://github.com/szTheory/accrue/commit/ee8792ff7632252958ae2fee82aa8ba2faeff38c))
* **098:** close review findings and normalize locks ([e277987](https://github.com/szTheory/accrue/commit/e2779872e11443bf1036c92904159cd66c18dc3a))
* **113-02:** gate portal cancellation flows by provider ([d20fdc1](https://github.com/szTheory/accrue/commit/d20fdc1758709ecd7aa0c2b083709f16322868bd))
* **113:** tighten braintree destructive action gating ([3340b33](https://github.com/szTheory/accrue/commit/3340b3345ae52beb8263e56050e69e9ec6629263))

## [0.3.1](https://github.com/szTheory/accrue/compare/accrue_admin-v0.3.0...accrue_admin-v0.3.1) (2026-04-22)

### Bug Fixes

* **ci:** keep package `mix.exs` `@version` aligned with published Hex ([13bfece](https://github.com/szTheory/accrue/commit/13bfece3a7325ace974bc119b3699321781e9d51))
* **ci:** restore accrue and accrue_admin `mix.exs` `@version` to 0.2.0 ([2d15aa8](https://github.com/szTheory/accrue/commit/2d15aa84641da2bdd947b8ba1b1b59ef32c3c792))
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
* **ci:** keep package `mix.exs` `@version` aligned with published Hex ([13bfece](https://github.com/szTheory/accrue/commit/13bfece3a7325ace974bc119b3699321781e9d51))
* **ci:** restore accrue and accrue_admin `mix.exs` `@version` to 0.2.0 ([2d15aa8](https://github.com/szTheory/accrue/commit/2d15aa84641da2bdd947b8ba1b1b59ef32c3c792))
* clear ci release blockers ([4dd3382](https://github.com/szTheory/accrue/commit/4dd33823c926831ef4650a7106d72c5072cac278))
* correct hexdocs package readmes ([066483d](https://github.com/szTheory/accrue/commit/066483d236b415579a178827a4cdd45bfb5911f9))
* migrate e2e database from correct path ([c12a3f4](https://github.com/szTheory/accrue/commit/c12a3f4bb96e82771daa58fba89a84449f68bdcf))
* **monorepo:** align accrue 0.3.0 with accrue_admin for CI lockstep ([017b38b](https://github.com/szTheory/accrue/commit/017b38bf73b7725b5da6fb6b26cebc8c2a3a7d6a))
* stabilize ci release gate ([edc639d](https://github.com/szTheory/accrue/commit/edc639d7027b58658991d705f4f6764beeac8ce8))

## [0.2.0](https://github.com/szTheory/accrue/compare/accrue_admin-v0.1.2...accrue_admin-v0.2.0) (2026-04-19)


### Features

* **15-02:** harden responsive browser trust coverage ([60e4984](https://github.com/szTheory/accrue/commit/60e498483a6e84bf5950c778fa06d7eeed741fc8))
* **19-04:** surface admin tax risk state ([f41d539](https://github.com/szTheory/accrue/commit/f41d53996223cd62ef1b3623985f05a690aed778))
* **20-03:** thread admin owner scope through mount session ([349c6ab](https://github.com/szTheory/accrue/commit/349c6ab86abbb1e0c43e3df52041ba45fd30609c))
* **20-04:** enforce owner-aware admin loaders ([2568995](https://github.com/szTheory/accrue/commit/25689955e56099d916be8853ee86e8a5e0522cf6))
* **20-05:** deny scoped customer and subscription detail routes ([fa13ca1](https://github.com/szTheory/accrue/commit/fa13ca1388794917bcebea567a287b713d600c1b))
* **20-05:** scope admin event feeds to the active organization ([0084d8e](https://github.com/szTheory/accrue/commit/0084d8eee742ca0b696ca46b525688f9c6eb5f5c))
* **20-06:** gate webhook replay on owner proof ([b909dff](https://github.com/szTheory/accrue/commit/b909dff9a8768e97fff5311fab60766bb0e79069))
* v1.4 ecosystem stability, demo visuals, and admin browser bundle ([647e683](https://github.com/szTheory/accrue/commit/647e68308857d6e1e82422afd783b177e55be7d8))


### Bug Fixes

* **12-07:** activate strict package docs verifier ([68e300a](https://github.com/szTheory/accrue/commit/68e300acae1187b44ff1d41880c63da954a25d8d))
* **19:** resolve tax rollout review findings ([a36d0ea](https://github.com/szTheory/accrue/commit/a36d0ea3b2177fcbc5c5b42ecc0699630868859c))
* **20:** close admin organization scope gaps ([fabea14](https://github.com/szTheory/accrue/commit/fabea1448e2cf0a33dfab0405c4527c241046b1a))
* **20:** resolve org billing review findings ([061b818](https://github.com/szTheory/accrue/commit/061b8186d106e5bb364193a0179ecf7c92956ec1))

## [0.1.2](https://github.com/szTheory/accrue/compare/accrue_admin-v0.1.1...accrue_admin-v0.1.2) (2026-04-16)


### Bug Fixes

* correct hexdocs package readmes ([066483d](https://github.com/szTheory/accrue/commit/066483d236b415579a178827a4cdd45bfb5911f9))

## [0.1.1](https://github.com/szTheory/accrue/compare/accrue_admin-v0.1.0...accrue_admin-v0.1.1) (2026-04-16)


### Bug Fixes

* clear ci release blockers ([4dd3382](https://github.com/szTheory/accrue/commit/4dd33823c926831ef4650a7106d72c5072cac278))
* migrate e2e database from correct path ([c12a3f4](https://github.com/szTheory/accrue/commit/c12a3f4bb96e82771daa58fba89a84449f68bdcf))
* stabilize ci release gate ([edc639d](https://github.com/szTheory/accrue/commit/edc639d7027b58658991d705f4f6764beeac8ce8))
