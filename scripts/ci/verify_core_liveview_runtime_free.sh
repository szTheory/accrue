#!/usr/bin/env bash
# Shift-left merge gate (ENT-07 / D-05): core stays runtime-LiveView-free.
#
# Fails the build if any ALWAYS-COMPILED core module references the LiveView
# socket runtime. This makes "core stays runtime-LiveView-free" a verifiable,
# non-regressing invariant: an accidental socket-runtime coupling in core is
# blocked at merge, not caught post-merge.
#
# What it matches (REAL refs only, never doc comments or strings):
#   - `import` / `alias` Phoenix.LiveView
#   - Phoenix.LiveView.Socket
#   - Phoenix.Socket
#   - `def on_mount`
#
# Allowlists (by construction):
#   - Doc comments / comment lines — the `^[^#]*` anchor means the matched
#     alternatives must appear BEFORE any `#` on the line, so a leading-`#`
#     comment line (e.g. the LiveView mention in oban/middleware.ex) never
#     trips the gate, and a same-line trailing comment is ignored.
#   - `lib/accrue/live/` — the legitimately cond-compiled `Accrue.Live.Entitlements`
#     on_mount guard (D-03/D-04). It is the ONLY always-shipped core file
#     permitted LiveView refs, all confined inside its
#     `Code.ensure_loaded?(Phoenix.LiveView)` block.
set -euo pipefail

repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
lib="${repo_root}/accrue/lib"

if [[ ! -d "${lib}" ]]; then
  echo "verify_core_liveview_runtime_free: missing ${lib}" >&2
  exit 1
fi

hits=$(grep -rnE \
  '^[^#]*((import|alias)[[:space:]]+Phoenix\.LiveView|Phoenix\.LiveView\.Socket|Phoenix\.Socket|def[[:space:]]+on_mount)' \
  "${lib}" \
  --include='*.ex' \
  | grep -v '/accrue/live/' \
  || true)

if [[ -n "${hits}" ]]; then
  echo "verify_core_liveview_runtime_free: FAIL — LiveView socket-runtime ref in always-compiled core:" >&2
  echo "${hits}" >&2
  exit 1
fi

echo "verify_core_liveview_runtime_free: OK"
