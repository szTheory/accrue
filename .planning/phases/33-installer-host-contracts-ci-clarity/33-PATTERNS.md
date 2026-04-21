# Phase 33 — Pattern map

Analogous artifacts for installer, doc contracts, and CI clarity work.

## Doc contract pattern (bash gates)

**Reference:** `scripts/ci/verify_package_docs.sh` uses `require_fixed "$ROOT_DIR/<path>" '<exact substring>'` — copy style when adding new invariants.

```23:28:scripts/ci/verify_package_docs.sh
require_fixed() {
  local file=$1
  local needle=$2

  grep -Fq "$needle" "$file" || fail "$file is missing: $needle"
}
```

## Phase plan shape (PLAN.md)

**Reference:** `.planning/phases/32-adoption-discoverability-doc-graph/32-01-PLAN.md` — YAML frontmatter with `wave`, `depends_on`, `files_modified`, `requirements`, `<threat_model>` table, tasks with `<read_first>`, `<action>`, `<acceptance_criteria>`, `<verify>`.

## Installer test fixture pattern

**Reference:** `accrue/test/support/install_fixture.ex` + `accrue/test/mix/tasks/accrue_install_test.exs` — `InstallFixture.tmp_app!/1`, `run_install/2`, tags for selective runs.

**Rerun excerpt:**

```283:308:accrue/test/mix/tasks/accrue_install_test.exs
  @tag :install_templates
  test "re-run updates pristine fingerprinted files and skips user-edited files even with --force" do
    app = InstallFixture.tmp_app!(:fingerprints)
    # ...
    run_install(app, ["--yes"])
    # ...
    run_install(app, ["--yes"])
    # ...
    output = run_install(app, ["--yes", "--force"])

    assert output =~ "skipped"
    assert output =~ "user-edited"
```

## first_hour doc test ordering

**Reference:** `accrue/test/accrue/docs/first_hour_guide_test.exs` — `assert_order!/2` requires markers appear in sequence; new sections must sit **after** the last ordered marker or the list must be extended.

## CI advisory job pattern

**Reference:** `.github/workflows/ci.yml` — `live-stripe` job with explicit comment preserving job id for `act -j live-stripe`; `continue-on-error: true`; restricted `if:` to non-PR paths.
