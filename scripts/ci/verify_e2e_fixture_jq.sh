#!/usr/bin/env bash
# Fail fast if E2E fixture JSON drifts from the seed contract (before full Playwright).
set -euo pipefail

fixture="${1:-}"
if [[ -z "${fixture}" || ! -f "${fixture}" ]]; then
  echo "usage: verify_e2e_fixture_jq.sh <fixture-json-path>" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "verify_e2e_fixture_jq: jq is required" >&2
  exit 1
fi

jq -e '
  (.password | type) == "string"
  and (.normal_email | type) == "string"
  and (.admin_email | type) == "string"
  and ((.webhook_id | type) == "string" or (.webhook_id | type) == "number")
  and ((.subscription_id | type) == "string" or (.subscription_id | type) == "number")
  and (.org_alpha_slug | type) == "string"
  and (.org_beta_slug | type) == "string"
  and (.org_alpha_name | type) == "string"
  and (.org_beta_name | type) == "string"
  and (.tax_invalid_customer_hint | type) == "string"
  and (.admin_org_alpha_slug | type) == "string"
  and (.admin_org_beta_slug | type) == "string"
  and ((.admin_denial_customer_id | type) == "string" or (.admin_denial_customer_id | type) == "number")
  and (.invoice_id | type) == "string"
  and (.first_run_webhook | type) == "object"
  and (.first_run_webhook | has("processor_event_id"))
  and (.first_run_webhook | has("payload"))
  and (.first_run_webhook | has("signature"))
' "${fixture}" >/dev/null

echo "verify_e2e_fixture_jq: OK (${fixture})"
