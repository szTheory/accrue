# Maturity and maintenance

How Accrue thinks about **“done enough”** for the core library and companion admin, and **when new work should start** — without duplicating the deep guides.

## Who this is for

- **Maintainers** triaging issues and doc PRs.
- **Integrators** deciding whether to pin another 1.0.x minor or stay on a known `mix.lock`.

## Operational pair

1. **[Production readiness](production-readiness.md)** — ordered checklist for shipping billing in a real Phoenix app (what to verify, where to read next).
2. **Friction inventory + stop rules (monorepo)** — ranked evidence and diminishing-returns doctrine live at **`.planning/research/v1.17-north-star.md`** (stop rules) and **`.planning/research/v1.17-FRICTION-INVENTORY.md`** (intake table) **relative to the git repository root** (not shipped inside the Hex package tarball). Use a full monorepo checkout or GitHub browse to read them.

New **P0 / P1** friction rows belong in that inventory only when they meet the **priority bar** in the inventory preamble (sources, integrator impact, CI contract). **Broad doc sweeps without a row** are out of policy — see north star **S1** / **S5**.

## Supported integration surface

The `1.0.x` stability contract applies to the documented facade:

- generated `MyApp.Billing`
- `use Accrue.Webhook.Handler`
- `use Accrue.Test`
- `Accrue.Billing`
- `Accrue.Auth`
- `Accrue.ConfigError`
- `AccrueAdmin.Router`
- documented Telemetry event names and metadata contracts in the public guides

The SemVer boundary does not include internal schemas, workers, generated migration history, demo helpers, or Fake-processor internals. Those may change when correctness, docs, or proof quality require it, as long as the documented facade stays stable.

## When Accrue is in “maintenance posture”

Roughly: **merge-blocking proof and package-doc contracts stay green**, the **post-1.0** friction table has **no open P0/P1** rows, and further changes should be **intake-gated** (new evidence, publish event, or security/correctness) rather than speculative polish.

**Revisit triggers** (examples — see inventory maintainer notes for the live list):

- Next **linked Hex publish** for **`accrue` / `accrue_admin`**.
- Intentional **adoption proof matrix** / **`verify_adoption_proof_matrix.sh`** taxonomy edits.

## Related

- [First Hour — How to enter](first_hour.md#how-to-enter-this-guide) (H/M/R capsules ↔ host README spine).
- [Contributing](https://github.com/szTheory/accrue/blob/main/CONTRIBUTING.md) — release gate and doc-contract expectations (monorepo root; not bundled in the Hex tarball).
