#!/usr/bin/env bash
# Shift-left merge gate (DUN-03 D-04): always-on dunning path stays Chimeway-free.
#
# Fails the build if any ALWAYS-ON dunning file references Chimeway symbols.
# This makes "core dunning stays Chimeway-free" a verifiable, non-regressing
# invariant: a future refactor that accidentally couples the always-on default
# recovery path to the optional Chimeway engine adapter is blocked at merge,
# not caught post-merge.
#
# Always-on dunning files scanned (the default recovery engine path):
#   - accrue/lib/accrue/billing/dunning.ex     (public dunning context API)
#   - accrue/lib/accrue/workers/dunning_step.ex (campaign step Oban worker)
#   - accrue/lib/accrue/dunning/campaign.ex    (pure campaign step resolver)
#
# What it matches (REAL refs only, never doc comments):
#   - `Accrue.Integrations.Chimeway`  (the optional adapter module namespace)
#   - `Chimeway.`                     (any Chimeway struct/function call)
#
# Allowlist (by construction):
#   - Comment lines — the `^[^#]*` anchor in the grep pattern means the matched
#     symbol must appear BEFORE any `#` on the line, so a leading-`#` comment
#     line (e.g. a moduledoc that names Chimeway to explain the isolation
#     boundary) never trips the gate, and a same-line trailing comment is
#     ignored. Only real code references fail the build.
#   - `lib/accrue/integrations/chimeway.ex` — the legitimately
#     cond-compiled off-by-default adapter. It lives OUTSIDE the three
#     always-on files scanned here and is never included in the grep targets,
#     so it is structurally excluded, not grepped-and-filtered.
set -euo pipefail

repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
lib="${repo_root}/accrue/lib"

if [[ ! -d "${lib}" ]]; then
  echo "verify_dunning_chimeway_isolation: missing ${lib}" >&2
  exit 1
fi

always_on_files=(
  "${lib}/accrue/billing/dunning.ex"
  "${lib}/accrue/workers/dunning_step.ex"
  "${lib}/accrue/dunning/campaign.ex"
)

for f in "${always_on_files[@]}"; do
  if [[ ! -f "${f}" ]]; then
    echo "verify_dunning_chimeway_isolation: missing always-on file ${f}" >&2
    exit 1
  fi
done

hits=$(grep -rnE \
  '^[^#]*(Accrue\.Integrations\.Chimeway|Chimeway\.)' \
  "${always_on_files[@]}" \
  --include='*.ex' \
  || true)

if [[ -n "${hits}" ]]; then
  echo "verify_dunning_chimeway_isolation: FAIL — Chimeway ref in always-on dunning path:" >&2
  echo "${hits}" >&2
  echo "The Chimeway engine adapter is off-by-default and conditionally compiled (DUN-03);" >&2
  echo "the always-on default recovery path must never reference it directly." >&2
  exit 1
fi

echo "verify_dunning_chimeway_isolation: OK"
