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

  grep -Fq -- "$needle" "$file" || fail "$file is missing: $needle"
}

require_regex() {
  local file=$1
  local pattern=$2

  grep -Eq -- "$pattern" "$file" || fail "$file does not match: $pattern"
}

require_absent_regex() {
  local file=$1
  local pattern=$2

  if grep -Eq -- "$pattern" "$file"; then
    fail "$file must not match: $pattern"
  fi
}

require_any_fixed() {
  local file=$1
  shift

  for needle in "$@"; do
    if grep -Fq -- "$needle" "$file"; then
      return 0
    fi
  done

  fail "$file is missing all of: $*"
}

is_release_please_pr() {
  [[ -n "${RELEASE_PLEASE_PR:-}" ]]
}

accrue_version=$(extract_version "$ROOT_DIR/accrue/mix.exs")
accrue_admin_version=$(extract_version "$ROOT_DIR/accrue_admin/mix.exs")
accrue_portal_version=$(extract_version "$ROOT_DIR/accrue_portal/mix.exs")

[[ "$accrue_version" == "$accrue_admin_version" ]] || fail "package versions diverged"
[[ "$accrue_version" == "$accrue_portal_version" ]] || fail "package versions diverged"

first_hour_md="$ROOT_DIR/accrue/guides/first_hour.md"
host_readme_md="$ROOT_DIR/examples/accrue_host/README.md"

require_fixed "$ROOT_DIR/accrue/guides/quickstart.md" '[First Hour](first_hour.md)'
require_fixed "$ROOT_DIR/accrue/guides/quickstart.md" 'capsule'
require_fixed "$ROOT_DIR/accrue/guides/quickstart.md" 'auth_adapters.md'
require_absent_regex "$ROOT_DIR/accrue/guides/quickstart.md" 'defp deps'

require_fixed "$first_hour_md" '### Capsule H'
require_fixed "$first_hour_md" '### Capsule M'
require_fixed "$first_hour_md" '### Capsule R'

require_fixed "$host_readme_md" '### Capsule H'
require_fixed "$host_readme_md" '### Capsule M'
require_fixed "$host_readme_md" '### Capsule R'

require_fixed "$ROOT_DIR/accrue/mix.exs" 'source_ref: "accrue-v#{@version}"'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" 'source_ref: "accrue_admin-v#{@version}"'

require_fixed "$ROOT_DIR/accrue/README.md" '> **Hex vs `main`:**'
require_fixed "$ROOT_DIR/accrue/README.md" 'https://hex.pm/packages/accrue'
require_fixed "$ROOT_DIR/accrue_admin/README.md" '> **Hex vs `main`:**'
require_fixed "$ROOT_DIR/accrue_admin/README.md" 'https://hex.pm/packages/accrue_admin'
require_fixed "$ROOT_DIR/accrue_portal/README.md" '> **Hex vs `main`:**'
require_fixed "$ROOT_DIR/accrue_portal/README.md" 'https://hex.pm/packages/accrue_portal'
require_fixed "$ROOT_DIR/accrue_portal/mix.exs" 'source_ref: "accrue_portal-v#{@version}"'

require_fixed "$ROOT_DIR/accrue/README.md" '[First Hour](guides/first_hour.md)'
require_fixed "$ROOT_DIR/accrue/README.md" '[Troubleshooting](guides/troubleshooting.md)'
require_fixed "$ROOT_DIR/accrue/README.md" '[Webhooks](guides/webhooks.md)'
require_fixed "$ROOT_DIR/accrue/README.md" "examples/accrue_host"
require_fixed "$ROOT_DIR/accrue/README.md" "mix verify"
require_fixed "$ROOT_DIR/accrue/README.md" "mix verify.full"
require_fixed "$ROOT_DIR/accrue/README.md" "bash scripts/ci/accrue_host_uat.sh"
require_fixed "$ROOT_DIR/accrue/README.md" "processor support matrix"
require_fixed "$ROOT_DIR/accrue/README.md" "gateway subscription core"
require_fixed "$ROOT_DIR/accrue/README.md" "mounted first-party local checkout and portal URLs"
require_fixed "$ROOT_DIR/accrue/README.md" "swap_plan/3"
require_fixed "$ROOT_DIR/accrue/README.md" "preview_upcoming_invoice/2"
require_fixed "$ROOT_DIR/accrue/README.md" "canonical path where supported"

# Entitlements spine (Phase 126, ENT-12)
# Pins the doc strings Plan 03 authored (D-14). grep -F is literal:
# brackets/parens/the ✅ glyph are matched byte-for-byte. The flip-guard is
# scoped to the unique scope-prose phrase Plan 03 removed (Pitfall 4) — it does
# NOT collide with the historical Update log. Excluded by design (D-14): the
# deny-redirect prose, quota numbers, the per-provider matrix wording, and the
# gate-fn names replicated across README/first_hour/host.
require_fixed "$ROOT_DIR/accrue/README.md" '[Entitlements](guides/entitlements.md)'
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'entitled?'
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'Accrue.Plug.RequireEntitlement'
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" '[:accrue, :entitlements, :check]'
require_fixed "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" 'entitlements ✅ shipped'
require_absent_regex "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" 'on the table\*\* is \*\*entitlements'
require_fixed "$ROOT_DIR/accrue/guides/quickstart.md" '[Entitlements](entitlements.md)'

# Analytics Guide (Phase 148, DAN-15)
require_fixed "$ROOT_DIR/accrue/guides/analytics.md" '100k events'
require_fixed "$ROOT_DIR/accrue/guides/analytics.md" 'Cutoff-Date Semantics'

# Optional Stripe-native advisory sync (Phase 127, ENT-10 / D-12)
# Pins the entitlements.md Stripe-native section + the telemetry.md sync catalog
# so the observational-disclaimer, enable steps, 10-cap, deferred 1.2 read, and
# the new telemetry events cannot silently regress. grep -F is literal: the
# brackets/backticks/event name are matched byte-for-byte. The disclaimer needle
# is the single-line slice of the blockquote (the line wraps after the "/").
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'stripe_native_sync'
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'entitlements.active_entitlement_summary.updated'
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'does NOT change `entitled?` /'
require_fixed "$ROOT_DIR/accrue/guides/telemetry.md" '[:accrue, :entitlements, :sync]'

# Optional Chimeway dunning engine adapter (Phase 131, DUN-03)
require_fixed "$ROOT_DIR/accrue/guides/dunning.md" 'Accrue.Dunning.Engine'
require_fixed "$ROOT_DIR/accrue/guides/dunning.md" 'Accrue.Integrations.Chimeway'
require_fixed "$ROOT_DIR/accrue/guides/dunning.md" 'dunning: [engine:'

require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"README.md"'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/admin_ui.md"'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/core-admin-parity.md"'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/theme-exceptions.md"'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" 'groups_for_extras:'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" 'Guides:'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" 'skip_code_autolink_to:'
require_fixed "$ROOT_DIR/README.md" "Canonical local demo: Fake"
require_fixed "$ROOT_DIR/README.md" "Provider parity: Stripe test mode"
require_fixed "$ROOT_DIR/README.md" "Advisory/manual: live Stripe"
require_fixed "$ROOT_DIR/README.md" "## Proof path (VERIFY-01)"
require_fixed "$ROOT_DIR/README.md" "proof-and-verification"
require_fixed "$ROOT_DIR/README.md" "[Merge-blocking proof, VERIFY-01 commands, and Playwright entry points](examples/accrue_host/README.md#proof-and-verification)."
require_fixed "$ROOT_DIR/README.md" "Pull requests are merge-blocked on GitHub Actions job \`host-integration\`"
require_fixed "$ROOT_DIR/README.md" 'bash scripts/ci/verify_adoption_proof_matrix.sh'
require_fixed "$ROOT_DIR/README.md" 'bash scripts/ci/accrue_host_uat.sh'
require_fixed "$ROOT_DIR/README.md" '> **Hex vs `main`:**'
require_fixed "$ROOT_DIR/README.md" 'https://hex.pm/packages/accrue'
require_fixed "$ROOT_DIR/accrue/guides/testing.md" "browser and integration path"
require_fixed "$ROOT_DIR/accrue/guides/testing.md" "gateway subscription core"
require_fixed "$ROOT_DIR/accrue/guides/testing.md" "Checkout and billing portal use the same shared facade across both providers"
require_fixed "$ROOT_DIR/accrue/guides/testing.md" "processor-support-matrix.md"
require_fixed "$ROOT_DIR/accrue/guides/testing.md" "Host browser proof vs provider parity"
require_absent_regex "$ROOT_DIR/accrue/guides/testing.md" '(/gsd-|gsd-)'
require_absent_regex "$ROOT_DIR/accrue/guides/testing.md" 'VERIFY-01'

require_regex "$ROOT_DIR/accrue_admin/README.md" 'https://hexdocs\.pm/accrue_admin(/admin_ui\.html)?'
require_regex "$ROOT_DIR/accrue_admin/README.md" 'https://hexdocs\.pm/accrue(/first_hour\.html)?'

# INT-08: release-gate vs host-integration (61-CONTEXT D-04 / D-05 / D-07):
# Structural pins on examples/accrue_host/README.md below back release-gate via
# package_docs_verifier_test.exs (see verify_package_docs / verify_verify01_readme_contract.sh).
# VERIFY-01 prose, Playwright inventory, and sk_live negation stay in
# verify_verify01_readme_contract.sh (host-integration README contract).
# Intentional overlap (e.g. mix verify.full) remains so release-gate does not depend on
# host-integration alone.
# D-07 audit: no removals; release-gate retains full host structural pins

require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "## First run"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "## Start Here"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "make build"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "make up"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "http://accrue.localhost/admin"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "Accrue.Processor.Fake"
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
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" '> **Hex vs `main`:**'
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "Seeded history"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "mix verify"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "mix verify.full"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "/webhooks/stripe"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "/billing"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "customer.subscription.created"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "upgrade.md#installer-rerun-behavior"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "Accrue.Billing.create_checkout_session/2"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "[:accrue, :billing, :checkout_session, :create]"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "billing-checkout-session-create"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "Accrue.Billing.create_billing_portal_session/2"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "[:accrue, :billing, :billing_portal, :create]"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "billing-billing-portal-create"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "processor support matrix"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "update_customer/2"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "cancel/2"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "cancel_at_period_end/2"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "swap_plan/3"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "preview_upcoming_invoice/2"
require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "canonical path where supported"
require_absent_regex "$ROOT_DIR/accrue/guides/first_hour.md" 'VERIFY-01'
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "Accrue.Billing.create_checkout_session/2"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "[:accrue, :billing, :checkout_session, :create]"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "checkout_session_facade_test.exs"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "Accrue.Billing.create_billing_portal_session/2"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "[:accrue, :billing, :billing_portal, :create]"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "billing_portal_session_facade_test.exs"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "gateway subscription core"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "Stripe returns upstream hosted checkout and"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "Braintree returns mounted local checkout and portal"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "update_customer/2"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "cancel/2"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "cancel_at_period_end/2"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "swap_plan/3"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "preview_upcoming_invoice/2"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "canonical path where supported"
require_fixed "$ROOT_DIR/examples/accrue_host/README.md" "scripts/ci/README.md"
require_absent_regex "$ROOT_DIR/accrue/README.md" 'all first-party.*(swap_plan/3|preview_upcoming_invoice/2)'
require_absent_regex "$ROOT_DIR/accrue/guides/first_hour.md" 'all first-party.*(swap_plan/3|preview_upcoming_invoice/2)'
require_absent_regex "$ROOT_DIR/examples/accrue_host/README.md" 'all first-party.*(swap_plan/3|preview_upcoming_invoice/2)'
require_absent_regex "$ROOT_DIR/examples/accrue_host/README.md" 'preview parity|pseudo-preview'
require_fixed "$ROOT_DIR/accrue/guides/troubleshooting.md" "mix accrue.install --check"
require_absent_regex "$ROOT_DIR/accrue/guides/production-readiness.md" 'VERIFY-01'
require_absent_regex "$ROOT_DIR/accrue_admin/README.md" 'VERIFY-01'
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "Braintree"
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "gateway subscription core"
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "Fake"
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "Stripe-first"
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "merchant-of-record"
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "Adyen"
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "PayPal direct subscriptions"
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "GoCardless"
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "fail clearly and early"
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "Laravel Cashier"
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "Pay (Rails)"
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "ActiveMerchant"
require_fixed "$ROOT_DIR/.planning/STRATEGY.md" "reopened only for high-impact changes"
require_fixed "$ROOT_DIR/.planning/PROJECT.md" "Braintree"
require_fixed "$ROOT_DIR/.planning/PROJECT.md" "gateway subscription core"
require_fixed "$ROOT_DIR/.planning/PROJECT.md" "Accrue.Billing.subscribe/3"
require_fixed "$ROOT_DIR/.planning/PROJECT.md" "Fake"
require_fixed "$ROOT_DIR/.planning/PROJECT.md" "Stripe-first"
require_fixed "$ROOT_DIR/accrue/guides/custom_processors.md" "outside first-party support"
require_fixed "$ROOT_DIR/accrue/guides/custom_processors.md" "official processor-support matrix"

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
require_fixed "$ROOT_DIR/RELEASING.md" 'linked `accrue` +'
require_fixed "$ROOT_DIR/RELEASING.md" '`accrue_admin` + `accrue_portal`'
require_fixed "$ROOT_DIR/RELEASING.md" "publish-accrue-portal"
require_fixed "$ROOT_DIR/RELEASING.md" "ACCRUE_PORTAL_HEX_RELEASE=1"
require_fixed "$ROOT_DIR/RELEASING.md" 'choose `accrue`, `accrue_admin`, or `accrue_portal`'
require_fixed "$ROOT_DIR/guides/testing-live-stripe.md" "STRIPE_TEST_SECRET_KEY"
require_fixed "$ROOT_DIR/guides/testing-live-stripe.md" "host-integration"
require_fixed "$ROOT_DIR/guides/testing-live-stripe.md" "first-party shared-facade surfaces"
require_fixed "$ROOT_DIR/guides/testing-live-stripe.md" "mounted-local Braintree side"
require_fixed "$ROOT_DIR/CONTRIBUTING.md" 'Node.js for browser UAT in `examples/accrue_host`'
require_fixed "$ROOT_DIR/CONTRIBUTING.md" "three sibling Mix packages"
require_fixed "$ROOT_DIR/CONTRIBUTING.md" '`accrue_portal/` for the customer billing portal UI'
require_fixed "$ROOT_DIR/CONTRIBUTING.md" "cd ../accrue_portal"
require_fixed "$ROOT_DIR/CONTRIBUTING.md" "ACCRUE_PORTAL_HEX_RELEASE=1"
require_absent_regex "$ROOT_DIR/RELEASING.md" 'Phase 9 release gate'
require_absent_regex "$ROOT_DIR/guides/testing-live-stripe.md" 'primary `test` job'
require_absent_regex "$ROOT_DIR/CONTRIBUTING.md" 'Node\.js for browser UAT in `accrue_admin`'
require_fixed "$ROOT_DIR/examples/accrue_host/playwright.config.js" 'trace: "retain-on-failure"'
require_fixed "$ROOT_DIR/examples/accrue_host/playwright.config.js" 'screenshot: "only-on-failure"'
require_absent_regex "$ROOT_DIR/examples/accrue_host/README.md" 'Stripe-only|remain Stripe-only'
require_absent_regex "$ROOT_DIR/examples/accrue_host/docs/adoption-proof-matrix.md" 'Stripe-only|remain Stripe-only'

for guide in \
  "$ROOT_DIR/accrue/guides/first_hour.md" \
  "$ROOT_DIR/accrue/guides/troubleshooting.md"; do
  require_fixed "$guide" 'config :accrue, :webhook_signing_secrets, %{'
require_fixed "$guide" 'stripe: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")'
  require_absent_regex "$guide" 'webhook_signing_secret([^s]|$)'
done

if ! is_release_please_pr; then
  require_fixed "$ROOT_DIR/accrue/README.md" "{:accrue, \"~> $accrue_version\"}"
  require_fixed "$ROOT_DIR/accrue_admin/README.md" "{:accrue_admin, \"~> $accrue_admin_version\"}"
  require_fixed "$ROOT_DIR/accrue_admin/README.md" "accrue ~> $accrue_version"
  require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "{:accrue, \"~> $accrue_version\"}"
  require_fixed "$ROOT_DIR/accrue/guides/first_hour.md" "{:accrue_admin, \"~> $accrue_admin_version\"}"
fi

# Token bypass guards (Phase 174, DSY-01)
app_css="$ROOT_DIR/accrue_admin/assets/css/app.css"
if grep -E '@media \((min|max)-width: [0-9.]+px\)' "$app_css" | grep -qv '\-\-ax-bp-'; then
  fail "$app_css must not have bare breakpoint @media without an --ax-bp-* annotation comment (DSY-01 — add a /* --ax-bp-NAME ↑/↓ */ comment to every breakpoint @media)"
fi

# Phase 188 foundation guards (FND-01..FND-06)
theme_css="$ROOT_DIR/accrue_admin/assets/css/theme.css"
admin_ui_md="$ROOT_DIR/accrue_admin/guides/admin_ui.md"
asset_build_task="$ROOT_DIR/accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex"

[[ ! -e "$ROOT_DIR/accrue_admin/assets/tailwind.config.js" ]] || fail "tailwind.config.js must stay absent (FND-04 Tailwind SSOT)"
[[ ! -e "$ROOT_DIR/accrue_admin/assets/tailwind_preset.js" ]] || fail "tailwind_preset.js must stay absent (FND-04 Tailwind SSOT)"

require_absent_regex "$asset_build_task" '--config'
require_absent_regex "$app_css" '@tailwind|@apply'
require_fixed "$admin_ui_md" "Tailwind utilities are not an authoring path"

if grep -Eiq 'Add Tailwind utilities|Prefer Tailwind utilities|Use Tailwind utilities|Tailwind utilities in HEEx|utility-first|class="[^"]*(mt-|mb-|mx-|my-|p-|px-|py-|flex|grid|rounded|shadow|text-|bg-)|tailwind_preset|tailwind\.config\.js|host apps? configure Tailwind' "$admin_ui_md"; then
  fail "$admin_ui_md contains positive Tailwind authoring guidance (FND-04 Tailwind authoring)"
fi

heex_utility_hit=$(
  find "$ROOT_DIR/accrue_admin/lib" -type f \( -name '*.ex' -o -name '*.heex' \) -print0 |
    xargs -0 perl -0ne '
      while (/~H"""(.*?)"""/sg) {
        my $template = $1;
        while ($template =~ /class="([^"]*)"/g) {
          my $class = $1;
          next if $class =~ /\bax-/;
          if ($class =~ /(^|\s)(mt-|mb-|mx-|my-|p-|px-|py-|flex\b|grid\b|hidden\b|block\b|rounded\b|shadow\b|text-|bg-)/) {
            print "$ARGV: $class\n";
          }
        }
      }
    ' |
    head -n 1
)
[[ -z "$heex_utility_hit" ]] || fail "HEEx Tailwind utility authoring is not allowed in accrue_admin/lib: $heex_utility_hit"

z_index_hit=$(
  perl -0ne '
    s{/\*.*?\*/}{}gs;
    while (/z-index\s*:\s*(-?[0-9]+)/gi) {
      my $value = $1;
      next if $value eq "-1" || $value eq "0" || $value eq "1";
      print "$value\n";
      last;
    }
  ' "$app_css"
)
[[ -z "$z_index_hit" ]] || fail "$app_css must not contain z-index literals outside micro-stacking exceptions (FND-02 z-index literals)"

raw_type_hit=$(
  awk '
    /@font-face/ { in_font_face = 1 }
    in_font_face && /\}/ { in_font_face = 0; next }
    /ax-type-exception:/ { in_type_exception = 1; next }
    /(font-size|font-weight|line-height|letter-spacing|font-family)[[:space:]]*:/ {
      if (!in_font_face && !in_type_exception && $0 !~ /font-family:[[:space:]]*var\(--ax-font-sans\)/) {
        print FNR ":" $0
        exit
      }
    }
    in_type_exception && /\}/ { in_type_exception = 0 }
  ' "$app_css"
)
[[ -z "$raw_type_hit" ]] || fail "$app_css contains raw type declarations outside ax-type-exception allowlist (FND-01 raw type declarations): $raw_type_hit"

semantic_tokens=(
  --ax-focus-ring
  --ax-focus-ring-offset
  --ax-focus-shadow
  --ax-scrollbar-thumb
  --ax-scrollbar-track
  --ax-scrollbar-thumb-hover
  --ax-disabled-bg
  --ax-disabled-border
  --ax-disabled-text
  --ax-disabled-opacity
  --ax-disabled-cursor
  --ax-readonly-bg
  --ax-readonly-border
  --ax-readonly-text
  --ax-interactive-hover
  --ax-interactive-active
  --ax-interactive-selected
  --ax-status-success-bg
)

for status in success warning danger info neutral; do
  semantic_tokens+=(
    "--ax-status-$status-bg"
    "--ax-status-$status-border"
    "--ax-status-$status-text"
    "--ax-status-$status-solid"
    "--ax-status-$status-on-solid"
  )
done

for token in "${semantic_tokens[@]}"; do
  count=$(grep -Ec "^[[:space:]]*$token:" "$theme_css" || true)
  [[ "$count" -ge 3 ]] || fail "$theme_css is missing semantic role tokens in root/dark/system-dark scopes: $token"
done

if ! ROOT_DIR="$ROOT_DIR" node "$ROOT_DIR/scripts/ci/verify_foundation_contrast.mjs"; then
  fail "semantic role contrast failed (FND-05); see [foundation_contrast] output above"
fi

require_css_rule_consumes() {
  local file=$1
  local token=$2
  local selector_pattern=$3
  local label=$4

  perl -0e '
    my ($file, $token, $selector_re) = @ARGV;
    open my $fh, "<", $file or die "open $file: $!";
    local $/;
    my $css = <$fh>;
    $css =~ s{/\*.*?\*/}{}gs;
    while ($css =~ /([^{}]+)\{([^{}]*)\}/g) {
      my ($selector, $body) = ($1, $2);
      if ($selector =~ /$selector_re/ && $body =~ /\Q$token\E/) {
        exit 0;
      }
    }
    exit 1;
  ' "$file" "$token" "$selector_pattern" || fail "$file is missing interactive role consumption for $label ($token)"
}

require_css_rule_consumes "$app_css" "--ax-interactive-hover" ':hover' "interactive role consumption hover"
require_css_rule_consumes "$app_css" "--ax-interactive-active" ':active' "interactive role consumption active"
require_css_rule_consumes "$app_css" "--ax-interactive-selected" 'aria-current|aria-selected|active|selected' "interactive role consumption selected/current"

# Motion antipattern guards (Phase 177, MOT-01)
if grep -qE 'transition:\s*all\b' "$app_css"; then
  fail "$app_css must not use 'transition: all' (MOT-01/A1) — name the exact properties or use an --ax-transition-* bundle"
fi

if grep -qE 'cubic-bezier\(' "$app_css"; then
  fail "$app_css must not contain raw cubic-bezier() literals (MOT-01/A3) — use --ax-ease-* atoms from theme.css"
fi

if grep -E '(transition|animation):[^;]*[0-9]+(ms|s)\b' "$app_css" | grep -qv 'ax-skeleton-shimmer'; then
  fail "$app_css must not have raw ms/s duration literals in transition/animation rules (MOT-01/A3) — use --ax-dur-* tokens; exception: ax-skeleton-shimmer 1.4s is allowlisted"
fi

if grep -qE 'transition:[^;]*\b(height|width|margin|padding|top|left|right|bottom)\b' "$app_css"; then
  fail "$app_css must not animate layout-triggering properties in transition lists (MOT-01/A2) — use only opacity/transform (composited)"
fi

# Motion guide existence (Phase 177, MOT-01)
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/motion.md"'

echo "package docs verified for accrue $accrue_version, accrue_admin $accrue_admin_version, and accrue_portal $accrue_portal_version"
echo "fixed invariants checked: README.md, RELEASING.md, CONTRIBUTING.md, quickstart.md, 15-TRUST-REVIEW.md, STRIPE_TEST_SECRET_KEY, release-gate, host-integration, retain-on-failure, only-on-failure, First run, Seeded history, mix verify, mix verify.full"
