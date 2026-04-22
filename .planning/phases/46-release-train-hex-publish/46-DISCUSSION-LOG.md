# Phase 46: Release train & Hex publish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `46-CONTEXT.md`.

**Date:** 2026-04-22  
**Phase:** 46 — Release train & Hex publish  
**Areas discussed:** Target SemVer + Release Please; Human gates vs automation; Verification evidence; Partial publish failure  
**Mode:** User selected **all** areas and requested **parallel subagent research** + one-shot synthesized recommendations (incorporated into CONTEXT).

---

## 1 — Target SemVer & Release Please

| Option | Description | Selected |
|--------|-------------|----------|
| RP-only from `main` | Next version purely from commits | |
| Milestone intent + RP mechanism | Roadmap intent; RP executes | ✓ (intent only) |
| Manifest + `mix.exs` as SSOT | RP writes manifest + mix + changelogs | ✓ (primary) |
| Full auto-publish without release PR | semantic-release style | ✗ |

**User's choice:** Synthesize toward **manifest + `mix.exs` SSOT**, **commit-derived semver**, **lockstep dual packages**, **Release Please sole writer** — see **D-01..D-05** in CONTEXT.

**Notes (subagent synthesis):** Compared RubyGems, npm semantic-release, Laravel packages, Rust workspaces — dual-package **atomic intent** + **REL-02** alignment beats roadmap-numeric promises.

---

## 2 — Human gates vs automation

| Option | Description | Selected |
|--------|-------------|----------|
| Full auto-merge release PRs | Bot merges when CI green | ✗ |
| Required maintainer merge | Human owns irreversible step | ✓ |
| Hybrid (auto draft, human merge) | RP opens; human merges | ✓ (aligned with maintainer merge) |

**User's choice:** **Human-required merge** for release PRs; strong CI; no bot-only approval theater — **D-06..D-10**.

**Notes:** Pay/Cashier/Kubernetes/npm lessons emphasize **irreversibility > velocity** for money-adjacent libs; supply-chain hygiene (least privilege, no secrets in logs).

---

## 3 — Verification evidence depth

| Depth | Description | Selected |
|-------|-------------|----------|
| Minimal | Links only | ✗ |
| Standard | Links + `hex.info` + CI + smoke commands | ✓ |
| Audit-heavy | SBOM, signed attestations per release | ✗ (deferred) |

**User's choice:** **Standard** checklist — **D-11..D-14** in CONTEXT.

**Notes:** Apache/CNCF patterns borrowed as **command blocks + anchors**, not log dumps.

---

## 4 — Partial publish failure

| Strategy | Description | Selected |
|----------|-------------|----------|
| Retry admin same V | Fix transient; republish admin | ✓ (default) |
| Revert core (window) | Hex revert for clear mistake | ✓ (narrow) |
| Yank-as-policy | Assume easy unpublish | ✗ |
| Forward-fix only | Always V+1 | ✓ (after immutability binds) |

**User's choice:** **Non-atomic Hex** assumed; **retry admin**; **revert** only in window; else **retire + forward**; **D-20** closure rule — see **D-15..D-20**.

**Notes:** npm left-pad, RubyGems yank semantics, Cargo yank culture → **immutability + retire + honest changelog**.

---

## Claude's Discretion

- **VERIFICATION.md** formatting and optional merge queue after approval (**CONTEXT** Claude discretion section).

## Deferred Ideas

- Deep per-release SBOM/SLSA — deferred in CONTEXT `<deferred>`.
