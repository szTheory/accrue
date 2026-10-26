---
quick_id: 261008-cjc
slug: repair-playwright-ci-automate-the-existi
description: Repair Playwright CI replay step-up and Phase 234 saved evidence behavior
date: 2026-10-08
status: planned
mode: quick
files_modified:
  - examples/accrue_host/e2e/phase13-canonical-demo.spec.js
  - examples/accrue_host/e2e/phase234-post-layout.spec.js
depends_on: []
autonomous: true
must_haves:
  truths:
    - The canonical webhook replay journey completes the test-only step-up challenge and still observes the replay confirmation and audit event.
    - A normal Phase 234 post-layout run checks live customer and subscription layout and the integrity of saved captures without changing saved evidence.
    - A Phase 234 post-layout capture requires an explicit environment flag and refuses a populated destination before any capture write.
    - The two affected specs and the full host Playwright suite pass with saved evidence already present.
  artifacts:
    - examples/accrue_host/e2e/phase13-canonical-demo.spec.js
    - examples/accrue_host/e2e/phase234-post-layout.spec.js
  key_links:
    - Replay confirmation leads to the test-only TOTP dialog, whose successful submit resumes replay before the existing toast and audit assertions.
    - The post-layout capture flag gates every write to .planning/phases/234-admin-customers-subscriptions/captures/post-layout while normal runs read its manifest and image bytes.
---

<objective>
Restore the host browser CI suite after the replay step-up change and preserve Phase 234 post-layout evidence during ordinary runs.

Purpose: CI discovers both specs through its full Playwright invocation, so each spec must pass against the current test host and the existing write-once evidence.
Output: Two narrowly edited Playwright specs and a quick-task SUMMARY with verification results.
</objective>

<context>
@.planning/STATE.md
@examples/accrue_host/e2e/phase13-canonical-demo.spec.js
@examples/accrue_host/e2e/phase234-post-layout.spec.js
@examples/accrue_host/e2e/phase234-pre-layout.spec.js
@examples/accrue_host/lib/accrue_host/auth.ex
@examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js
@.github/workflows/ci.yml
</context>

<tasks>
<task type="auto">
  <name>Task 1: Complete the replay step-up in the canonical journey</name>
  <files>examples/accrue_host/e2e/phase13-canonical-demo.spec.js</files>
  <action>Immediately after clicking the existing confirm-replay control, expect the Step-up required dialog, fill its Verification code textbox with the host's MIX_ENV=test-only code 123456 from AccrueHost.Auth, and click Verify identity inside that dialog. Wait for the dialog to close and the LiveView to settle before the existing replay toast and audit-row checks. Keep the challenge scoped to this replay journey and retain its confirmation-copy, toast, and audit assertions; do not change auth or provider behavior.</action>
  <verify><automated>cd examples/accrue_host && npm run e2e -- e2e/phase13-canonical-demo.spec.js --workers=1</automated></verify>
  <done>The canonical journey completes replay after the test challenge, shows the replay confirmation, and finds the replay audit event.</done>
</task>

<task type="auto">
  <name>Task 2: Make saved Phase 234 post-layout evidence read-only in normal runs</name>
  <files>examples/accrue_host/e2e/phase234-post-layout.spec.js</files>
  <action>Introduce an explicit PHASE234_CAPTURE_POST_LAYOUT=1 capture branch, following the Phase 234 pre-layout spec's capture convention. In normal mode, load the existing post-layout manifest through resolvePhaseEvidencePath, check its phase and each named image's byte count and SHA-256 against the manifest, and retain the current served-page navigation, 320px overflow, hierarchy, control-size, and asset availability assertions. Do not create the capture directory or write images or manifest in normal mode. In capture mode, check before browser work that the destination is absent or empty; refuse any populated destination, then retain the current source/asset provenance and exclusive wx writes for the three images and manifest. Keep the pre-layout baseline read and its phase check; make screenshot buffers, source digests, and current HEAD collection capture-only where they serve only the manifest. Update the manifest's capture_command text to show the explicit flag for any new capture. Do not edit stored captures.</action>
  <verify>
    <automated>cd examples/accrue_host && npm run e2e -- e2e/phase234-post-layout.spec.js --workers=1</automated>
    <automated>node -e 'const fs=require("node:fs"),path=require("node:path"),crypto=require("node:crypto"),cp=require("node:child_process"); const dir=".planning/phases/234-admin-customers-subscriptions/captures/post-layout"; const digest=()=>fs.readdirSync(dir,{recursive:true}).filter(name=>fs.statSync(path.join(dir,name)).isFile()).sort().map(name=>[name,crypto.createHash("sha256").update(fs.readFileSync(path.join(dir,name))).digest("hex")]); const before=digest(); if(before.length===0) throw Error("expected populated post-layout evidence"); const run=cp.spawnSync("npm",["run","e2e","--","e2e/phase234-post-layout.spec.js","--workers=1"],{cwd:"examples/accrue_host",env:{...process.env,PHASE234_CAPTURE_POST_LAYOUT:"1"},encoding:"utf8"}); const output=(run.stdout||"")+(run.stderr||""); const after=digest(); if(run.status===0||!output.includes("post-layout evidence is write-once")||JSON.stringify(before)!==JSON.stringify(after)){process.stderr.write(output);throw Error("capture refusal, expected message, or saved evidence integrity failed")}'</automated>
  </verify>
  <done>With the existing populated destination, normal mode passes live and stored-integrity assertions without changing evidence bytes; explicit capture mode refuses the destination and leaves every saved file unchanged.</done>
</task>
</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Browser test to test host | The replay step-up credential is accepted only in MIX_ENV=test by the existing host auth callback. |
| Test process to saved evidence | Environment-controlled capture mode can write to the Phase 234 evidence directory. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-cjc-01 | Elevation of privilege | Replay journey | low | mitigate | Use the existing test-only verification code only within the browser spec and require the real challenge dialog before submission. |
| T-cjc-02 | Tampering | Saved post-layout captures | medium | mitigate | Default to manifest and image reads; gate exclusive writes with PHASE234_CAPTURE_POST_LAYOUT=1 and refuse a populated destination before writing. |
</threat_model>

<verification>
From examples/accrue_host, run `npm run e2e -- e2e/phase13-canonical-demo.spec.js e2e/phase234-post-layout.spec.js --workers=1`, then `npx playwright test --workers=1` to cover CI's normal spec discovery. Run Task 2's capture-refusal check, which requires a failed capture process, the expected write-once message, and identical SHA-256 digests for every stored evidence file before and after. Run `git diff --check` and review the diff so only the two specified specs are changed by execution. Do not edit or stage .planning/config.json, the Phase 233 capture PNGs, or .planning/milestone.lock; they are pre-existing user/session state.
</verification>

<success_criteria>
Both affected specs and the full host browser suite exit 0 in normal mode; saved Phase 234 post-layout evidence has identical bytes before and after; explicit capture mode refuses its populated destination; the source diff is limited to the two named specs.
</success_criteria>

<output>
Create .planning/quick/261008-cjc-repair-playwright-ci-automate-the-existi/261008-cjc-SUMMARY.md when done.
</output>
