# Changelog

## Unreleased

## [1.5.1](https://github.com/szTheory/accrue/compare/accrue_portal-v1.5.0...accrue_portal-v1.5.1) (2026-08-30)

### Notes

* Compatibility only: the linked 1.5.1 release accepts the core Decimal 3 and API-only entitlement-reader fixes. The core `accrue` package owns those capabilities; this package owns only its existing UI surface.

### Miscellaneous Chores

* **accrue_portal:** Synchronize accrue-monorepo versions

## [1.5.0](https://github.com/szTheory/accrue/compare/accrue_portal-v1.4.0...accrue_portal-v1.5.0) (2026-08-19)

### Notes

* Compatibility only: the linked 1.5.0 release resolves with the coordinated core `lattice_stripe ~> 2.0` and advisory entitlement-sync work. The core `accrue` package owns the new refresh contracts and grant-boundary documentation.


### Miscellaneous Chores

* **accrue_portal:** Synchronize accrue-monorepo versions

## [1.4.0](https://github.com/szTheory/accrue/compare/accrue_portal-v1.3.0...accrue_portal-v1.4.0) (2026-06-01)


### Bug Fixes

* **152:** CR-03 add fallback mount/3 clause in CheckoutLive ([117c4ce](https://github.com/szTheory/accrue/commit/117c4ce4f6cb086f0686bcf82eec48f7aaddefdb))
* **152:** WR-01 fix format_minor_amount sign loss for sub-dollar negatives ([285a03f](https://github.com/szTheory/accrue/commit/285a03f9c5b1dc908931106d23add241f064df72))
* **152:** WR-02 add integer and catch-all clauses to parse_amount_minor/1 ([a91c2cd](https://github.com/szTheory/accrue/commit/a91c2cdf5e9bd1c2bded0aa1b18faee6075aada4))

## [1.3.0](https://github.com/szTheory/accrue/compare/accrue_portal-v1.2.0...accrue_portal-v1.3.0) (2026-05-30)


### Bug Fixes

* **151-03:** resolve test coverage blockers ([21f5d6e](https://github.com/szTheory/accrue/commit/21f5d6e205eef2ad523f5d621338c5f1e6118838))
* **152-02:** resolve pre-existing credo issues blocking Three Zeros gate ([bd72ec1](https://github.com/szTheory/accrue/commit/bd72ec15058507eab6657db412612caf80ac9698))

## [1.2.0](https://github.com/szTheory/accrue/compare/accrue_portal-v1.1.2...accrue_portal-v1.2.0) (2026-05-26)


### Features

* **129-03:** render provider-aware portal recovery banner (DUN-06) ([5113a60](https://github.com/szTheory/accrue/commit/5113a60bce93a02ae5deb12985ee01a4f1d52e87))

## [1.1.2](https://github.com/szTheory/accrue/compare/accrue_portal-v1.1.1...accrue_portal-v1.1.2) (2026-05-08)


### Bug Fixes

* trigger 1.1.2 patch release for docs contract alignment ([1e4d970](https://github.com/szTheory/accrue/commit/1e4d9709c03bb6a98f2f24d88be6e1d601994552))

## [1.1.1](https://github.com/szTheory/accrue/compare/accrue_portal-v1.1.0...accrue_portal-v1.1.1) (2026-05-08)


### Bug Fixes

* add missing accrue_portal package license ([fc92978](https://github.com/szTheory/accrue/commit/fc929783aad92be2c41641e0dee6a0fdf624464a))
* **portal:** add missing package license ([f6ad680](https://github.com/szTheory/accrue/commit/f6ad680ccebf6a25cba3e0b5dec00880ef61c48d))

## [1.1.0](https://github.com/szTheory/accrue/compare/accrue_portal-v1.0.0...accrue_portal-v1.1.0) (2026-05-08)


### Features

* **101-02:** align portal mount contract ([6ab10c3](https://github.com/szTheory/accrue/commit/6ab10c363ed8f6e91efee94f7e0f2b99b0512518))
* **101-04:** ship hosted checkout flow ([7941c5d](https://github.com/szTheory/accrue/commit/7941c5d7eb65662ce35f2353c137e88aaca6a675))
* **101-05:** add customer-scoped subscription portal flows ([e55434b](https://github.com/szTheory/accrue/commit/e55434bf539c6f65b0047368cfacda4babc071bf))
* **101-06:** finish portal payment method surfaces ([a74de65](https://github.com/szTheory/accrue/commit/a74de65ed808061be56eb151604cea0a415e6f44))
* **101-07:** lock portal shell proof and braintree test seam ([403deba](https://github.com/szTheory/accrue/commit/403deba5c7e01cb8b6f709d7316bb96c87e2665f))
* **101-07:** publish portal runtime dependency contract ([9495f88](https://github.com/szTheory/accrue/commit/9495f886aa097f09c112bef64871c724a9c930e9))
* **101-08:** wire portal checkout completion pipeline ([ce86b7b](https://github.com/szTheory/accrue/commit/ce86b7bb9352baf48a6fb79dd13da990cf01e450))
* **101-09:** add portal test fixtures and auth assertions ([836880b](https://github.com/szTheory/accrue/commit/836880b6e0fbc75ebb986b6dcdfac7e3787d3da0))
* **102-03:** add portal promo preview and revalidation ([60111cf](https://github.com/szTheory/accrue/commit/60111cf624f8297b97fe0925d083849353e03aa5))
* **118-03:** add bounded portal plan change flow ([1d66cb2](https://github.com/szTheory/accrue/commit/1d66cb235587d894ceaa6650ba40fc1256421480))


### Bug Fixes

* **101-09:** prove portal customer scoping end to end ([fb8315f](https://github.com/szTheory/accrue/commit/fb8315f5f0bd8cbaeb4392db48ab4f45808fc011))
* **101-10:** prove portal payment and invoice boundaries ([184500a](https://github.com/szTheory/accrue/commit/184500a88daf64adf09697518cf5bf442ecaf701))
* **113-02:** gate portal cancellation flows by provider ([d20fdc1](https://github.com/szTheory/accrue/commit/d20fdc1758709ecd7aa0c2b083709f16322868bd))
* **113:** tighten braintree destructive action gating ([3340b33](https://github.com/szTheory/accrue/commit/3340b3345ae52beb8263e56050e69e9ec6629263))

## 1.0.0

- Initial `accrue_portal` package with mounted customer portal, local Braintree
  checkout, payment-method management, subscriptions, and invoice views.
