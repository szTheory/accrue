#!/usr/bin/env bash
# Read-only drift guard: merge-blocking invoice VERIFY flow ids in parity docs must
# stay wired in verify01-admin-a11y.spec.js (Phase 55 D-05).
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
spec="$repo_root/examples/accrue_host/e2e/verify01-admin-a11y.spec.js"

if [[ ! -f "$spec" ]]; then
  echo "verify_core_admin_invoice_verify_ids: missing $spec" >&2
  exit 1
fi

for id in core-admin-invoices-index core-admin-invoices-detail; do
  if ! grep -qF "$id" "$spec"; then
    echo "verify_core_admin_invoice_verify_ids: expected id '$id' in $spec" >&2
    exit 1
  fi
done

echo "verify_core_admin_invoice_verify_ids: OK"
