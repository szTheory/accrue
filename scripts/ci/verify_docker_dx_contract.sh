#!/usr/bin/env bash
# Shift-left gate: examples/accrue_host Docker DX must stay fleet-safe and cache-correct.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
host_dir="${repo_root}/examples/accrue_host"

fail() {
  echo "verify_docker_dx_contract: $*" >&2
  exit 1
}

require_file() {
  local path="$1"
  [[ -f "${path}" ]] || fail "missing ${path}"
}

require_substring() {
  local path="$1"
  local needle="$2"
  local label="$3"

  grep -Fq -- "${needle}" "${path}" || fail "${path} missing ${label} (expected substring: ${needle})"
}

reject_substring() {
  local path="$1"
  local needle="$2"
  local label="$3"

  ! grep -Fq -- "${needle}" "${path}" || fail "${path} contains stale ${label} (forbidden substring: ${needle})"
}

require_config_substring() {
  local config="$1"
  local needle="$2"
  local label="$3"

  grep -Fq -- "${needle}" <<<"${config}" || fail "rendered compose config missing ${label} (${needle})"
}

require_no_db_ports() {
  local config="$1"
  local name="$2"

  awk '
    /^  db:/ { in_db = 1; next }
    /^  [a-zA-Z0-9_-]+:/ && in_db { in_db = 0 }
    in_db && /ports:/ { found = 1 }
    END { exit found ? 1 : 0 }
  ' <<<"${config}" || fail "${name} rendered compose config publishes db ports by default"
}

compose_config() {
  local project="$1"
  local host="$2"

  (
    cd "${host_dir}"
    COMPOSE_PROJECT_NAME="${project}" ACCRUE_HOST="${host}" docker compose -f docker-compose.yml config
  )
}

makefile="${host_dir}/Makefile"
compose="${host_dir}/docker-compose.yml"
override="${host_dir}/docker-compose.override.yml.example"
env_example="${host_dir}/.env.example"
entrypoint="${host_dir}/bin/dev-entrypoint.sh"
banner="${host_dir}/bin/dev-banner.sh"
readme="${host_dir}/README.md"
docker_dx="${host_dir}/docs/docker-dx.md"
traefik="${host_dir}/docker/traefik/compose.yml"

for path in "${makefile}" "${compose}" "${override}" "${env_example}" "${entrypoint}" "${banner}" "${readme}" "${docker_dx}" "${traefik}"; do
  require_file "${path}"
done

require_substring "${makefile}" "validate-instance" "DNS-safe INSTANCE preflight"
require_substring "${makefile}" "^[a-z0-9]([a-z0-9-]*[a-z0-9])?" "DNS-safe INSTANCE regex"
require_substring "${makefile}" "validate-docker-platform" "native-platform preflight"
require_substring "${makefile}" "DOCKER_DEFAULT_PLATFORM" "amd64 emulation guard"
require_substring "${makefile}" "ensure-proxy-network" "first-run proxy-network creation"
require_substring "${makefile}" "docker network create proxy" "idempotent proxy network creation"
require_substring "${makefile}" "docker compose up -d --build --remove-orphans" "reset returns to bannered detached boot"

require_substring "${entrypoint}" ".accrue-assets-setup.sha256" "asset setup manifest marker"
require_substring "${entrypoint}" ".accrue-assets-build.sha256" "asset build manifest marker"
require_substring "${entrypoint}" "assets/package-lock.json" "package-lock-driven npm refresh"
require_substring "${entrypoint}" "asset_build_hash" "first-paint asset hash"
require_substring "${entrypoint}" "mix assets.setup" "asset setup still runs when stale"
require_substring "${entrypoint}" "mix assets.build" "asset build still runs when stale"

require_substring "${override}" '${PGPORT:-}:5432' "ephemeral DB GUI port default"
require_substring "${override}" "docker compose port db 5432" "DB GUI port discovery guidance"

require_substring "${traefik}" '"127.0.0.1:80:80"' "loopback web entrypoint"
require_substring "${traefik}" '"127.0.0.1:8080:8080"' "loopback dashboard entrypoint"
require_substring "${traefik}" "--api.insecure=true" "explicit local-only dashboard mode"

require_substring "${banner}" "http://localhost:8080/dashboard/" "dashboard URL with trailing slash"
require_substring "${readme}" "http://accrue.localhost/admin" "canonical stable URL"
require_substring "${readme}" "make up INSTANCE=accrue-foo" "side-by-side checkout command"
require_substring "${readme}" "docker compose port db 5432" "DB GUI ephemeral port discovery"
require_substring "${readme}" "INSTANCE" "Makefile instance variable"
require_substring "${readme}" "DOCKER_DEFAULT_PLATFORM" "emulation footgun"
reject_substring "${readme}" "ACCRUE_HOST_COMPOSE_PROJECT" "retired instance variable"
reject_substring "${readme}" "PostgreSQL 14+ must already be running" "Docker-host Postgres prerequisite"

require_substring "${docker_dx}" "http://localhost:8080/dashboard/" "dashboard URL with trailing slash"
require_substring "${docker_dx}" "INSTANCE must be DNS-safe" "DNS-safe instance guidance"
require_substring "${docker_dx}" "Docker socket" "Docker socket sensitivity note"
require_substring "${docker_dx}" "docker compose port db 5432" "DB GUI ephemeral port discovery"
require_substring "${docker_dx}" "DOCKER_DEFAULT_PLATFORM" "emulation footgun"
reject_substring "${docker_dx}" "http://localhost:8080 shows" "stale dashboard URL"

require_substring "${env_example}" "COMPOSE_PROJECT_NAME=accrue-host" "Compose project variable"
require_substring "${env_example}" "PGPORT=55432" "non-default DB GUI port example"
reject_substring "${env_example}" "ACCRUE_HOST_COMPOSE_PROJECT" "retired instance variable"

default_config="$(compose_config accrue-host accrue.localhost)"
instance_config="$(compose_config accrue-foo accrue-foo.localhost)"

require_no_db_ports "${default_config}" "default"
require_no_db_ports "${instance_config}" "INSTANCE=accrue-foo"

require_config_substring "${default_config}" "name: accrue-host" "default project name"
require_config_substring "${default_config}" "traefik.http.routers.accrue-host.rule: Host(\`accrue.localhost\`)" "default Traefik host rule"
require_config_substring "${default_config}" "name: proxy" "external proxy network"
require_config_substring "${default_config}" "external: true" "external proxy network flag"
require_config_substring "${default_config}" "host_ip: 127.0.0.1" "loopback-only ephemeral fallback"
require_config_substring "${default_config}" "target: /workspace/accrue/deps" "accrue deps shadow volume"
require_config_substring "${default_config}" "target: /workspace/accrue/_build" "accrue build shadow volume"
require_config_substring "${default_config}" "target: /workspace/accrue_admin/deps" "accrue_admin deps shadow volume"
require_config_substring "${default_config}" "target: /workspace/accrue_admin/_build" "accrue_admin build shadow volume"
require_config_substring "${default_config}" "target: /workspace/accrue_portal/deps" "accrue_portal deps shadow volume"
require_config_substring "${default_config}" "target: /workspace/accrue_portal/_build" "accrue_portal build shadow volume"
require_config_substring "${default_config}" "target: /root/.hex" "Hex download cache"
require_config_substring "${default_config}" "target: /root/.npm" "npm download cache"

if grep -Fq "target: /root/.mix" <<<"${default_config}"; then
  fail "rendered compose config mounts over /root/.mix"
fi

require_config_substring "${instance_config}" "name: accrue-foo" "instance project name"
require_config_substring "${instance_config}" "traefik.http.routers.accrue-foo.rule: Host(\`accrue-foo.localhost\`)" "instance Traefik host rule"
require_config_substring "${instance_config}" "name: accrue-foo_pgdata" "instance-scoped db volume"
require_config_substring "${instance_config}" "name: accrue-foo_mix_deps" "instance-scoped deps volume"

echo "verify_docker_dx_contract: OK"
