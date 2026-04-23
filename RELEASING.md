# Releasing Accrue

This runbook is written for the **recurring** maintainer path: **pre-1.0 linked**
`accrue` + `accrue_admin` releases via **Release Please** on a green `main`, followed
by ordered Hex publishes and lightweight post-publish checks. The **same-day `1.0.0`**
bootstrap story is an **exceptional** appendix at the end — read that only when you
are intentionally coordinating a first public major.

**Planning milestones vs Hex SemVer:** files under **`.planning/`** may use labels like **`v1.14`** or **`v1.15`** for internal milestone bookkeeping. Those **do not** replace the **`accrue` / `accrue_admin` `@version`** values in each **`mix.exs`** or the versions published on **Hex**. Consumers pin and upgrade against **Hex + changelogs**; maintainers use this runbook plus **`accrue/guides/upgrade.md`**.

**Last verified against** `release-please-config.json`, `.release-please-manifest.json`,
and `.github/workflows/release-please.yml` on **2026-04-22** (UTC). Update this line when
automation semantics change.

## Routine pre-1.0 linked releases (Release Please + Hex)

1. Confirm CI is green on `main`, especially the `release-gate` workflow and the lanes below.
2. Let **Release Please** open the **combined** linked release PR (see `release-please-config.json`
   — `separate-pull-requests: false` — and `.release-please-manifest.json` for per-package versions).
3. Review the PR: both `accrue/mix.exs` and `accrue_admin/mix.exs` `@version` values match the manifest,
   both package-local `CHANGELOG.md` files update, and automation outputs look sane.
4. Merge after checklist sign-off, **or** after review dispatch **Actions → Release PR automation → Run workflow**
   with the PR number so auto-merge queues **only** via **`workflow_dispatch`** (not on PR open/sync).
   Use `scripts/ci/gh_merge_release_pr.sh` if you need the Release Please PR number before dispatching.
5. Confirm Hex package availability for **`accrue`** before relying on **`accrue_admin`** consumers.
6. Let `.github/workflows/release-please.yml` publish **`accrue_admin`** when the workflow gates
   (`needs.release.outputs.*`, `ACCRUE_ADMIN_HEX_RELEASE=1`) say it is safe — **`accrue` publishes first**.
7. Verify HexDocs for both packages, tags, and GitHub releases as appropriate.

### Release Please + Hex (linked automation)

The standard path is `.github/workflows/release-please.yml`:

- Release Please runs only on pushes to `main` and manual `workflow_dispatch`.
- `release-please-config.json` uses **one combined release PR** for `accrue` and `accrue_admin` (`separate-pull-requests: false`) so versions and `scripts/ci/verify_package_docs.sh` stay aligned.
- Authoritative package changelogs are only `accrue/CHANGELOG.md` and `accrue_admin/CHANGELOG.md` (the paths wired in `release-please-config.json`); do not add duplicate changelogs under nested directories such as `accrue/accrue/` or `accrue_admin/accrue_admin/`.
- Automated publish is gated by same-workflow outputs:
  - `needs.release.outputs.accrue_release_created`
  - `needs.release.outputs.accrue_admin_release_created`
- `accrue` publishes first.
- `accrue_admin` publishes only after the `accrue` publish job succeeds when both packages release together.
- `accrue_admin` dry-run and publish steps export `ACCRUE_ADMIN_HEX_RELEASE=1`.
- If Release Please creates the **core** GitHub Release but not the admin one in the same run, the workflow **lockstep fallback** still publishes `accrue_admin` when both manifest versions match (same push SHA).

This automation does not publish from `pull_request`, `pull_request_target`, or ordinary branch pushes.

### Optional: queue merge after maintainer review

`.github/workflows/release-pr-automation.yml` runs **only** on **`workflow_dispatch`**. After you review the Release Please PR, optionally dispatch it with the PR number so `gh pr merge --merge --auto` queues merge when required checks pass — there is **no** subscription to `pull_request` events.

Enable **Allow auto-merge** under repository **Settings → General**. If branch protection requires approving reviews, complete human review first, then dispatch (or merge manually / use `scripts/ci/gh_merge_release_pr.sh`).

## Release verification lanes

- `Canonical local demo: Fake` is the required deterministic gate for docs and release readiness. This is the normal release lane.
- `Provider parity: Stripe test mode` is for optional/manual provider-parity checks. Use it to prove hosted Checkout behavior, signed Stripe webhook delivery, SCA/3DS branches, and response-shape fidelity that Fake does not cover.
- `Advisory/manual: live Stripe` is for final app-level confidence before shipping your app. It is not required for clone-to-evaluate, standard CI, or normal Accrue releases.

Fake is the canonical front door and required deterministic gate. Stripe-backed lanes exist to catch provider drift and app-specific integration risk, not to replace Fake or to block ordinary package releases.

The required deterministic gate includes package verification, host integration, generated drift/docs drift, the checked-in security/trust artifact at `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md`, seeded performance smoke, compatibility floor/target checks, and browser accessibility/responsive checks.

For the provider-parity detail lane, see [guides/testing-live-stripe.md](guides/testing-live-stripe.md).

## Release PR review checklist

- The combined release PR updates **both** `accrue/mix.exs` and `accrue_admin/mix.exs` `@version` consistently with `.release-please-manifest.json` before publish jobs run.
- The same PR updates both package-local `CHANGELOG.md` files.
- `accrue` publishes before `accrue_admin`.
- `Canonical local demo: Fake` remains the required deterministic gate before release.
- The required deterministic gate still includes `security/trust artifact`, `seeded performance smoke`, `compatibility floor/target checks`, and `browser accessibility/responsive checks`.
- `Provider parity: Stripe test mode` stays optional/manual and out of the required release lane.
- `Advisory/manual: live Stripe` stays advisory/manual before shipping your app, not a package release blocker.
- `RELEASE_PLEASE_TOKEN` and `HEX_API_KEY` exist only as GitHub Actions secrets.
- Secrets are never checked into docs, commit messages, config files, or echoed in workflow logs, and public docs must not ask for webhook secrets, customer data, or PII.

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

## Verification before publishing

Run the required deterministic gate first:

```bash
cd accrue
mix test --warnings-as-errors
bash ../scripts/ci/verify_package_docs.sh
```

That `Canonical local demo: Fake` lane is the required deterministic gate for release readiness because it stays credential-free and reproducible.

Required deterministic gate checklist:

- package verification
- host integration
- generated drift/docs drift
- security/trust artifact
- seeded performance smoke
- compatibility floor/target checks
- browser accessibility/responsive checks

If you need provider fidelity coverage, run `Provider parity: Stripe test mode` separately. It is optional/manual, uses Stripe test-mode secrets through environment variables or GitHub secrets, and exists to prove provider-specific behavior that Fake cannot:

- hosted Checkout behavior
- signed Stripe webhook delivery and signature fidelity
- SCA/3DS branches
- Stripe response-shape drift

Keep provider-backed checks out of the required release lane. In real integrations, signed webhook verification and runtime secrets remain required; this runbook does not make raw-body verification optional. Follow the public webhook guidance in `accrue/guides/webhooks.md` and the provider-parity detail guide at [guides/testing-live-stripe.md](guides/testing-live-stripe.md). Never paste webhook secrets, customer data, or PII into release docs, issue reports, or retained artifacts.

`Advisory/manual: live Stripe` is the last lane. Use it for final host-app confidence before shipping your app, after the Fake gate and any Stripe test-mode parity checks. It is advisory/manual before shipping your app, not a required Accrue release blocker.

## Manual fallback

If Release Please dry-run cannot produce a combined release PR when you need one, use the manual fallback only after creating and reviewing a manual release PR that sets both package versions and both package changelogs consistently.

Use `.github/workflows/publish-hex.yml` only as a manual fallback or recovery path:

- `package`: choose `accrue` or `accrue_admin`
- `tag`: reviewed tag or commit ref to publish from
- `release_version`: expected version at that ref

Manual fallback order:

1. Publish `accrue`.
2. Confirm Hex availability.
3. Publish `accrue_admin`.

Each recovery run checks out the explicit ref, verifies the package `@version`, runs `mix hex.publish --dry-run`, then runs `mix hex.publish --yes`. The recovery workflow never references `steps.release.outputs[...]`.

## Partial Hex publish recovery

When the dual publish is not one atomic transaction, prefer the smallest corrective step first:

- **Retry `accrue_admin`** for the **same** version if core `accrue` at **V** is already correct on Hex — token, metadata, or transient CI issues often clear on a focused re-run.
- **`mix hex.publish --revert`** only for a **clear mistake** on **`accrue`** and **only** inside Hex’s short post-publish window; see [Hex immutability / retire FAQ](https://hex.pm/docs/faq).
- **Otherwise** use **`mix hex.retire`** on the bad release and ship a **new paired version** forward (new combined release PR), with changelog honesty about what not to use.
- If **`accrue`** at **V** should not be consumed without admin **V**, document the partial state and follow the retire / forward-fix path rather than leaving a silent half-pair.

See [https://hex.pm/docs/faq](https://hex.pm/docs/faq) for revert windows, retirement, and registry semantics.

## Appendix: Same-day `1.0.0` bootstrap (exceptional)

Use this section only when you are intentionally coordinating a **first public `1.0.0`**
(or an equivalent historic bootstrap) for **both** packages in one tightly managed window.

1. Confirm CI is green on `main`, especially the `release-gate` workflow and the required deterministic gate for both packages.
2. Trigger or merge the **combined** Release Please PR that explicitly carries `Release-As: 1.0.0` for both package paths when needed. The first bootstrap should use Conventional Commits plus the `Release-As: 1.0.0` trailer for both `accrue` and `accrue_admin`.
3. Review the release PR diff and confirm each package shows `@version "1.0.0"` in its `mix.exs` and the package-local changelog updates in `accrue/CHANGELOG.md` and `accrue_admin/CHANGELOG.md`.
4. Merge the reviewed release PR manually, **or** after checklist sign-off run **Actions → Release PR automation → Run workflow** and enter the PR number so auto-merge queues **only** via **`workflow_dispatch`** (not on PR open/sync). Then let `.github/workflows/release-please.yml` publish `accrue`. You can use `scripts/ci/gh_merge_release_pr.sh` to discover the Release Please PR number before dispatching.
5. Confirm Hex package availability for `accrue` before proceeding.
6. Let `.github/workflows/release-please.yml` publish `accrue_admin` with `ACCRUE_ADMIN_HEX_RELEASE=1`.
7. Verify HexDocs for both packages and confirm `llms.txt` is present in generated docs output.
8. Verify repo health files, package changelogs, and GitHub release notes for both tags.
