# Requirements: Accrue — v1.7 Adoption DX + operator admin depth

**Defined:** 2026-04-21  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — with evaluator-clear proof paths and operator admin that stays intentional on first open.

## v1.7 Requirements

Scope is **documentation, host example, CI discoverability, `mix accrue.install`, and `accrue_admin` operator surfaces** — not core billing schema, not **PROC-08**, **FIN-03**, or **ORG-04**.

### Adoption & proof (ADOPT)

- [x] **ADOPT-01**: A new contributor can reach **VERIFY-01** run instructions (host README or linked canonical doc) from the **repository root README** within **two** navigational hops (link → link → runnable command section).
- [x] **ADOPT-02**: `examples/accrue_host/README.md` keeps a **single authoritative** subsection for Fake-first verification, Playwright entry points, and pointers to the **adoption proof matrix** and evaluator walkthrough where those artifacts exist.
- [x] **ADOPT-03**: `accrue` / top-level guides relevant to host onboarding **cross-link** the adoption matrix, testing guide, and host tutorial paths so they do not contradict each other on **which** command is the merge-blocking proof.
- [x] **ADOPT-04**: `mix accrue.install` **rerun** behavior (no-clobber, conflict sidecars, or documented limitations) matches **documented** behavior in install guide or troubleshooting anchors; gaps are either fixed or explicitly called out with a tracking note in phase artifacts.
- [x] **ADOPT-05**: **Broken doc anchors** or renamed scripts introduced by v1.7 doc moves are caught by **existing** doc contract tests / verify scripts where applicable, or a phase note lists **manual** verification steps if no automated hook exists yet.
- [x] **ADOPT-06**: `.github/workflows/ci.yml` (and related docs) keep **unambiguous** language that **Fake / VERIFY-01** lanes are merge-blocking while **Stripe test-mode parity** lanes remain **advisory** — without changing documented job **ids** consumers rely on (`act`, guides).

### Operator admin (OPS)

- [ ] **OPS-01**: Operators landing on the **default admin entry** see a **credible home** surface: bounded “signal” summaries (e.g. recent failures, counts, or links to indexes) that reuse **Phase 20/21** card / grid patterns — **no** new accounting semantics or Stripe objects beyond existing admin queries.
- [ ] **OPS-02**: At least **one** cross-entity operator flow is measurably smoother (clearer navigation, fewer dead ends, or preserved context) — scoped in phase plan to a concrete pair (e.g. customer ↔ subscription ↔ invoice) without new billing APIs.
- [ ] **OPS-03**: Primary **admin navigation labels and ordering** match an operator mental model (billing nouns, not internal module names); changes are reflected in route matrix or inventory appendix if maintainer-facing tables drift.
- [ ] **OPS-04**: New or expanded **summary / KPI** rows use **theme tokens** and `ax-*` layout primitives; any **exception** colors are documented in phase notes per v1.6 **UX-04** discipline.
- [ ] **OPS-05**: New user-visible admin strings introduced by v1.7 go through **`AccrueAdmin.Copy`** (or existing copy SSOT) so **Playwright** and LiveView tests do not rely on duplicate divergent literals.

## Future (not v1.7)

- **PROC-08** second processor adapter, **FIN-03** product/finance exports, **ORG-04** org billing recipes — remain **future milestone** candidates.
- Dedicated **B2C-shaped host LiveView** teaching path (historical backlog item).

## Out of Scope

| Item | Reason |
|------|--------|
| New third-party UI kits or charting stacks | Same as v1.6 — Phase 20/21 contracts. |
| Core billing API, schema, or processor changes | v1.7 is adoption + operator presentation layer. |
| Full WCAG audit of every admin string | Targeted updates for touched surfaces only. |
| Changing Hex-published version numbers as part of planning | Release tagging is separate from milestone planning artifacts. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADOPT-01 | Phase 32 | Complete |
| ADOPT-02 | Phase 32 | Complete |
| ADOPT-03 | Phase 32 | Complete |
| ADOPT-04 | Phase 33 | Complete |
| ADOPT-05 | Phase 33 | Complete |
| ADOPT-06 | Phase 33 | Complete |
| OPS-01 | Phase 34 | Pending |
| OPS-02 | Phase 34 | Pending |
| OPS-03 | Phase 34 | Pending |
| OPS-04 | Phase 35 | Pending |
| OPS-05 | Phase 35 | Pending |

**Coverage:** v1.7 requirements: **11** total — mapped to phases: **11** — unmapped: **0**

---
*Requirements defined: 2026-04-21*  
*Last updated: 2026-04-21 after `/gsd-new-milestone` roadmap creation*
