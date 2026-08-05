# Alpha/Crosswake readiness boundary

Alpha is the anonymized B2C offline language-learning first adopter being
developed in another repository. This Accrue repository supplies reusable
library and host contract proof; it does not stand in for that application's
mobile runtime or production integration.

## Evidence owners

| Evidence owner | What this repository can establish | Current boundary |
| --- | --- | --- |
| **Accrue contract proof** | Deterministic Stripe/Apple account convergence, offline-policy, diagnostic, repair, and release-contract proof under D-01, D-02, D-04, and D-09 through D-11. | Reusable, merge-blocking contract evidence; it is not mobile-runtime or production-integration authority. |
| **Crosswake runtime proof** | A pinned Crosswake source and documented bridge compiling against authenticated transport and StoreKit, plus dated physical-device evidence. | `feasibility_blocked` under D-03 until the [capability report](../../../examples/crosswake_tracer/capability-report.json) has both bridge-compile and physical-device evidence. |
| **Alpha-owned production integration evidence** | Real application wiring, release configuration, live native/billing behavior, and production-readiness evidence. | **external / not evaluated in this repository**. Alpha owns this evidence in its own repository. |

The in-repo deterministic host/server scenarios and Swift vectors are bounded
conformance evidence. They remain useful for D-01, D-02, and D-04, but do not
acquire runtime or production-integration authority.

## Explicit non-claims

- Accrue fixture, server, host, browser, or Swift-vector evidence does not prove
  Crosswake runtime behavior.
- Crosswake runtime evidence would not by itself prove Alpha integration.
- This repository has not inspected or certified Alpha's repository.
- No App Store, live-provider, or production-readiness claim follows from this
  note.

For exact supported and unsupported cells, use the generated [capability and
limits matrix](../../../examples/accrue_host/docs/capability-limits-matrix.md),
not this hand-authored explanation. The [adoption proof
matrix](../../../examples/accrue_host/docs/adoption-proof-matrix.md), [Crosswake
README](../../../examples/crosswake_tracer/README.md), [release
guide](../../../accrue/guides/multi-rail-offline-release.md), and [operator
runbooks](../../../accrue/guides/operator-runbooks.md#v159-multi-rail-and-offline-runbooks)
retain their respective facts and procedures.

## Cross-repository seam checklist

Each Alpha cell below is intentionally **external / unasserted**: it names an
integration obligation without claiming that it has been reviewed or completed.

### Native seams

| Seam | Accrue reference | Crosswake runtime proof | Alpha-owned production integration evidence |
| --- | --- | --- | --- |
| Pinned Crosswake source and documented bridge | [Capability matrix](../../../examples/accrue_host/docs/capability-limits-matrix.md) | Pinned source and bridge compile/unit evidence in the [report](../../../examples/crosswake_tracer/capability-report.json) | **external / unasserted** — pins and integrates the approved source/bridge. |
| Authenticated transport | [Crosswake README](../../../examples/crosswake_tracer/README.md#evidence-lanes) | Bridge compile/unit plus dated device evidence | **external / unasserted** — wires authenticated app transport. |
| StoreKit `appAccountToken` | [Crosswake README](../../../examples/crosswake_tracer/README.md#evidence-lanes) | Bridge compile/unit evidence | **external / unasserted** — passes the opaque account token through the real purchase flow. |
| Transaction updates, current entitlements, and restore | [Release guide](../../../accrue/guides/multi-rail-offline-release.md#evidence-and-app-review) | Bridge compile/unit evidence | **external / unasserted** — wires the application's update, entitlement, and restore lifecycle. |
| Device-key non-exportability and migration exclusion | [Crosswake README](../../../examples/crosswake_tracer/README.md#evidence-lanes) | Dated physical-device evidence for Secure Enclave and `ThisDeviceOnly` behavior | **external / unasserted** — validates device behavior in the shipped application. |
| Atomic cache replacement and termination recovery | [Capability matrix](../../../examples/accrue_host/docs/capability-limits-matrix.md) | Native compile/unit and dated physical-device evidence | **external / unasserted** — proves application lifecycle recovery around real termination. |
| Reconnect | [Release guide](../../../accrue/guides/multi-rail-offline-release.md#release-checklist) | Bridge compile/unit and dated physical-device evidence | **external / unasserted** — proves authenticated reconnect in the application. |
| Dated, redacted physical-device proof | [Crosswake README](../../../examples/crosswake_tracer/README.md#evidence-lanes) | Required report evidence recorded in `physical-device-evidence.md` | **external / unasserted** — retains its own release evidence without copying it here. |

### Billing/account seams

| Seam | Accrue reference | Crosswake runtime proof | Alpha-owned production integration evidence |
| --- | --- | --- | --- |
| One opaque entitlement account across Stripe and Apple | [Adoption proof matrix](../../../examples/accrue_host/docs/adoption-proof-matrix.md#v159-first-adopter-path) | Runtime proof only verifies client transport; it does not establish account authority | **external / unasserted** — wires the account identity through real application flows. |
| Apple-to-web and Stripe-to-iOS convergence | [Capability matrix](../../../examples/accrue_host/docs/capability-limits-matrix.md#scenario-references) | Runtime proof verifies only the client boundary | **external / unasserted** — validates end-to-end application convergence. |
| Equivalent-purchase preflight | [Release guide](../../../accrue/guides/multi-rail-offline-release.md#start-with-the-reference-host) | Runtime proof verifies only the client boundary | **external / unasserted** — presents and obeys preflight behavior in the application. |
| Provider-honest lifecycle management | [Release guide](../../../accrue/guides/multi-rail-offline-release.md#start-with-the-reference-host) | Runtime proof does not grant provider lifecycle authority | **external / unasserted** — exposes only application-appropriate provider controls. |
| Stale downloaded-study/local-progress continuity with value expansion blocked | [Capability matrix](../../../examples/accrue_host/docs/capability-limits-matrix.md#compatibility-and-limits) | Runtime proof verifies cache/device behavior when evidence exists | **external / unasserted** — enforces the learner-facing stale and expansion boundary. |
| Authenticated account/device reconnect | [Operator runbooks](../../../accrue/guides/operator-runbooks.md#v159-multi-rail-and-offline-runbooks) | Bridge and physical-device reconnect evidence | **external / unasserted** — wires account and device authentication in production. |
| Signed allow-or-deny replacement | [Capability matrix](../../../examples/accrue_host/docs/capability-limits-matrix.md#deterministic-verification) | Native/physical-device replacement evidence | **external / unasserted** — consumes only the verified replacement outcome. |
| Privacy-bounded diagnostics | [Release guide](../../../accrue/guides/multi-rail-offline-release.md#privacy-and-security-limits) | Runtime proof is not diagnostic or support authority | **external / unasserted** — applies its own authorized, privacy-reviewed operational workflow. |
