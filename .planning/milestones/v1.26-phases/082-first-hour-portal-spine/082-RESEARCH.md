# Phase 82 — Technical research (INT-13 first-hour portal spine)

**Question:** What do we need to know to plan **INT-13** integrator parity for **`create_billing_portal_session/2`**?

## Stripe / ecosystem shape

- **Checkout vs Customer Portal** remain distinct Stripe products; Accrue already ships **`Accrue.Billing.create_billing_portal_session/2`** and **`billing_portal_session_facade_test.exs`** (Phase 78). Phase 82 is **documentation + CI substring contracts**, not API work.
- Cashier/Pay-style docs treat each named entry point as a **repeatable tuple**: public function arity → telemetry tuple → catalog anchor → ExUnit path.

## Repo SSOT (verified)

- **`accrue/guides/first_hour.md`** documents checkout with **`Accrue.Billing.create_checkout_session/2`**, **`[:accrue, :billing, :checkout_session, :create]`**, fragment **`telemetry.md#billing-checkout-session-create`** (lines 8–10). **No** billing portal paragraph yet after **`list_payment_methods`** block.
- **`accrue/guides/telemetry.md`** lists **`[:accrue, :billing, :billing_portal, :create]`** and `create_billing_portal_session/2` (~136–137) but the **checkout** row has **`<a id="billing-checkout-session-create"></a>`** while the billing-portal row has **no** matching **`billing-billing-portal-create`** anchor yet.
- **`verify_package_docs.sh`** pins checkout literals for **`first_hour.md`** and **`examples/accrue_host/README.md`** (~153–158); **no** portal literals yet.
- **`verify_adoption_proof_matrix.sh`** requires checkout substrings (~41–43); **no** portal row substrings yet.
- **`examples/accrue_host/docs/adoption-proof-matrix.md`** “Blocking” table has **one** billing checkout row (~17); needs a **second row** for portal (CONTEXT **D-03**).
- **`examples/accrue_host/README.md` `## Observability`** has checkout bullet only (~92); needs sibling portal bullet (**D-06**).

## Pitfalls

- **Order of operations:** Add markdown literals **before** extending **`require_fixed`** / **`require_substring`** in bash verifiers, or CI will fail on missing needles.
- **False-green substrings:** Avoid vague “mentions portal”; use exact literals from **INT-13** / **082-CONTEXT.md** (**D-04**, **D-05**).
- **Collapsed bullets:** Merging checkout + portal into one Observability bullet violates **D-06** and breaks grep parity with checkout.

## Validation Architecture

**Dimension 8 (Nyquist) — feedback loops for this phase**

| Dimension | How satisfied |
|-----------|----------------|
| Package + host doc literals | **`bash scripts/ci/verify_package_docs.sh`** from repo root after editing **`first_hour.md`** or **`examples/accrue_host/README.md`** |
| Matrix ORG-09 row | **`bash scripts/ci/verify_adoption_proof_matrix.sh`** after editing **`adoption-proof-matrix.md`** or the script |
| Bounded billing proof | **`cd accrue && mix test test/accrue/billing/billing_portal_session_facade_test.exs`** if any accidental guide/code drift is suspected (optional regression guard) |
| Phase evidence | **`082-VERIFICATION.md`** records command transcripts / SHA per **D-08** |

**Wave 0:** Not applicable — no new ExUnit modules; reuse existing bash gates + optional facade test.

**Sampling:** After each markdown edit batch, run **`bash scripts/ci/verify_package_docs.sh`** once portal **`require_fixed`** lines exist. After matrix + script edits, run **`bash scripts/ci/verify_adoption_proof_matrix.sh`**.

---

## RESEARCH COMPLETE
