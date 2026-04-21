# Feature Research

**Domain:** OSS billing library adoption + internal operator admin  
**Researched:** 2026-04-21  
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Adoption / DX)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Two-hop path from repo root to “run VERIFY-01” | Evaluators abandon after ~2 clicks of confusion | LOW | Root README + `examples/accrue_host/README.md` must agree with CI script names. |
| Single “proof matrix” story | Maintainers need one map: ExUnit vs Playwright vs advisory Stripe | LOW | Extend v1.5 matrix pattern; avoid parallel contradictory tables. |
| Safe `mix accrue.install` reruns | Real users re-run generators after upgrades | MEDIUM | Document + test no-clobber semantics already directionally required for Phoenix installers. |
| CI labels distinguish blocking vs advisory | Trust in CI output | LOW | Job **display names** already tuned in v1.5—do not regress semantics when editing workflows. |

### Differentiators (Operator admin)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Coherent **admin home / dashboard** | Operators see health at a glance without dropping into Stripe | MEDIUM | Bounded counts / recent failures; must not invent accounting or revenue semantics. |
| One improved **cross-entity drill** | Reduces tab churn (e.g. customer → subscription → invoice) | MEDIUM | Stays inside existing LiveView stack; respects row-scope / org lessons from v1.3. |

### Anti-Features

| Feature | Why Problematic | Alternative |
|---------|-----------------|---------------|
| Full “BI dashboard” in Accrue | Wrong layer; duplicates Stripe Sigma / exports | Thin KPI + links to existing admin indexes + external Stripe docs. |
| Rewriting all guides in one phase | High churn, broken anchors | Incremental edits with contract tests / scripts already in repo. |

## Feature Dependencies

```
ADOPT doc graph (clear links)
    └──enforces──> VERIFY-01 scripts + README contracts

OPS dashboard (home)
    └──requires──> consistent nav model (OPS-03)
    └──enhances──> drill flow (OPS-02)
```

## MVP Definition (v1.7)

### Launch With

- [ ] ADOPT: doc discoverability + matrix cross-links (this milestone’s ADOPT reqs)  
- [ ] ADOPT: installer + host README / CI clarity  
- [ ] OPS: admin home + one drill improvement + `AccrueAdmin.Copy` for new literals  

### Defer

- Second processor, finance exports, org recipes → explicit backlog / future milestones  

## Sources

- Pay / Cashier mental model: “install generator + dashboard” as adoption anchor  
- Accrue `.planning/milestones/v1.6-REQUIREMENTS.md` — operator UX baseline  

---
*Feature research for: Accrue v1.7*
