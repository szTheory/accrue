# Phase 150 — documentation-adopter-proof — Security Audit

**Result:** SECURED
**Threats Closed:** 7/7
**ASVS Level:** 1
**block_on:** critical_high
**Register source:** authored at plan time in 150-01-PLAN.md and 150-02-PLAN.md (not retroactive)

## Threat Verification

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-150-01 | Tampering | mitigate | CLOSED | `accrue/guides/dunning.md:320-336` — Pitfall blockquote: ":customer attr accepts ... a raw billable. Passing a raw billable triggers Accrue.Billing.customer/1, which has a get-or-create side effect." Snippet at `:331` resolves via `customer_for_scope(socket.assigns.current_scope)` to a `%Accrue.Billing.Customer{}`, never a raw billable. DIY caveat repeated at `:359-360`. |
| T-150-02 | Information Disclosure | mitigate | CLOSED | `accrue/guides/dunning.md:329` ("never from a params-supplied id") and `:336` ("Resolving from the scope (not from a params-supplied customer id) ...prevents a cross-tenant ...leak"). Snippet sources customer strictly from `current_scope`. |
| T-150-04 | Information Disclosure | mitigate | CLOSED | `layouts.ex:85-92` — `dunning_customer(%AccrueHost.Accounts.Scope{} = scope)` matches ONLY on the Scope struct (no params/customer-id arg), delegates to `AccrueHost.Billing.billing_state_for_scope(scope)`. `billing.ex:99-103` → `organization_from_scope(scope)` → `billing_state_for(organization)`; `find_customer/1` (`billing.ex:207-216`) is scoped by `owner_type`/`owner_id` of the active org. Cross-tenant isolation proven by `dunning_banner_live_test.exs:28-67` (past-due org sees banner; healthy org refutes it). |
| T-150-05 | Tampering/Availability | mitigate | CLOSED | `layouts.ex:85-92` resolver uses the READ-ONLY `billing_state_for_scope/1` → `find_customer/1` (`billing.ex:207-216`, pure `Repo.one`), NOT the get-or-create `customer_for_scope/1` → `customer_for/1` → `Billing.customer/1`. Returns an existing `%Accrue.Billing.Customer{}` or `nil` only (`:87-88`). Banner mounted conditionally (`layouts.ex:66`) so nil never reaches the non-nil-safe `Accrue.Dunning.requires_attention?/1` (`accrue/lib/accrue/dunning.ex:28-33` catch-all calls `Billing.customer(billable)`). Regression history in 150-02-SUMMARY confirms the fix (commit `bfed965a`). |
| T-150-06 | Elevation of Privilege | mitigate | CLOSED | `seeds.exs:39` documented demo password `accrue-demo-password`; `:36` explicit "Demo-only credentials — never a production recipe." Owner membership seeded with `role: :owner` (`:87-89`) — org-level owner, NOT admin/superuser. Users created via standard `Accounts.register_user/1` (`:47`). Idempotent via `Repo.get_by` guards (`:42`, `:64`, `:77`). Seed runs only in the example host. No production/admin credentials introduced. |
| T-150-07 | Information Disclosure/Logging | mitigate | CLOSED | Banner uses the shipped zero-config default copy (generic "Action Required..." string, no PII) — no custom inner_block in `layouts.ex:67`. Resolution path (`layouts.ex:85-92`, `billing.ex:65-70,99-103,207-227`) is read-only and contains NO `Logger`/`IO.inspect`/`inspect` of customer/subscription fields (grep: NONE). |
| T-150-SC | Tampering (supply chain) | accept | CLOSED (accepted) | No package-manifest changes in any phase-150 commit. Audited `mix.exs`, `mix.lock`, `package*.json`, `requirements.txt`, `Cargo.toml`, `Gemfile` across commits `29f25d0f`, `6ea5d826`, `b22b2287`, `af85ea8d`, `bfed965a` — NONE touched. All modules first-party (`Accrue.*`, `AccrueAdmin.*`, `AccrueHost.*`). No supply-chain surface introduced. Accepted-risk basis: docs + example-host wiring only. |

## Accepted Risks Log

- **T-150-SC (Supply chain / package installs):** Accepted. This phase introduced no new package dependencies or lockfile changes; all referenced modules are first-party monorepo code. No npm/pip/cargo/hex install surface. Confirmed by git diff of all phase-150 commits against package manifests.

## Unregistered Flags

None. 150-01-SUMMARY "Threat Surface Scan" (line 80) declares no new security-relevant surface (docs-only). 150-02-SUMMARY declares no Threat Flags section and no new attack surface beyond the registered T-150-04..07. No unmapped attack surface detected.

## Notes

- Implementation files were NOT modified (read-only audit). Only this SECURITY.md was written.
- The 150-02 executor regression-fix (commit `bfed965a`) is itself the in-place mitigation of T-150-05: the resolver was moved from get-or-create `customer_for_scope/1` to read-only `billing_state_for_scope/1`, and the banner was made conditional on a non-nil Customer. Verified present in current `layouts.ex`.
