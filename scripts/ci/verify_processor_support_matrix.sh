#!/usr/bin/env bash
# Shift-left gate: Phase 94 processor-support matrix literals must stay aligned with strategy and CI.
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
require_substring "subscription.lifecycle_webhook_projection" "subscription lifecycle projection row"
require_substring "invoice.lifecycle_webhook_projection" "invoice lifecycle projection row"
require_substring "checkout.hosted_handoff" "checkout hosted handoff row"
require_substring "billing_portal.hosted_self_serve" "billing portal self-serve row"
require_substring 'Accrue.Billing.subscribe/3' "subscribe facade mapping"
require_substring 'Accrue.Billing.create_checkout_session/2' "checkout facade mapping"
require_substring 'Accrue.Billing.create_billing_portal_session/2' "billing portal facade mapping"
require_substring "Stripe-only" "stripe-only support label"
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

echo "verify_processor_support_matrix: OK"
