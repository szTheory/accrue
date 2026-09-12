#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: $0 --commit <40-hex-sha> --expected-state <candidate|inverse_rollback> --evidence-out <path>" >&2; exit 64; }
commit="" expected_state="" evidence_out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit) commit="${2:-}"; shift 2 ;;
    --expected-state) expected_state="${2:-}"; shift 2 ;;
    --evidence-out) evidence_out="${2:-}"; shift 2 ;;
    *) usage ;;
  esac
done
[[ "$commit" =~ ^[0-9a-f]{40}$ ]] || { echo "commit must be a full lowercase 40-hex SHA" >&2; exit 64; }
[[ "$expected_state" == candidate || "$expected_state" == inverse_rollback ]] || usage
[[ -n "$evidence_out" ]] || usage

root="$(git rev-parse --show-toplevel)"
resolved="$(git -C "$root" rev-parse "${commit}^{commit}")"
[[ "$resolved" == "$commit" ]] || { echo "commit does not resolve exactly" >&2; exit 65; }
scratch="$(mktemp -d "${TMPDIR:-/tmp}/phase227-preflight.XXXXXX")"
worktree="$scratch/tree"
cleanup() { git -C "$root" worktree remove --force "$worktree" >/dev/null 2>&1 || true; rmdir "$scratch" 2>/dev/null || true; }
trap cleanup EXIT
git -C "$root" worktree add --detach "$worktree" "$commit" >/dev/null
[[ "$(git -C "$worktree" rev-parse HEAD)" == "$commit" ]] || { echo "detached worktree revision differs" >&2; exit 65; }
[[ -z "$(git -C "$worktree" status --porcelain)" ]] || { echo "detached worktree is dirty" >&2; exit 65; }
tree="$(git -C "$worktree" rev-parse HEAD^{tree})"
wrapper_digest="sha256:$(shasum -a 256 "$root/scripts/ci/preflight_phase227_candidate.sh" | awk '{print $1}')"
phase=".planning/phases/227-measured-critical-path-improvement"
(
  cd "$worktree"
  node --check scripts/ci/verify_ci_critical_path.mjs
  node --test scripts/ci/verify_ci_critical_path.test.mjs
  node scripts/ci/verify_ci_critical_path.mjs --fixtures --workflow-fixture "$phase/fixtures/ci-workflow-restored-v2.yml" --contract "$phase/227-ci-contract.json"
  node scripts/ci/verify_ci_critical_path.mjs --verify-workflow --workflow .github/workflows/ci.yml --contract "$phase/227-ci-contract.json" --expected-state "$expected_state"
  ASDF_ERLANG_VERSION=28.4.1 ASDF_ELIXIR_VERSION=1.19.5-otp-28 bash -c 'cd accrue && mix format --check-formatted'
  ASDF_ERLANG_VERSION=28.4.1 ASDF_ELIXIR_VERSION=1.19.5-otp-28 bash -c 'cd accrue && mix test test/accrue/backend_automation_contract_test.exs --warnings-as-errors'
)
mkdir -p "$(dirname "$evidence_out")"
node - "$evidence_out" "$commit" "$tree" "$expected_state" "$wrapper_digest" <<'NODE'
const fs = require("node:fs");
const [out, candidate_sha, candidate_tree, expected_state, wrapper_sha256] = process.argv.slice(2);
fs.writeFileSync(out, `${JSON.stringify({kind:"phase227_preflight", status:"passed", candidate_sha, candidate_tree, expected_state, wrapper_sha256, remote_effects:"none", check_results:{node_syntax:"passed",node_tests:"passed",fixtures:"passed",workflow:"passed",accrue_format:"passed",accrue_test:"passed",prohibited_invocations:0}}, null, 2)}\n`);
NODE
