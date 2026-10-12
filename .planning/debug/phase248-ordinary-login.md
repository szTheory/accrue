---
status: resolved
trigger: "Phase 248 ordinary mounted tracer fails login: API POST returned 500 without auth cookie; native chooser login also failed before Admin navigation"
created: 2026-10-12T02:09:49Z
updated: 2026-10-12T12:50:18.077962+00:00
---

## Current Focus

hypothesis: Confirmed two-factor Phase 248 harness failure: wrong README password extraction plus chooser redirect/page.goto race.
test: Corrected both and ran the exact mounted ordinary Playwright tracer.
expecting: The login reaches authenticated Admin and invoice review capture.
next_action: Commit the owned README, harness and debug artifact; lifecycle executor reruns the ordinary capture after the commit and performs visual inspection and full render verification.
reasoning_checkpoint:
  hypothesis: "The README parser supplied a wrong credential; after its repair, the chooser click succeeds but immediate page.goto races the redirect and drops the session cookie."
  confirming_evidence:
    - "Existing regex starts at README line 24 and captures a three-character value on line 699; it fails equality with the documented demo password."
    - "After parser repair, chooser POST returned 302 and created a session, but its immediately following /admin request had no user_token and redirected to login."
    - "A direct CSRF HTTP login with the anchored README password returned /admin 200 with Admin navigation; Phase 247 uses the same request API path."
  falsification_test: "If Phase 247's awaitable API POST still leaves /admin unauthenticated in the same Playwright browser context, the redirect race explanation is wrong."
  fix_rationale: "Anchor credential extraction and await completion of the proven request-context login before page navigation."
  blind_spots: "The remaining invoice review and source-asset assertions may reveal separate failures after login."
  candidate_causes:
    - "code: overly broad README regex in Phase 248 command"
    - "code: chooser click followed by immediate navigation before cookie commit"
    - "environment: host account password differs from documentation (refuted by successful HTTP login)"
  and_gate: "Yes. Both the broken parser and premature navigation independently prevent a successful mounted login. The server's failed-password timestamp exception explains the 500 observed with the first bad credential."

## Symptoms

expected: Ordinary Fake host signs in as local operator and renders mounted Admin invoice action review.
actual: Phase 248 ordinary tracer does not reach authenticated Admin navigation.
errors: Earlier API login returned HTTP 500 without authentication cookie; later native chooser login failed Admin navigation assertion.
reproduction: Run guarded ordinary Phase 248 Playwright command with README local operator credential in process memory.
started: During Phase 248 tracer implementation; Phase 247 ordinary login previously worked.

## Eliminated

## Evidence

- timestamp: 2026-10-12T02:09:49Z
  checked: Phase 247 and Phase 248 login helpers
  found: Phase 247 posts CSRF, email and password with Playwright request API; Phase 248 fills a preselected chooser form by direct DOM value assignment and clicks Enter workspace.
  implication: Both auth path and exact credential selection must be compared before changing code.
- timestamp: 2026-10-12T02:17:00Z
  checked: Ordinary host logs for failed Phase 248 POSTs
  found: Both API and chooser POSTs queried admin, then HTTP 500 arose at Sigra.Auth.handle_failed_login_with_lockout/5 because its failed-login update wrote microseconds into a :utc_datetime field.
  implication: The supplied credential was wrong; changing form submission alone cannot fix this failure.
- timestamp: 2026-10-12T02:17:00Z
  checked: Existing Phase 248 README command's regex, comparing without printing credentials
  found: Regex starts at the operator account on README line 24 but captures a 3-character punctuation-ended string on line 699; it does not match the documented demo password.
  implication: Credential extraction is deterministically wrong because the regex expects a space after `password`, while the documentation has a newline.
- timestamp: 2026-10-12T02:21:00Z
  checked: Correctly anchored README password used in an isolated HTTP cookie-jar CSRF login
  found: Login redirected to /; follow-up /admin returned 200 and contained Admin navigation.
  implication: The host account and session path are healthy for the correct credential; the first failure is isolated to Phase 248 credential extraction.
- timestamp: 2026-10-12T02:27:00Z
  checked: Phase 248 tracer after README parser correction, with ordinary host logs
  found: Correct chooser POST returned 302 and wrote a session. The test's immediately following GET /admin carried no user_token and redirected to login, reproducing the Admin navigation failure.
  implication: Phase 248 form click/navigation ordering is a second necessary fix; use Phase 247's request-context POST.
- timestamp: 2026-10-12T02:31:00Z
  checked: Mounted Phase 248 ordinary Playwright tracer after both fixes
  found: 1/1 test passed in 7.3 seconds; authenticated Admin invoice action review generated wide/light and narrow/dark PNGs plus a manifest.
  implication: The original login failure no longer occurs; capture inspection and final source-bound verification remain with the lifecycle executor.

## Resolution

root_cause: The Phase 248 README command's regex crossed from the documented operator line to a later backtick, supplying a wrong password; after that was corrected, the chooser submit succeeded but immediate page.goto raced its redirect and lost the browser session cookie. The bad-password attempt surfaced as HTTP 500 because Sigra's failed-login update writes microseconds to an Ecto :utc_datetime field.
fix: Bound the README credential parser to the operator login sentence; use the proven Phase 247 CSRF request-context POST before navigating to mounted Admin.
verification: Correctly anchored credential gave direct HTTP /admin 200; ordinary Phase 248 Playwright tracer passed 1/1; node --check and parser equality checks passed. Generated captures await visual inspection and source-bound validation after commit.
files_changed: [examples/accrue_host/README.md, examples/accrue_host/e2e/phase248-scenarios.spec.js, .planning/debug/phase248-ordinary-login.md]

## Milestone Closeout Resolution — 2026-10-12

Anchored credential extraction and awaited CSRF login are committed in929b140b. Ordinary mounted lane passed1/1, final10captures at112d484d inspected and both validatorspassed. Incorrect-password Sigra timestamp exception remains outside scope; this resolved record concerns the harness login.
