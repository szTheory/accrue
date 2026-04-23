# Phase 59 — Pattern map

Analogs for executor agents — closest existing implementations.

| Intent | Target / artifact | Closest analog | Notes |
|--------|-------------------|----------------|-------|
| Doc contract script | `scripts/ci/verify_package_docs.sh` | Self — extend with `require_fixed` / `require_absent_regex` for `quickstart.md` | Follow `extract_version`, `fail`, `require_fixed` patterns already used for `first_hour.md`. |
| ExUnit doc gate | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | Existing `ROOT_DIR` tmp-dir tests | Copy `quickstart.md` into fixture tree when tests assert full-repo behavior. |
| Trust / Sigra framing | `accrue/guides/first_hour.md` | `examples/accrue_host/README.md` opening blockquote | Do not duplicate host README; **link** out per **59-CONTEXT D-06**. |
| Thin hub | `accrue/guides/quickstart.md` | **51-03** quickstart constraints | Stay hub-only; one line to **`auth_adapters.md`**. |
| CONTRIBUTING verifier map | `CONTRIBUTING.md` | Existing paragraph referencing `scripts/ci/README.md` | Append **ordered** bash trio for golden-path editors (**D-13**). |

## PATTERN MAPPING COMPLETE
