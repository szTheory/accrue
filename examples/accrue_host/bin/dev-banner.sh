#!/usr/bin/env bash
set -euo pipefail

# Host-side launch banner for the Accrue admin-UI demo.
#
# Advertises the STABLE URL the shared Traefik proxy routes to
# (http://accrue.localhost/admin) and the ephemeral loopback FALLBACK Docker
# assigned (used when the proxy isn't running). Readiness is polled against the
# loopback, which always resolves even without *.localhost DNS.
#
# Usage:
#   bin/dev-banner.sh             print the full banner once the server is up
#   bin/dev-banner.sh --url-only  print the best single URL (for `make open`)

# Run from the directory that holds docker-compose.yml so `docker compose` resolves.
cd "$(dirname "$0")/.."

ACCRUE_HOST="${ACCRUE_HOST:-accrue.localhost}"
STABLE_URL="http://${ACCRUE_HOST}"

resolve_port() {
  # `docker compose port web 4000` prints e.g. "127.0.0.1:49183"; take the port.
  local mapping
  mapping="$(docker compose port web 4000 2>/dev/null || true)"
  printf '%s' "${mapping##*:}"
}

PORT="$(resolve_port)"

if [ -z "$PORT" ]; then
  echo "web container not up yet — run \`make up\` first" >&2
  exit 1
fi

# Always advertise 127.0.0.1 for the fallback, even when the container bound 0.0.0.0.
FALLBACK_URL="http://127.0.0.1:${PORT}"

proxy_up() {
  # Hit Traefik on :80 with the Host header so this works even when the OS won't
  # resolve *.localhost (curl/Safari). A completed connection counts as routed.
  curl -s -o /dev/null --max-time 2 -H "Host: ${ACCRUE_HOST}" "http://127.0.0.1/" 2>/dev/null
}

if [ "${1:-}" = "--url-only" ]; then
  # Prefer the stable URL when the proxy is routing; otherwise the loopback.
  if proxy_up; then printf '%s\n' "$STABLE_URL"; else printf '%s\n' "$FALLBACK_URL"; fi
  exit 0
fi

# Poll the loopback until the server answers. A completed connection counts as
# "up" — `/` may return a 4xx, so we do not require a 2xx (no `-f`).
printf 'starting'
for _ in $(seq 1 30); do
  if curl -s -o /dev/null --max-time 2 "${FALLBACK_URL}/"; then
    printf '\n'
    break
  fi
  printf '.'
  sleep 1
done

if proxy_up; then
  PRIMARY_LINE="  ${STABLE_URL}/admin"
  PROXY_NOTE="  (stable URL via the shared Traefik proxy — bookmark it)"
else
  PRIMARY_LINE="  ${FALLBACK_URL}/admin"
  PROXY_NOTE="  (shared proxy not running — run \`make proxy\` once for http://${ACCRUE_HOST}/admin)"
fi

cat <<BANNER

==============================================================================
Accrue admin-UI demo is up:

${PRIMARY_LINE}
${PROXY_NOTE}

  Fallback (proxy down / Safari / curl): ${FALLBACK_URL}/admin

Key routes (append to the URL above):
  /admin                  mounted Accrue Admin UI
  /billing                mounted billing portal
  /app/billing            host billing screen
  /app/reports/advanced   entitlement-gated reports
  /users/log-in           sign in
  /dev/mailbox            sent-email preview

Seeded demo logins (password for ALL: accrue-demo-password):
  healthy@example.com      clean, subscribed (no dunning banner)
  past-due@example.com     past_due, dunning campaign active
  canceled@example.com     canceled subscription
  enterprise@example.com   premium plan + JPY invoice showcase
  trialing@example.com     trialing subscription

Handy commands:
  make open   make url   make logs   make psql   make sh   make down
==============================================================================
BANNER
