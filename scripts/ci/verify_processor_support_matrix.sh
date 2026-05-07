#!/usr/bin/env bash
# Shift-left gate: processor-support matrix literals must stay aligned with strategy and CI.
set -euo pipefail

repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
matrix="${repo_root}/.planning/processor-support-matrix.md"

if [[ ! -f "${matrix}" ]]; then
  echo "verify_processor_support_matrix: missing ${matrix}" >&2
  exit 1
fi

require_substring() {
  local needle="$1"
  local label="$2"
  if ! grep -Fq "${needle}" "${matrix}"; then
    echo "verify_processor_support_matrix: matrix missing ${label} (expected substring: ${needle})" >&2
    exit 1
  fi
}

require_substring "| Capability | Fake | Stripe | Braintree | Public label |" "matrix header"
require_substring "gateway subscription core" "official capability slice"
require_substring "subscription.direct_create" "direct subscription capability row"
require_substring "| subscription.cancel | Supported | Supported | Supported | all first-party |" "immediate cancellation capability row"
require_substring "| subscription.swap_plan | testing/local-only | native | bounded first-party | official active-subscription-change |" "swap-plan capability row"
require_substring "| subscription.cancel_immediately | Supported | Supported | Supported | all first-party |" "immediate cancellation alias capability row"
require_substring "| subscription.cancel_at_period_end | Supported | Supported | Unsupported | staged first-party target |" "scheduled-end split capability row"
require_substring "subscription.lifecycle_webhook_projection" "subscription lifecycle projection row"
require_substring "invoice.lifecycle_webhook_projection" "invoice lifecycle projection row"
require_substring "| invoice.preview_upcoming_invoice | testing/local-only | native | unsupported | official active-subscription-change |" "preview capability row"
require_substring "checkout.hosted_handoff" "checkout hosted handoff row"
require_substring "billing_portal.hosted_self_serve" "billing portal self-serve row"
require_substring 'Accrue.Billing.subscribe/3' "subscribe facade mapping"
require_substring '| `Accrue.Billing.cancel/2` | all first-party | Immediate cancellation is the shared shipped path across Fake, Stripe, and Braintree. |' "cancel facade mapping"
require_substring '| `Accrue.Billing.swap_plan/3` | official active-subscription-change | Official active-subscription-change facade for plan changes: Stripe is native, Fake is testing/local-only, and Braintree is bounded first-party only when the host provides `:plan_resolver`. |' "swap-plan facade mapping"
require_substring '| `Accrue.Billing.cancel_at_period_end/2` | staged first-party target | Scheduled-end cancellation remains supported on Fake and Stripe; Braintree rejects it with a typed unsupported error and a host-owned next-step hint. |' "cancel-at-period-end facade mapping"
require_substring '| `Accrue.Billing.preview_upcoming_invoice/2` | official active-subscription-change | Official active-subscription-change preview facade and the canonical path where supported before committing a swap. Stripe is native, Fake is testing/local-only proof, and Braintree is explicitly unsupported. |' "preview facade mapping"
require_substring 'Accrue.Billing.create_checkout_session/2' "checkout facade mapping"
require_substring 'Accrue.Billing.create_billing_portal_session/2' "billing portal facade mapping"
require_substring "Supported via first-party local checkout" "braintree local checkout support label"
require_substring "Supported via mounted first-party portal" "braintree local portal support label"
require_substring "Stripe returns upstream hosted URLs; Braintree returns mounted first-party local checkout URLs." "checkout provider-honest facade wording"
require_substring "Stripe returns upstream hosted URLs; Braintree returns mounted first-party local portal URLs." "billing portal provider-honest facade wording"
require_substring "out of slice" "out-of-slice support label"
require_substring "Fake-first lane" "fake-first lane wording"
require_substring "Braintree" "locked target provider"
require_substring "Adyen" "explicit non-target provider"
require_substring "PayPal direct subscriptions" "explicit PayPal non-target"
require_substring "GoCardless" "explicit bank-debit non-target"
require_substring "fail clearly and early" "early failure support rule"
require_substring "Laravel Cashier" "cashier lesson"
require_substring "Pay (Rails)" "pay rails lesson"
require_substring "ActiveMerchant" "activemerchant lesson"
require_substring '`Stripe` remains the default first-user path' "stripe default path wording"
require_substring '`Fake` is the required local and CI proof surface' "fake required surface wording"
require_substring "Hyperwallet" "explicit Hyperwallet boundary"
require_substring "strategically out of bounds unless the project boundary changes" "Phase 104 no-go wording"
require_substring "reopening requires an explicit strategy change plus a new milestone" "Phase 104 reopen rule"
if grep -Fq "| checkout.hosted_handoff | Local proof helper | Supported | No | Stripe-only |" "${matrix}"; then
  echo "verify_processor_support_matrix: stale Stripe-only checkout row still present" >&2
  exit 1
fi

if grep -Fq "| billing_portal.hosted_self_serve | Local proof helper | Supported | No | Stripe-only |" "${matrix}"; then
  echo "verify_processor_support_matrix: stale Stripe-only billing portal row still present" >&2
  exit 1
fi

if grep -Fq "| subscription.cancel | Supported | Supported | Supported | staged first-party target |" "${matrix}"; then
  echo "verify_processor_support_matrix: immediate cancellation row drifted back to staged" >&2
  exit 1
fi

if grep -Fq "| subscription.cancel_immediately | Supported | Supported | Supported | staged first-party target |" "${matrix}"; then
  echo "verify_processor_support_matrix: immediate cancellation alias row drifted back to staged" >&2
  exit 1
fi

if grep -Fq "| subscription.cancel_at_period_end | Supported | Supported | Supported | all first-party |" "${matrix}"; then
  echo "verify_processor_support_matrix: Braintree scheduled-end parity was reintroduced" >&2
  exit 1
fi

if grep -Fq '| `Accrue.Billing.cancel_at_period_end/2` | all first-party |' "${matrix}"; then
  echo "verify_processor_support_matrix: scheduled-end facade mapping drifted to first-party parity" >&2
  exit 1
fi

if grep -Fq '| `Accrue.Billing.preview_upcoming_invoice/2` | out of slice |' "${matrix}"; then
  echo "verify_processor_support_matrix: preview facade drifted back to out-of-slice wording" >&2
  exit 1
fi

if grep -Eq 'preview parity|pseudo-preview' "${matrix}"; then
  echo "verify_processor_support_matrix: stale preview-parity wording still present" >&2
  exit 1
fi

echo "verify_processor_support_matrix: OK"
