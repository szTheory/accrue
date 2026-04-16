#!/usr/bin/env bash

set -euo pipefail

echo "Phase 12 plan 07 activates package-doc drift checks"

# Target files reserved for the real package-doc drift checks in plan 07:
# - accrue/mix.exs
# - accrue_admin/mix.exs
# - accrue/README.md
# - accrue_admin/README.md
#
# Planned checks:
# - parse @version from accrue/mix.exs and accrue_admin/mix.exs
# - compare README install snippets against those version values
# - verify docs.source_ref remains accrue-v#{@version} and accrue_admin-v#{@version}
# - verify relative ExDoc guide links point at guides/first_hour.md,
#   guides/troubleshooting.md, guides/webhooks.md, and guides/admin_ui.md
# - verify package README links use https://hexdocs.pm/accrue and
#   https://hexdocs.pm/accrue_admin
# - keep README, HexDocs, source_ref, and guides/ invariants locked to
#   published package metadata without printing secrets or env-var values

exit 0
