# Phase 39: Org billing proof alignment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `39-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-22  
**Phase:** 39 — Org billing proof alignment  
**Areas discussed:** Archetype row; Proof strength; Enforcement placement; scripts/ci/README ownership  
**Method:** User requested **all** areas + parallel `generalPurpose` subagent research, then orchestrator synthesis into a single coherent decision set.

---

## 1. Archetype(s) for the adoption proof matrix

| Option | Description | Selected |
|--------|-------------|----------|
| A | phx.gen.auth org mainline (ORG-05/06) as primary named archetype | ✓ |
| B | Pow-oriented row | Optional advisory |
| C | Custom org / ORG-08 row | Optional advisory |
| D | Combo: A + honest example-host / Sigra tension in prose | ✓ |
| E | Doc-only anchors without machine check | ✗ (paired with D-06/D-07 gates) |

**User's choice:** Delegated to research synthesis — **primary row = A**, **optional B/C as advisory**, **explicit honesty** about example host vs recipe (D-02).

**Notes:** Subagent highlighted **accrue_host** Sigra dependency vs **non-Sigra guide** mainline; footgun = implying stack equals archetype.

---

## 2. Proof strength (executable vs prose)

| Option | Description | Selected |
|--------|-------------|----------|
| 1 | New host E2E / Playwright / heavy ExUnit for non-Sigra path | ✗ default |
| 2 | Matrix + README prose only | ✗ for merge-blocking (D-07) |
| 3 | Hybrid: new matrix bash + extend `organization_billing_guide_test.exs` | ✓ |

**User's choice:** Research synthesis — **hybrid (3)**; VERIFY-01 remains **narrow** (D-05).

**Notes:** Idiomatic OSS = fast doc contracts in library; expensive proof for VERIFY-01 only.

---

## 3. Where ORG-09 enforcement lives

| Option | Description | Selected |
|--------|-------------|----------|
| A | Extend `verify_verify01_readme_contract.sh` heavily | ✗ (semantic creep) |
| B | Dedicated `verify_adoption_proof_matrix.sh` | ✓ primary |
| C | Package ExUnit only | ✗ as sole owner; ✓ as supplement |

**User's choice:** **B** primary + **C** as belt-and-suspenders per D-06; **A** stays minimal (D-11).

**Notes:** Avoid duplicating matrix semantics inside VERIFY-01 awk.

---

## 4. scripts/ci/README.md ORG-09 row

| Option | Description | Selected |
|--------|-------------|----------|
| A | New `## ORG gates (v1.8 org billing proof)` subsection | ✓ |
| B | Fold into ADOPT table | ✗ |
| Single row | One ORG-09 row, multi-script primary cell | ✓ |

**User's choice:** Subagent + synthesis — **new subsection**, **one REQ-ID row**, triage bullets for new script.

---

## Claude's Discretion

- Exact grep needles, optional ExUnit harness for matrix script (D-12), README one-liner depth.

## Deferred Ideas

- Sigra-free host or second app; per-archetype Playwright — see `39-CONTEXT.md` `<deferred>`.
