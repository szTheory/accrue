# Releasing Accrue

This runbook is for the same-day public `1.0.0` release of `accrue` and `accrue_admin`, then for later recovery runs when a manual publish is necessary. The release order is `accrue` then `accrue_admin`.

## Same-day `1.0.0` bootstrap

1. Confirm CI is green on `main`, especially the Phase 9 release gate for both packages.
2. Trigger or merge release PRs that explicitly carry `Release-As: 1.0.0` for both package paths. The first bootstrap should use Conventional Commits plus the `Release-As: 1.0.0` trailer for both `accrue` and `accrue_admin`.
3. Review both release PR diffs and confirm each package shows `@version "1.0.0"` in its `mix.exs` and the package-local changelog update in `accrue/CHANGELOG.md` or `accrue_admin/CHANGELOG.md`.
4. Merge the reviewed release PRs and let `.github/workflows/release-please.yml` publish `accrue`.
5. Confirm Hex package availability for `accrue` before proceeding.
6. Let `.github/workflows/release-please.yml` publish `accrue_admin` with `ACCRUE_ADMIN_HEX_RELEASE=1`.
7. Verify HexDocs for both packages and confirm `llms.txt` is present in generated docs output.
8. Verify repo health files, package changelogs, and GitHub release notes for both tags.

## Release PR review checklist

- Both package release PRs show `@version "1.0.0"` before any bootstrap publish is allowed to run.
- Both package release PRs update the correct package-local `CHANGELOG.md`.
- `accrue` publishes before `accrue_admin`.
- `RELEASE_PLEASE_TOKEN` and `HEX_API_KEY` exist only as GitHub Actions secrets.
- Secrets are never checked into docs, commit messages, config files, or echoed in workflow logs.

## Minimum secret setup

Create both secrets in GitHub before the first release run:

1. Open the repository on GitHub.
2. Go to **Settings** -> **Secrets and variables** -> **Actions**.
3. Add `RELEASE_PLEASE_TOKEN` as a GitHub token that can create release pull requests, push release tags, create GitHub releases, and write pull-request comments for this repository.
4. Add `HEX_API_KEY` as a Hex.pm API key that can publish the `accrue` and `accrue_admin` packages.
5. Never paste either value into workflow files, docs, commit messages, terminal transcripts, issues, or pull requests.

For the first anonymous maintainer release, use the GitHub identity `szTheory`
and the noreply commit email already configured in this checkout:
`szTheory@users.noreply.github.com`.

## Automated path

The standard path is `.github/workflows/release-please.yml`:

- Release Please runs only on pushes to `main` and manual `workflow_dispatch`.
- Automated publish is gated by same-workflow outputs:
  - `needs.release.outputs.accrue_release_created`
  - `needs.release.outputs.accrue_admin_release_created`
- `accrue` publishes first.
- `accrue_admin` publishes only after the `accrue` publish job succeeds when both packages release together.
- `accrue_admin` dry-run and publish steps export `ACCRUE_ADMIN_HEX_RELEASE=1`.

This automation does not publish from `pull_request`, `pull_request_target`, or ordinary branch pushes.

## Manual fallback

If Release Please dry-run cannot produce both `1.0.0` release PRs, use the manual fallback only after creating and reviewing a manual release PR that sets both package versions and both package changelogs to `1.0.0`.

Use `.github/workflows/publish-hex.yml` only as a manual fallback or recovery path:

- `package`: choose `accrue` or `accrue_admin`
- `tag`: reviewed tag or commit ref to publish from
- `release_version`: expected version at that ref

Manual fallback order:

1. Publish `accrue`.
2. Confirm Hex availability.
3. Publish `accrue_admin`.

Each recovery run checks out the explicit ref, verifies the package `@version`, runs `mix hex.publish --dry-run`, then runs `mix hex.publish --yes`. The recovery workflow never references `steps.release.outputs[...]`.
