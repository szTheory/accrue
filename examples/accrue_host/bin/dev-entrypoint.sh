#!/usr/bin/env bash
set -euo pipefail

# Lean idempotent container boot for the Accrue admin-UI demo.
#
# Replaces the per-boot `mix setup` sledgehammer: each step is guarded so that a
# warm checkout (named volumes already populated) skips npm install and the
# first-paint asset build. Watchers own rebuilds once the server is running.

cd /workspace/examples/accrue_host

hash_files() {
  find "$@" -type f -print0 \
    | sort -z \
    | xargs -0 -r sha256sum \
    | sha256sum \
    | awk '{print $1}'
}

asset_setup_hash() {
  hash_files assets/package.json assets/package-lock.json
}

asset_build_hash() {
  hash_files assets/package.json assets/package-lock.json assets/css assets/js assets/vendor config/config.exs config/dev.exs mix.exs
}

asset_setup_current() {
  local marker="assets/node_modules/.accrue-assets-setup.sha256"
  local current

  current="$(asset_setup_hash)"
  [ -d assets/node_modules/.bin ] && [ -f "$marker" ] && [ "$(cat "$marker")" = "$current" ]
}

asset_build_current() {
  local marker="priv/static/assets/.accrue-assets-build.sha256"
  local current

  current="$(asset_build_hash)"
  [ -d priv/static/assets ] && [ -f "$marker" ] && [ "$(cat "$marker")" = "$current" ]
}

mark_asset_setup_current() {
  mkdir -p assets/node_modules
  asset_setup_hash > assets/node_modules/.accrue-assets-setup.sha256
}

mark_asset_build_current() {
  mkdir -p priv/static/assets
  asset_build_hash > priv/static/assets/.accrue-assets-build.sha256
}

echo "[entrypoint] deps.get"
mix deps.get

if asset_setup_current; then
  echo "[entrypoint] assets.setup (package manifests unchanged)"
else
  echo "[entrypoint] assets.setup"
  mix assets.setup
  mark_asset_setup_current
fi

echo "[entrypoint] ecto.create"
mix ecto.create --quiet

echo "[entrypoint] ecto.migrate"
mix ecto.migrate

if [ "${ACCRUE_HOST_SKIP_SEEDS:-}" = "1" ]; then
  echo "[entrypoint] seeds skipped (ACCRUE_HOST_SKIP_SEEDS=1)"
else
  echo "[entrypoint] seeds (idempotent)"
  mix run priv/repo/seeds.exs
fi

if asset_build_current; then
  echo "[entrypoint] assets.build (first-paint assets current)"
else
  echo "[entrypoint] assets.build"
  mix assets.build
  mark_asset_build_current
fi

echo "[entrypoint] starting Phoenix"
exec mix phx.server
