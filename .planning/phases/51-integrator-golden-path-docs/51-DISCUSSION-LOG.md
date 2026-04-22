# Phase 51: Integrator golden path & docs - Discussion log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`51-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 51 — Integrator golden path & docs  
**Areas discussed:** Golden-path spine & sequencing; Command & proof vocabulary; VERIFY-01 & repo-root discoverability; Troubleshooting placement & stable anchors  
**Method:** User requested **all** areas + parallel **generalPurpose** subagent research; parent synthesized into locked **D-01..D-20** decisions.

---

## 1 — Golden-path spine & sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| A — Single spine + sidebars | One narrative; contributor callouts | |
| B — Hub-and-spoke | Index routes to deep guides | Partial (`quickstart` hub only) |
| C — Dual tracks | Full integrator vs contributor trees | |
| D — Strict spine + Step 0 capsules | Parallel entries converge to one ordered spine | ✓ |

**User's choice:** **D** hybridized with **B** for `quickstart.md` only (thin index).  
**Notes:** Cross-language research (Stripe linear flows, Laravel OS tabs, Phoenix guides) supports **one spine + short entry capsules** to minimize drift; dual full tracks rejected as high drift.

---

## 2 — Command & proof vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Keep `verify` / `verify.full` | Current naming; fix prose honesty | ✓ |
| Rename / invert defaults | e.g. `verify` = full CI | |
| Makefile façade only | `make verify` | |

**User's choice:** Keep aliases; adopt **explicit three-layer** vocabulary (package gate vs host proof vs `host-integration` job).  
**Notes:** Subagent identified semantic gap: **`host-integration` ≠ `mix verify.full` alone**—CONTEXT mandates accurate phrasing + `CONTRIBUTING` bridge.

---

## 3 — VERIFY-01 & repo-root discoverability

| Option | Description | Selected |
|--------|-------------|----------|
| A — Minimal root + deep link | Root scent + host README SSOT | ✓ |
| B — Dedicated verification hub | New top-level doc | Deferred |
| C — Badges / CI table | Optional minimal | Optional discretion |

**User's choice:** **A** (+ light **CONTRIBUTING** routing per research).  
**Notes:** Two-hop satisfied if first hop is stable and anchor exposes commands; avoid splitting authority with duplicate hub.

---

## 4 — Troubleshooting placement & stable anchors

| Option | Description | Selected |
|--------|-------------|----------|
| SSOT centralized | Single troubleshooting page | ✓ (matrix + sections) |
| Distributed inline | Errors only in each guide | |
| Hybrid | SSOT + short pointers in spines | ✓ |

**User's choice:** **Hybrid** — `troubleshooting.md` + `ACCRUE-DX-*` + `SetupDiagnostic` paths; spines link only.  
**Notes:** Aligns with existing `accrue/lib/accrue/setup_diagnostic.ex` and `accrue/guides/troubleshooting.md` anchors.

---

## Claude's discretion

- Root README fenced-block formatting and exact Layer B/C one-liner wording.
- Optional single merge-blocking CI badge on root.

## Deferred ideas

- Renaming verify tasks; standalone verification hub duplicating host README; INT-04+ / phases 52–53 scope.
