#!/usr/bin/env bash
set -euo pipefail

# Lean idempotent container boot for the Accrue admin-UI demo.
#
# Replaces the per-boot `mix setup` sledgehammer: each step is guarded so that a
# warm checkout (named volumes already populated) skips npm install and the
# first-paint asset build. Watchers own rebuilds once the server is running.

cd /workspace/examples/accrue_host

echo "[entrypoint] assets.setup (skipped if node_modules warm)"
[ -d assets/node_modules/.bin ] || mix assets.setup

echo "[entrypoint] deps.get"
mix deps.get

echo "[entrypoint] ecto.create"
mix ecto.create --quiet

echo "[entrypoint] ecto.migrate"
mix ecto.migrate

echo "[entrypoint] seeds (idempotent)"
mix run priv/repo/seeds.exs

echo "[entrypoint] assets.build (first paint only; watchers rebuild after)"
[ -d priv/static/assets ] || mix assets.build

echo "[entrypoint] starting Phoenix"
exec mix phx.server
