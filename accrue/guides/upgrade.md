# Upgrade Guide

For a **readable, version-by-version story** of what shipped (before you read every changelog bullet), see **[Release notes (plain language)](release-notes.md)**.

This guide defines the public upgrade contract for Accrue consumers. Follow the
published billing facade, package changelogs, and documented guides. Do not
assume silent compatibility with undocumented internals, private modules, or
copy-pasted implementation details from the repository.

## Generated code is host-owned

`mix accrue.install` generates host-facing files such as `MyApp.Billing`,
router mounts, and starter config snippets. Those generated code paths are
host-owned after generation.

Installer reruns only update pristine generated files that still match the
Accrue fingerprint marker. If you changed a generated file, Accrue treats it as
user-edited and leaves it alone on rerun.

## Installer rerun behavior

- pristine generated files are safe to update in place
- user-edited generated files are skipped
- unmarked existing files are skipped unless you opt into a narrow overwrite
- `--write-conflicts` writes sidecars under `.accrue/conflicts/` instead of
  patching live app files blindly

That contract is meant to keep upgrades predictable: generated code is
host-owned, and installer reruns do not erase local policy edits.

## Current Hex baseline

The **numeric SemVer** on [Hex.pm for `accrue`](https://hex.pm/packages/accrue) (and the matching **`accrue_admin`** version) is the consumer upgrade boundary. On the branch you are reading, authoritative versions are the **`@version`** fields in **`accrue/mix.exs`** and **`accrue_admin/mix.exs`** (they stay **lockstep** for linked releases — see repository root **`RELEASING.md`**).

**Planning vs packages:** files under **`.planning/`** may refer to internal milestones as **`v1.14`**, **`v1.15`**, and so on. Those labels track **maintainer shipping cadence**, not the Hex major line. `accrue` and `accrue_admin` publish in lockstep on the **`1.0.x`** line. For the 1.0.0 bootstrap story (historical reference for the cut event), read **[`RELEASING.md`](https://github.com/szTheory/accrue/blob/main/RELEASING.md)** → *Appendix: Same-day `1.0.0` bootstrap*.

**Post-1.0 cadence:** On the `1.0.x` line, expect additive fixes, proof hardening, and integrator-contract tightening within the documented facade; breaking changes go through the deprecation cycle in [`RELEASING.md`](https://github.com/szTheory/accrue/blob/main/RELEASING.md#post-1-0-cadence-maintainer-intent). Maintainer framing lives in **[Maturity and maintenance](maturity-and-maintenance.md)**.

Upgrade planning should start from the **published** version you have installed, not from internal modules or undocumented git SHAs.

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
compatibility promise to undocumented internals or private modules. For
generated code, the stability contract is the rerun behavior above: pristine
generated files may be refreshed, while user-edited generated files stay
skipped.

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
mix accrue.install --check
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix docs --warnings-as-errors
```

Those commands catch compile drift, warning-level deprecations, and doc-link
regressions early. Run them after updating dependencies and before promoting the
new version to shared environments.
