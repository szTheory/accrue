#!/usr/bin/env bash

# Fixed, privacy-safe ownership diagnostics for the host/CI setup boundary.
set -euo pipefail

usage() {
  echo "usage: ci_setup_diagnostic.sh {describe|emit|render} CODE [--result RESULT] [--duration-ms INTEGER] [--node-identity ID] [--playwright-identity ID] [--lockfile-identity ID] [--browser-class CLASS] [--cache-state STATE]" >&2
  exit 64
}

fail() {
  echo "ci_setup_diagnostic: $*" >&2
  exit 64
}

registry() {
  case "$1" in
    node_missing_or_version)
      printf '%s\n' 'host|node preflight|Install Node 22 with your version manager, then run mix verify.full.|local host preflight stderr|host_browser_proof'
      ;;
    npm_lock_or_registry)
      printf '%s\n' 'host|npm lockfile preflight|cd examples/accrue_host && npm ci|local host preflight stderr|host_browser_proof'
      ;;
    playwright_binary_or_revision)
      printf '%s\n' 'host|Playwright browser preflight|cd examples/accrue_host && npm run e2e:install|local host preflight stderr|host_browser_proof'
      ;;
    linux_browser_dependency)
      printf '%s\n' 'CI|Linux browser dependency provisioning|Review the host-integration CI provisioning step.|GitHub Actions host-integration setup log|ci_provisioning'
      ;;
    browser_launch)
      printf '%s\n' 'host|Playwright browser launch|cd examples/accrue_host && npm run e2e|Playwright report, trace, screenshot, and host browser log|host_browser_proof'
      ;;
    port_or_server_readiness)
      printf '%s\n' 'host|Phoenix browser server readiness|cd examples/accrue_host && mix verify.full|host browser log|host_browser_proof'
      ;;
    fixture_or_database)
      printf '%s\n' 'host|browser fixture and database setup|cd examples/accrue_host && mix verify.full|local host preflight stderr|host_browser_proof'
      ;;
    *) return 1 ;;
  esac
}

valid_value() {
  [[ "$1" =~ ^[A-Za-z0-9._:-]{1,80}$ ]]
}

valid_result() {
  case "$1" in success|failure) return 0 ;; *) return 1 ;; esac
}

describe() {
  local code="$1" row owner fact next_command evidence command_identity
  row="$(registry "$code")" || fail "unknown setup code: $code"
  IFS='|' read -r owner fact next_command evidence command_identity <<<"$row"
  printf 'code=%s\nowner=%s\nfact=%s\nnext_command=%s\nevidence_location=%s\ncommand_identity=%s\n' \
    "$code" "$owner" "$fact" "$next_command" "$evidence" "$command_identity"
}

emit() {
  local code="$1"; shift
  local result='failure' duration_ms='0' node_identity='unknown' playwright_identity='unknown'
  local lockfile_identity='unknown' browser_class='unknown' cache_state='unknown'
  local option value row owner fact next_command evidence command_identity

  while [ "$#" -gt 0 ]; do
    option="$1"; shift
    [ "$#" -gt 0 ] || fail "missing value for $option"
    value="$1"; shift
    case "$option" in
      --result) result="$value" ;;
      --duration-ms) duration_ms="$value" ;;
      --node-identity) node_identity="$value" ;;
      --playwright-identity) playwright_identity="$value" ;;
      --lockfile-identity) lockfile_identity="$value" ;;
      --browser-class) browser_class="$value" ;;
      --cache-state) cache_state="$value" ;;
      *) fail "unknown emit option: $option" ;;
    esac
  done

  row="$(registry "$code")" || fail "unknown setup code: $code"
  IFS='|' read -r owner fact next_command evidence command_identity <<<"$row"
  valid_result "$result" || fail "invalid result"
  [[ "$duration_ms" =~ ^[0-9]{1,10}$ ]] || fail "invalid duration"
  for value in "$node_identity" "$playwright_identity" "$lockfile_identity" "$browser_class" "$cache_state"; do
    valid_value "$value" || fail "unsafe setup fact value"
  done

  [ -n "${ACCRUE_CI_SETUP_FACTS:-}" ] || return 0
  printf '{"schema_version":"1","code":"%s","owner":"%s","command_identity":"%s","node_identity":"%s","playwright_identity":"%s","lockfile_identity":"%s","browser_revision_or_path_class":"%s","cache_state":"%s","duration_ms":%s,"result":"%s"}\n' \
    "$code" "$owner" "$command_identity" "$node_identity" "$playwright_identity" "$lockfile_identity" "$browser_class" "$cache_state" "$duration_ms" "$result" >>"$ACCRUE_CI_SETUP_FACTS"
}

render() {
  local code="$1" row owner fact next_command evidence command_identity
  row="$(registry "$code")" || fail "unknown setup code: $code"
  IFS='|' read -r owner fact next_command evidence command_identity <<<"$row"
  printf 'SETUP_CODE=%s\nOWNER=%s\nNEXT_COMMAND=%s\nEVIDENCE_LOCATION=%s\n' \
    "$code" "$owner" "$next_command" "$evidence" >&2
}

[ "$#" -ge 2 ] || usage
command="$1"; shift
case "$command" in
  describe) [ "$#" -eq 1 ] || usage; describe "$1" ;;
  emit) [ "$#" -ge 1 ] || usage; emit "$@" ;;
  render) [ "$#" -eq 1 ] || usage; render "$1" ;;
  *) usage ;;
esac
