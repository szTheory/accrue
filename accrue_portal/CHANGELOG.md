# Changelog

## Unreleased

## [1.7.0](https://github.com/szTheory/accrue/compare/accrue_portal-v1.6.0...accrue_portal-v1.7.0) (2026-10-26)


### Features

* **233-01:** block denied billable contexts safely ([d07ffc0](https://github.com/szTheory/accrue/commit/d07ffc0c3b2da4b1ca5f3e3c956714ce8c610e04))
* **233-01:** resolve selected billable Portal context ([329d63e](https://github.com/szTheory/accrue/commit/329d63e5a006c1fafb33d7c0c8b687a09ca7d5b5))
* **233-02:** authorize and pin add-card creation ([12f33a4](https://github.com/szTheory/accrue/commit/12f33a475ea9dde7f4bed47a2f34d17997867075))
* **233-02:** bind default and delete actions to signed context ([1132b6c](https://github.com/szTheory/accrue/commit/1132b6c7d30ab7bc7a6a8281ae4f0226d4299287))
* **233-03:** authorize pinned subscription LiveView actions ([08f53e2](https://github.com/szTheory/accrue/commit/08f53e27d070e6bed0d95ceee3d065fc259df6a0))
* **233-03:** reauthorize portal context across LiveView events ([18bbe9c](https://github.com/szTheory/accrue/commit/18bbe9ce5c332f977733a11746f4f7fa43ac5557))
* **233-05:** add host shared billing context adapter ([e4e9752](https://github.com/szTheory/accrue/commit/e4e975269b3d16689f1892151e2a6fe50017da83))
* **233-07:** authorize pinned checkout LiveView actions ([17c2237](https://github.com/szTheory/accrue/commit/17c22370d30fbe22316784a976853b55c74ba380))
* **233-07:** enforce pinned checkout POST completion ([a2affdb](https://github.com/szTheory/accrue/commit/a2affdb2b05df94bb1be3b29989cfa3b16e6061b))
* **235-01:** submit visible Braintree checkout to server ([6ac9e5e](https://github.com/szTheory/accrue/commit/6ac9e5e0ae70f1790b6374915200b40325e1436d))
* **235-03:** align LiveView checkout outcome handling ([62f44af](https://github.com/szTheory/accrue/commit/62f44afe010a6247630da3188b6abeed071aa9dc))
* **235-03:** guard POST checkout submission outcomes ([c280b01](https://github.com/szTheory/accrue/commit/c280b01489afced21e975c7f3b7d49d4ae2892ee))
* **235-05:** accept trusted zero-priced checkout terms in POST ([275feb6](https://github.com/szTheory/accrue/commit/275feb6a317594cd8af74d134938617441eaf156))
* **235-05:** add validated recovery action for expired checkout ([a219f5a](https://github.com/szTheory/accrue/commit/a219f5a598bbc87b766275714262bca8f3343acc))
* **236-01:** open scoped hosted invoices ([1ec6dd0](https://github.com/szTheory/accrue/commit/1ec6dd0306eea6801a2798babe7252ec2f6860ef))
* **236-02:** gate payment method actions ([ae9e26c](https://github.com/szTheory/accrue/commit/ae9e26c1fbd6b1a343a5857f80b6b65bff90c639))
* **236-03:** align subscription actions and lifecycle ([73d6ad0](https://github.com/szTheory/accrue/commit/73d6ad0ac2f0f6883c7799e118259a53b62f2358))
* **236-05:** refine host-branded Portal self-service ([b8c04a5](https://github.com/szTheory/accrue/commit/b8c04a522f83fcfd5c0fcd1dcdd2d732cc9a2342))


### Bug Fixes

* **233-05:** preserve host hooks on blocked portal live view ([e21cb7f](https://github.com/szTheory/accrue/commit/e21cb7f9b10d52ae45fa5b5a3d3ea05a5d83fa46))
* **233-05:** prove checkout targets and revoked context denial ([7e6d893](https://github.com/szTheory/accrue/commit/7e6d8933acab8031c4e449db98be3803ae4d30a7))
* **233-06:** align Portal status and accent semantics ([879e23a](https://github.com/szTheory/accrue/commit/879e23a46f66d677ef61aff98a233ba0aeaa8210))
* **233:** CR-01 align checkout eligibility with configured processor ([d828adc](https://github.com/szTheory/accrue/commit/d828adc9c59815ca6e9f522642929744e4459be9))
* **235-01:** prevent submit after checkout abandonment ([19d63bf](https://github.com/szTheory/accrue/commit/19d63bf642902d2ceb8d98436070a2119d855541))
* **235-02:** render only complete trusted checkout terms ([049a859](https://github.com/szTheory/accrue/commit/049a859f79bee33bc633952c5f05d43a6d005d2f))
* **235-03:** unify checkout eligibility and promotions ([d92fc6b](https://github.com/szTheory/accrue/commit/d92fc6bee24f826f2b95cf95ad4be32ce106305e))
* **235:** CR-01 validate LiveView success redirects ([ab9fdd2](https://github.com/szTheory/accrue/commit/ab9fdd20ace07d79c857c084fca0cbba65c66b72))
* **236-01:** distinguish unavailable invoice reads ([ff6263d](https://github.com/szTheory/accrue/commit/ff6263d0c41c1bcf72955865857c2dba7a1e1c7b))
* **236-02:** gate Hosted Fields lifecycle ([b628c71](https://github.com/szTheory/accrue/commit/b628c711aa684c7bdfde232864eff34a55f239a2))
* **236-04:** preserve checkout decline outcomes ([44f4346](https://github.com/szTheory/accrue/commit/44f4346f972c7ffec96cf0a61aedaa6e1facf93f))
* **236-04:** validate checkout return destinations ([e6679ac](https://github.com/szTheory/accrue/commit/e6679ace2550b8bfea526ae5c8d70a7c412dbf88))
* **236-06:** derive Hosted Fields colors from Portal themes ([56f28ef](https://github.com/szTheory/accrue/commit/56f28efcdb4e72879e28ff8d2e5b5710df2c0871))
* **236-06:** use supported Hosted Fields style selectors ([cdad46b](https://github.com/szTheory/accrue/commit/cdad46b3722ba486f890ca84704d41b834f5fcee))
* **236:** configure checkout return origin in discount tests ([42b6407](https://github.com/szTheory/accrue/commit/42b6407aa55d284b3fac4536a96ef3206be5f011))
* **236:** satisfy portal formatter gate ([05651fa](https://github.com/szTheory/accrue/commit/05651fa08b4767324fbc75122a654f04f0487f10))
* **249-02:** supervise portal CustomEndpoint per test to remove ETS race ([854e998](https://github.com/szTheory/accrue/commit/854e9989cb4c573455a7ad4b7fef73f9144ab5e2))
* **250-04:** start the portal Braintree client-token stub unlinked ([70924ef](https://github.com/szTheory/accrue/commit/70924efd8dd30fe4b8d844227e4c30eb81b51d6a))
* **quick-261008-lbv:** fail closed on teardown errors ([fc324cd](https://github.com/szTheory/accrue/commit/fc324cdf3fc3c073554000287cf61986005ac8b8))
* **quick-261008-lbv:** guard theme refresh teardown failures ([88e8fda](https://github.com/szTheory/accrue/commit/88e8fda52f0b405f21a9067b6e3711c66d51ef4a))
* **quick-261008-lbv:** refresh pending fields after theme changes ([0784a1c](https://github.com/szTheory/accrue/commit/0784a1c906a35e922e6aecba94d0e2aaad7de1a8))
* **quick-261008-lbv:** secure hosted fields lifecycle and theme fallbacks ([ec62555](https://github.com/szTheory/accrue/commit/ec62555206192754c1dc9466dd4053bab93180f2))
* **quick-261008-lbv:** serialize liveview updates with field teardown ([adcdbbf](https://github.com/szTheory/accrue/commit/adcdbbfa92be164b4847dfc8fa0bf788ccdafd1e))

## [1.6.0](https://github.com/szTheory/accrue/compare/accrue_portal-v1.5.1...accrue_portal-v1.6.0) (2026-09-18)

### Notes

* Compatibility only: the linked 1.6.0 release accepts the core release-safe environment resolution and the live Stripe provider-contract fixes. The core `accrue` package owns those capabilities; this package owns only its existing UI surface.

### Features

* **230-05:** pin toolchain and re-resolve sibling lockfiles for Decimal 3 ([a81c8fb](https://github.com/szTheory/accrue/commit/a81c8fba6f25d9006fdc910d33bb85100e23cd43))


### Bug Fixes

* **232-08:** remove degraded phase-200 shadow directory (finding 2) ([3743f8a](https://github.com/szTheory/accrue/commit/3743f8a85c5f39b5cf5a497a785edb5837067b19))
* **quick-260916-hl9:** use same-minor operator for accrue_portal sibling dep ([afff201](https://github.com/szTheory/accrue/commit/afff2018f7ee80ba92ce6dc9567ac984391fc6ff))

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
