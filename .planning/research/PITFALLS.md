# Pitfalls Research

**Domain:** Accrue v1.25 — checkout facade + friction + integrator contracts  
**Researched:** 2026-04-24  
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Leaking **`client_secret`** or checkout **`url`** via telemetry / logs

**What goes wrong:** Support copies span attrs or logs whole **`{:ok, session}`** — attacker window for hosted/embedded checkout.  
**Why it happens:** Developers assume “billing spans” are safe like subscription ids.  
**How to avoid:** Mirror **BIL-04** doc warnings; **`billing_metadata`** must not include **`attrs`** wholesale; never **`inspect(session)`** in telemetry.  
**Warning signs:** New **`accrue.status`** or custom metadata keys referencing **`url`**, **`secret`**, **`client_secret`**.  
**Phase to address:** **80** (**BIL-06**) + review in **81** (**BIL-07**).

---

### Pitfall 2: **`billing_span_coverage_test`** failure after adding public **`Billing`** function

**What goes wrong:** New **`create_checkout_session`** without **`span_billing`** wrapper breaks merge-blocking test.  
**Why it happens:** Forgot audit pattern on **`Accrue.Billing`**.  
**How to avoid:** TDD: run **`mix test test/accrue/telemetry/billing_span_coverage_test.exs`** before push.  
**Warning signs:** PR touches **`billing.ex`** without touching telemetry test or **`.md`**.  
**Phase to address:** **80**.

---

### Pitfall 3: Doc / matrix / script drift (**INT-12**)

**What goes wrong:** First Hour mentions **`create_checkout_session`** but matrix row missing → **`verify_adoption_proof_matrix.sh`** red.  
**Why it happens:** Partial same-PR updates.  
**How to avoid:** Follow **`scripts/ci/README.md`** triage — touch matrix + script + ExUnit literals in one PR when adding golden-path language.  
**Warning signs:** CI fails only **`docs-contracts-shift-left`** fringe script.  
**Phase to address:** **81**.

---

### Pitfall 4: Friction inventory “silent empty” pass

**What goes wrong:** Maintainer assumes no friction without dated note — future you reopens same class of drift.  
**Why it happens:** Skipping **INV-03** written acceptance criteria.  
**How to avoid:** Require either **new `v1.17-P1-xxx` row** with **`sources`** or explicit **dated maintainer line** referencing **`main`** evidence checked.  
**Warning signs:** Phase **79** closes with no diff to **`v1.17-FRICTION-INVENTORY.md`** and no **`79-VERIFICATION.md`** rationale.  
**Phase to address:** **79**.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip **First Hour** update | Faster **BIL-06** merge | Evaluators never discover API | Only if **INT-12** explicitly defers with written reason in **REQ** |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|-------------------|
| **`customer:`** in attrs | Passing Stripe id string when **`%Customer{}`** already pins Accrue row | **`Billing`** strips duplicate or validates mutual exclusion per **`Session`** expectations. |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Treating checkout **URL** like a non-secret | Session hijack / phishing | Docs + span redaction; align with **`Accrue.Checkout.Session` `Inspect`**. |

## "Looks Done But Isn't" Checklist

- [ ] **Telemetry:** **`accrue.billing.checkout_session.create`** appears in **`guides/telemetry.md`** with PII note.  
- [ ] **Tests:** Fake path covers success + at least one validation or processor error class.  
- [ ] **Friction:** **`verify_v1_17_friction_research_contract.sh`** still passes if inventory row count changes.

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Secret/url leak | 80, 81 | Code review + **`guides/telemetry.md`** diff |
| Span coverage | 80 | **`billing_span_coverage_test.exs`** |
| Proof drift | 81 | **`verify_package_docs`**, matrix scripts, **VERIFY-01** |
| Inventory silent pass | 79 | **`79-VERIFICATION.md`** |

## Sources

- **`.planning/milestones/v1.24-REQUIREMENTS.md`** (**BIL-04** security note)  
- **`accrue/test/accrue/telemetry/billing_span_coverage_test.exs`**  
- **`.planning/research/v1.17-north-star.md`**

---
*Pitfalls research for: Accrue v1.25*  
*Researched: 2026-04-24*
