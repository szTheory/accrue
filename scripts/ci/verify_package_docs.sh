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
  local message=${3:-"$file is missing: $needle"}

  grep -Fq -- "$needle" "$file" || fail "$message"
}

require_regex() {
  local file=$1
  local pattern=$2
  local message=${3:-"$file does not match: $pattern"}

  grep -Eq -- "$pattern" "$file" || fail "$message"
}

require_absent_regex() {
  local file=$1
  local pattern=$2
  local message=${3:-"$file must not match: $pattern"}

  if grep -Eq -- "$pattern" "$file"; then
    fail "$message"
  fi
}

require_fixed_count() {
  local file=$1
  local needle=$2
  local expected=$3
  local actual

  actual=$(grep -Fc -- "$needle" "$file" || true)
  [[ "$actual" == "$expected" ]] ||
    fail "$file expected $expected occurrences of $needle, found $actual"
}

require_since_immediately_before() {
  local file=$1
  local target=$2
  local label=$3

  awk -v target="$target" '
    $0 == target {
      if (previous == "  @doc since: \"1.5.0\"") {
        found = 1
      }
    }
    { previous = $0 }
    END { exit found ? 0 : 1 }
  ' "$file" || fail "$label must carry @doc since: \"1.5.0\" immediately before its spec/callback"
}

require_no_since_immediately_before() {
  local file=$1
  local target=$2
  local label=$3

  awk -v target="$target" '
    $0 == target && previous == "  @doc since: \"1.5.0\"" {
      bad = 1
    }
    { previous = $0 }
    END { exit bad ? 1 : 0 }
  ' "$file" || fail "$label internal Phase 213 surface must not carry @doc since: \"1.5.0\""
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
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'fetch_entitled/2` is closed and will-not-build'
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'Accrue.Entitlements.StripeSync.refresh/2'
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'When the flag is disabled, it returns'
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" '`{:ok, :disabled}` before processor or repository I/O'
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'refreshed advisory rows never'
require_fixed "$ROOT_DIR/accrue/lib/accrue/entitlements/admin.ex" 'fetch_entitled/2` is closed and will-not-build'
require_fixed "$ROOT_DIR/accrue/lib/accrue/entitlements/admin.ex" 'Accrue.Entitlements.StripeSync.summary_for_customer/1'
require_absent_regex "$ROOT_DIR/accrue/guides/entitlements.md" 'fetch_entitled/2.*deferred'
require_absent_regex "$ROOT_DIR/accrue/guides/entitlements.md" 'Deferred: the full paginated read|lattice_stripe >= 1\.2|That read is \*\*deferred\*\*'
require_absent_regex "$ROOT_DIR/accrue/guides/entitlements.md" 'advisory Stripe cache changes|authoritative for grant decisions|changes `entitled\?/2`'
require_absent_regex "$ROOT_DIR/accrue/lib/accrue/entitlements/admin.ex" 'def(p)?[[:space:]]+fetch_entitled'
require_fixed "$ROOT_DIR/accrue/guides/telemetry.md" '[:accrue, :entitlements, :sync]'

# Current lattice_stripe 2.x and Stripe-native advisory truth (Phase 214, DOCS-01/DOCS-02)
require_fixed "$ROOT_DIR/CLAUDE.md" '| `:lattice_stripe` | `~> 2.0` | Stripe API wrapper |'
require_fixed "$ROOT_DIR/CLAUDE.md" '| `lattice_stripe ~> 2.0` |'
require_fixed "$ROOT_DIR/CLAUDE.md" 'current lock resolves to 2.1.0'
require_fixed "$ROOT_DIR/CLAUDE.md" '2.x `LatticeStripe.Entitlements.*` active-entitlement support'
require_absent_regex "$ROOT_DIR/CLAUDE.md" '^\| `:lattice_stripe` \| `~> (0\.2|1\.1)` \|'
require_absent_regex "$ROOT_DIR/CLAUDE.md" '^\| `lattice_stripe ~> (0\.2|1\.1)` \|'
require_fixed "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" '*optional* Stripe-native sync now ships as an off-by-default'
require_fixed "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" 'local plan→feature map remains Accrue'
require_fixed "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" 'It never'
require_fixed "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" 'changes `entitled?/2`, `has_active_plan?/2`, controller plugs, or LiveView'
require_absent_regex "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" 'Stripe-native sync.*deferred|deferred.*Stripe-native sync'
require_absent_regex "$ROOT_DIR/accrue/guides/jobs_to_be_done.md" 'Stripe-native.*grant authority|grant authority.*Stripe-native'
require_fixed "$ROOT_DIR/.planning/research/JTBD-FRONTIER.md" '*optional* Stripe-native sync now ships as an off-by-default observational diagnostics lane'
require_fixed "$ROOT_DIR/.planning/research/JTBD-FRONTIER.md" 'local plan→feature map remains Accrue'
require_fixed "$ROOT_DIR/.planning/research/JTBD-FRONTIER.md" 'never changes `entitled?/2`, `has_active_plan?/2`, controller plugs, or LiveView guards'
require_absent_regex "$ROOT_DIR/.planning/research/JTBD-FRONTIER.md" 'Stripe-native sync.*deferred|deferred.*Stripe-native sync'
require_absent_regex "$ROOT_DIR/.planning/research/JTBD-FRONTIER.md" "Stripe-native entitlements are Accrue's source of truth|source of truth for grant decisions"
require_fixed "$ROOT_DIR/.planning/processor-support-matrix.md" 'entitlements.local_mapping'
require_fixed "$ROOT_DIR/.planning/processor-support-matrix.md" 'local mapping remains the canonical default'
require_fixed "$ROOT_DIR/.planning/processor-support-matrix.md" 'StripeSync.refresh/2` results to an advisory cache'
require_absent_regex "$ROOT_DIR/.planning/processor-support-matrix.md" 'Stripe-native sync can displace|grant source of truth|lattice_stripe` 1\.1'
require_fixed "$ROOT_DIR/examples/accrue_host/docs/adoption-proof-matrix.md" 'verify_package_docs.sh` pins the public wording'
require_fixed "$ROOT_DIR/examples/accrue_host/docs/adoption-proof-matrix.md" 'verify_entitlement_sync_isolation.sh` proves the advisory cache'
require_fixed "$ROOT_DIR/examples/accrue_host/docs/adoption-proof-matrix.md" 'Live Stripe parity remains advisory evidence only'
require_absent_regex "$ROOT_DIR/examples/accrue_host/docs/adoption-proof-matrix.md" 'Live Stripe entitlement refresh is the merge-blocking proof|live Stripe.*merge-blocking proof'

# Phase 213 public availability metadata (Phase 214, DOCS-03 / D-09..D-12)
stripe_sync_ex="$ROOT_DIR/accrue/lib/accrue/entitlements/stripe_sync.ex"
processor_ex="$ROOT_DIR/accrue/lib/accrue/processor.ex"
fake_processor_ex="$ROOT_DIR/accrue/lib/accrue/processor/fake.ex"
stripe_processor_ex="$ROOT_DIR/accrue/lib/accrue/processor/stripe.ex"
reconcile_ex="$ROOT_DIR/accrue/lib/accrue/entitlements/reconcile.ex"
refresh_worker_ex="$ROOT_DIR/accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex"

require_no_since_immediately_before "$stripe_sync_ex" \
  '  @spec summary_for_customer(Customer.t()) :: EntitlementSummary.t() | nil' \
  "StripeSync.summary_for_customer/1"
require_no_since_immediately_before "$processor_ex" \
  '  @spec active_entitlement_list_metadata() :: %{list_path: String.t()}' \
  "Processor.active_entitlement_list_metadata/0"
require_no_since_immediately_before "$fake_processor_ex" \
  '  @spec active_entitlement_list_metadata() :: %{list_path: String.t()}' \
  "Processor.Fake.active_entitlement_list_metadata/0"

require_since_immediately_before "$stripe_sync_ex" \
  '  @spec refresh(Customer.t(), keyword()) ::' \
  "StripeSync.refresh/2"
require_since_immediately_before "$processor_ex" \
  '  @callback list_active_entitlements(id(), opts()) :: {:ok, [map()]} | {:error, Exception.t()}' \
  "Processor.list_active_entitlements/2 callback"
require_since_immediately_before "$processor_ex" \
  '  @spec list_active_entitlements(id(), opts()) :: {:ok, [map()]} | {:error, Exception.t()}' \
  "Processor.list_active_entitlements/2 facade"
require_since_immediately_before "$fake_processor_ex" \
  '  @spec put_entitlements(String.t(), [map()]) :: :ok' \
  "Processor.Fake.put_entitlements/2"

require_fixed_count "$stripe_sync_ex" '@doc since: "1.5.0"' 1
require_fixed_count "$processor_ex" '@doc since: "1.5.0"' 2
require_fixed_count "$fake_processor_ex" '@doc since: "1.5.0"' 1
require_absent_regex "$stripe_sync_ex" '@doc since: "1\.4\.0"'

# DOCS-03: both optional writer paths converge through the same advisory row;
# they remain diagnostic-only and cannot become a grant source of truth.
stripe_sync_writer_provenance="StripeSync writer provenance ($stripe_sync_ex)"
entitlement_summary_ex="$ROOT_DIR/accrue/lib/accrue/billing/entitlement_summary.ex"
telemetry_md="$ROOT_DIR/accrue/guides/telemetry.md"
stripe_sync_one_way_dependency=$(awk '
  /^  ## One-way dependency$/ { in_section = 1; next }
  in_section && /^  """$/ { exit }
  in_section { print }
' "$stripe_sync_ex")

require_fixed "$stripe_sync_ex" "webhook handling" \
  "$stripe_sync_writer_provenance: missing webhook writer"
require_fixed "$stripe_sync_ex" "client-backed pull refresh" \
  "$stripe_sync_writer_provenance: missing pull-refresh writer"
require_fixed "$stripe_sync_ex" 'same advisory `Accrue.Billing.EntitlementSummary` row' \
  "$stripe_sync_writer_provenance: missing shared advisory row"
[[ "$stripe_sync_one_way_dependency" == *"Accrue.Entitlements.Reconcile"* ]] ||
  fail "$stripe_sync_writer_provenance: missing shared reconciler"
require_fixed "$stripe_sync_ex" "stripe_native_sync: :advisory" \
  "$stripe_sync_writer_provenance: missing advisory opt-in boundary"
require_fixed "$stripe_sync_ex" "off by default" \
  "$stripe_sync_writer_provenance: missing default-off boundary"
require_fixed "$stripe_sync_ex" "diagnostic only" \
  "$stripe_sync_writer_provenance: missing diagnostic-only boundary"
require_fixed "$stripe_sync_ex" "neither path can influence grants" \
  "$stripe_sync_writer_provenance: missing non-gate boundary"
require_fixed "$stripe_sync_ex" "Local plan→feature mapping remains the sole Accrue grant authority." \
  "$stripe_sync_writer_provenance: missing local grant authority"
require_absent_regex "$stripe_sync_ex" 'only reads through `Accrue\.Repo`' \
  "$stripe_sync_writer_provenance: stale read-only claim remains"
require_absent_regex "$stripe_sync_ex" 'written exclusively by `Accrue\.Webhook\.DefaultHandler`' \
  "$stripe_sync_writer_provenance: stale webhook-exclusive claim remains"

# DOCS-03 / D-21: current advisory-snapshot completeness truth. Client-backed
# pull exhaustively drains active entitlements before persistence; webhook
# summaries can be incomplete. Both paths remain observational-only.
require_fixed "$entitlement_summary_ex" "streams the customer's active entitlements before persisting its advisory" \
  "EntitlementSummary completeness ($entitlement_summary_ex): missing exhaustive pull truth"
require_fixed "$entitlement_summary_ex" "snapshot. Webhook summary snapshots can contain only the first reported" \
  "EntitlementSummary completeness ($entitlement_summary_ex): missing webhook incompleteness truth"
require_fixed "$entitlement_summary_ex" "never affect local access or a gate decision." \
  "EntitlementSummary completeness ($entitlement_summary_ex): missing advisory-only boundary"
require_absent_regex "$entitlement_summary_ex" '`lattice_stripe >= 1\.2`|deferred.*paginated.*reconcile|full pagination is deferred' \
  "EntitlementSummary completeness ($entitlement_summary_ex): stale deferred pagination truth remains"

require_fixed "$telemetry_md" "Known-incomplete webhook advisory snapshot: \`has_more: true\` means only the first reported entitlements were received. Client-backed pull exhaustively streams active entitlements before persistence; neither path gates local access." \
  "telemetry completeness ($telemetry_md): missing webhook/pull advisory truth"
require_absent_regex "$telemetry_md" '`lattice_stripe >= 1\.2`|full pagination is deferred|deferred.*pagination' \
  "telemetry completeness ($telemetry_md): stale deferred pagination truth remains"

for internal_file in \
  "$stripe_processor_ex" \
  "$reconcile_ex" \
  "$refresh_worker_ex"; do
  require_absent_regex "$internal_file" '@doc since: "1\.5\.0"'
done

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
      # Pattern to detect obvious Tailwind utility tokens (spacing, layout, visibility, etc.)
      my $tailwind_re = qr/(^|\s)(mt-|mb-|mx-|my-|p-|px-|py-|flex\b|grid\b|hidden\b|block\b|inline\b|rounded\b|shadow\b|text-|bg-|w-|h-|sr-only\b)/;
      while (/~H"""(.*?)"""/sg) {
        my $template = $1;
        # Check literal quoted class attributes: class="..."
        while ($template =~ /class="([^"]*)"/g) {
          my $class = $1;
          next if $class =~ /\bax-/;
          if ($class =~ $tailwind_re) {
            print "$ARGV (literal class): $class\n";
          }
        }
        # Check dynamic class expressions: class={...} — extract string literals inside
        while ($template =~ /class=\{([^\}]*)\}/g) {
          my $expr = $1;
          # Extract all double-quoted string fragments from the expression
          while ($expr =~ /"([^"]*)"/g) {
            my $frag = $1;
            next if $frag =~ /\bax-/;
            if ($frag =~ $tailwind_re) {
              print "$ARGV (dynamic class): $frag\n";
            }
          }
        }
      }
    ' |
    head -n 1
)
[[ -z "$heex_utility_hit" ]] || fail "HEEx Tailwind utility authoring is not allowed in accrue_admin/lib (literal or dynamic class expressions): $heex_utility_hit"

z_index_hit=$(
  perl -0ne '
    use strict;
    my $raw = $_;
    my @lines = split /\n/, $raw;
    my $in_block_comment = 0;
    for (my $i = 0; $i < @lines; $i++) {
      my $line = $lines[$i];
      # Track block comment state to skip z-index inside comments
      if ($in_block_comment) {
        $in_block_comment = 0 if $line =~ /\*\//;
        next;
      }
      if ($line =~ /\/\*/ && $line !~ /\*\//) {
        $in_block_comment = 1;
        next;
      }
      # Strip inline comment for value extraction only
      (my $code = $line) =~ s{/\*.*?\*/}{}g;
      next unless $code =~ /z-index\s*:\s*(-?[0-9]+)/i;
      my $value = $1;
      # Larger numerics always fail
      if ($value ne "-1" && $value ne "0" && $value ne "1") {
        print "$value\n";
        last;
      }
      # For -1/0/1: require ax-z-micro-stack annotation on this raw line (inline comment)
      unless ($line =~ /ax-z-micro-stack/) {
        print "undocumented micro-stack: $value\n";
        last;
      }
      # Also require isolation: isolate somewhere in the preceding ~25 raw lines
      my $lookback = join("\n", @lines[($i > 25 ? $i - 25 : 0) .. $i]);
      unless ($lookback =~ /isolation\s*:\s*isolate/) {
        print "micro-stack without isolation: $value\n";
        last;
      }
    }
  ' "$app_css"
)
[[ -z "$z_index_hit" ]] || fail "$app_css must not contain z-index literals outside documented isolated micro-stacks (FND-02 z-index literals — pair micro-stacking 0/1/-1 with ax-z-micro-stack comment and isolation: isolate on the shell)"

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

# Phase 189 CMP-05: no per-page CSS overrides of primitive ax-* classes.
# Only app.css and theme.css may define primitive selectors.
# Note: the `|| true` guards against `set -euo pipefail` aborting on the
# no-hit path. With no matches (or no input files), grep exits 1 and GNU
# xargs propagates 123 — a portability trap vs BSD xargs (macOS) which
# exits 0 on empty input. An empty result is the *passing* case here.
primitive_override_hit=$(
  find "$ROOT_DIR/accrue_admin/assets/css" -name "*.css" \
    ! -name "app.css" ! -name "theme.css" -print0 |
    xargs -0 grep -E '\.ax-(button|field|input|select|status-badge|icon|money|json|empty)[^{]*\{' 2>/dev/null |
    head -n 1
) || true
[[ -z "$primitive_override_hit" ]] || fail "per-page CSS overrides of primitive ax-* classes are not allowed (CMP-05): $primitive_override_hit"

# Phase 189 CMP-05: no raw inline style= on primitive component wrappers.
# `|| true` for the same no-hit portability reason as above.
inline_style_hit=$(
  find "$ROOT_DIR/accrue_admin/lib" -type f \( -name '*.ex' -o -name '*.heex' \) -print0 |
    xargs -0 perl -0ne '
      while (/~H"""(.*?)"""/sg) {
        my $tmpl = $1;
        while ($tmpl =~ /<[a-z][^>]*class="[^"]*\b(ax-button|ax-field|ax-input|ax-select|ax-status-badge|ax-money|ax-json)\b[^"]*"[^>]*style=/g) {
          print "$ARGV: $1\n";
          last;
        }
      }
    ' 2>/dev/null |
    head -n 1
) || true
[[ -z "$inline_style_hit" ]] || fail "raw inline style= on primitive ax-* elements is not allowed (CMP-05): $inline_style_hit"

# Phase 193 CSS source guards (RES-04)

# Guard A — Spacing-literal ban (no raw px on padding/margin/gap outside --ax-space-* tokens)
spacing_literal_hit=$(
  perl -0ne '
    while (/([^\n]+)\n/g) {
      my $line = $1;
      next if $line =~ /\/\*/;
      next if $line =~ /ax-spacing-exception:/;
      if ($line =~ /\b(padding|margin|gap)\s*:[^;]*\b\d+px\b/ && $line !~ /var\(--ax-/) {
        print "$line\n";
        last;
      }
    }
  ' "$app_css" || true
)
[[ -z "$spacing_literal_hit" ]] || fail "$app_css must not use raw px spacing outside --ax-space-* tokens (RES-04 spacing-literal guard)"

# Guard B — :focus-visible enforcement (focus styles must target :focus-visible not bare :focus)
focus_ring_hit=$(grep -En ':focus[^-]' "$app_css" | grep -v ':focus-visible' | head -n 1 || true)
[[ -z "$focus_ring_hit" ]] || fail "$app_css contains :focus selector without :focus-visible (RES-04 focus-visible guard)"

# Guard C — Truncation without min-width:0 (text-overflow:ellipsis must have min-width:0 in same CSS block)
truncation_hit=$(
  perl -0ne '
    while (/\{([^}]*text-overflow\s*:\s*ellipsis[^}]*)\}/gs) {
      my $block = $1;
      unless ($block =~ /min-width\s*:\s*0/) {
        print "found truncation without min-width:0\n";
        last;
      }
    }
  ' "$app_css" || true
)
[[ -z "$truncation_hit" ]] || fail "$app_css has truncation without min-width:0 in same block (RES-04 truncation guard)"

# Guard D — Empty-rail non-interactivity (Phase 194, SPEC-OVERVIEW)
empty_rail_pointer_hit=$(
  perl -0ne '
    while (/\.ax-attention-rail--empty[^{]*\{([^}]*)\}/gs) {
      my $block = $1;
      if ($block =~ /cursor\s*:\s*pointer/) { print "found cursor:pointer on empty rail\n"; last; }
    }
  ' "$app_css" || true
)
[[ -z "$empty_rail_pointer_hit" ]] || fail "$app_css must not put cursor:pointer on .ax-attention-rail--empty (SPEC-OVERVIEW non-interactive empty-rail guard)"

# Archetype spec guide existence (Phase 193, RES-01 / D-07)
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/spec-overview.md"'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/spec-list.md"'
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" '"guides/spec-detail.md"'
require_fixed "$ROOT_DIR/accrue_admin/guides/spec-overview.md" "## SPEC-OVERVIEW — "
require_fixed "$ROOT_DIR/accrue_admin/guides/spec-list.md" "## SPEC-LIST — "
require_fixed "$ROOT_DIR/accrue_admin/guides/spec-detail.md" "## SPEC-DETAIL — summary-then-drill"

# Storybook dep + router guard presence (Phase 193, STY-01 / D-07)
require_fixed "$ROOT_DIR/accrue_admin/mix.exs" ':phoenix_storybook'
require_fixed "$ROOT_DIR/accrue_admin/lib/accrue_admin/router.ex" 'Code.ensure_loaded?(PhoenixStorybook.Router)'

echo "package docs verified for accrue $accrue_version, accrue_admin $accrue_admin_version, and accrue_portal $accrue_portal_version"
echo "fixed invariants checked: README.md, RELEASING.md, CONTRIBUTING.md, quickstart.md, 15-TRUST-REVIEW.md, STRIPE_TEST_SECRET_KEY, release-gate, host-integration, retain-on-failure, only-on-failure, First run, Seeded history, mix verify, mix verify.full"
