#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}

fail() {
  echo "[verify_package_docs] package docs verification failed: $*" >&2
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

require_any_fixed() {
  local file=$1
  shift

  for needle in "$@"; do
    if grep -Fq "$needle" "$file"; then
      return 0
    fi
  done

  fail "$file is missing all of: $*"
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
require_fixed "$ROOT_DIR/accrue/README.md" "examples/accrue_host"
require_fixed "$ROOT_DIR/accrue/README.md" "mix verify"
require_fixed "$ROOT_DIR/accrue/README.md" "mix verify.full"
require_fixed "$ROOT_DIR/accrue/README.md" "bash scripts/ci/accrue_host_uat.sh"
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" 'extras: ["README.md", "guides/admin_ui.md"]'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" 'groups_for_extras: [Guides: ["guides/admin_ui.md"]]'
require_fixed "$ROOT_DIR/README.md" "Canonical local demo: Fake"
require_fixed "$ROOT_DIR/README.md" "Provider parity: Stripe test mode"
require_fixed "$ROOT_DIR/README.md" "Advisory/manual: live Stripe"
require_fixed "$ROOT_DIR/README.md" "## Proof path (VERIFY-01)"
require_fixed "$ROOT_DIR/README.md" "proof-and-verification"
require_fixed "$ROOT_DIR/README.md" "Pull requests are merge-blocked on GitHub Actions job \`host-integration\`"
require_fixed "$ROOT_DIR/accrue/guides/testing.md" "Pull requests are merge-blocked on GitHub Actions job \`host-integration\`"

require_regex "$ROOT_DIR/accrue_admin/README.md" 'https://hexdocs\.pm/accrue_admin(/admin_ui\.html)?'
require_regex "$ROOT_DIR/accrue_admin/README.md" 'https://hexdocs\.pm/accrue(/first_hour\.html)?'

require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "## First run"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "## Seeded history"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "## Proof and verification"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "### Verification modes"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "mix setup"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "mix phx.server"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "/webhooks/stripe"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "/billing"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "mix verify"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "mix verify.full"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "bash scripts/ci/accrue_host_uat.sh"

require_any_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "## 1. First run" "## First run"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "Seeded history"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "mix verify"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "mix verify.full"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "/webhooks/stripe"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "/billing"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "customer.subscription.created"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "upgrade.md#installer-rerun-behavior"
require_fixed "$ROOT_DIR/accrue/guides/troubleshooting.md" "mix accrue.install --check"

require_fixed "$ROOT_DIR/scripts/ci/accrue_host_uat.sh" "mix verify.full"
require_fixed "$ROOT_DIR/scripts/ci/accrue_host_uat.sh" "bash scripts/ci/accrue_host_uat.sh"
require_fixed "$ROOT_DIR/RELEASING.md" "Canonical local demo: Fake"
require_fixed "$ROOT_DIR/RELEASING.md" "Provider parity: Stripe test mode"
require_fixed "$ROOT_DIR/RELEASING.md" "Advisory/manual: live Stripe"
require_fixed "$ROOT_DIR/RELEASING.md" "required deterministic gate"
require_fixed "$ROOT_DIR/RELEASING.md" "security/trust artifact"
require_fixed "$ROOT_DIR/RELEASING.md" "seeded performance smoke"
require_fixed "$ROOT_DIR/RELEASING.md" "compatibility floor/target checks"
require_fixed "$ROOT_DIR/RELEASING.md" "browser accessibility/responsive checks"
require_fixed "$ROOT_DIR/RELEASING.md" "provider-parity checks"
require_fixed "$ROOT_DIR/RELEASING.md" "advisory/manual before shipping your app"
require_fixed "$ROOT_DIR/RELEASING.md" "15-TRUST-REVIEW.md"
require_fixed "$ROOT_DIR/RELEASING.md" "HEX_API_KEY"
require_fixed "$ROOT_DIR/RELEASING.md" "RELEASE_PLEASE_TOKEN"
require_fixed "$ROOT_DIR/RELEASING.md" "release-gate"
require_fixed "$ROOT_DIR/guides/testing-live-stripe.md" "STRIPE_TEST_SECRET_KEY"
require_fixed "$ROOT_DIR/guides/testing-live-stripe.md" "host-integration"
require_fixed "$ROOT_DIR/CONTRIBUTING.md" 'Node.js for browser UAT in `examples/accrue_host`'
require_absent_regex "$ROOT_DIR/RELEASING.md" 'Phase 9 release gate'
require_absent_regex "$ROOT_DIR/guides/testing-live-stripe.md" 'primary `test` job'
require_absent_regex "$ROOT_DIR/CONTRIBUTING.md" 'Node\.js for browser UAT in `accrue_admin`'
require_fixed "$ROOT_DIR/examples/accrue_host/playwright.config.js" 'trace: "retain-on-failure"'
require_fixed "$ROOT_DIR/examples/accrue_host/playwright.config.js" 'screenshot: "only-on-failure"'

for guide in \
  "$ROOT_DIR/accrue/guides/first_hour.md" \
  "$ROOT_DIR/accrue/guides/troubleshooting.md"; do
  require_fixed "$guide" 'config :accrue, :webhook_signing_secrets, %{'
  require_fixed "$guide" 'stripe: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")'
  require_absent_regex "$guide" 'webhook_signing_secret([^s]|$)'
done

echo "package docs verified for accrue $accrue_version and accrue_admin $accrue_admin_version"
echo "fixed invariants checked: README.md, RELEASING.md, CONTRIBUTING.md, 15-TRUST-REVIEW.md, STRIPE_TEST_SECRET_KEY, release-gate, host-integration, retain-on-failure, only-on-failure, First run, Seeded history, mix verify, mix verify.full"
