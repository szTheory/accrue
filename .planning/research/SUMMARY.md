# Research Summary — v1.7 Adoption DX + operator admin depth

**Synthesized:** 2026-04-21  
**Inputs:** `STACK.md`, `FEATURES.md`, `ARCHITECTURE.md`, `PITFALLS.md`

## Executive Summary

v1.7 should **tighten proof and onboarding paths** (README graph, host example, guides, adoption matrix, VERIFY-01 contracts, installer reruns) **before** shipping visible **admin home / drill / nav** improvements, so evaluators never hit broken instructions. Admin work stays inside **LiveView + `ax-*` + `AccrueAdmin.Copy`**, with **bounded** aggregates and **no** new billing primitives or processor/finance scope.

## Stack additions

**None required.** Stay on Elixir 1.17+, Phoenix 1.8+, existing Playwright + GitHub Actions split (Fake merge-blocking vs advisory Stripe test-mode).

## Feature table stakes

- Two-hop discoverability for VERIFY-01 from repo root.  
- Single coherent adoption / testing matrix story (v1.5 foundation).  
- CI + README language that preserves **blocking vs advisory** semantics.  
- Operator **home** + **one** strengthened cross-entity flow + nav clarity.  

## Watch out for

- README / script drift → enforce with existing verify script patterns.  
- Dashboard scope creep → KPI-style summaries only; defer BI/accounting.  
- Query scope bugs on aggregates → reuse org/tenant query discipline from v1.3/v1.6.  

## Recommended phase shape

Four phases: **docs graph → installer/CI contracts → admin flows → summary surfaces + Copy tests** (matches `ARCHITECTURE.md` build order).

---
*Research summary for: Accrue v1.7*
