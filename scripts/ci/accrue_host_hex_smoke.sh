#!/usr/bin/env bash
#
# Resolves accrue + accrue_admin + accrue_portal from Hex (see examples/accrue_host ACCRUE_HOST_HEX_RELEASE).
#
# On GitHub Actions, after a release merge, this job can start before Hex publish finishes.
# We poll hex.pm until all linked @version releases exist (or timeout), so CI does not
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

current_head_sha() {
  git -C "$repo_root" rev-parse HEAD
}

current_head_subject() {
  git -C "$repo_root" log -1 --format=%s
}

remote_tag_sha() {
  local tag="$1"
  git -C "$repo_root" ls-remote --tags origin "refs/tags/${tag}" 2>/dev/null | awk 'NR == 1 { print $1 }' || true
}

hex_release_exists() {
  local pkg="$1"
  local ver="$2"
  curl -fsS -o /dev/null --max-time 30 "https://hex.pm/api/packages/${pkg}/releases/${ver}"
}

maybe_skip_unreleased_checkout() {
  if [[ "${ACCRUE_HOST_HEX_SMOKE_FORCE:-}" == "1" ]]; then
    return 0
  fi

  local accrue_ver accrue_admin_ver accrue_portal_ver
  accrue_ver="$(parse_mix_version "$repo_root/accrue/mix.exs")"
  accrue_admin_ver="$(parse_mix_version "$repo_root/accrue_admin/mix.exs")"
  accrue_portal_ver="$(parse_mix_version "$repo_root/accrue_portal/mix.exs")"

  if [[ -z "$accrue_ver" || -z "$accrue_admin_ver" || -z "$accrue_portal_ver" ]]; then
    echo "accrue_host_hex_smoke: could not parse @version from sibling mix.exs" >&2
    exit 1
  fi

  local head_sha
  head_sha="$(current_head_sha)"

  local missing_tags=()
  local mismatched_tags=()
  local tag tag_sha

  for package_version in \
    "accrue:${accrue_ver}" \
    "accrue_admin:${accrue_admin_ver}" \
    "accrue_portal:${accrue_portal_ver}"
  do
    tag="${package_version/:/-v}"
    tag_sha="$(remote_tag_sha "$tag")"

    if [[ -z "$tag_sha" ]]; then
      missing_tags+=("$tag")
    elif [[ "$tag_sha" != "$head_sha" ]]; then
      mismatched_tags+=("${tag}@${tag_sha}")
    fi
  done

  if ((${#mismatched_tags[@]} > 0)); then
    echo "accrue_host_hex_smoke: skipping; published release tag(s) do not point at this checkout (${head_sha}): ${mismatched_tags[*]}."
    echo "accrue_host_hex_smoke: path-based host integration already validated this unreleased branch; set ACCRUE_HOST_HEX_SMOKE_FORCE=1 to force."
    exit 0
  fi

  if ((${#missing_tags[@]} > 0)); then
    if [[ "$(current_head_subject)" == chore:\ release* ]]; then
      echo "accrue_host_hex_smoke: release commit tags are not visible yet (${missing_tags[*]}); continuing and waiting for Hex."
      return 0
    fi

    echo "accrue_host_hex_smoke: skipping; release tag(s) are not published for this checkout: ${missing_tags[*]}."
    echo "accrue_host_hex_smoke: path-based host integration already validated this unreleased branch; set ACCRUE_HOST_HEX_SMOKE_FORCE=1 to force."
    exit 0
  fi
}

maybe_wait_for_sibling_releases_on_hex() {
  if [[ "${ACCRUE_HOST_HEX_SMOKE_WAIT_HEX:-}" == "0" ]]; then
    return 0
  fi
  if [[ "${GITHUB_ACTIONS:-}" != "true" ]]; then
    return 0
  fi

  local accrue_ver accrue_admin_ver accrue_portal_ver
  accrue_ver="$(parse_mix_version "$repo_root/accrue/mix.exs")"
  accrue_admin_ver="$(parse_mix_version "$repo_root/accrue_admin/mix.exs")"
  accrue_portal_ver="$(parse_mix_version "$repo_root/accrue_portal/mix.exs")"

  if [[ -z "$accrue_ver" || -z "$accrue_admin_ver" || -z "$accrue_portal_ver" ]]; then
    echo "accrue_host_hex_smoke: could not parse @version from sibling mix.exs" >&2
    exit 1
  fi

  local max_s="${ACCRUE_HOST_HEX_SMOKE_WAIT_SECONDS:-600}"
  local poll_s="${ACCRUE_HOST_HEX_SMOKE_POLL_SECONDS:-15}"
  local deadline=$(( $(date +%s) + max_s ))

  while true; do
    local accrue_ok=0 admin_ok=0 portal_ok=0
    if hex_release_exists accrue "$accrue_ver"; then accrue_ok=1; fi
    if hex_release_exists accrue_admin "$accrue_admin_ver"; then admin_ok=1; fi
    if hex_release_exists accrue_portal "$accrue_portal_ver"; then portal_ok=1; fi
    if [[ "$accrue_ok" == 1 && "$admin_ok" == 1 && "$portal_ok" == 1 ]]; then
      echo "accrue_host_hex_smoke: Hex has accrue ${accrue_ver}, accrue_admin ${accrue_admin_ver}, and accrue_portal ${accrue_portal_ver}."
      return 0
    fi
    if [[ $(date +%s) -ge $deadline ]]; then
      echo "accrue_host_hex_smoke: timed out after ${max_s}s waiting for Hex (accrue ok=${accrue_ok}, accrue_admin ok=${admin_ok}, accrue_portal ok=${portal_ok})." >&2
      exit 1
    fi
    echo "accrue_host_hex_smoke: waiting for Hex releases (accrue ${accrue_ver} ok=${accrue_ok}, accrue_admin ${accrue_admin_ver} ok=${admin_ok}, accrue_portal ${accrue_portal_ver} ok=${portal_ok}); sleeping ${poll_s}s..." >&2
    sleep "$poll_s"
  done
}

restore_mix_lock() {
  cp "$mix_lock_backup" mix.lock
  rm -f "$mix_lock_backup"
}

maybe_skip_unreleased_checkout
maybe_wait_for_sibling_releases_on_hex

mix_lock_backup="$(mktemp)"
cp mix.lock "$mix_lock_backup"
trap restore_mix_lock EXIT

mix deps.unlock accrue accrue_admin accrue_portal rendro
mix deps.get
mix accrue.install --yes \
  --billable AccrueHost.Accounts.User \
  --billing-context AccrueHost.Billing \
  --admin-mount /admin \
  --webhook-path /webhooks/stripe
mix compile --warnings-as-errors
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
MIX_ENV=test mix test --warnings-as-errors \
  test/install_boundary_test.exs \
  test/accrue_host/billing_facade_test.exs
