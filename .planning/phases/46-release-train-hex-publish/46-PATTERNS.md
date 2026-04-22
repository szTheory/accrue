# Phase 46 — Pattern Map

Analogs for release-train work (read before editing).

| Planned touch | Closest existing pattern |
|---------------|-------------------------|
| CI bash gate | `scripts/ci/verify_package_docs.sh` — `set -euo pipefail`, `fail()` helper, parses `mix.exs` with `sed` |
| Hex ordering + env | `.github/workflows/release-please.yml` — `needs: [release, publish-accrue]` on admin job |
| Manual merge helper | `scripts/ci/gh_merge_release_pr.sh` — explicit maintainer-driven `gh pr merge` |
| Recovery publish | `.github/workflows/publish-hex.yml` — `workflow_dispatch`, version grep before publish |
| Annotation sweep contract | `.github/workflows/ci.yml` — `annotation_sweep.sh` job list must include all merge-blocking jobs |

**Excerpt — admin publish waits on core (pattern to preserve):**

```yaml
publish-accrue-admin:
  needs: [release, publish-accrue]
  if: ${{ always() && ... && (needs.release.outputs.accrue_release_created != 'true' || needs.publish-accrue.result == 'success') }}
```

*Source:* `.github/workflows/release-please.yml` (publish job block).

---

## PATTERN MAPPING COMPLETE
