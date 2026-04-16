#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "package docs verification failed: $*" >&2
  exit 1
}

extract_version() {
  local file=$1
  local version

  version=$(sed -n 's/^  @version "\([^"]*\)"/\1/p' "$file" | head -n 1)
  [[ -n "$version" ]] || fail "could not parse @version from $file"
  printf '%s\n' "$version"
}

require_fixed() {
  local file=$1
  local needle=$2

  grep -Fq "$needle" "$file" || fail "$file is missing: $needle"
}

require_regex() {
  local file=$1
  local pattern=$2

  grep -Eq "$pattern" "$file" || fail "$file does not match: $pattern"
}

require_absent_regex() {
  local file=$1
  local pattern=$2

  if grep -Eq "$pattern" "$file"; then
    fail "$file must not match: $pattern"
  fi
}

accrue_version=$(extract_version "$ROOT_DIR/accrue/mix.exs")
accrue_admin_version=$(extract_version "$ROOT_DIR/accrue_admin/mix.exs")

[[ "$accrue_version" == "$accrue_admin_version" ]] || fail "package versions diverged"

require_fixed "$ROOT_DIR/accrue/mix.exs" 'source_ref: "accrue-v#{@version}"'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" 'source_ref: "accrue_admin-v#{@version}"'

require_fixed "$ROOT_DIR/accrue/README.md" "{:accrue, \"~> $accrue_version\"}"
require_fixed "$ROOT_DIR/accrue_admin/README.md" "{:accrue_admin, \"~> $accrue_admin_version\"}"
require_fixed "$ROOT_DIR/accrue_admin/README.md" "accrue ~> $accrue_version"

require_fixed "$ROOT_DIR/accrue/README.md" '[First Hour](guides/first_hour.md)'
require_fixed "$ROOT_DIR/accrue/README.md" '[Troubleshooting](guides/troubleshooting.md)'
require_fixed "$ROOT_DIR/accrue/README.md" '[Webhooks](guides/webhooks.md)'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" 'extras: ["README.md", "guides/admin_ui.md"]'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" 'groups_for_extras: [Guides: ["guides/admin_ui.md"]]'

require_regex "$ROOT_DIR/accrue_admin/README.md" 'https://hexdocs\.pm/accrue_admin(/admin_ui\.html)?'
require_regex "$ROOT_DIR/accrue_admin/README.md" 'https://hexdocs\.pm/accrue(/first_hour\.html)?'

for guide in \
  "$ROOT_DIR/accrue/guides/first_hour.md" \
  "$ROOT_DIR/accrue/guides/troubleshooting.md"; do
  require_fixed "$guide" 'config :accrue, :webhook_signing_secrets, %{'
  require_fixed "$guide" 'stripe: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")'
  require_absent_regex "$guide" 'webhook_signing_secret([^s]|$)'
done

echo "package docs verified for accrue $accrue_version and accrue_admin $accrue_admin_version"
