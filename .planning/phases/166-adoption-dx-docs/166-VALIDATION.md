---
phase: 166
slug: adoption-dx-docs
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-02
---

# Phase 166 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash doc verifiers, Docker Compose smoke, Elixir/Phoenix app commands |
| **Config file** | `.github/workflows/ci.yml`, `examples/accrue_host/docker-compose.yml`, `examples/accrue_host/config/dev.exs` |
| **Quick run command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh` |
| **Full suite command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && cd examples/accrue_host && docker compose config` |
| **Estimated runtime** | ~30-90 seconds without Docker build; Docker boot smoke depends on local image/cache state |

---

## Sampling Rate

- **After every task commit:** Run the quick doc verifier command for touched docs.
- **After every plan wave:** Run the full suite command above.
- **Before `$gsd-verify-work`:** Full suite must be green, and Docker boot smoke should be attempted when local Docker is available.
- **Max feedback latency:** 90 seconds for doc/script checks; Docker boot smoke may exceed this and should be recorded separately.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 166-01-01 | 01 | 1 | DOC-02 | T-166-01 | Do not publish a false Docker browser-access claim | source + compose | `cd examples/accrue_host && docker compose config` | yes | pending |
| 166-01-02 | 01 | 1 | DOC-02 | T-166-01 | Docker Start Here command remains reachable at published localhost port | smoke | `cd examples/accrue_host && docker compose up --build -d && for i in $(seq 1 30); do curl -fsS http://localhost:4000/ && break; sleep 1; done; docker compose down --volumes --remove-orphans` | yes | pending |
| 166-02-01 | 02 | 2 | DOC-01,DOC-02,DOC-03 | T-166-02 | Start Here copy stays honest about Fake/local proof and no live keys | doc contract | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh` | yes | pending |
| 166-03-01 | 03 | 3 | DOC-01,DOC-03 | T-166-02 | Proof ladder preserves maintainer/support contract guardrails | doc contract | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` | yes | pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- `scripts/ci/verify_package_docs.sh`
- `scripts/ci/verify_verify01_readme_contract.sh`
- `scripts/ci/verify_adoption_proof_matrix.sh`
- `examples/accrue_host/docker-compose.yml`
- `.github/workflows/ci.yml` host Docker smoke

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Docker boot smoke if local Docker is unavailable or port 5432 is already occupied | DOC-02 | Local Docker availability and host Postgres port collisions are environment-dependent | Record the failure mode, verify `docker compose config`, and leave the actual boot smoke for CI or a clean local Docker environment. |
| Editorial readability of persona-framed Start Here copy | DOC-01,DOC-03 | Bash needles cannot judge whether the top section is clear for a Phoenix SaaS adopter | Read the first screen of `examples/accrue_host/README.md` and confirm it answers whether an adopter can boot and inspect the realistic billing loop. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency target documented
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
