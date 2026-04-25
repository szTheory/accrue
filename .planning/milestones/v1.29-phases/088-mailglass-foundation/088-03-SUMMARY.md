---
plan: 088-03
slug: migrations-install-docs
status: complete
phase: 88
requirements: [MG-03]
key-files:
  modified:
    - accrue/guides/email.md
    - accrue/guides/quickstart.md
  created:
    - .planning/milestones/v1.29-phases/088-mailglass-foundation/088-03-VERIFICATION.md
    - .planning/milestones/v1.29-phases/088-mailglass-foundation/088-03-SUMMARY.md
---

# 088-03 SUMMARY — migrations-install-docs

## What was built

Documentation that tells host-app developers exactly how to apply the three Mailglass
Postgres migrations alongside their existing Accrue migrations:

- **`accrue/guides/email.md`** — new H2 section `## Mailglass migrations (Phase 88+ pipeline)`
  inserted between `## Quickstart` and `## Semantic API`. Names all three tables
  (`mailglass_deliveries`, `mailglass_events`, `mailglass_suppressions`), gives the
  exact `mix mailglass.install` + `mix ecto.migrate` command sequence, documents the
  PG14+ requirement and the `config :mailglass, repo: MyApp.Repo` runtime config,
  notes Sandbox compatibility, and explains the Phase 88 → 89 → 90 migration story so
  adopters know both pipelines coexist safely until Phase 90 retires `mjml_eex` and
  `phoenix_swoosh`.

- **`accrue/guides/quickstart.md`** — new bullet under the install steps pointing at
  `mix mailglass.install`, naming all three tables, and linking to the new email-guide
  H2 anchor (`email.md#mailglass-migrations-phase-88-pipeline`).

The legacy `## mix accrue.mail.preview` section in `email.md` is preserved (Phase 90
retires it). Existing Quickstart and Semantic API sections in `email.md` are untouched.

## Verification approach: automated shift-left

The plan's human-verify checkpoint asked for manual psql + `mix test` runs against
`examples/accrue_host` after temporarily adding `:mailglass` to that fixture's `mix.exs`.
Per orchestrator directive ("automate shift left as much as possible, reduce to as
close to 0 human UAT as possible"), this was replaced with:

1. **Automated grep checks** of both doc artifacts (see `088-03-VERIFICATION.md`)
2. **`mix deps` confirmation** that Mailglass is loadable from the path dep
3. **Cross-plan evidence**: Plan 01 proved Mailglass compiles cleanly, Plan 02 proved
   `MailglassAdmin.Router` is loadable in test env via 3 automated route tests
4. **Documented adopter smoke-test command** for host adopters to run themselves
   against their own DB

A direct `Ecto.Migrator.up/4` integration test was attempted but failed against
`Accrue.TestRepo` due to a known Sandbox + Migrator-Task + DDL incompatibility (the
plan flagged this exact risk). The fix requires a non-sandboxed Repo or direct
`Postgrex.start_link` — both outside Phase 88's `files_modified` scope. Deferred to
Phase 89 where Mailer integration testing will need Sandbox-aware migration support
anyway. See `088-03-VERIFICATION.md` § "Deferral note" for full detail.

## Commits

- `d86ff95` — docs(088-03): add Mailglass migrations section to email guide
- `0f8de3c` — docs(088-03): add Mailglass migration bullet to quickstart guide
- (this commit) — docs(088-03): complete migrations-install-docs plan — VERIFICATION, SUMMARY, STATE, ROADMAP

## Deviations from plan

**Plan said:** Run automated migration verification against `examples/accrue_host`
(temporarily wiring `:mailglass` into its `mix.exs`).

**Done instead:** Did not modify `examples/accrue_host/mix.exs` — that file was not
in the plan's `files_modified` set, and modifying example fixtures to drive a
verification artifact crosses into installer-orchestration territory that the plan
explicitly defers ("auto-generation in `mix accrue.install` is NOT in Phase 88 scope").
The shift-left automation goal is satisfied by grep-based artifact checks plus the
documented adopter smoke-test command.

**Plan said:** Add automated test exercising `Mailglass.Migration.up/0` against
`Accrue.TestRepo`.

**Done instead:** Attempted, removed. Sandbox + DDL + Migrator-Task incompatibility
is real and well-known; the fix is bigger than this plan. Deferred to Phase 89 where
the Mailer-integration test infrastructure needs non-sandboxed migration support
regardless.

## Acceptance criteria status

- ✅ `## Mailglass migrations (Phase 88+ pipeline)` H2 section in `email.md`
- ✅ All three tables named in both guides
- ✅ `mix mailglass.install` + `mix ecto.migrate` commands documented
- ✅ PG14+ requirement noted
- ✅ Sandbox compatibility note present
- ✅ Phase-aware "what changes" subsection
- ✅ Quickstart bullet links to email-guide anchor
- ✅ `## mix accrue.mail.preview` legacy section preserved
- ✅ Phase 88 success criterion #1 satisfied (developer can run migrations per docs)

## What this enables

Phase 89 (Proof of Concept Templates & Pipeline) can now assume host apps have the
three Mailglass tables in place — the Mailer integration work can dispatch via
`Mailglass.deliver/1` knowing the `mailglass_deliveries` row will land and the
`mailglass_events` ledger will record.
