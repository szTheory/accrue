---
phase: quick-260719-ix8
plan: 01
subsystem: documentation
status: complete
tags: [exdoc, mermaid, architecture, webhooks]
requires: []
provides:
  - outside-in architecture guide for direct subscription creation and webhook convergence
  - inside-out code walkthrough with 18 source-faithful Elixir excerpts
  - theme-aware HTML-only Mermaid rendering with readable offline fallback
  - adaptive Accrue logo and favicon in generated and packaged HexDocs
  - focused documentation drift and packaging contracts
affects:
  - core HexDocs learning path
  - core package documentation contracts
tech-stack:
  added: []
  patterns:
    - render Mermaid only after ExDoc loads and replace source only after render succeeds
    - initialize Mermaid from ExDoc's active theme and rerender retained source after live theme changes
    - freeze documentation structure and a small set of source anchors in focused ExUnit tests
key-files:
  created:
    - accrue/guides/architecture.md
    - accrue/guides/code-walkthrough.md
    - accrue/priv/ex_doc/accrue-mark.svg
    - accrue/priv/ex_doc/favicon.svg
    - accrue/test/accrue/docs/architecture_code_walkthrough_test.exs
  modified:
    - README.md
    - accrue/README.md
    - accrue/mix.exs
decisions:
  - "Use direct subscription creation as the primary outbound route and webhook convergence as the matching inbound route."
  - "Describe processor objects as canonical remote truth and local rows as durable projections used for application reads and fail-closed entitlements."
  - "Document, but do not repair, the queued-event timestamp asymmetry and the bounded Braintree processor conversion gap."
  - "Load pinned Mermaid 11.16.0 only for HTML with strict security; retain readable source when import or rendering fails and emit no EPUB hook."
  - "Follow Mailglass's active-ExDoc-theme lesson: render real dark Mermaid SVGs on transparent native surfaces and rerender in place when the Settings theme changes."
  - "Ship adaptive Accrue mark and favicon SVGs from priv/ex_doc so HexDocs branding survives package builds and dark browser chrome."
requirements-completed: [QUICK-260719-ix8]
metrics:
  duration_min: 29
  completed: 2026-07-19
  tasks: 4
  files: 8
---

# Quick 260719-ix8: Architecture and Code Walkthrough Summary

The core package now has one coherent learning path for senior Elixir/Phoenix engineers: an outside-in architecture guide and an inside-out code walkthrough that follow the same direct-subscribe and webhook-convergence spine. The guides are discoverable from both READMEs, ship in the Hex archive, render accessible theme-aware Mermaid diagrams in HTML, carry branded Accrue logo/favicon assets, and retain readable diagram source when the Mermaid CDN is unavailable.

## What Was Built

### Task 1 — Paired architecture learning path (`677b2b58`)

- Added `accrue/guides/architecture.md` with the 11 locked H2 sections, exactly four accessible Mermaid diagrams, and exactly five parseable Elixir examples.
- Traced direct subscription creation through the adopter facade, customer normalization, capability and idempotency boundaries, processor authority, and transactional local projection.
- Traced webhook receipt through raw signature verification, durable deduplication, Oban dispatch, canonical refetch, transactional projection/audit, and fail-closed local entitlements.
- Added `accrue/guides/code-walkthrough.md` with the locked 18-step order and exactly 18 parseable, source-faithful Elixir excerpts. Its opening warns that internal modules and private functions are explanatory, not promised public API.
- Added cross-links near the beginning and end of both guides, module-based reading routes, and concise Architecture/Code Walkthrough entries to the root and core README reading maps.
- Kept host, core, Admin, Portal, and processor ownership explicit without turning the guide into a directory or dependency catalog.

### Task 2 — Safe rendering and maintainability contracts (`65ab4b50`)

- Extended ExDoc HTML with pinned `mermaid@11.16.0`, `startOnLoad: false`, and `securityLevel: "strict"`.
- The hook handles every `exdoc:loaded`, assigns unique render IDs, guards in-progress nodes, waits for `mermaid.render/2`, installs returned bind functions, and replaces source only after successful rendering.
- Import or render failure leaves the original `<pre><code class="mermaid">` readable and logs one nonfatal warning. EPUB and other non-HTML formats receive an empty hook.
- Added responsive theme-native surfaces, with a layered light-mode shadow, a subtle dark-mode ring, max-width SVGs, and mobile overflow.
- Added seven focused ExUnit contracts covering extras and README discovery, adaptive branding, locked headings and diagram counts, all 23 parseable Elixir blocks, mutual links/path hygiene, five stable source anchors, and Mermaid/EPUB safety behavior.

### Task 4 — Dark-mode and branded-doc polish (`825ffeb9`)

- Applied the Mailglass lesson that the SVG itself must use Mermaid's active `dark` or `default` theme; CSS around a light SVG is not sufficient.
- Retained each graph definition on its rendered wrapper and observed ExDoc's `body.dark` class, so the four diagrams rerender in place after a live Settings theme change without duplicate SVGs or fallback flashes.
- Removed the forced white diagram canvas. Dark diagrams now blend with dark HexDocs while a low-opacity ring preserves surface definition; light diagrams use a small layered shadow.
- Added adaptive Accrue mark and favicon SVGs under `priv/ex_doc/`, wired them through ExDoc's `logo` and `favicon` settings, and verified that the package's existing `priv` whitelist includes them.

### Task 3 — Verification and packaging

- Built warning-free HexDocs and confirmed generated HTML retains four Mermaid source blocks before runtime rendering while EPUB contains no Mermaid loader.
- Built `accrue-1.4.0.tar` without publishing. Its inner archive contains both guides plus `priv/ex_doc/accrue-mark.svg` and `priv/ex_doc/favicon.svg`; package checksum is `799dd91ba911026615caf19f3965b976170e36da970308267b78ad9648fcbed2`.
- Opened both generated guides with the native macOS `open` command as requested.

## Browser Evidence

Named session `accrue-ix8-online`:

- Architecture page rendered four Mermaid SVGs, four wrappers, four accessible titles, and four `aria-labelledby` relationships, with zero raw Mermaid fallbacks.
- All four SVG render IDs were unique. Dispatching a second `exdoc:loaded` event left exactly four diagrams and zero fallbacks, proving the rerender path does not double-render.
- The initial light/dark pass confirmed readability and bounded width, but also exposed the visually discordant forced light canvas that prompted the follow-up polish.
- Follow-up light/dark review after `825ffeb9` verified transparent theme-native surfaces, dark node fill `rgb(31, 32, 32)`, light node fill `rgb(236, 236, 255)`, and four wrapper theme markers changing between `dark` and `default` through the visible ExDoc Settings control.
- The live theme toggle rerendered all four retained graph definitions in place with no duplicates, raw fallback flashes, console messages, or page errors.
- Generated pages reference `assets/logo.svg` and `assets/favicon.svg`; both source SVGs adapt their neutral bars under `prefers-color-scheme: dark`.
- Cross-navigation reached the walkthrough and returned to architecture successfully.
- Walkthrough exposed the expected H1, all 19 ordered H2s (18 numbered steps plus next-reading routes), exactly 18 Elixir code blocks, and no Mermaid nodes or wrappers. All code blocks remained within their 829 px content containers.
- Browser console and page-error reports were empty.

Named session `accrue-ix8-fallback`, with the browser offline before page load:

- Mermaid's dynamic import failed as intended. The page retained four visible source blocks containing 1017, 1027, 1000, and 972 characters; no SVG wrapper was created.
- The browser logged exactly one nonfatal Accrue warning and no uncaught page error. The full-page fallback screenshot was visually inspected and the diagrams remained readable as source.

## Verification Evidence

From `accrue/` unless noted:

- `mix test test/accrue/docs/architecture_code_walkthrough_test.exs` — **7 tests, 0 failures** after the branding/theme contracts were added.
- Direct-subscribe, webhook ingest/reduction, entitlements, and event-immutability journey tests — **76 tests, 0 failures**.
- `mix format --check-formatted mix.exs test/accrue/docs/architecture_code_walkthrough_test.exs` — passed.
- `MIX_ENV=dev mix docs --warnings-as-errors` — passed with no warnings.
- Generated HTML/EPUB inspection — four HTML Mermaid source blocks retained; EPUB has no loader URL.
- `mix hex.build` — passed; both new guides are in the package.
- `git diff --check` across the six implementation paths — passed.
- Both implementation commits contain only the six plan-authorized paths. Pre-existing Admin, workflow, lockfile, example-host, prompt, planning, and Fake-test work was not staged or edited.

The complete core suite and repository-wide documentation/format gates were also run. They expose unrelated pre-existing failures rather than failures in this task:

- `mix test --warnings-as-errors` — **58 properties, 1684 tests, 25 failures (11 excluded)**. Twenty-four `Accrue.Docs.PackageDocsVerifierTest` cases are preempted by an existing bare-breakpoint DSY-01 violation in `accrue_admin/assets/css/app.css`; the remaining `Accrue.ApplicationTest` FND-07 failure expects 7 `--accrue-*` variables in the existing `brand.css` but finds 21.
- `bash scripts/ci/verify_package_docs.sh` — fails on the same existing Admin CSS DSY-01 violation.
- Full `mix format --check-formatted` — fails only on the pre-existing, explicitly out-of-scope `accrue/test/accrue/processor/fake_test.exs`. The scoped format gate passes.

No out-of-scope source was modified to mask these baseline failures.

## Current-State Caveats Captured

- Queued normalized events derive `created_at` from persisted `received_at`; the raw/Fake path can carry provider-created timestamps. Canonical processor refetch is therefore the queued path's primary convergence guarantee.
- Braintree receipt can persist, but `Accrue.Webhook.Event` currently omits `"braintree"` from its bounded processor conversion map, so queued Braintree dispatch fails before its handler. Direct Braintree subscription creation is a separate route and is unaffected.

## Deviations from Plan

The user expanded the accepted scope after the initial implementation to require Mailglass-quality dark diagrams and branded HexDocs chrome. That follow-up added two packaged SVG assets and commit `825ffeb9`; the quick plan and verification contract were updated accordingly. The initial browser invocation used a domain allowlist that cannot admit a `file://` hostname; the session was closed and recreated with local-file access, after which the requested online and offline checks ran normally.

## Self-Check: PASSED

- Commit `677b2b58` — found; four documentation paths only.
- Commit `65ab4b50` — found; `mix.exs` and the focused test only.
- Commit `825ffeb9` — found; Mermaid/theme contracts and two adaptive brand assets only.
- All eight final implementation files — found and committed.
- Scoped tests, formatting, warning-free docs build, package build, online browser rendering, offline source fallback, cross-navigation, and native opens — passed.
- Full-suite/package-docs/full-format baseline failures — reproduced, isolated to untouched files, and reported without scope expansion.
