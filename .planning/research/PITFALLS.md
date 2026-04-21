# Pitfalls Research

**Domain:** Adoption + admin polish on a mature billing codebase  
**Researched:** 2026-04-21  
**Confidence:** HIGH

## Common Mistakes

| Pitfall | Symptom | Prevention | Phase attention |
|---------|---------|------------|-----------------|
| **Drift between README and scripts** | CI green but README commands wrong | Extend or add contract shell tests (pattern: `verify_verify01_readme_contract.sh`) | 32–33 |
| **Breaking merge-blocking semantics** | Accidental promotion of advisory Stripe to required | Code review on `ci.yml`; document job ids vs display names | 33 |
| **Dashboard N+1 queries** | Slow admin home on large datasets | Eager limits, aggregate queries, or “recent N” only | 34–35 |
| **Bypassing `AccrueAdmin.Copy`** | Flaky Playwright after copy tweak | New strings go through Copy module; grep for raw duplicates | 35 |
| **Scope creep into billing domain** | New tables/APIs for “metrics” | KPIs derived from existing public contexts or read models only | 34–35 |
| **Cross-tenant leakage in new aggregates** | Org A sees Org B counts | Reuse established scope functions from host / admin queries | 34 |

## Warning Signs During Review

- New **Stripe API** calls added for “dashboard” without a REQ id.  
- Docs pointing to **removed** mix tasks or npm scripts.  
- **Hex** version bumps bundled with unrelated doc PRs (split releases).  

## Sources

- Prior milestone audits (`v1.6-MILESTONE-AUDIT.md`) — traceability and VERIFY-01 discipline  
- `STATE.md` deferred items — known audit-open class work stays out unless explicitly scoped  

---
*Pitfalls research for: Accrue v1.7*
