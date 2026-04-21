# Phase 32 — Technical Research

**Question:** What do we need to know to plan adoption discoverability and the doc graph well?

## Summary

Phase 32 is **documentation and IA only**: unify merge-blocking proof discovery (VERIFY-01, `mix verify`, `mix verify.full`, `host-integration`, Playwright) across the root README, `examples/accrue_host/README.md`, package guides, and CI doc-contract scripts. No runtime, installer, or admin UI changes.

### Repo facts (verified)

- **Root** `README.md` has a strong “Start here” hub but no above-the-fold block that states the PR merge-blocking path in one breath.
- **Host** `examples/accrue_host/README.md` already contains correct facts: `host-integration` ↔ `mix verify.full`, `mix verify` as focused slice, VERIFY-01 checklist, Playwright/npm notes, matrix + walkthrough links. The **problem is IA**: `## Verification modes` and `## VERIFY-01` are separate top-level sections; evaluators must scroll between them.
- **Mechanical enforcement** exists:
  - `scripts/ci/verify_package_docs.sh` — fixed-string checks including `## Verification modes` on the host README (line ~89).
  - `scripts/ci/verify_verify01_readme_contract.sh` — substrings for `host-integration`, `mix verify.full`, spec paths; **awk** block detection uses `^## VERIFY-01` for `sk_live` negation scanning.
- **`accrue/guides/testing.md`** already states host VERIFY-01 vs parity in “Host VERIFY-01 vs provider parity” but does **not** open with the same approved merge-blocking one-liner the phase wants everywhere.
- **`guides/testing-live-stripe.md`** already distinguishes `live-stripe` job from merge-blocking lane and mentions `host-integration`; keep advisory framing.

### Ecosystem pattern (OSS billing libs)

Libraries like Pay / Jumpstart / Cashier converge on: **short root README** + **one long-form runnable path** in the demo app README + **guides for philosophy**. Duplicating command matrices at the root causes drift; the phase CONTEXT correctly chooses **thin root + host SSOT + hub-and-spoke guides**.

### Planning implications

1. Any host README restructure that demotes `## Verification modes` / `## VERIFY-01` to `###` **must** update `verify_package_docs.sh` and the VERIFY-01 awk in `verify_verify01_readme_contract.sh` in the **same** change set.
2. Root README should add a **named block** (≤5 lines) + **one** deep link to the new host H2 anchor; slug must match GitHub’s heading rules (verify after rename).
3. **Approved one-liner** (finalize verbatim in implementation; job id and task names stay stable):

   > Pull requests are merge-blocked on GitHub Actions job `host-integration`, which runs the same contract as `cd examples/accrue_host && mix verify.full`; use `mix verify` for a faster bounded Fake slice that is not CI-complete.

## Risks / footguns

- **Doc-contract drift:** Editing host headings without updating bash gates breaks CI — treat script updates as mandatory companions.
- **Contradictory “primary” command:** Any file that implies `mix verify` is “what CI runs” without qualification violates ADOPT-03; grep for risky phrasing during execution.
- **Anchor rot:** Root and guides must point to the **single** host H2 chosen in CONTEXT (executor picks stable title; avoid phase numbers in the heading text).

## Validation Architecture

**Nyquist dimension 8 — executable verification for this phase**

| Dimension | How we sample |
|-------------|----------------|
| Doc contracts | After each doc/script edit wave: `bash scripts/ci/verify_package_docs.sh` and `bash scripts/ci/verify_verify01_readme_contract.sh` from repo root (both must exit 0). |
| Goal / SSOT | Manual read: root block ≤2 hops to VERIFY-01 / `mix verify` / Playwright commands; host H2 opening contains approved one-liner verbatim; guides link in without a second contradictory matrix. |
| Regression | Optional: `mix format --check` if any `.ex` touched (unlikely); no app compile required for pure doc phase unless executor touches code. |

**Quick command:** `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh`

**Full command:** Same as quick for this phase (doc contracts are the merge-relevant gate).

**Wave sampling:** Run quick command after **each** plan’s task commits; run once before handoff if any plan only touched non-script docs.

---

## RESEARCH COMPLETE
