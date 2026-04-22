# Phase 52 — Technical research

**Question:** What do we need to know to **plan** integrator proof honesty (**INT-04**), package doc / `@version` alignment (**INT-05**), and coupon + promotion code **Copy** SSOT (**AUX-01**, **AUX-02**)?

---

## 1. Proof stack (INT-04)

- **`examples/accrue_host/README.md`** is the **executable-command SSOT** enforced by **`scripts/ci/verify_verify01_readme_contract.sh`** (Playwright paths, `host-integration`, `mix verify.full`, links to matrix + specs).
- **`examples/accrue_host/docs/adoption-proof-matrix.md`** is the **semantic map** (ORG-09 archetypes, blocking vs advisory). **`scripts/ci/verify_adoption_proof_matrix.sh`** pins stable substrings (section headings, `phx.gen.auth`, `use Accrue.Billable`, ORG-07/08 rows, self-path).
- **`evaluator-walkthrough-script.md`** should change **only** when **D-06** triggers: commands, CI equivalence claims, artifact names, or blocking vs advisory language the evaluator must speak changes — not for cosmetic matrix edits alone.
- **Layer honesty:** README / matrix must never imply **local Layer B** equals **`host-integration` (Layer C)** or “mirrors full PR CI” unless literally true (**52-CONTEXT D-08**).

---

## 2. Package docs & version SSOT (INT-05)

- **`scripts/ci/verify_package_docs.sh`** parses **`@version`** from **`accrue/mix.exs`** and **`accrue_admin/mix.exs`**, asserts versions match, and **`require_fixed` / `require_regex`** on READMEs, guides, `RELEASING.md`, `CONTRIBUTING.md`, Playwright config needles, etc.
- **Extension pattern:** add **`require_fixed`** or **`require_regex`** lines for **each** consumer-facing path Phase 52 edits so Release Please bumps surface **CI failures** instead of silent drift (**desirable friction**).
- **Hex vs `main`:** add or strengthen short **banner** prose on GitHub-facing READMEs: install lines on **`main`** track **`@version` on this branch**; published bits → **Hex.pm / HexDocs** (**D-11**, Oban-style).

---

## 3. Copy architecture (AUX-01 / AUX-02)

- **Reference:** **`AccrueAdmin.Copy`** + **`AccrueAdmin.Copy.Subscription`** + **`defdelegate`** (**Phase 50**).
- **New modules:** **`lib/accrue_admin/copy/coupon.ex`** and **`lib/accrue_admin/copy/promotion_code.ex`** (`@moduledoc false`), exposed only via **`defdelegate`** on **`AccrueAdmin.Copy`** — keeps **`copy.ex`** thin (**52-CONTEXT D-01**).
- **Naming:** **`coupon_*`**, **`promotion_code_*`** prefixes for grep-friendly review (**D-02**).
- **Targets:** **`coupons_live.ex`**, **`coupon_live.ex`**, **`promotion_codes_live.ex`**, **`promotion_code_live.ex`** — replace inline operator strings with Copy calls.
- **Tests:** Route strings through **`AccrueAdmin.Copy`** in assertions; avoid snapshotting entire catalogs (**D-04**).
- **Playwright:** Default **defer** full mounted coverage to **Phase 53**; if Phase 52 touches export task or VERIFY-01 specs, follow **D-15** minimal path + **`export_copy_strings`** allowlist (**Phase 50 D-23**).

---

## 4. Risks & footguns

| Risk | Mitigation |
|------|------------|
| Matrix/README drift under new CI lanes | Update matrix + **`verify_adoption_proof_matrix.sh`** needles together; extend README contract script if new literals are SSOT. |
| Version literals in prose bypassing `mix.exs` | Extend **`verify_package_docs.sh`** for every edited install surface. |
| Copy/tests diverging | Assertions call **Copy** functions; optional allowlist extension for generated JSON if Playwright lands. |
| Over-editing walkthrough | Apply **D-06** trigger checklist before touching **`evaluator-walkthrough-script.md`**. |

---

## Validation Architecture

Phase 52 validation is **bash contract scripts** + **`mix test`** (scoped admin + host) + optional **`mix verify`** / **`mix verify.full`** as repo norms dictate.

| Dimension | Approach |
|-----------|----------|
| **Feedback loop** | After each task: **`mix test`** in touched app (`accrue_admin` or `accrue`); after doc-only waves: run **`bash scripts/ci/verify_package_docs.sh`**, **`bash scripts/ci/verify_verify01_readme_contract.sh`**, **`bash scripts/ci/verify_adoption_proof_matrix.sh`** as applicable. |
| **Copy correctness** | **`mix test`** on **`accrue_admin`** including **`LiveViewTest`** for coupon/promo routes — assertions reference **`AccrueAdmin.Copy`** (no duplicate English for SSOT strings). |
| **CI parity** | Full **`mix verify`** / **`mix verify.full`** before merge per project CONTRIBUTING norms. |
| **Browser** | **Not** required for Phase 52 completion unless **D-15** exception; then narrow Playwright + **`copy_strings.json`**. |

**Nyquist note:** Keep at least one automated check every few tasks (no long stretches of doc-only commits without re-running the nearest relevant script).

---

## RESEARCH COMPLETE

Planning can proceed with **`52-CONTEXT.md`**, this file, and **`52-UI-SPEC.md`** as primary inputs.
