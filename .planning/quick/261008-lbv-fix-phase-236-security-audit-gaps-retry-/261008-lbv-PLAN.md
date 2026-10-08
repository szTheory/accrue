---
quick_id: 261008-lbv
phase: quick-261008-lbv
plan: 01
type: execute
wave: 1
slug: fix-phase-236-security-audit-gaps-retry-
description: Retry invalidated Hosted Fields creation and keep malformed-token styles readable
date: 2026-10-08
status: planned
mode: quick-full
requirements: [POR-05]
files_modified:
  - accrue_portal/priv/static/accrue_portal.js
  - examples/accrue_host/e2e/phase236-portal-self-service.spec.js
  - .planning/phases/236-portal-billing-self-service/236-VALIDATION.md
  - .planning/phases/236-portal-billing-self-service/236-06-SUMMARY.md
  - .planning/quick/261008-lbv-fix-phase-236-security-audit-gaps-retry-/COVERAGE.md
depends_on: []
autonomous: true
must_haves:
  truths:
    - "T-236-14 / POR-05: A post-mount LiveView lifecycle update during delayed Hosted Fields creation invalidates the stale callback, cleans up stale resources, and retries only after both teardown callbacks succeed; if teardown fails, Save stays disabled with refresh guidance and no overlapping instance is created."
    - "T-236-13 / POR-05: With malformed semantic text tokens, the application supplies input, placeholder, and invalid colors at >=4.5:1 against each actual secure-field surface in served light and dark modes."
    - "The direct-route browser check observes delayed creation across the actual context-pin URL patch without claiming that URL-only patch invokes the hook; the separate lifecycle regression uses the framework's ViewHook update wrapper to cover a post-mount update."
    - "A theme change during pending Hosted Fields creation invalidates styles captured for the old theme and recreates fields using current styles after successful stale cleanup."
    - "A LiveView update during active-instance theme teardown cannot start replacement fields until teardown completes; teardown errors keep Save disabled and do not create another instance."
    - "The Phase 236 validation map and 236-06 summary cite actual passing focused browser results and identify mock-only evidence without claiming live Braintree iframe fidelity or security-audit closure."
  artifacts:
    - accrue_portal/priv/static/accrue_portal.js
    - examples/accrue_host/e2e/phase236-portal-self-service.spec.js
    - .planning/phases/236-portal-billing-self-service/236-VALIDATION.md
    - .planning/phases/236-portal-billing-self-service/236-06-SUMMARY.md
    - .planning/quick/261008-lbv-fix-phase-236-security-audit-gaps-retry-/COVERAGE.md
  key_links:
    - "LiveView updated() during pending client/Hosted Fields creation -> generation invalidation -> stale callback cleanup -> retry for the mounted form."
    - "Computed secure-field background and validated semantic tokens -> contrast-checked SDK style handoff for input, placeholder, and invalid states."
    - "Served browser mock observations and exact passing commands -> distinct follow-up rows in Phase 236 validation and summary."
---

<objective>
Close the verified Phase 236 Hosted Fields lifecycle and malformed-token style gaps in the existing direct add-card integration.

Purpose: A post-mount LiveView update can invalidate delayed creation permanently, and malformed semantic tokens currently produce low-contrast dark-field styles.
Output: Resilient creation and readable style handoff, deterministic served-browser regressions, and accurately bounded Phase 236 evidence.
</objective>

<context>
@.planning/STATE.md
@.planning/phases/236-portal-billing-self-service/236-CONTEXT.md
@.planning/phases/236-portal-billing-self-service/236-06-PLAN.md
@.planning/phases/236-portal-billing-self-service/236-06-SUMMARY.md
@.planning/phases/236-portal-billing-self-service/236-VALIDATION.md
@.planning/phases/236-portal-billing-self-service/236-SECURITY.md
@.planning/quick/261008-lbv-fix-phase-236-security-audit-gaps-retry-/COVERAGE.md
@accrue_portal/priv/static/accrue_portal.js
@examples/accrue_host/e2e/phase236-portal-self-service.spec.js
</context>

<tasks>

<task type="tracer" tdd="true">
  <name>Task 1: Recover delayed Hosted Fields creation after a post-mount update</name>
  <files>accrue_portal/priv/static/accrue_portal.js, examples/accrue_host/e2e/phase236-portal-self-service.spec.js</files>
  <behavior>On a direct GET without context_pin, hold the mock client.create callback while the real LiveView push_patch adds context_pin, then confirm the route stays disabled until setup resolves. Separately, while the hook is mounted and either client.create or hostedFields.create remains pending, trigger the framework ViewHook __updated lifecycle wrapper; releasing the now-stale callback must clean up stale resources and start one current creation only after both teardown callbacks succeed. If teardown reports an error, keep Save disabled, show refresh guidance, and do not create an overlapping instance. Change theme while hostedFields.create is pending and confirm stale styles are discarded and the retry uses current-theme styles. With an active instance, hold theme-refresh teardown pending while a LiveView update runs; no setup may begin until cleanup completes, and cleanup failure must not create replacement fields. Save card remains disabled until a current instance is ready, nonce state stays empty, and abandonment during pending client creation never revives it.</behavior>
  <action>Per D-06 and D-08, add deterministic served-browser regressions with controllable SDK callback gates. Observe the real direct-route context-pin URL patch and do not claim that this URL-only patch invokes the already-mounted hook's update callback. Separately retrieve the mounted hook from the LiveView view and invoke its framework __updated lifecycle wrapper to model post-mount DOM updates during both client and Hosted Fields creation; do not call the hook's updated() method directly. In the hook, reconcile updated() generation invalidation with pending creation and teardown: keep hostedFieldsBound from suppressing retry, serialize one safe restart after stale callbacks settle, and prevent duplicate creation or event listeners. Keep submit disabled through retry; clear the single-use nonce, teardown stale client/Hosted Fields resources, and guard destroyed/pagehide paths so late callbacks cannot revive abandoned fields. Invalidate pending style snapshots when a theme change makes them stale, then retry with current styles after successful cleanup. During active theme teardown, prevent LiveView updated() from mounting replacement fields until cleanup reports success. Inspect teardown callback errors in both async setup and theme-refresh paths. Retry only after cleanup succeeds; on failure, keep the form disabled and show refresh guidance. Preserve the official SDK and nonce-only submission boundary. Make the post-mount lifecycle regressions fail against the pre-fix hook, then pass through the served hashed asset.</action>
  <verify><automated>ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields'</automated><fails_when>The direct route enables submission before setup resolves, or a post-mount update or theme refresh creates overlapping fields after cleanup failure, leaves submission enabled, retains a nonce, or lets stale callbacks revive an abandoned form.</fails_when></verify>
  <done>The direct-route patch keeps delayed setup disabled until ready; async setup and theme refresh retry only after successful cleanup, while cleanup failure stays disabled and abandonment stays inert.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Select readable malformed-token fallback colors in light and dark</name>
  <files>accrue_portal/priv/static/accrue_portal.js, examples/accrue_host/e2e/phase236-portal-self-service.spec.js</files>
  <behavior>For deliberately malformed --accrue-ink and --accrue-slate values on the served direct add-card route, every number, expirationDate, and cvv field receives SDK input, ::placeholder, and .invalid colors whose contrast against its computed field background is >=4.5:1 in both host-forced light and host-forced dark. Valid semantic colors continue to work through theme refresh.</behavior>
  <action>Per D-06 and D-08, inject malformed semantic token values in the browser before the mock creation style capture and measure the actual computed .portal-hosted-field surfaces. Replace the current fixed fallback text and placeholder colors with a background-aware, normalized, SDK-usable choice; contrast-check valid token candidates too, so malformed or low-contrast host tokens cannot select an unreadable style. Keep invalid-state color subject to the same >=4.5:1 threshold. Reuse the existing contrastRatio browser helper and assert each field's input, placeholder, and invalid styles in separate forced-light and forced-dark served runs. Retain the explicit deterministic-mock evidence label and make no provider iframe rendering assertion.</action>
  <verify><automated>ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 ACCRUE_HOST_PORTAL_THEME=light npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields'</automated><fails_when>Malformed-token input, placeholder, or invalid colors are unparsable or below 4.5:1 against any served light field surface.</fails_when></verify>
  <verify><automated>ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 ACCRUE_HOST_PORTAL_THEME=dark npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields'</automated><fails_when>Malformed-token input, placeholder, or invalid colors are unparsable or below 4.5:1 against any served dark field surface.</fails_when></verify>
  <done>All three application-supplied style states meet >=4.5:1 on every tested field surface in both host-forced themes, including malformed semantic tokens.</done>
</task>

<task type="auto">
  <name>Task 3: Record passing follow-up evidence without premature security closure</name>
  <files>.planning/phases/236-portal-billing-self-service/236-VALIDATION.md, .planning/phases/236-portal-billing-self-service/236-06-SUMMARY.md, .planning/quick/261008-lbv-fix-phase-236-security-audit-gaps-retry-/COVERAGE.md</files>
  <action>After Tasks 1 and 2 pass their exact commands, add a separate quick-follow-up POR-05 row to 236-VALIDATION.md for T-236-13 and T-236-14 with the real context-pin route observation, post-mount ViewHook wrapper regressions, and malformed-token light/dark assertions. Record each exact command and its observed positive N passed result; if any run fails, leave the follow-up row pending and do not describe it as passing. Append a correction/evidence note to 236-06-SUMMARY.md that identifies the two gaps found after its original completion, the actual fix and results, and the distinction between deterministic framework/mock lifecycle evidence and unverified live-provider iframe rendering. Keep the original historical results intact. Confirm COVERAGE.md retains its no-new-external-capability declaration, no-change identity/model delta, and no-schema gate. Do not mark T-236-13/T-236-14 or the security audit closed; that decision belongs to the follow-up security auditor.</action>
  <verify><automated>node -e 'const fs=require("node:fs"); const v=fs.readFileSync(".planning/phases/236-portal-billing-self-service/236-VALIDATION.md","utf8"); const s=fs.readFileSync(".planning/phases/236-portal-billing-self-service/236-06-SUMMARY.md","utf8"); const row=v.split(/\r?\n/).find(x=>x.includes("261008-lbv")&&x.includes("POR-05"))||""; const note=s.split("261008-lbv")[1]||""; const ok=row.includes("T-236-13")&&row.includes("T-236-14")&&(row.match(/\b[1-9][0-9]* passed\b/g)||[]).length===3&&note.includes("T-236-13")&&note.includes("T-236-14")&&/mock/i.test(row+note)&&/live.{0,20}provider|provider.{0,20}iframe/i.test(row+note); if(!ok) process.exit(1)'</automated><fails_when>The distinct follow-up validation row lacks either threat, three observed positive pass counts, or the summary and row omit the mock versus live-provider evidence boundary.</fails_when></verify>
  <done>Phase 236 evidence maps both repaired findings to actual green served-browser runs while security status remains for a separate auditor decision.</done>
</task>

</tasks>

<threat_model>
Security enforcement: ASVS L1; block_on: high. The high-severity lifecycle finding must be mitigated and verified before this quick task can be reported complete. Follow-up security audit owns threat closure.

## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| LiveView patch to browser hook | An asynchronous update can invalidate in-flight provider creation while the mounted form and submit state persist. |
| Host theme tokens to Hosted Fields SDK | Untrusted or malformed presentation tokens influence application-supplied iframe style options; field surfaces determine safe contrast. |
| Provider SDK to Portal form | Only a single-use nonce may enter application state; stale instances and callbacks must not restore it. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-236-13 | Tampering | Hosted Fields style handoff | medium | mitigate | Task 2 checks normalized semantic candidates and background-aware fallbacks against each served field surface, then proves >=4.5:1 for input, placeholder, and invalid in light and dark. |
| T-236-14 | Information disclosure | Hosted Fields async lifecycle | high | mitigate | Task 1 observes the direct context-pin route separately and proves post-mount updates and theme refresh serialize cleanup/retry, discard stale pending styles, block remount during active teardown, fail closed on teardown errors, keep submit and nonce state safe, and avoid reviving abandoned forms. |
| T-Q261008-LBV-SC | Tampering | Package supply chain | low | accept | No package install or dependency change is planned. |
</threat_model>

<verification>
Run Task 1's default focused browser command and Task 2's forced-light and forced-dark commands from the repository root. Record their actual pass counts in the Phase 236 validation map and summary. The direct-route patch is observed in the browser but does not itself call the already-mounted hook update callback; the separate lifecycle tests exercise the framework ViewHook update wrapper under the deterministic SDK mock. These tests establish application-side lifecycle and style handoff, not live Braintree iframe rendering. Request a separate Phase 236 security audit after implementation to decide whether T-236-13/T-236-14 can close.
</verification>

<success_criteria>
The direct-route patch keeps delayed setup disabled until ready, post-mount lifecycle updates during both SDK create stages clean up stale resources and retry to one working instance only after successful teardown, theme changes during pending creation use current styles, active theme teardown blocks overlapping remounts, malformed semantic tokens yield >=4.5:1 application-supplied colors in both themes, all focused browser commands pass, and evidence records the framework-wrapper test boundary and mock-only scope.
</success_criteria>

<output>
Create .planning/quick/261008-lbv-fix-phase-236-security-audit-gaps-retry-/261008-lbv-SUMMARY.md after implementation, with exact command output and security-auditor handoff.
</output>
