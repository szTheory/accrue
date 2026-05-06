#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/accrue-rendro-XXXXXX")"
CLONE_DIR="$TMP_DIR/checkout"
PATCH_FILE="$TMP_DIR/worktree.patch"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

echo "[verify_rendro_hex_resolution] cloning repository into $CLONE_DIR"
git clone "$ROOT_DIR" "$CLONE_DIR" >/dev/null 2>&1

if ! git -C "$ROOT_DIR" diff --quiet HEAD --; then
  echo "[verify_rendro_hex_resolution] applying current workspace diff into clone"
  git -C "$ROOT_DIR" diff --binary HEAD -- >"$PATCH_FILE"
  git -C "$CLONE_DIR" apply "$PATCH_FILE"
fi

if rg -n '\.\./\.\./rendro' "$CLONE_DIR/accrue/mix.exs"; then
  echo "ERROR: accrue/mix.exs still references ../../rendro"
  exit 1
fi

pushd "$CLONE_DIR/accrue" >/dev/null

echo "[verify_rendro_hex_resolution] running mix deps.get"
mix deps.get >/dev/null

echo "[verify_rendro_hex_resolution] checking mix deps.tree for rendro"
DEPS_TREE_OUTPUT="$(mix deps.tree)"
echo "$DEPS_TREE_OUTPUT"

if ! grep -q 'rendro' <<<"$DEPS_TREE_OUTPUT"; then
  echo "ERROR: mix deps.tree did not show rendro"
  exit 1
fi

if rg -n '\.\./\.\./rendro' mix.exs; then
  echo "ERROR: cloned accrue/mix.exs still references ../../rendro after deps.get"
  exit 1
fi

popd >/dev/null

echo "[verify_rendro_hex_resolution] ok"
