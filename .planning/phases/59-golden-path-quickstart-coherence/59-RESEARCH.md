# Phase 59 — Technical research

**Question:** What do we need to know to plan **golden path + quickstart coherence** (INT-06) well?

## Findings

### 1. Current verifier coverage

- **`scripts/ci/verify_package_docs.sh`** already enforces a large literal contract on **`accrue/README.md`**, **`accrue_admin/README.md`**, **`accrue/guides/first_hour.md`**, **`examples/accrue_host/README.md`**, **`RELEASING.md`**, **`CONTRIBUTING.md`** (single line about Node), **`accrue/guides/testing.md`**, **`troubleshooting.md`** (webhook signing plural + anti-pattern), **`accrue_host_uat.sh`**, Playwright config, **`guides/testing-live-stripe.md`**, etc.
- **`accrue/guides/quickstart.md` is not referenced** anywhere in that script (confirmed: end of script only loops `first_hour.md` and `troubleshooting.md` for webhook config invariants). That matches **59-CONTEXT D-12** — extending the script is the right lever, not a parallel one-off check.

### 2. ExUnit harness

- **`Accrue.Docs.PackageDocsVerifierTest`** shells **`bash scripts/ci/verify_package_docs.sh`** with optional **`ROOT_DIR`** for temp-tree negative tests.
- Any new **`require_*`** on `quickstart.md` implies updating **positive** test expectations (stdout substrings) and possibly **fixture copies** in `tmp_dir` tests so negative cases still isolate failures.

### 3. Narrative surfaces today

- **`first_hour.md`**: Already has **Hex vs `main`**, three-part **`~>`** pins sourced from `mix.exs`, **H/M/R** capsules, spine alignment sentence with host README, webhook signing **secrets** map (plural). Gap vs **D-06**: no single titled **“Trust boundary (production vs demo)”** block routing to **`auth_adapters.md`**, **`organization_billing.md`**, and host README — trust content is spread (Hex paragraph + list_payment_methods note). A **bounded** block after capsules (before **§ 1**) satisfies CONTEXT without duplicating host README’s Sigra essay.
- **`quickstart.md`**: Thin hub (~30 lines), capsule routing, spine bullet list. Missing: **explicit** pointer to **`auth_adapters.md`** for production **`Accrue.Auth`** (D-08).
- **`examples/accrue_host/README.md`**: Opening blockquote already states Sigra optional + demo rationale (**TRT-04** / Phase 58). Re-scan after First Hour edits for **command order** / **capsule** vocabulary drift only.

### 4. Structural anti-drift (D-17 / D-18)

- **Same-PR discipline** for spine/capsules is human process; automation can add **cheap needles**: capsule headings present; **quickstart** must link **First Hour** and must **not** grow a second tutorial body (e.g. absent `defp deps` / full `mix accrue.install` block).
- **Ordering tokens** (deps → … → webhooks → admin → proof): quickstart already lists a bullet outline — script can `grep -Fq` ordered substrings or use a small ordered check; avoid brittle regex across reflows.

### 5. Preflight trio (D-11 / D-13)

- Order: **`verify_package_docs.sh`** first (fast `@version` / pin failures), then **`verify_verify01_readme_contract.sh`**, then **`verify_adoption_proof_matrix.sh`**. CONTRIBUTING already mentions `verify_package_docs` and `scripts/ci/README.md`; add **one** explicit **command block** for golden-path doc editors.

### 6. Out of scope guardrails

- **INT-07/08/09**, **PROC-08**, **FIN-03**, VERIFY hop budget (**Phase 61**), **YAML/codegen spine** — do not implement here.

### 7. Risks

- Over-tightening **quickstart** checks could fight intentional hub refactors — prefer **stable anchors** (required links, forbidden patterns) over prose wording.
- Fixture drift: **`package_docs_verifier_test`** temp trees must gain **`quickstart.md`** when any test assumes a full doc tree.

## Validation Architecture

Documentation phases still require **executable verification** so Nyquist sampling applies:

| Dimension | How this phase proves it |
|-----------|---------------------------|
| **Correctness** | `bash scripts/ci/verify_package_docs.sh` (extended) exits 0; `mix test accrue/test/accrue/docs/package_docs_verifier_test.exs` exits 0. |
| **Integration** | `bash scripts/ci/verify_verify01_readme_contract.sh` and `bash scripts/ci/verify_adoption_proof_matrix.sh` exit 0 after markdown changes. |
| **Regression** | ExUnit negative tests with `ROOT_DIR` tmp fixtures still fail on deliberate drift. |

**Sampling strategy:** After each task that edits docs or scripts, run **`verify_package_docs.sh`** (fast). After the verifier-plan wave completes, run the **full bash trio** + **`package_docs_verifier_test`**.

---

## RESEARCH COMPLETE
