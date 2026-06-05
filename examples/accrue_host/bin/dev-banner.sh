#!/usr/bin/env bash
set -euo pipefail

# Host-side launch banner for the Accrue admin-UI demo.
#
# Resolves the live (ephemeral) host port Docker assigned to the web container,
# waits for the server to answer, then prints a copy-pasteable block of the live
# URL, the real mounted routes, and the seeded demo logins.
#
# Usage:
#   bin/dev-banner.sh             print the full banner once the server is up
#   bin/dev-banner.sh --url-only  print only the base URL (for `make open` / scripts)

# Run from the directory that holds docker-compose.yml so `docker compose` resolves.
cd "$(dirname "$0")/.."

resolve_port() {
  # `docker compose port web 4000` prints e.g. "0.0.0.0:49183" or "127.0.0.1:49183".
  local mapping
  mapping="$(docker compose port web 4000 2>/dev/null || true)"
  # Parse the trailing :PORT segment.
  printf '%s' "${mapping##*:}"
}

PORT="$(resolve_port)"

if [ -z "$PORT" ]; then
  echo "web container not up yet — run \`make up\` first" >&2
  exit 1
fi

# Always advertise 127.0.0.1 for the browser, even when the container bound 0.0.0.0.
BASE_URL="http://127.0.0.1:${PORT}"

if [ "${1:-}" = "--url-only" ]; then
  printf '%s\n' "$BASE_URL"
  exit 0
fi

# Poll until the server answers. A completed connection counts as "up" — `/` may
# return a 4xx, so we do not require a 2xx (no `-f`).
printf 'starting'
for _ in $(seq 1 30); do
  if curl -s -o /dev/null --max-time 2 "${BASE_URL}/"; then
    printf '\n'
    break
  fi
  printf '.'
  sleep 1
done

cat <<BANNER

==============================================================================
Accrue admin-UI demo is up:

  ${BASE_URL}

Key routes:
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
  make open   make logs   make psql   make sh   make down
==============================================================================
BANNER
