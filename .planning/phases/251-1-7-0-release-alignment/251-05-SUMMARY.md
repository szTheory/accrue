---
phase: 251-1-7-0-release-alignment
plan: "05"
subsystem: release-automation
status: complete
completed: 2026-10-26
requirements-completed: []
tags: [release-please, changelog, release-notes, pins, alignment, sc1, rls-01]
requires: [251-04]
provides:
  - aligned release PR 55 head A 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2 (two fast-forward docs(release) commits on RAW 24f8a342)
  - curated, evidence-backed 1.7.0 sections in accrue, accrue_admin and accrue_portal CHANGELOGs
  - 1.7.0 release-notes stories under accrue and accrue_admin; README and first_hour pins at 1.7.0
affects: [251-06]
key-files:
  created:
    - .planning/phases/251-1-7-0-release-alignment/251-05-SUMMARY.md
  modified:
    - accrue/CHANGELOG.md (release branch only)
    - accrue_admin/CHANGELOG.md (release branch only)
    - accrue_portal/CHANGELOG.md (release branch only)
    - accrue/guides/release-notes.md (release branch only)
    - accrue/README.md (release branch only)
    - accrue/guides/first_hour.md (release branch only)
    - accrue_admin/README.md (release branch only)
    - .planning/phases/251-1-7-0-release-alignment/251-RELEASE-LEDGER.md
    - .planning/phases/251-1-7-0-release-alignment/251-VERIFICATION.md
    - .planning/phases/251-1-7-0-release-alignment/251-UAT.md
decisions:
  - "The D2 Known issues bullet includes the UTC-session workaround because the code confirms the column default supplies every inserted_at value: inserted_at is not in Event @cast_fields, the schema field is read_after_writes, and the insert path sets no timestamp."
  - "Draft bullets that put admin or portal behavior in core (recovery scope on navigation, promotion revalidation, processor action gating) were moved to the package that owns the code; core states only its own API facts."
  - "The core section names the LocalSession.mark_completed/1 behavior change (it now completes only a claimed session), which the draft omitted, because LocalSession is a documented public module."
  - "The claim table keeps the verdict as the last cell and folds curation notes into the bullet cell, because the Task 2 coverage audit matches the verdict at end of line."
actuals:
  tokens: 11800
  tasks: 3
  commits: 2
plan_head_before: 24f8a34220070ee7148ecc1b9f37d922386bf3c9
plan_head_after: 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2
coverage:
  - id: A1
    description: the curated 1.7.0 sections of all three packages pass the SC1 curated-CHANGELOG gate on head A, and the raw release-please sections at RAW fail it for all three packages
    requirement: RLS-01
    verification:
      - kind: command
        ref: "bash scripts/ci/verify_release_changelog_curated.sh --self-test && bash scripts/ci/verify_release_changelog_curated.sh (in a worktree at A)"
        status: pass
      - kind: command
        ref: "R=$(mktemp -d) && for p in accrue accrue_admin accrue_portal; do mkdir -p $R/$p && git show 24f8a342:$p/CHANGELOG.md > $R/$p/CHANGELOG.md; done && git show 24f8a342:.release-please-manifest.json > $R/.release-please-manifest.json && ! bash scripts/ci/verify_release_changelog_curated.sh --root $R"
        status: pass
    human_judgment: false
  - id: A2
    description: on head A the release-notes contract, release manifest alignment, release contract and package docs (RELEASE_PLEASE_PR unset, the post-merge main bar) pass, and the notes contract and package docs both fail at RAW
    requirement: RLS-01
    verification:
      - kind: command
        ref: "bash scripts/ci/verify_release_notes_contract.sh && bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && env -u RELEASE_PLEASE_PR bash scripts/ci/verify_package_docs.sh (in a worktree at A)"
        status: pass
      - kind: command
        ref: "! bash scripts/ci/verify_release_notes_contract.sh && ! env -u RELEASE_PLEASE_PR bash scripts/ci/verify_package_docs.sh (in a worktree at RAW 24f8a342)"
        status: pass
    human_judgment: false
  - id: A3
    description: README and first_hour pins name 1.7.0 at all four sites and no ~> 1.6.0 pin remains, and release-notes.md carries a 1.7.0 story above 1.6.0 under both accrue and accrue_admin
    requirement: RLS-01
    verification:
      - kind: command
        ref: "git show 2d3a4c62:accrue/README.md | grep -F '{:accrue, \"~> 1.7.0\"}' && ! git grep -n -F -e '~> 1.6.0' 2d3a4c62 -- accrue/README.md accrue/guides/first_hour.md accrue_admin/README.md"
        status: pass
    human_judgment: false
  - id: A4
    description: the alignment reached the release branch as a plain fast-forward push after asserting the remote branch was RAW and main was FREEZE_SHA; the PR head is A with title and body unchanged, and the release PR scope gate still passes
    requirement: RLS-01
    verification:
      - kind: command
        ref: "test \"$(git ls-remote origin refs/heads/release-please--branches--main | cut -f1)\" = 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2 && bash scripts/ci/verify_release_pr_scope.sh --pr 55 --version 1.7.0"
        status: pass
    human_judgment: false
---

# Phase 251 Plan 05: Release Branch Alignment Summary

Release PR #55 now carries curated 1.7.0 notes for all three packages, 1.7.0 release-notes stories, and 1.7.0 install pins. Every bullet was checked against code, tests or the `ca8f6655..RAW` diff, and many draft bullets were reworded. The work landed on `release-please--branches--main` as two fast-forward `docs(release):` commits on top of release-please's raw commit, giving head A = `2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2`.

## What changed on the release branch

| Commit | Files |
|--------|-------|
| `3eb2beac` docs(release): curate accrue 1.7.0 changelog, release-notes stories and pins | `accrue/CHANGELOG.md`, `accrue/guides/release-notes.md`, `accrue/README.md`, `accrue/guides/first_hour.md`, `accrue_admin/README.md` |
| `2d3a4c62` docs(release): curate accrue_admin and accrue_portal 1.7.0 changelogs | `accrue_admin/CHANGELOG.md`, `accrue_portal/CHANGELOG.md` |

- **Core `## [1.7.0]`:** `### Release highlights` (10 bullets) and `### Known issues` (1 bullet). The release-please heading line (compare URL and date) is byte-identical to RAW.
- **Admin and portal `## [1.7.0]`:** `### Notes` with the `Compatibility only:` bullet (`linked 1.7.0`, `core`, `package owns`), then `### Release highlights` (admin 9 bullets, portal 5). Both heading lines are byte-identical to RAW.
- **Historic sections:** every `## [1.6.0]`-and-older tail of all three CHANGELOGs is byte-identical to RAW (Task 2 verify).
- **release-notes.md:** `### 1.7.0` above `### 1.6.0` under `## accrue` and under `## accrue_admin`.
- **Pins:** `accrue/README.md:38`, `accrue/guides/first_hour.md:95-96`, `accrue_admin/README.md:24` and `:84` now say `1.7.0`.
- **Contract traps:** the admin and portal 1.7.0 sections contain no `new ` token and none of `admin-owned`, `portal-owned`, `grant authority` or `authorization behavior`. The scan showed it could find these: a synthetic fixture gave 2 hits, and RAW's admin CHANGELOG gave 1. The text has no personal names, e-mails or absolute paths; the census and the no-home-paths guard pass.

No `.release-please-manifest.json`, `mix.exs`, gate script or PR body/title was edited.

## D2 Known issues wording (core CHANGELOG)

> `accrue_events.inserted_at` is filled by the column default `now()` into a `timestamp without time zone` column (the migration declares `:utc_datetime_usec`), so the stored value follows the database session time zone. On a session that is not UTC, event times are stored as local time but read as UTC, and UTC-windowed event queries can select the wrong rows. Until the fix, which is planned for the next release, run the database session in UTC (for example, set the database or role `timezone` to `UTC`, or pass `parameters: [timezone: "UTC"]` in the Repo config). Rows already written under another time zone are not corrected.

The release-notes core story has the matching sentence: "Known issue: `accrue_events.inserted_at` follows the database session time zone, so UTC-windowed event queries can be wrong on a database session that is not UTC. Run the session in UTC until the fix, which is planned for the next release."

The workaround is included because the code confirms the mechanism. The migration (`20260411000001_create_accrue_events.exs:34`) declares `:utc_datetime_usec, null: false, default: fragment("now()")`, and Ecto's Postgres adapter maps `:utc_datetime_usec` to `timestamp`. `Accrue.Events.Event` declares `inserted_at` with `read_after_writes: true` and leaves it out of `@cast_fields`, and the insert path (`insert_opts/1`) sends no timestamp, so the column default supplies every value. No later migration alters the column. Under a UTC session, `now()` cast to `timestamp` is UTC wall time, which is what Ecto reads back as UTC.

## Claim-to-evidence table

32 rows: 16 verified, 13 reworded, 3 dropped. Areas: `area:core` 11, `area:known-issue` 1, `area:refinement` 13, `area:owner-feedback` 2, `area:320px-reflow` 1, `area:focus-ring` 1, `area:not-adopter-facing` 3. Each CONTEXT-named area (`refinement`, `owner-feedback`, `320px-reflow`, `focus-ring`) maps to at least one verified or reworded row. The coverage audit was shown able to fail: the same check against a copy of the table without the focus-ring row exits 1 with `missing focus-ring`.

Material rewordings from the drafts:
- **Draft claims that overreached into core:** "keep their scope when you navigate", "promotions decided in one place" and "actions are gated on what the processor will honor". Each was moved to the package whose code does it (admin `scoped_path.ex`, portal `checkout_controller.ex`, and portal `payment_method_controller.ex` capability checks). Core now states only its own API facts.
- **Install template hooks:** the draft called them "the optional Portal policy hooks". Nothing in Accrue calls them; a host's Portal context adapter delegates to them (as `examples/accrue_host` does). Reworded to say that.
- **Portal context:** the draft said "Personal, organization and mixed billing contexts". `accrue_portal/lib` has no organization or mixed-context code, so this was reworded to "resolved through your host's Portal context adapter (or the signed-in billable when there is none)".
- **Admin focus ring:** "quiet table links" became "quiet links". `.ax-link-quiet` is not table-specific.
- **Additions the drafts lacked:** `LocalSession.mark_completed/1` now completes only a claimed session (a behavior change in a documented module); `recovered_vs_lost_mrr/1` now returns `nil` instead of `0` / `"usd"`; the `brand.css` accent changes; and an owner-feedback bullet.
- **Dropped (not adopter-facing):** the CI seed boundary, the portal Braintree client-token stub race, and compile, credo, test and visual-baseline plumbing.

| package | coverage area | bullet (and curation note) | evidence (file:line, test, or commit) | verdict |
|---------|---------------|--------|---------------------------------------|---------|
| accrue | area:core | LocalSession reuses the session on a concurrent same-operation retry; claim/2, mark_uncertain/1, release_claim/1; mark_completed/1 completes only a claimed session; actionable?/2 single expiry check [note: draft "retries, double submits and provider returns" made concrete; adds the mark_completed/1 behavior change the draft omitted] | accrue/lib/accrue/checkout/local_session.ex (insert_or_reuse_after_conflict, claim/2, update_claimed_status where status == "processing", actionable?/2); commits f4c2c135, d92fc6be, c280b014; accrue/test/accrue/checkout/local_session_test.exs | reworded |
| accrue | area:core | Checkout.reconcile/2 :expected_metadata, {:error, :checkout_context_mismatch}, paid-only projection, serialized per session [note: draft "reconciled against authoritative provider state"] | accrue/lib/accrue/checkout.ex reconcile/2, validate_expected_metadata/2, paid_checkout?/1, pg_advisory_xact_lock; commit cb583311; accrue/test/accrue/checkout_test.exs | reworded |
| accrue | area:core | Braintree subscription decline becomes Accrue.CardError card_declined instead of a generic API error [note: draft "Braintree declines keep their decline outcome"] | accrue/lib/accrue/processor/braintree.ex create_subscription ErrorResponse clause + translate_charge_error/1 (:825); prior to_accrue_error/1 APIError (:428); test "create_subscription/2 translates a processor decline into a card error" (accrue/test/accrue/processor/braintree_test.exs, commit 44f4346f) | reworded |
| accrue | area:core | (draft) "eligibility and promotions are decided in one place" [note: core keeps the actionable?/2 fact; promotions moved to the portal checkout bullet] | core part of d92fc6be is only actionable?/2; promotion-code revalidation lives in accrue_portal | reworded |
| accrue | area:core | DLQ.requeue/1 locks and claims the row in one transaction; requeue/2 authorization callback, {:error, :out_of_scope} [note: draft "two operators cannot dispatch"; bulk owner-scope revalidation is the admin caller of requeue/2, stated as the callback] | accrue/lib/accrue/webhooks/dlq.ex requeue/2, fetch_replayable/2 (lock: "FOR UPDATE"), commit_requeue/1 update_all on status in [:dead, :failed]; commits 8e11fcaa, 16aab2eb | reworded |
| accrue | area:core | Manual invoice item add/remove locks the invoice, refuses non-draft, removes only manual items ({:error, :invoice_item_not_manual}) | accrue/lib/accrue/billing/invoice_actions.ex lock_invoice/1, add_locked_invoice_item/4, remove path price_ref: nil clause; commits 060734e0, 5bfa1be7 | verified |
| accrue | area:core | Fake/Stripe/Braintree declare payment-method create/update/delete/set_default, swap_plan, preview_upcoming_invoice; Braintree reports swap_plan and preview false; checked with Accrue.Processor.supports?/1 [note: draft "actions are gated on what the active processor will honor"; the gating itself is in portal/admin] | accrue/lib/accrue/processor/{fake,stripe,braintree}.ex capabilities/0; accrue/lib/accrue/processor.ex supports?/1 (:462, public @doc); consumers accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex authorize_supported (:15,:47,:77), billing_read_model.ex:108; commits ae9e26c1, 73d6ad0a | reworded |
| accrue | area:core | (draft) "Recovery analytics report evidence-based amounts and keep their scope when you navigate" [note: core states the nil-instead-of-0/"usd" return change and current_status; scope-on-navigate moved to admin journeys bullet] | accrue/lib/accrue/analytics/dunning.ex recovered_vs_lost_mrr/1 (ELSE NULL, no "usd"/0 default), at_risk_subscriptions/1 current_status; commits f995d6ea, 82ee2045. Scope-on-navigate is accrue_admin/lib/accrue_admin/scoped_path.ex (admin) | reworded |
| accrue | area:core | :admin_branding theme: :system/:light/:dark, default :system; :light/:dark lock and hide picker | accrue/lib/accrue/config.ex :admin_branding theme option + admin_branding/0 default theme: :system; accrue_admin/lib/accrue_admin/components/topbar.ex theme_forced (:12,:48-51); commit 907909a7 | verified |
| accrue | area:core | mix accrue.install billing context includes self-only portal_organization_for/2 and authorize_portal_action/5 for a Portal context adapter to delegate to [note: draft "default for the optional Portal policy hooks"; nothing in Accrue calls them, a host adapter does] | accrue/priv/accrue/templates/install/billing.ex.eex:45-73; caller pattern examples/accrue_host/lib/accrue_host/portal_context_adapter.ex:67,73; commit e4e97526 | reworded |
| accrue | area:core | shared brand.css derives accent hover and accent-text from a darker accent mix in light and dark [note: added; not in draft core section] | accrue/priv/static/brand.css --accrue-brand-accent-strong / --accrue-brand-accent-text; commit 879e23a4 | verified |
| accrue | area:known-issue | accrue_events.inserted_at filled by column default now() into timestamp without time zone; follows session TZ; workaround: UTC session; fix planned next release; existing rows not corrected [note: draft lacked mechanism detail and the workaround; workaround included because the code confirms the DB default supplies the value] | accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs:34 (:utc_datetime_usec, default: fragment("now()")); accrue/deps/ecto_sql/lib/ecto/adapters/postgres/connection.ex:2071 (:utc_datetime_usec -> "timestamp"); accrue/lib/accrue/events/event.ex:48 (read_after_writes: true) and @cast_fields (inserted_at not cast, so the DB default supplies every value); accrue/lib/accrue/events.ex insert_opts/1 (returning: true, no timestamp); no later migration alters the column; Postgrex :parameters option (deps/postgrex/lib/postgrex.ex:105); .planning/REQUIREMENTS.md:46 (v1.68) | reworded |
| accrue_admin | area:refinement | Journeys keep their place: customer, subscription, invoice, payment, coupon, promotion code, Connect, webhook, event and Recovery pages preserve list, filters and owner scope; return links name and validate destination | accrue_admin/lib/accrue_admin/scoped_path.ex return_destination/5, validate_return_path, return_label/2; used by live/{customer,charge,webhook,connect_account,promotion_code,events,event,subscriptions,coupon,subscription,invoice}_live.ex and live/analytics/campaign_live.ex; commits 234-07, 241-02..04, 242-01..04, 82ee2045 | verified |
| accrue_admin | area:refinement | Actions recheck before they run (subscription, invoice, refund, payment-method, webhook replay after step-up); unconfirmed outcomes shown as such and not retried | live/customer_live.ex revalidate_payment_method_action (:1215), "Outcome not confirmed" (:1295); live/charge_live.ex revalidate_refund (:703, :666); live/invoice_live.ex:1328; live/subscription_live.ex :unconfirmed (:1595,:2023); commits 234-04, 237-05, 237-06, 238-02, 241-06, 241 ambiguous outcomes | verified |
| accrue_admin | area:refinement | Lists: labeled filters with removable chips; bounded global search (100 chars, 5 per group) with one active index for pointer and keyboard | components/filter_chip_bar.ex:84-88 (remove_href, "Remove ... filter"); components/global_search.ex:11-12,106,337; commit a4c00f5c (command_palette.js active index) | verified |
| accrue_admin | area:owner-feedback | Infinite lists keep every loaded row, report "N of M <rows> loaded" and say "End of list"; quieter copyable record IDs; "Missing default method" wording [note: draft "resource-specific counts" made concrete; payment-method wording added] | components/data_table.ex:568-569, pagination_progress/3 (:1099); commit f23f8e75 removed @default_dom_limit 100 / retain_rows; components/id_badge.ex:3-7 click-to-copy; copy.ex customers_list_missing_payment_method_label; commits a467006f, b493c50e, f23f8e75 | reworded |
| accrue_admin | area:owner-feedback | Quieter header utility controls and billing activity, unified page gutters, aligned breadcrumbs, clearer Home activity, event details and timelines [note: added as its own bullet; described as fixes only] | commits 3d7d949d, b493c50e, b396fc16 (components/topbar.ex), 7e77a01f (breadcrumbs.ex, event_icon.ex), d122d53a (timeline.ex, event_presentation.ex), 66d5b3ce, a467006f, c5b25640, b4a7eeac (range 3d7d949d..b4a7eeac); every selector added to app.css by b4a7eeac, c5b25640, a467006f and dc5e89cd is present in the committed accrue_admin/priv/static/accrue_admin.css | verified |
| accrue_admin | area:refinement | One time convention: Local/UTC preference shared across pages; clicking a timestamp copies its exact UTC ISO value with a confirmation naming what was copied; selectable fallback when the clipboard is unavailable | components/timestamp.ex:13-37 (data-clipboard-text={@iso}, "Click to copy the exact UTC timestamp."); assets/js/hooks/clipboard.js:21-24 ("Copied ${label} to clipboard"); assets/js/hooks/time_display.js; commits 3b9d2c01, 483d5d3c, a72a3e0e | verified |
| accrue_admin | area:refinement | Events and webhooks: readable event labels, exact scoped links to event detail, clearer replay acceptance and read-recovery states, raw payloads wrap on narrow screens | event_presentation.ex for/1 (:88) label map; commits 6f864858 (238-02), 36f69a5a (244-03), dc5e89cd (247 wrap) | verified |
| accrue_admin | area:320px-reflow | 320px reflow fixes for the top bar (200% text) and the webhook detail header | commit 8b9dc258 (app.css topbar grid; committed bundle rebuilt in the same commit), commit 50e814b4 (live/webhook_live.ex ax-body overflow-wrap) | verified |
| accrue_admin | area:focus-ring | Shared keyboard focus ring on quiet links [note: draft "quiet table links"; the selector covers all quiet links] | commit 6fc488cd: assets/css/app.css adds .ax-link-quiet:focus-visible to the shared ring list and rebuilds priv/static/accrue_admin.css; in the shipped bundle the ring-list rule (byte 127148) follows the old outline:none rule (byte 99974) at equal specificity, so the ring wins | reworded |
| accrue_admin | area:refinement | Larger touch targets for table links and review controls on coarse pointers | commits 7f1d89a4 (@media (pointer: coarse) .ax-data-table-shell .ax-link 44px), 6ae839c7 | verified |
| accrue_admin | area:refinement | Admin theme can be locked from host config; theme choice survives LiveView patches | components/topbar.ex theme_forced + "theme set by host"; brand_plug.ex; commit 2a79b390 (accrue_theme.js resync) | verified |
| accrue_portal | area:refinement | (draft) "Personal, organization and mixed billing contexts are resolved through your host policy" [note: now "resolved through your host's Portal context adapter, or the signed-in billable without one"] | accrue_portal/lib contains no organization or mixed-context code; organization billing exists only in examples/accrue_host via a host Context adapter | reworded |
| accrue_portal | area:refinement | Context rechecked on every action; a signed pin only locates the account and never expands what the actor may do | accrue_portal/lib/accrue_portal/context.ex moduledoc ("a session selection or pin is only a locator"), mint_pin/2 / verify_pin/2 (signed, 20-minute max age), authorize_action/4; authorize.ex fresh_context/1; commits 233-01..03, 233-07 | verified |
| accrue_portal | area:refinement | Adding, defaulting and deleting payment methods, cancelling or changing subscriptions and completing checkout each authorized against the pinned context; denied or revoked context blocks safely; unsupported processor actions are refused | live/payment_methods_live.ex:30-62,193; live/add_payment_method_live.ex:15-18; controllers/payment_method_controller.ex:15,47,77,109 (authorize_supported with capability paths); live/subscriptions_live.ex:29,74; live/subscription_live.ex:66,198; controllers/checkout_controller.ex:25-28; live/checkout_live.ex:37; live/blocked_live.ex | verified |
| accrue_portal | area:refinement | Checkout: Braintree Hosted Fields submit to the server; POST completion claims the session first; promotion codes revalidated before a POST claims it; expired checkouts offer a validated way back to billing; return destinations validated; decline outcomes preserved [note: draft "expired checkouts offer a validated recovery action" made concrete; promotions moved here from core] | commit 235-01 (priv/static/accrue_portal.js); controllers/checkout_controller.ex:31,76-95 (LocalSession.claim/mark_completed/mark_uncertain/release_claim); controllers/checkout_controller.ex:23,39 (validate_promotion before the :31 claim, {:error, :stale_promotion}; commit d92fc6be); live/checkout_live.ex safe_recovery_url (:74-75, "Return to billing"); commits 236-04 (return destinations, declines) | reworded |
| accrue_portal | area:refinement | Hosted invoices open within the billable's scope; an unavailable read is distinguished from an empty one | billing_read_model.ex invoices/1, invoice_result/1 (:175-180); live/invoices_live.ex; accrue_portal/test/accrue_portal/live/invoices_live_test.exs; commits 236-01 (both) | verified |
| accrue_portal | area:refinement | Hosted Fields colors follow the Portal theme; status and accent colors consistent | commit 236-06 (priv/static/accrue_portal.js theme-derived colors, supported style selectors); commit 879e23a4 (priv/static/accrue_portal.css, accrue/priv/static/brand.css) | verified |
| accrue_admin | area:not-adopter-facing | CI seed boundary (250-03 CI-only) omitted | CONTEXT: CI-only; no package code ships it | dropped |
| accrue_portal | area:not-adopter-facing | Portal Braintree client-token stub race (250-04, test-only) omitted | raw bullet "250-04: start the portal Braintree client-token stub unlinked" changes test support only | dropped |
| accrue_admin | area:not-adopter-facing | compile/credo/test hygiene (249-01, 249-02, 249-12, quick-261008-cb9, 250-02 test PG timezone), visual-baseline/browser-UAT plumbing (240-02, 243-01, 243-02) omitted | raw bullets; test/CI-only or warning cleanup | dropped |

## Gate replay on the worktree at A (all rc 0)

Raw outputs are in `.planning/251-evidence.local/251-05-*.out` (git-ignored).

| Gate | Last line |
|------|-----------|
| verify_release_notes_contract.sh | `verify_release_notes_contract: OK (1.7.0)` |
| verify_release_manifest_alignment.sh | `OK: release manifest and mix.exs @version aligned at 1.7.0 (accrue, accrue_admin, accrue_portal) ...` |
| verify_release_changelog_curated.sh `--self-test` / live | `self-test PASS (...)` / `OK (1.7.0): curated release sections` (0/0/0) |
| verify_package_docs.sh (`RELEASE_PLEASE_PR` unset; `mix deps.get` from the lockfile in the worktree, no symlinks) | `fixed invariants checked: ...` |
| verify_release_contract.sh | `verify_release_contract: v1.59 OK` |
| verify_no_home_paths.sh `--self-test` / `--repo` | `SELF-TEST OK` / `OK (mode repo)` |
| sensitive-token census (TAP, fixtures, repo, as ci.yml) | `PASS (... 5463 tracked files scanned ...)` |
| verify_release_pr_title_roundtrip.sh, verify_stable_core_posture.sh, verify_reference_scenario_contract.sh and the other 11 docs-contracts-shift-left bash gates | OK |
| `mix test test/accrue/docs` | `123 tests, 0 failures` |
| 250-prepush-guard.sh `--hygiene-only --range 24f8a342..HEAD` | `guard: all checks passed` |

**Positive controls at RAW (each must fail, and does):**
- SC1 on RAW's three CHANGELOGs plus manifest: rc 1, `accrue: 18`, `accrue_admin: 168`, `accrue_portal: 41` raw lines.
- verify_release_notes_contract.sh on a RAW worktree: rc 1, `accrue_admin/CHANGELOG.md must remain compatibility-only`.
- verify_package_docs.sh on a RAW worktree (`RELEASE_PLEASE_PR` unset): rc 1, `accrue/README.md is missing: {:accrue, "~> 1.7.0"}`.
- Task 1's intermediate run had core curated and the companions raw: rc 1 with `accrue: 0`, `accrue_admin: 168`, `accrue_portal: 41`. This shows the gate discriminates per package.

## Remote writes (CONTEXT A6)

| UTC timestamp | Action | Target | Result |
|---------------|--------|--------|--------|
| 2026-10-26T15:53:00Z | push | `refs/heads/release-please--branches--main` (plain fast-forward, maintainer credentials, no force) | ok, `24f8a342..2d3a4c62` |

Immediately before the push, `git ls-remote` gave release branch = RAW `24f8a342...` and main = FREEZE_SHA `6e285bff...`, and `merge-base --is-ancestor RAW HEAD` held. After the push, the remote branch was A; `gh pr view 55` showed head A, title `chore: release main`, and a body byte-identical to the pre-push capture; `verify_release_pr_scope.sh --pr 55 --version 1.7.0` passed (`Target version: 1.7.0`). Main was not touched and no tag was pushed.

## CI on head A

`node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2 --event pull_request --pr-base origin/main` (origin/main = FREEZE_SHA) returned:

```
250-ci-head-status: GREEN at 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2 (event pull_request)
  note: ci.yml: run 40353699704 attempt 1 head_sha 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2
  note: ci.yml: parked lane, any conclusion allowed: Admin UI ratchet guardrails [parked]: failure; first failed step: Verify frozen ratchet evidence (job 121685875535)
  note: accrue_admin_browser.yml: 11 PR path(s) checked against its pull_request paths, 8 match
  note: accrue_admin_browser.yml: run 40353699699 attempt 1 head_sha 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2
  success jobs: 20
```

In run 40353699704 the steps `verify_package_docs.sh`, `Release notes freshness contract` and `Release CHANGELOG sections are curated (Phase 251 SC1)` each concluded `success`. The parked ratchet lane also failed at F (`8a9c1c99`, run 40340488190) and at S (`6e285bff`, push run 40344886087), so the failure is pre-existing and was not introduced here.

## Deviations from Plan

**1. [Rule 3 - Blocking] The claim table's verdict cell had to be bare**
- **Found during:** Task 2 verify
- **Issue:** the coverage audit matches `| (verified|reworded) |` at end of line, but the first table appended curation notes to the verdict cell.
- **Fix:** curation notes moved into the bullet cell as `[note: ...]`. The verdict stays the last, bare cell. The audit then passed, and its negative fixture (focus-ring row removed) failed.

**2. [Rule 3 - Blocking] verify_release_contract.sh needs Accrue deps**
- Its reference-scenario sub-gate runs mix. `mix deps.get` was run in the worktree from the committed lockfile (no symlinks, no lock change), as the plan allows for verify_package_docs.

**3. Extra evidence beyond the plan**
- Positive controls for the notes contract and package docs on a disposable RAW worktree (removed afterwards), and `mix test test/accrue/docs` on A.

**4. Measured commits**
- `commits: 2` is `git rev-list --count RAW..A` (`plan_head_before` = RAW, `plan_head_after` = A). The package edits live only on the release branch. The bookkeeping commit carrying this SUMMARY on unpushed `docs/251-close` is not counted, as in 251-04.

## Notes for 251-06

- R = 55, A = `2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2` (logged as `A=` in `.planning/251-remote-writes.local`), GREEN on its exact head. Re-run the helper on A right before merging, then merge with `gh pr merge 55 --merge --match-head-commit 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2`.
- Main stays frozen at FREEZE_SHA. A push to main would rerun Release Please, which could rebuild the branch and wipe the alignment.
- The parked `Admin UI ratchet guardrails [parked]` lane is red at A, F and S. The helper allows any conclusion for it.
- The post-merge main push enforces verify_package_docs without `RELEASE_PLEASE_PR`. It passes on A's tree locally.
- The scratch worktree was removed after A was confirmed on the remote. The commits remain in the object store and on the remote branch.



## Self-Check: PASSED

- FOUND: 251-05-SUMMARY.md, 251-RELEASE-LEDGER.md
- FOUND: 3eb2beac and 2d3a4c62 on the remote release branch (head A = 2d3a4c62787b8511ab3f0b5d65c57e3af2b38cc2)
- FOUND: A3 ref passes on A, and its `~> 1.6.0` probe finds 1 hit at RAW (the positive control)
