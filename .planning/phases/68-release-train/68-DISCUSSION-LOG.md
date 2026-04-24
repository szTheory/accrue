# Phase 68: Release train — Discussion log

> **Audit trail only.** Decisions live in **`68-CONTEXT.md`**.

**Date:** 2026-04-23  
**Phase:** 68 — Release train  
**Areas discussed:** Release PR merge path · REL-03 evidence weight · Partial publish recovery · REL-02 changelog boundary  
**Method:** User requested **all** gray areas + parallel research subagents + single synthesis pass.

---

## Release PR merge path

| Option | Description | Selected |
|--------|-------------|----------|
| Manual merge (default) | Release PR merged like any PR after green CI | ✓ |
| Merge queue (optional) | Only if already needed for `main` | ○ (conditional) |
| workflow_dispatch as primary | Automation-first merge | ✗ |
| workflow_dispatch as escape | Documented optional path | ✓ (secondary) |

**Notes:** Elixir/Hex culture skews human-gated ship; Dashbit-style libs observable as maintainer-driven releases.

---

## REL-03 verification evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal URL table | Tags + Hex + changelog-at-tag + timestamp | ✓ |
| Rich screenshots / CI logs | Forensic dossier | ✗ (exceptions only) |

**Notes:** Durable third-party verification; avoids ephemeral Actions URLs and PII in screenshots.

---

## Partial publish recovery

| Option | Description | Selected |
|--------|-------------|----------|
| Re-run failed jobs | GHA first-line recovery | ✓ (first) |
| Manual admin publish from tag | Same recipe as CI | ✓ (second) |
| Revert good `accrue` | Because admin failed | ✗ |

**Notes:** Hex revert/replace reserved for bad core artifact inside time window; forward-fix after wide consumption.

---

## REL-02 changelog boundary

| Option | Description | Selected |
|--------|-------------|----------|
| RP owns versioned sections | Single writer | ✓ |
| Polish on release PR only | Narrative / breaking / security | ✓ |
| Competing manual blocks on `main` | Fight RP | ✗ |
| Unreleased freeze at PR cut | Enforces no gap at boundary | ✓ |

**Notes:** Keep a Changelog audience = integrators scanning breaking/security/processor coupling.

---

## Claude's discretion

- Table formatting in **`68-VERIFICATION.md`** and optional **`mix hex.*`** helper mentions in **`RELEASING.md`** — implementer choice within D-02 / D-04.

## Deferred ideas

- Phase **69** doc mirrors; optional workflow idempotency if publish flakes recur.
