# Release notes (plain-language)

This page is the **story** of what shipped—not a commit list. For every line item and hash, see the package changelogs and GitHub releases:

- [`accrue/CHANGELOG.md`](https://github.com/szTheory/accrue/blob/main/accrue/CHANGELOG.md) — machine-precise history for the core library
- [`accrue_admin/CHANGELOG.md`](https://github.com/szTheory/accrue/blob/main/accrue_admin/CHANGELOG.md) — same for the admin UI package
- [GitHub releases](https://github.com/szTheory/accrue/releases) — tags and generated notes (more technical)

`accrue` and `accrue_admin` live in one repo and are usually bumped together so your host app never depends on mismatched versions.

---

## accrue

### 0.2.0

**Stripe Tax–ready billing, calmer installs, stronger CI trust.**

You can turn on **automatic tax** for subscriptions and checkout in a first-class way, with billing state and observability columns to match. The **Fake** processor understands the same shapes, so tests stay deterministic.

Install and boot got **clearer diagnostics**: preflight checks, webhook route awareness, and migration inspection errors surface as ordinary setup hints instead of mystery crashes. Docs and the **checked-in host demo** stay aligned so “what CI proves” and “what you run locally” mean the same thing.

Under the hood: Connect, webhooks, telemetry, and config refinements; release gates and package-doc checks got stricter so regressions are caught before they reach Hex.

### 0.1.2

Patch release focused on **HexDocs** and README polish so published docs match what you see on GitHub.

### 0.1.1

Early **CI and release pipeline** stabilization so public automation and docs publishing behave predictably.

---

## accrue_admin

The admin package is the **LiveView dashboard** that mounts into your Phoenix router. It tracks `accrue` closely—install the same version family for both.

### 0.2.0

Matches **accrue 0.2.0**: same tax and billing surface assumptions, asset and docs drift fixes alongside the core release.

### 0.1.x

Initial public releases with the admin UI, asset pipeline, and docs wired for the same Stripe-backed flows as the core library.

---

## How we version

- **Patch** — safe fixes, docs, and internal quality.
- **Minor** (pre-1.0) — new capabilities you can adopt incrementally; read the changelog before upgrading production.

When in doubt, read **[Upgrade](upgrade.md)** and run your usual test and staging passes.
