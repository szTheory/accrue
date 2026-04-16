# Upgrade Guide

This guide defines the public upgrade contract for Accrue consumers. Follow the
published billing facade, package changelogs, and documented guides. Do not
assume silent compatibility with undocumented internals, private modules, or
copy-pasted implementation details from the repository.

## v1.0.0 baseline

`v1.0.0` is the first public baseline for the release surface documented in the
README, ExDoc API pages, and package guides. Upgrade planning should start from
that boundary, not from internal modules or earlier pre-release commits.

When upgrading, review the package-local docs for the package you consume:

- `accrue/CHANGELOG.md`
- `accrue_admin/CHANGELOG.md`

Package consumers should read per-package `CHANGELOG.md` files because the core
package and the admin package can evolve on different release tracks.

## Deprecation window

v1.x breaking changes require a deprecation cycle. If a public API needs to
change during the v1 major line, Accrue first marks the old path as deprecated,
documents the replacement, and removes the deprecated path only in a later
release after that warning window.

That rule applies to documented public surface area. It does not extend a
compatibility promise to undocumented internals, private modules, or generated
snippets that callers modified in their own host app.

## Release Please and changelog flow

Accrue uses Release Please and Conventional Commits to keep release PRs and
package changelogs aligned with shipped changes.

For every upgrade:

1. read the package release PR or tag notes
2. read the relevant package `CHANGELOG.md`
3. check for deprecation notices and replacement paths
4. verify any config or guide updates required by that release

The changelog is the compatibility ledger. If a change is not documented there
or in the public guides, do not assume it is part of the supported contract.

## Verifying an upgrade

Validate the upgrade in the consuming app, not only in the library checkout:

```bash
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix docs --warnings-as-errors
```

Those commands catch compile drift, warning-level deprecations, and doc-link
regressions early. Run them after updating dependencies and before promoting the
new version to shared environments.
