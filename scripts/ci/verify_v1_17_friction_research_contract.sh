#!/usr/bin/env bash
# Shift-left: v1.17 planning SSOT — friction inventory (FRG-01/03), north-star pointers (FRG-02),
# ROADMAP FRG-03 anchors. No BEAM/Postgres; safe to run before release-gate matrix.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
inv="${repo_root}/.planning/research/v1.17-FRICTION-INVENTORY.md"
ns="${repo_root}/.planning/research/v1.17-north-star.md"
state="${repo_root}/.planning/STATE.md"
project="${repo_root}/.planning/PROJECT.md"
roadmap="${repo_root}/.planning/ROADMAP.md"

die() {
  echo "verify_v1_17_friction_research_contract: $*" >&2
  exit 1
}

[[ -f "$inv" ]] || die "missing $inv"
[[ -f "$ns" ]] || die "missing $ns"
[[ -f "$state" ]] || die "missing $state"
[[ -f "$project" ]] || die "missing $project"
[[ -f "$roadmap" ]] || die "missing $roadmap"

archive="${repo_root}/.planning/milestones/v1.17-REQUIREMENTS.md"
if [[ ! -f "$archive" ]]; then
  echo "ERROR: missing ${archive} (UAT-04 v1.17 requirements archive)" >&2
  exit 1
fi

if grep -Fq '*(example)*' "$inv"; then
  die "friction inventory must not contain the *(example)* placeholder"
fi

# Every v1.17-P0- token must start a full id v1.17-P0-NNN (three digits), not a grep-audit trap substring.
if ! perl -0777 -ne 'exit 1 if /v1\.17-P0-(?!\d{3})/' "$inv"; then
  die "ambiguous v1.17-P0- substring in inventory (must always be v1.17-P0-NNN)"
fi

row_count=$(grep -cE '^\| v1\.17-P[012]-[0-9]{3} \|' "$inv" || true)
[[ "$row_count" -eq 5 ]] || die "expected exactly 5 inventory data rows (P0/P1/P2), got ${row_count}"

p0_count=$(grep -cE '^\| v1\.17-P0-' "$inv" || true)
[[ "$p0_count" -eq 2 ]] || die "expected exactly 2 P0 inventory rows, got ${p0_count}"

p1_count=$(grep -cE '^\| v1\.17-P1-' "$inv" || true)
[[ "$p1_count" -eq 2 ]] || die "expected exactly 2 P1 inventory rows, got ${p1_count}"

p2_count=$(grep -cE '^\| v1\.17-P2-' "$inv" || true)
[[ "$p2_count" -eq 1 ]] || die "expected exactly 1 P2 inventory row, got ${p2_count}"

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  grep -Fq '| INT-10 |' <<<"$line" || die "P0 row missing INT-10 req column: ${line}"
  grep -Fq '| →63 |' <<<"$line" || die "P0 row missing frg03_disposition →63: ${line}"
done < <(grep -E '^\| v1\.17-P0-' "$inv" || true)

grep -Fq '### Backlog — INT-10' "$inv" || die "missing ### Backlog — INT-10 anchor"
grep -Fq '### Backlog — BIL-03' "$inv" || die "missing ### Backlog — BIL-03 anchor"
grep -Fq '### Backlog — ADM-12' "$inv" || die "missing ### Backlog — ADM-12 anchor"

grep -Fq '.planning/research/v1.17-FRICTION-INVENTORY.md' "$state" || die "STATE.md must reference canonical inventory path"
grep -Fq 'v1.17-north-star.md' "$state" || die "STATE.md must reference v1.17-north-star.md"
grep -Fq 'v1.17-north-star.md' "$project" || die "PROJECT.md must reference v1.17-north-star.md"

grep -Fq '| S1 |' "$ns" || die "north star missing S1 stop rule row"
grep -Fq '| S5 |' "$ns" || die "north star missing S5 stop rule row"

grep -Fq 'research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63' "$roadmap" ||
  die "ROADMAP missing FRG-03 INT-10 inventory anchor"
grep -Fq 'research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64' "$roadmap" ||
  die "ROADMAP missing FRG-03 BIL-03 inventory anchor"
grep -Fq 'research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65' "$roadmap" ||
  die "ROADMAP missing FRG-03 ADM-12 inventory anchor"

echo "verify_v1_17_friction_research_contract: OK"
