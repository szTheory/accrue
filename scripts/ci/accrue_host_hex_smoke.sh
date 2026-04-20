#!/usr/bin/env bash
#
# Resolves accrue + accrue_admin from Hex (see examples/accrue_host ACCRUE_HOST_HEX_RELEASE).
#
# On GitHub Actions, after a release merge, this job can start before Hex publish finishes.
# We poll hex.pm until both sibling @version releases exist (or timeout), so CI does not
# need a manual re-run. Opt out: ACCRUE_HOST_HEX_SMOKE_WAIT_HEX=0
#
# Release Please PRs still skip this script in ci.yml: the version is not published until
# after merge.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$repo_root/examples/accrue_host"

export ACCRUE_HOST_HEX_RELEASE=1

parse_mix_version() {
  sed -n 's/^[[:space:]]*@version "\([^"]*\)".*/\1/p' "$1" | head -1
}

hex_release_exists() {
  local pkg="$1"
  local ver="$2"
  curl -fsS -o /dev/null --max-time 30 "https://hex.pm/api/packages/${pkg}/releases/${ver}"
}

maybe_wait_for_sibling_releases_on_hex() {
  if [[ "${ACCRUE_HOST_HEX_SMOKE_WAIT_HEX:-}" == "0" ]]; then
    return 0
  fi
  if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
    return 0
  fi

  local accrue_ver accrue_admin_ver
  accrue_ver="$(parse_mix_version "$repo_root/accrue/mix.exs")"
  accrue_admin_ver="$(parse_mix_version "$repo_root/accrue_admin/mix.exs")"

  if [[ -z "$accrue_ver" || -z "$accrue_admin_ver" ]]; then
    echo "accrue_host_hex_smoke: could not parse @version from sibling mix.exs" >&2
    exit 1
  fi

  local max_s="${ACCRUE_HOST_HEX_SMOKE_WAIT_SECONDS:-600}"
  local poll_s="${ACCRUE_HOST_HEX_SMOKE_POLL_SECONDS:-15}"
  local deadline=$(( $(date +%s) + max_s ))

  while true; do
    local accrue_ok=0 admin_ok=0
    if hex_release_exists accrue "$accrue_ver"; then accrue_ok=1; fi
    if hex_release_exists accrue_admin "$accrue_admin_ver"; then admin_ok=1; fi
    if [[ "$accrue_ok" == 1 && "$admin_ok" == 1 ]]; then
      echo "accrue_host_hex_smoke: Hex has accrue ${accrue_ver} and accrue_admin ${accrue_admin_ver}."
      return 0
    fi
    if [[ $(date +%s) -ge $deadline ]]; then
      echo "accrue_host_hex_smoke: timed out after ${max_s}s waiting for Hex (accrue ok=${accrue_ok}, accrue_admin ok=${admin_ok})." >&2
      exit 1
    fi
    echo "accrue_host_hex_smoke: waiting for Hex releases (accrue ${accrue_ver} ok=${accrue_ok}, accrue_admin ${accrue_admin_ver} ok=${admin_ok}); sleeping ${poll_s}s…" >&2
    sleep "$poll_s"
  done
}

maybe_wait_for_sibling_releases_on_hex

mix deps.get
mix accrue.install --yes \
  --billable AccrueHost.Accounts.User \
  --billing-context AccrueHost.Billing \
  --admin-mount /billing \
  --webhook-path /webhooks/stripe
mix compile --warnings-as-errors
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
MIX_ENV=test mix test --warnings-as-errors \
  test/install_boundary_test.exs \
  test/accrue_host/billing_facade_test.exs
