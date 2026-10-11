#!/usr/bin/env bash
set -euo pipefail

project=accrue-host-phase245-ordinary
compose_file=examples/accrue_host/docker-compose.yml
snapshot="${TMPDIR:-/tmp}/accrue245-phase243.snapshot.json"
compose=(docker compose -p "$project" -f "$compose_file")

die() { printf 'Phase 245 seed refused: %s\n' "$1" >&2; exit 1; }

web_id=$("${compose[@]}" ps -q web)
db_id=$("${compose[@]}" ps -q db)
[[ -n "$web_id" && -n "$db_id" ]] || die "ordinary web and db containers must already be running"

# Compose's actual labels, network membership, and persistent volume establish
# the target instance. Caller-controlled COMPOSE_PROJECT_NAME is not evidence.
expected_network="${project}_default"
expected_volume="${project}_pgdata"
web_networks=$(docker inspect --format '{{range $name, $network := .NetworkSettings.Networks}}{{printf "%s " $name}}{{end}}' "$web_id")
db_networks=$(docker inspect --format '{{range $name, $network := .NetworkSettings.Networks}}{{printf "%s " $name}}{{end}}' "$db_id")
db_volumes=$(docker inspect --format '{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{.Name}}{{end}}{{end}}' "$db_id")
[[ " $web_networks " == *" $expected_network "* && " $db_networks " == *" $expected_network "* ]] || die "containers are not attached to the named ordinary network"
[[ "$db_volumes" == "$expected_volume" ]] || die "database does not use the named ordinary data volume"

db_ip=$(docker inspect --format "{{(index .NetworkSettings.Networks \"$expected_network\").IPAddress}}" "$db_id")
fingerprint=$("${compose[@]}" exec -T db psql -U postgres -d accrue_host_dev -Atc \
  "SELECT current_database() || '|' || current_user || '|' || inet_server_addr()::text")
[[ "$fingerprint" == "accrue_host_dev|postgres|$db_ip" ]] || die "database fingerprint does not match the inspected ordinary container"

custody=(env ACCRUE_HOST_PREVIEW_INSTANCE=accrue-host-phase243-preview ACCRUE_HOST_PREVIEW_SNAPSHOT="$snapshot" node scripts/ci/accrue_host_preview_custody.sh)
"${custody[@]}" snapshot
seed_status=0
"${compose[@]}" exec -T web mix run priv/repo/seeds/ordinary.exs || seed_status=$?
"${custody[@]}" assert-preserved || die "protected Phase 243 snapshot changed; inspect before further writes"
(( seed_status == 0 )) || exit "$seed_status"
printf 'Ordinary Phase 245 fixtures seeded; protected Phase 243 snapshot is preserved.\n'
