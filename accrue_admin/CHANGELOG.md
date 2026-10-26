# Changelog

## Unreleased

## [1.7.0](https://github.com/szTheory/accrue/compare/accrue_admin-v1.6.0...accrue_admin-v1.7.0) (2026-10-26)


### Features

* **234-01:** preserve baseline and validate return context ([8844319](https://github.com/szTheory/accrue/commit/88443198f43cd4fee193d8c7c0b49427c889e0d0))
* **234-01:** preserve subscription investigation context ([cf03cc8](https://github.com/szTheory/accrue/commit/cf03cc80215ddb7ea4b6377ddfcf523bfe610094))
* **234-02:** make global search bounded and stateful ([39ca340](https://github.com/szTheory/accrue/commit/39ca340191667a8b61fd167f0ca04f9cb35a45be))
* **234-03:** prioritize customer and subscription evidence ([6632dd2](https://github.com/szTheory/accrue/commit/6632dd2b346a8b7591e1137c8d3502ee5140c92a))
* **234-03:** separate lifecycle facts from subscription observations ([0d093a4](https://github.com/szTheory/accrue/commit/0d093a47221e220e6fa3e54bbf82916f05b88a6b))
* **234-04:** gate subscription actions on current eligibility ([457f481](https://github.com/szTheory/accrue/commit/457f481ea3d700bb3e0e282cf10ecf0336241089))
* **234-05:** enforce single-intent scoped action outcomes ([d9b2fba](https://github.com/szTheory/accrue/commit/d9b2fba9e309a9e72384179f602f2df46dca4d43))
* **234-07:** preserve customer return context ([0f15763](https://github.com/szTheory/accrue/commit/0f15763c5737766dbc4d5c7047b326191b68dfd3))
* **234-07:** validate related record return context ([59b0366](https://github.com/szTheory/accrue/commit/59b03668123b44086d6ca8f2b60dcfee49f585ab))
* **237-04:** distinguish overdue invoices and format list money accurately ([0f75386](https://github.com/szTheory/accrue/commit/0f7538612f4b620bab50339170fe9f2529cb7c78))
* **237-06:** make charge refund review exact ([dbd9ede](https://github.com/szTheory/accrue/commit/dbd9ede8ab2e2f280c732e40d3cc1be1f36d163f))
* **237-07:** preserve recovery scope and return navigation ([82ee204](https://github.com/szTheory/accrue/commit/82ee2045b628b1c2a69203cd7ac90206d55e2811))
* **238-01:** queue confirmed webhook selection with fresh step-up ([f9c9151](https://github.com/szTheory/accrue/commit/f9c91517c01bfddff124d3864495f875ac55c4c1))
* **238-02:** link event rows to exact scoped detail ([6f86485](https://github.com/szTheory/accrue/commit/6f864858f58aca688a24b99ef56488642cc7ffd4))
* **238-04:** clarify Connect list observations ([d0d4640](https://github.com/szTheory/accrue/commit/d0d46406ffd3b8cf688858e5060a2be30bd50d91))
* **238-04:** separate observed Connect readiness ([f554ff1](https://github.com/szTheory/accrue/commit/f554ff12e02ad30c5c0903a7b4bdb429fa13ffe5))
* **240-01:** make invoice review targets explicit ([54023db](https://github.com/szTheory/accrue/commit/54023dbb8ba6ec25144f0edfc3031a49e2f5db6b))
* **240-02:** fail closed on incomplete visual baselines ([61dbc0c](https://github.com/szTheory/accrue/commit/61dbc0c81376379bebd1d3463b832fe02833e960))
* **240-04:** resync theme choice after LiveView patches ([2a79b39](https://github.com/szTheory/accrue/commit/2a79b3909643ced54866ee9b69324b200a05814f))
* **241-01:** scope subscription invoice destinations ([b36fe0d](https://github.com/szTheory/accrue/commit/b36fe0d08678795a5a3cf21f7308895006fb8901))
* **241-02:** name invoice return destinations ([2416961](https://github.com/szTheory/accrue/commit/2416961fecd9397829114b99cd32ca632e6e85b3))
* **241-02:** validate contextual return destinations ([99b071c](https://github.com/szTheory/accrue/commit/99b071c9eaa62b2ef81e57b328d656c3b0f95d8b))
* **241-03:** bind payment and customer returns ([042a479](https://github.com/szTheory/accrue/commit/042a479038a05b7bf8bfce2a92250babbc7b8ecd))
* **241-03:** bind subscription return journeys ([8ac16f2](https://github.com/szTheory/accrue/commit/8ac16f2ddd92b4a30055b93627e0489414a791e7))
* **241-04:** retain Recovery windows in campaign journeys ([908840f](https://github.com/szTheory/accrue/commit/908840f8ee3638b825e03748b8cbd263409ad65d))
* **241-04:** scope campaign returns to Recovery ([8f04683](https://github.com/szTheory/accrue/commit/8f04683f5a41769550f1285e356b67e86c3edd65))
* **241-05:** compose subscription action reviews ([3d52396](https://github.com/szTheory/accrue/commit/3d52396c08161685554536e59f267e124e7f5d4f))
* **241-06:** make refund review exact and dismissible ([d69a504](https://github.com/szTheory/accrue/commit/d69a5044bb27a3ab0e4bd9c62fedaed7980c9a98))
* **241-06:** revalidate customer payment method reviews ([3c6fc18](https://github.com/szTheory/accrue/commit/3c6fc18caaa08334cf424aca935503988d8779b0))
* **241-08:** align billing action gaps to 4px token ([65c4d04](https://github.com/szTheory/accrue/commit/65c4d0436ad1c0be7b583bdb778259946c6a3ed2))
* **242-01:** validate event list return paths ([959e45a](https://github.com/szTheory/accrue/commit/959e45abae21c3cc55b6a04cf5506ac823129e29))
* **242-02:** preserve single delivery review evidence ([a1e303a](https://github.com/szTheory/accrue/commit/a1e303a16efa0dc528de8e1a07d90897be4ea627))
* **242-03:** preserve coupon list context and scoped children ([ff2b7a6](https://github.com/szTheory/accrue/commit/ff2b7a68f38643d4ca6838147af8340fb3eac2a2))
* **242-03:** preserve promotion code context and exact parent ([6919558](https://github.com/szTheory/accrue/commit/6919558dc24fee2593aef9ad3556d0912d28f3c2))
* **242-04:** preserve Connect context and fee review ([1eaa768](https://github.com/szTheory/accrue/commit/1eaa768dd86eef2ee67ba6832a3a19f84e0d175c))
* **243-01:** extend selected visual evidence set ([dd11264](https://github.com/szTheory/accrue/commit/dd11264dfda532c8a5f8c4038c06c2c6c5a4b2bf))
* **244-01:** implement confirmed event labels ([5a0876f](https://github.com/szTheory/accrue/commit/5a0876f939de0bbc57a91f8a09a119e1e2b69891))
* **244-01:** prove Home event evidence path ([a44dbd7](https://github.com/szTheory/accrue/commit/a44dbd71afcceb56f562d7bc8b9b71ba01b19c18))
* **244-02:** preserve webhook event evidence ([613f230](https://github.com/szTheory/accrue/commit/613f2309023e724d1d70428a2a061b8d073368b2))
* **244-02:** share event labels in the events list ([1cd9320](https://github.com/szTheory/accrue/commit/1cd93201b6d74cf6f148b54b31d49e372890a03b))
* **244-03:** describe replay acceptance and read recovery ([36f69a5](https://github.com/szTheory/accrue/commit/36f69a5a3a5a5732d54fa9629f72bbc8d62f481c))
* **246-01:** add labeled collection filters and scoped chips ([f3e6ea0](https://github.com/szTheory/accrue/commit/f3e6ea01892d7e44fa5b79341e948456032767a8))
* **246-01:** implement invoice status filtering ([e20d12f](https://github.com/szTheory/accrue/commit/e20d12f851ea314bf8eb7bdb41df3cf422979509))
* **246-02:** add collection status and coupon controls ([a6e3947](https://github.com/szTheory/accrue/commit/a6e394719ad737d9f46d334cb943e32e2837784a))
* **246-02:** clarify collection search fields ([97fecbb](https://github.com/szTheory/accrue/commit/97fecbbd6587401cc76da982cf8afa510a96691e))
* **246-02:** clarify payment and connect filters ([cee685e](https://github.com/szTheory/accrue/commit/cee685ee88c20c793573ffdaea8b2a823f445513))
* **246-03:** align pointer and keyboard search results ([a4c00f5](https://github.com/szTheory/accrue/commit/a4c00f5c8485de88206eab2823015a845a53ff28))
* **246-03:** compact global search and expose held-out states ([68e17e0](https://github.com/szTheory/accrue/commit/68e17e022cab251069e13489e5e69ef1c1165c43))
* **246-04:** apply separated identity across admin tables ([ec8a0d1](https://github.com/szTheory/accrue/commit/ec8a0d135590cee843570254875d98997f65e20e))
* **246-04:** exercise shared identity in heldout table states ([1fef625](https://github.com/szTheory/accrue/commit/1fef6257c56dc6b44d8876fa034aeda54b1f47a4))
* **246-04:** group shared identity and empty content ([5e05c0b](https://github.com/szTheory/accrue/commit/5e05c0b2b89fa022c2c05204eb4b83c08d81aa78))
* **247-01:** mount timezone-aware webhook timestamps ([7885a23](https://github.com/szTheory/accrue/commit/7885a23acb81ae6855501381799fc373ed3eae22))
* **247-02:** share Local and UTC timestamp preference ([3b9d2c0](https://github.com/szTheory/accrue/commit/3b9d2c011eef89052db0851f593df2b7e95dd71f))
* **247-03:** convert commerce and customer timestamps ([16a20e1](https://github.com/szTheory/accrue/commit/16a20e13da6366713853eb214e88e77d1d6d0695))
* **247-03:** convert dashboard and Connect timestamps ([de3d269](https://github.com/szTheory/accrue/commit/de3d26986d9cca6b0e3db73d0c6e4ec8088f03e4))
* **247-03:** convert event and subscription timestamps ([0d066da](https://github.com/szTheory/accrue/commit/0d066da2585e9b249ada5a72fc4611ba7e985b1a))
* **247-04:** clarify webhook activity and payload controls ([06577a3](https://github.com/szTheory/accrue/commit/06577a3cec8a4dc08680d49ae926a7f8c90828b7))
* **247-04:** clarify webhook identity and replay hierarchy ([e6f39ce](https://github.com/szTheory/accrue/commit/e6f39cef861d334a91e3d1f0261e76d28296d89c))
* **247-08:** convert campaign and risk timestamp displays ([377c46c](https://github.com/szTheory/accrue/commit/377c46c418500882eee3c5f9a9dcc5e9fc8033db))
* **247-08:** convert subscription and webhook list timestamps ([2312dfe](https://github.com/szTheory/accrue/commit/2312dfec33c500ff262407925d2d55a94fb2808d))
* **phase-238:** automate admin verification and complete phase ([907909a](https://github.com/szTheory/accrue/commit/907909a7b8766a7eded5a649a7152ff8e6ecb815))


### Bug Fixes

* **234-02:** replace unsupported Home aggregates with scoped activity ([12d5dac](https://github.com/szTheory/accrue/commit/12d5dac52cfcd886a9b10ede1d7fb8dd47f16c20))
* **234-03:** verify narrow customer and subscription details ([c977d81](https://github.com/szTheory/accrue/commit/c977d815a2dc026878c4bdcc7158c94d552324cf))
* **234-08:** cancel step-up without discarding staged action ([a75ea84](https://github.com/szTheory/accrue/commit/a75ea845f8b1b319a8329d565312765dfc2ce3f2))
* **234-08:** deliver async search results and add pooled E2E coverage ([742d187](https://github.com/szTheory/accrue/commit/742d187267a39c7ca3debd3a0ea090c4faffba52))
* **234-08:** raise detail readability and make UAT evidence default ([7edad79](https://github.com/szTheory/accrue/commit/7edad799141a491e13d8ea9ade18664791294826))
* **237-04:** show invoice detail money and overdue evidence accurately ([dd4a304](https://github.com/szTheory/accrue/commit/dd4a30456cc5b23950f1626fc0196233f3b4c31f))
* **237-05:** revalidate invoice action review before dispatch ([7638d94](https://github.com/szTheory/accrue/commit/7638d94d7bfa03f74686e8181e779df683776014))
* **237-06:** revalidate refund dispatch after step-up ([5023a5d](https://github.com/szTheory/accrue/commit/5023a5dfe3bb5139fd96186ac6ba507cc6107412))
* **237-07:** keep recovery amounts evidence-based ([f995d6e](https://github.com/szTheory/accrue/commit/f995d6ea18c21fa85eee0f1c1ed7b7fa0e34d6c4))
* **237-07:** show scoped recovery loading and read errors ([dd714cf](https://github.com/szTheory/accrue/commit/dd714cf369fcc490ef38fa6ccbee69f9abcfb648))
* **237-08:** keep recovery count truthful while loading ([6de9ff3](https://github.com/szTheory/accrue/commit/6de9ff36e2d576dafa44a78438534a9270b717e3))
* **237-08:** keep recovery tabs on four-pixel grid ([a1a6e2a](https://github.com/szTheory/accrue/commit/a1a6e2acc9897d4b746a130b44ad2a3c2f342c54))
* **237-08:** reveal all recovery windows on mobile ([7afd27c](https://github.com/szTheory/accrue/commit/7afd27cd7cfb0589da8f47daa84ac145e3aa48e7))
* **237:** close mobile invoice and review UI gaps ([bed31a4](https://github.com/szTheory/accrue/commit/bed31a44f634fa0718beafeae8bd30f10ff7ce7e))
* **238-01:** preserve exact bulk webhook replay outcomes ([a87afbc](https://github.com/szTheory/accrue/commit/a87afbcde82c84271fcd3b00666f06d94645c1fb))
* **238-02:** render unavailable history with retry ([d8a7213](https://github.com/szTheory/accrue/commit/d8a721320da2b8e4694c0b589b6d59a6405a2a58))
* **238-02:** revalidate single replay after step-up ([d6be0e6](https://github.com/szTheory/accrue/commit/d6be0e6404e4681e5f99405abaa296e68f291a42))
* **238-03:** recover coupon detail read failures ([ba0ee1e](https://github.com/szTheory/accrue/commit/ba0ee1e7ea2d061513cc5609b886f89fb20b4206))
* **238-03:** recover promotion code detail read failures ([b01f3bc](https://github.com/szTheory/accrue/commit/b01f3bc323da6e78854992e67f6523a57f623f16))
* **238-05:** clear warnings blocking strict Admin suite ([093f850](https://github.com/szTheory/accrue/commit/093f850a620cfc06c0d42d728cc5b1d7082eede8))
* **238:** CR-01 atomically claim webhook replay ([8e11fca](https://github.com/szTheory/accrue/commit/8e11fcaa73679fb662115582af3bafd460235f22))
* **238:** CR-01 atomically revalidate owner scope for bulk replay ([16aab2e](https://github.com/szTheory/accrue/commit/16aab2eb092c7dc8697bddf8c564a725989402ad))
* **238:** CR-02 revalidate single replay owner scope ([b2ee710](https://github.com/szTheory/accrue/commit/b2ee710b0d2e6721f95dc6a58030d90e23f1f016))
* **238:** WR-01 audit every bulk replay outcome ([43699c6](https://github.com/szTheory/accrue/commit/43699c614957b27879176f440ecb487decef46fd))
* **238:** WR-01 keep unknown coupon currencies unavailable ([7540ef0](https://github.com/szTheory/accrue/commit/7540ef0753cce8a317ba5af004c8df0761234d6b))
* **238:** WR-02 align Connect query fixtures with snapshots ([c85e2bc](https://github.com/szTheory/accrue/commit/c85e2bc181bba7e16565e7c7a371c8e2ec5a9974))
* **238:** WR-02 recover from polling read failures ([fd245c8](https://github.com/szTheory/accrue/commit/fd245c8639e792768697b33d3395e2891bb52fbf))
* **238:** WR-03 filter Connect observations ([874b8de](https://github.com/szTheory/accrue/commit/874b8de3bc73d1f684d8d6dcbd8edbd83b23be95))
* **238:** WR-04 label stored Connect snapshots ([0d83428](https://github.com/szTheory/accrue/commit/0d83428747b4909049ac28e6a1f738d1df2daec9))
* **238:** WR-05 scope webhook audit events ([566d795](https://github.com/szTheory/accrue/commit/566d795982f3df75f91555fd237f512ce982f326))
* **239:** isolate copy export temporary output ([67ddd96](https://github.com/szTheory/accrue/commit/67ddd960001e745da4263ad9ba28d4a613d4f922))
* **240-01:** restore shared detail hit geometry ([ba3bf48](https://github.com/szTheory/accrue/commit/ba3bf484db63534b5431ebdce5e18dda08a26ed0))
* **240-03:** clarify unavailable invoice actions ([67b1ebc](https://github.com/szTheory/accrue/commit/67b1ebca643c4560e9ee6415211857e12004fd58))
* **240-03:** enlarge coarse-pointer review controls ([6ae839c](https://github.com/szTheory/accrue/commit/6ae839c792cf95cf9d94e05a8d157bb097860135))
* **240-03:** enlarge coarse-pointer table links ([7f1d89a](https://github.com/szTheory/accrue/commit/7f1d89a4bf803f49d323dcb12346d8c1b7ec283e))
* **240-05:** keep billing controls locked through reconnect ([6c382a1](https://github.com/szTheory/accrue/commit/6c382a1509ae2bb458ac28c4184684ad5614b25c))
* **240:** restore invoice action after step-up dismissal ([2f8293d](https://github.com/szTheory/accrue/commit/2f8293dfbf132258b0ad6f4a931ee957d70fc663))
* **240:** validate manual invoice items at dispatch ([060734e](https://github.com/szTheory/accrue/commit/060734e00aaef8a0742140fc4d8881476c66b28f))
* **240:** WR-01 clarify invoice review dismissal ([5623c42](https://github.com/szTheory/accrue/commit/5623c421794506c52e4761a5d568e4f18adb06e9))
* **240:** WR-02 consolidate invoice list filters ([25af07f](https://github.com/szTheory/accrue/commit/25af07fa2f12957b708f7489de1437c7775bb465))
* **240:** WR-03 align shared health type and spacing ([b033698](https://github.com/szTheory/accrue/commit/b0336989853595d22ad524c542cf86e2da12a1ae))
* **241-06:** remove unused payment method bindings ([e101395](https://github.com/szTheory/accrue/commit/e1013955dfae0296f6dfaf713aa7285aab762465))
* **241-07:** close browser acceptance coverage gaps ([1b902e9](https://github.com/szTheory/accrue/commit/1b902e9fa77446e56039f7214f451a182667c18c))
* **241-ui:** close subscription audit findings ([e51f3e3](https://github.com/szTheory/accrue/commit/e51f3e3161f938a2484ac422d5d31be9765ac380))
* **241:** keep ambiguous method outcomes unconfirmed ([f44f36d](https://github.com/szTheory/accrue/commit/f44f36dd6be7bca3d69bc53ed3bb24559a130b30))
* **242-01:** prove event relationships within owner scope ([3daeeaa](https://github.com/szTheory/accrue/commit/3daeeaa329b301f803db9f9cc50ead22c8d42af3))
* **242-02:** bind bulk replay to reviewed delivery outcomes ([a03a1ee](https://github.com/szTheory/accrue/commit/a03a1ee5b62e86b2d95604e867d66f370202b907))
* **242-03:** describe unknown catalog limits accurately ([72aa63c](https://github.com/szTheory/accrue/commit/72aa63c54dc67ac2e8884c4d8a0af5661d93dea5))
* **242-05:** retain bounded scoped search groups ([21d3789](https://github.com/szTheory/accrue/commit/21d37895e57ea5ad982e3c68816eae03f34d6255))
* **242-05:** synchronize command palette selection ([0ca44aa](https://github.com/szTheory/accrue/commit/0ca44aa840915676889a0a1866918204cf4f0cca))
* **242-06:** align scoped Home navigation identity ([f1145fd](https://github.com/szTheory/accrue/commit/f1145fd3cc68b68bb5762400ef391f7e2565b3ba))
* **242-06:** reconcile routine billing copy ([7711400](https://github.com/szTheory/accrue/commit/7711400e4353d5d971e4f306f2e28aeb5e904289))
* **242-07:** unblock warnings and replay contract gate ([ffcfb9b](https://github.com/szTheory/accrue/commit/ffcfb9bec862506338311348283332b1f95cf9a2))
* **242:** align Phase 242 presentation audit contracts ([157ef37](https://github.com/szTheory/accrue/commit/157ef37d9f2c1a7cb73eef0d4d9a3d1652e5169b))
* **242:** WR-01 preserve successful search groups on retry ([c39cc1c](https://github.com/szTheory/accrue/commit/c39cc1c200f29cb5c577876fe54db6a644a65d11))
* **243-01:** align browser UAT with current admin surfaces ([7528b44](https://github.com/szTheory/accrue/commit/7528b447866f955bba91aefe4e7c1dd307ab2ec0))
* **243-01:** pass visual timestamp masks as locator list ([2c59529](https://github.com/szTheory/accrue/commit/2c59529b0aab4ff32317e54effe99e53f07f8a01))
* **243-01:** validate rendered visual timestamp anchors ([73f93cb](https://github.com/szTheory/accrue/commit/73f93cb6786e767c8fd748e0ce886bf128102d97))
* **243-02:** complete browser custody acceptance ([b93d154](https://github.com/szTheory/accrue/commit/b93d15404a8e6426fe858ab5bc55ce7f705eeee2))
* **244-04:** attribute unknown bulk replay outcomes ([e608c2f](https://github.com/szTheory/accrue/commit/e608c2f485647038f5cfa40f9a32c8f8803ecb35))
* **244:** CR-01 preserve lazy evidence disclosures ([4c0ce62](https://github.com/szTheory/accrue/commit/4c0ce625858631e1244d4c9e3572d9e9911b7da1))
* **244:** distinguish pre-dispatch replay read failure ([19449fb](https://github.com/szTheory/accrue/commit/19449fb4edaed168ec8d903155ba01b3ff8e9cad))
* **246-04:** avoid repeated identity in table cards ([3975907](https://github.com/szTheory/accrue/commit/39759079b614e9858dd5edeb2ba749acc5354420))
* **246-05:** keep responsive identity badges unique ([abc4b54](https://github.com/szTheory/accrue/commit/abc4b54bc15a229de1a54ec8cd117aac89331e2f))
* **246-05:** meet copy target and proof contracts ([517703f](https://github.com/szTheory/accrue/commit/517703f6f03c4bd77f057269a90ed91cef86a951))
* **246-05:** preserve record identity in mobile cards ([889d5b3](https://github.com/szTheory/accrue/commit/889d5b323cf8ceef86620840e3fcf294ca5ef31a))
* **246-identity:** add copyable exact IDs to collections ([d184067](https://github.com/szTheory/accrue/commit/d18406775fab093195c40b552af961ecaa3b3167))
* **246:** WR-01 explain overlong search validation ([d1c467c](https://github.com/szTheory/accrue/commit/d1c467cd1a4b9a3ca306e73ea90f8cbc68ec5bd4))
* **247-01:** avoid duplicate timestamp clipboard binding ([1a54f68](https://github.com/szTheory/accrue/commit/1a54f68655cd8e242d553145d90a17b916aed942))
* **247-01:** preserve exact ISO in manual copy fallback ([483d5d3](https://github.com/szTheory/accrue/commit/483d5d3cba30836db185239f0dd7eb8b5133863d))
* **247-02:** make clipboard feedback truthful ([a72a3e0](https://github.com/szTheory/accrue/commit/a72a3e0e9aa89868d24da7f58bebba0731cbf1f1))
* **247-05:** clarify billing detail evidence and parents ([989c75e](https://github.com/szTheory/accrue/commit/989c75e927652dd4767f343d1a924f71e45b1ab1))
* **247-05:** clarify billing evidence labels ([215ac9d](https://github.com/szTheory/accrue/commit/215ac9d425ec63a14ed862611ce8704464b52a65))
* **247-05:** use concrete detail breadcrumbs ([9f45d9a](https://github.com/szTheory/accrue/commit/9f45d9a47de4e736efb6ee8a56ee54c8445193bf))
* **247-06:** clarify recovery window and coverage ([32064e6](https://github.com/szTheory/accrue/commit/32064e691c2990ce57790ccfffe5cc66f2a40015))
* **247-06:** keep coverage copy within the view ([646d8d2](https://github.com/szTheory/accrue/commit/646d8d2c662e2bcee0e600eb33fde02825bcb91d))
* **247-06:** pair currency recovery metrics ([166fc96](https://github.com/szTheory/accrue/commit/166fc96c322fd36397de7dba1494dfd238ab6c0e))
* **247-07:** give recovery currency pairs readable width ([b4ede49](https://github.com/szTheory/accrue/commit/b4ede4913cdd3f9009e7dd299c1753655a48be0c))
* **247-07:** preserve recovery KPI grid override ([a2a21d8](https://github.com/szTheory/accrue/commit/a2a21d8b04982845dc710fa455a02fed1ff2ad76))
* **247-07:** preserve recovery KPI value wrapping ([b2fbe79](https://github.com/szTheory/accrue/commit/b2fbe79f1b98730383db71252ade70887819b49a))
* **247-07:** restore webhook parent breadcrumb evidence ([a40c567](https://github.com/szTheory/accrue/commit/a40c567daf917b2e91b96d12eae3c66c7403d0cb))
* **247-post-review:** close detail and timestamp gaps ([306efe9](https://github.com/szTheory/accrue/commit/306efe92c2d8baf7b2dcee938fc9e1742b21084d))
* **247-post-review:** explain payment retries in recovery ([e65fedc](https://github.com/szTheory/accrue/commit/e65fedc6b692048597d50d2ece5a8980e47cf11a))
* **247:** wrap narrow raw webhook payloads ([dc5e89c](https://github.com/szTheory/accrue/commit/dc5e89cd6291c400bddf6fb5d703463bac4f856d))
* **249-01:** prefix unused binding in activity_audit_summary ([cb3dc54](https://github.com/szTheory/accrue/commit/cb3dc546255ddd81460591d455f5bbacb84bb3d3))
* **249-01:** satisfy package-docs CSS guards (DSY-01, FND-01, RES-04) in admin css ([1a755b2](https://github.com/szTheory/accrue/commit/1a755b2da2377114d43a4f0f8ebc6ec58ed41936))
* **249-02:** clear credo alias-order and negated-condition findings in accrue_admin ([9be2c27](https://github.com/szTheory/accrue/commit/9be2c27fd8c0bda6521cd6aa1c7be7e3b2cfc4f4))
* **249-02:** replace length/1 comparisons with exact list assertions in admin tests ([c7a5e99](https://github.com/szTheory/accrue/commit/c7a5e99044a54473af14ba71a1b54daf8ee5358b))
* **249-08:** wrap webhook detail header description at 320px text-spacing reflow ([50e814b](https://github.com/szTheory/accrue/commit/50e814b43fa974cbf208dabf2edb181034f94d79))
* **249-09:** reflow topbar at 200% text on 320px and update Phase 196 list contracts ([8b9dc25](https://github.com/szTheory/accrue/commit/8b9dc25871f4369ae9b3751c79c2e82f1faeb08c))
* **249-12:** drop unreachable queue branch in customers empty-state action ([c3a9cad](https://github.com/szTheory/accrue/commit/c3a9cad4ebd0ae9b30c7e661a481c2e652e67981))
* **250-02:** ceil RecoveryLiveTest clock and pin admin test PG timezone to UTC ([4a94f7b](https://github.com/szTheory/accrue/commit/4a94f7b8583a662613fbb5be0a681dee97912859))
* **250-03:** give quiet admin links the shared keyboard focus ring ([6fc488c](https://github.com/szTheory/accrue/commit/6fc488cd12253e049e105104df6ab952bf35635e))
* **admin:** align breadcrumb groups and activity family cues ([7e77a01](https://github.com/szTheory/accrue/commit/7e77a01f37c451adbae1d5fcb7c6ea2781fb9fad))
* **admin:** align Phase 233 regression with current dashboard ([ae64e0c](https://github.com/szTheory/accrue/commit/ae64e0cd53b852255fb6ad2760ee27f5203fdaf2))
* **admin:** clarify billing views and recorded evidence ([b4a7eea](https://github.com/szTheory/accrue/commit/b4a7eeac114cb8a6d5691c55f458dd4c94ec4257))
* **admin:** clarify home activity and event details ([3d7d949](https://github.com/szTheory/accrue/commit/3d7d949def2eca73bbb240784d31de0b039b8d67))
* **admin:** clarify timeline creation and row hierarchy ([d122d53](https://github.com/szTheory/accrue/commit/d122d53a0b1f16808f862e89a2ea6fec7f47ef9e))
* **admin:** close phase 237 mobile toolbar gaps ([ba1774b](https://github.com/szTheory/accrue/commit/ba1774bf324b4fac5c612e1d5496f8a64ddbc1b3))
* **admin:** keep infinite lists complete and clarify default methods ([f23f8e7](https://github.com/szTheory/accrue/commit/f23f8e7501c6e776cd984cc2b07cea91b864d523))
* **admin:** quiet billing activity presentation ([b493c50](https://github.com/szTheory/accrue/commit/b493c50e5588f3636842ee01dcc93c7880f1836f))
* **admin:** quiet shared header utility controls ([b396fc1](https://github.com/szTheory/accrue/commit/b396fc1657d5f6c93054c5d67461b2c6dbf75b72))
* **admin:** quiet table links and align record references ([a467006](https://github.com/szTheory/accrue/commit/a467006f42a00516457c2106e29ac5c07f4fe579))
* **admin:** unify list controls and billing evidence ([66d5b3c](https://github.com/szTheory/accrue/commit/66d5b3ce68131da0ef3aa71b95eb367c8c0badca))
* **admin:** unify page gutters and bound record labels ([c5b2564](https://github.com/szTheory/accrue/commit/c5b2564076475b03692a1afdd6e5d0ef6e55c30e))
* **quick-261008-cb9:** clear Admin compile warnings ([795114d](https://github.com/szTheory/accrue/commit/795114d9ac59276b978929df624b225ec69a3cb8))
* **regression:** align semantic queue type and currency expectations ([b24092f](https://github.com/szTheory/accrue/commit/b24092fa487ddb702e6f99c581d377ed739af349))

## [1.6.0](https://github.com/szTheory/accrue/compare/accrue_admin-v1.5.1...accrue_admin-v1.6.0) (2026-09-18)

### Notes

* Compatibility only: the linked 1.6.0 release accepts the core release-safe environment resolution and the live Stripe provider-contract fixes. The core `accrue` package owns those capabilities; this package owns only its existing UI surface.

### Features

* **230-05:** pin toolchain and re-resolve sibling lockfiles for Decimal 3 ([a81c8fb](https://github.com/szTheory/accrue/commit/a81c8fba6f25d9006fdc910d33bb85100e23cd43))


### Bug Fixes

* **232-08:** remove degraded phase-200 shadow directory (finding 2) ([3743f8a](https://github.com/szTheory/accrue/commit/3743f8a85c5f39b5cf5a497a785edb5837067b19))
* resolve milestone verification gaps ([87e0ebf](https://github.com/szTheory/accrue/commit/87e0ebf512bce76208140017eba20ecc83688ba0))

## [1.5.1](https://github.com/szTheory/accrue/compare/accrue_admin-v1.5.0...accrue_admin-v1.5.1) (2026-08-30)

### Notes

* Compatibility only: the linked 1.5.1 release accepts the core Decimal 3 and API-only entitlement-reader fixes. The core `accrue` package owns those capabilities; this package owns only its existing UI surface.

### Miscellaneous Chores

* **accrue_admin:** Synchronize accrue-monorepo versions

## [1.5.0](https://github.com/szTheory/accrue/compare/accrue_admin-v1.4.0...accrue_admin-v1.5.0) (2026-08-19)

### Notes

* Compatibility only: the linked 1.5.0 release resolves with the coordinated core `lattice_stripe ~> 2.0` and advisory entitlement-sync work. The core `accrue` package owns the new refresh contracts and grant-boundary documentation.


### Bug Fixes

* **ci:** satisfy strict admin Credo ([29c0986](https://github.com/szTheory/accrue/commit/29c0986b8970ebfec3b1df1481f1a288f5283fee))
* make Chimeway dunning recipient identity opaque ([f579bf2](https://github.com/szTheory/accrue/commit/f579bf27770bee142258682b23bae09122f662cf))

## [1.4.0](https://github.com/szTheory/accrue/compare/accrue_admin-v1.3.0...accrue_admin-v1.4.0) (2026-06-01)


### Bug Fixes

* **152:** CR-01 replace String.to_atom with String.to_existing_atom for currency ([2fd2683](https://github.com/szTheory/accrue/commit/2fd268362701427760107718c8e036c56e8f8901))
* **152:** CR-02 guard elem/2 call in CampaignTimeline arc_rows ([512b6db](https://github.com/szTheory/accrue/commit/512b6db642dd5df4eb5baaed1559bb7fe96e9bb1))
* **152:** WR-03 read failure info from event data not invoice_map in campaign_row ([43b2179](https://github.com/szTheory/accrue/commit/43b21791265f8a288ed348f3ce51284430c63ef7))
* **156-01:** address code review findings ([c6273bd](https://github.com/szTheory/accrue/commit/c6273bdfa6f92281b08adfa01a3c1ffb2d246828))
* **156-01:** constrain admin display copy on mobile ([05e201c](https://github.com/szTheory/accrue/commit/05e201c663808b24c310f76790887e13266beee3))
* **156-01:** keep recovery analytics currency formatting bounded ([76beb47](https://github.com/szTheory/accrue/commit/76beb4740e8604e8f26074ca308209e7c0b27733))
* **156-01:** restore dark admin contrast ([46e62b0](https://github.com/szTheory/accrue/commit/46e62b0ce2143a52e08a2169845f60850452f0db))

## [1.3.0](https://github.com/szTheory/accrue/compare/accrue_admin-v1.2.0...accrue_admin-v1.3.0) (2026-05-30)

**1.0.0 — Stable.** Released in lockstep with `accrue` 1.0.0. The supported integration surface for the admin package is `AccrueAdmin.Router` and the documented mount/scope helpers; see `accrue/CHANGELOG.md` and `accrue/guides/maturity-and-maintenance.md` for the v1.x stability commitment that governs both packages.

### Host-visible copy (accrue_admin)

- Webhook replay confirmations, bulk DLQ prompts, and related operator strings now live in `AccrueAdmin.Copy` / `AccrueAdmin.Copy.Locked` (Phase 27). Hosts that snapshot admin flash or HEEx literals should diff package tests when upgrading.

### Features

* **143-02:** create RecoveryLive component ([4e3973a](https://github.com/szTheory/accrue/commit/4e3973a5e297f287213aad04aa637be2530b0d30))
* **143-02:** register recovery route in router ([dea3420](https://github.com/szTheory/accrue/commit/dea342026eccafe0d652027de2ffdf147233d01d))
* **144-03:** add .ax-funnel-* CSS block to app.css (DAN-09) ([2ec7bc2](https://github.com/szTheory/accrue/commit/2ec7bc22f4ef4c60e7b65d628fce5a83a073f7dc))
* **144-03:** add AccrueAdmin.Components.FunnelChart (DAN-09) ([7e50ed4](https://github.com/szTheory/accrue/commit/7e50ed412585651755f06dea6f99edc2883b94df))
* **144-04:** wire funnel + MoneyFormatter + Exhausted-MRR rename in RecoveryLive (DAN-09, DAN-13) ([410caeb](https://github.com/szTheory/accrue/commit/410caebcf7f38b032f62646e968990b0b57810ee))
* **145-01:** create AccrueAdmin.Components.WindowSelector ([a4e0e47](https://github.com/szTheory/accrue/commit/a4e0e47eda59dfada5d097d268607faccb97853a))
* **145-01:** refactor RecoveryLive — data loading to handle_params ([f8c1ece](https://github.com/szTheory/accrue/commit/f8c1eceacb2863e35828a3be6e10409ed320e584))
* **146-03:** AtRiskTable component + ax-at-risk-* CSS classes ([e199cd4](https://github.com/szTheory/accrue/commit/e199cd4aec5d9e1146b0952bec9482e8c2b89326))
* **146-03:** wire RecoveryLive to render AtRiskTable (DAN-11 GREEN) ([f097ab6](https://github.com/szTheory/accrue/commit/f097ab62a5a645db8cca9636377d64b1a0ed783a))
* **147-02:** implement CampaignLive and drill-down routing ([060c704](https://github.com/szTheory/accrue/commit/060c704e06d1aa849a97e440f432b4e3a6671856))
* **149-02:** add DunningBanner headless component ([0ea7b08](https://github.com/szTheory/accrue/commit/0ea7b08fd70f5b99da62ab60b17b1b228743d07e))
* **v1.42:** complete Ad-hoc Invoices & Adopter Confidence milestone ([452995e](https://github.com/szTheory/accrue/commit/452995e3327220ff3b50023f82871354ec3d0f2c))


### Bug Fixes

* **145:** CR-01 remove stale active_organization_name assign from assign_shell/2 ([3698f84](https://github.com/szTheory/accrue/commit/3698f84a43d807ede37bf76ecc032dfd3ef26533))
* **145:** CR-02 capture DateTime.utc_now/0 once in window_bounds/1 clauses ([29ae506](https://github.com/szTheory/accrue/commit/29ae506717f40fa65a303480962617a2b1bd3b1d))
* **145:** WR-01 use URI to build window patch URLs safely in window_selector ([6ca402f](https://github.com/szTheory/accrue/commit/6ca402fbc32de53e79872c97547eb22c2e13265e))
* **145:** WR-02 assert correct button carries aria-current in window parameter tests ([e4fd410](https://github.com/szTheory/accrue/commit/e4fd4101b263ee44f9d2096f53f615d218964053))
* **145:** WR-03 pattern-match Events.record/1 return values in test setup blocks ([b430647](https://github.com/szTheory/accrue/commit/b4306477253547d6ca6443de73977787d3ef647a))
* **146:** resolve CR-01 GROUP BY bug, CR-02 failure reason display, WR-01/02/03 ([142f21b](https://github.com/szTheory/accrue/commit/142f21baa8b45a92f81f5c0b6c99c41ffe973e3a))
* **151-03:** resolve test coverage blockers ([21f5d6e](https://github.com/szTheory/accrue/commit/21f5d6e205eef2ad523f5d621338c5f1e6118838))
* **152-01:** correct [@since](https://github.com/since) annotation in funnel_chart.ex to canonical [@doc](https://github.com/doc) since: "1.3.0" ([5af7b87](https://github.com/szTheory/accrue/commit/5af7b87e833f4599d6ae9e6952a50b832d596762))
* **152-02:** resolve pre-existing credo issues blocking Three Zeros gate ([bd72ec1](https://github.com/szTheory/accrue/commit/bd72ec15058507eab6657db412612caf80ac9698))
* **152-03:** close accrue_admin --warnings-as-errors gaps ([01c8e32](https://github.com/szTheory/accrue/commit/01c8e32a7298fc297202204b6a983f3fdaf3ff66))
* **152-03:** give command-palette dialog an accessible name (a11y) ([de7a3fe](https://github.com/szTheory/accrue/commit/de7a3fef53247619d96a26eea60197d74fd14634))

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
