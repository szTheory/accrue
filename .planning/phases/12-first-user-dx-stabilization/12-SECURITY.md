---
phase: 12
slug: first-user-dx-stabilization
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-16
---

# Phase 12 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| docs/tests -> published docs | Contract tests and verifier script constrain first-user docs, package metadata, and remediation links. | Public setup guidance, versions, guide links, diagnostic anchors |
| installer -> host-owned files | `mix accrue.install` writes generated code and conflict sidecars into host apps. | Host code, config, conflict artifacts |
| host router/config -> setup diagnostics | Installer preflight and boot checks infer whether webhook/auth/admin wiring is safe. | Router text, runtime config, migration state |
| webhook request -> webhook plug | Signature headers and request bodies are attacker-controlled until verification succeeds. | Raw body bytes, signature header, endpoint secret selection |
| host UI -> host billing facade | Host LiveView reads billing state through host-owned facade helpers instead of package-private tables. | Current user scope, customer/subscription state |
| CI/scripts -> package and host release surfaces | CI and shell verifiers prove path-mode and Hex-mode surfaces separately. | Package versions, ExDoc metadata, host dependency mode |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-12-01-01 | Security Misconfiguration | docs contract tests | mitigate | Public/forbidden doc boundaries are enforced in `accrue/test/accrue/docs/first_hour_guide_test.exs:18` and `accrue/test/accrue/docs/first_hour_guide_test.exs:27`. | closed |
| T-12-01-02 | Information Disclosure | package-doc verifier scaffold | mitigate | Verifier only parses versions, refs, and links in `scripts/ci/verify_package_docs.sh:14` and `scripts/ci/verify_package_docs.sh:46`. | closed |
| T-12-01-03 | Repudiation | troubleshooting guide contract | mitigate | Exact diagnostic codes and anchors are locked in `accrue/test/accrue/docs/troubleshooting_guide_test.exs:5`. | closed |
| T-12-01-04 | Elevation of Privilege | admin/docs guidance | mitigate | First Hour guide keeps admin mount on host auth boundary in `accrue/guides/first_hour.md:115` and `accrue/test/accrue/docs/first_hour_guide_test.exs:18`. | closed |
| T-12-02-01 | Tampering | installer test contract | mitigate | No-clobber and summary taxonomy are enforced in `accrue/test/mix/tasks/accrue_install_test.exs:284` and `accrue/test/mix/tasks/accrue_install_test.exs:311`. | closed |
| T-12-02-02 | Information Disclosure | future conflict artifacts | mitigate | Conflict artifacts are rooted under `.accrue/conflicts` with header-only metadata in `accrue/test/mix/tasks/accrue_install_test.exs:340` and `accrue/test/mix/tasks/accrue_install_uat_test.exs:155`. | closed |
| T-12-02-03 | Security Misconfiguration | Hex smoke scaffold | mitigate | Canonical Hex mode remains a single host app gated by `ACCRUE_HOST_HEX_RELEASE=1` in `scripts/ci/accrue_host_hex_smoke.sh:9`. | closed |
| T-12-03-01 | Tampering | `accrue/lib/accrue/install/fingerprints.ex` | mitigate | Stamped user-edited files stay skipped before `--force` in `accrue/lib/accrue/install/fingerprints.ex:62` and `accrue/lib/accrue/install/fingerprints.ex:66`. | closed |
| T-12-03-02 | Information Disclosure | `.accrue/conflicts/*` artifacts | mitigate | Template and patch conflicts are written only under `.accrue/conflicts/templates` and `.accrue/conflicts/patches` with `target:`/`reason:` headers in `accrue/lib/accrue/install/fingerprints.ex:79`, `accrue/lib/accrue/install/fingerprints.ex:93`, and `accrue/lib/accrue/install/fingerprints.ex:145`. | closed |
| T-12-03-03 | Denial of Service | installer summary output | mitigate | Summary categories are emitted exactly in `accrue/lib/mix/tasks/accrue.install.ex:214` and `accrue/lib/mix/tasks/accrue.install.ex:238`. | closed |
| T-12-04-01 | Security Misconfiguration | `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | mitigate | LiveView loads state through `Billing.billing_state_for/1` in `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:172`. | closed |
| T-12-04-02 | Elevation of Privilege | host billing facade | mitigate | Host-owned facade exposes explicit policy hook functions in `examples/accrue_host/lib/accrue_host/billing.ex:17` and `examples/accrue_host/lib/accrue_host/billing.ex:39`. | closed |
| T-12-04-03 | Repudiation | host billing tests | mitigate | `billing_state_for/1` behavior is proved in `examples/accrue_host/test/accrue_host/billing_facade_test.exs:66` and `examples/accrue_host/test/accrue_host/billing_facade_test.exs:70`. | closed |
| T-12-05-01 | Information Disclosure | `setup_diagnostic.ex` and `webhook/plug.ex` | mitigate | Secret redaction patterns and formatting are in `accrue/lib/accrue/setup_diagnostic.ex:28`, `accrue/lib/accrue/setup_diagnostic.ex:147`, and `accrue/test/accrue/webhook/plug_test.exs:215`. | closed |
| T-12-05-02 | Tampering | `accrue/lib/accrue/webhook/plug.ex` | mitigate | Signature verification stays on raw body path and bad signatures stay generic 400 in `accrue/lib/accrue/webhook/plug.ex:64`, `accrue/lib/accrue/webhook/plug.ex:72`, and `accrue/test/accrue/webhook/plug_test.exs:135`. | closed |
| T-12-05-03 | Elevation of Privilege | `accrue/lib/accrue/auth/default.ex` and installer preflight | mitigate | Default auth fails closed in prod in `accrue/lib/accrue/auth/default.ex:53` and `accrue/lib/accrue/auth/default.ex:84`; installer `--check` detects missing host auth/admin wiring in `accrue/lib/mix/tasks/accrue.install.ex:317` and `accrue/lib/mix/tasks/accrue.install.ex:325`. | closed |
| T-12-05-04 | Security Misconfiguration | installer preflight | mitigate | Stable setup diagnostics for route, raw body, pipeline, auth, admin, and Oban are built in `accrue/lib/mix/tasks/accrue.install.ex:293`. | closed |
| T-12-06-01 | Security Misconfiguration | public docs | mitigate | Public docs stay on host-facing surfaces in `accrue/guides/first_hour.md:102`, `accrue/guides/first_hour.md:115`, and `accrue/test/accrue/docs/first_hour_guide_test.exs:18`. | closed |
| T-12-06-02 | Information Disclosure | troubleshooting and webhook guides | mitigate | Guides use stable codes, public fixes, and placeholder secrets in `accrue/guides/troubleshooting.md:7`, `accrue/guides/troubleshooting.md:99`, and `accrue/guides/webhooks.md:45`. | closed |
| T-12-06-03 | Elevation of Privilege | admin guide | mitigate | Admin guide keeps `/billing` behind host session keys and `Accrue.Auth` boundary in `accrue_admin/guides/admin_ui.md:48`. | closed |
| T-12-07-01 | Repudiation | package-doc verification script | mitigate | Verifier parses versions directly from `mix.exs` in `scripts/ci/verify_package_docs.sh:14`. | closed |
| T-12-07-02 | Tampering | package README and ExDoc metadata | mitigate | Source-ref and guide expectations derive from package metadata in `scripts/ci/verify_package_docs.sh:51`, `accrue/mix.exs:130`, and `accrue_admin/mix.exs:62`. | closed |
| T-12-07-03 | Information Disclosure | verifier output | mitigate | Script output is limited to versions and file/link failures in `scripts/ci/verify_package_docs.sh:9` and `scripts/ci/verify_package_docs.sh:75`. | closed |
| T-12-08-01 | Security Misconfiguration | `examples/accrue_host/mix.exs` | mitigate | Host dependency mode is gated only by `ACCRUE_HOST_HEX_RELEASE=1` in `examples/accrue_host/mix.exs:74` and `examples/accrue_host/mix.exs:90`. | closed |
| T-12-08-02 | Denial of Service | `scripts/ci/accrue_host_hex_smoke.sh` | mitigate | Hex smoke remains narrow to deps/install/compile/migrate/two proof files in `scripts/ci/accrue_host_hex_smoke.sh:11`. | closed |
| T-12-08-03 | Repudiation | `.github/workflows/ci.yml` | mitigate | CI keeps path-mode UAT primary and Hex smoke separate in `.github/workflows/ci.yml:315`. | closed |
| T-12-09-01 | Security Misconfiguration | `accrue/lib/mix/tasks/accrue.install.ex` | mitigate | Webhook pipeline misuse is scoped to the actual webhook route context in `accrue/lib/mix/tasks/accrue.install.ex:362` and `accrue/lib/mix/tasks/accrue.install.ex:422`. | closed |
| T-12-09-02 | Information Disclosure | `accrue/lib/accrue/config.ex` | mitigate | Migration lookup failures raise shared redacted diagnostics in `accrue/lib/accrue/config.ex:491` and `accrue/lib/accrue/config.ex:719`; secret redaction is regression-tested in `accrue/test/accrue/config_test.exs:143`. | closed |
| T-12-09-03 | Tampering | installer/config tests | mitigate | Valid-router and no-silent-`:ok` regressions are covered in `accrue/test/mix/tasks/accrue_install_uat_test.exs:197` and `accrue/test/accrue/config_test.exs:143`. | closed |
| T-12-09-04 | Denial of Service | boot validation | accept | Accepted risk documented below: unexpected migration inspection errors still stop boot by design, while expected failures map to `ACCRUE-DX-MIGRATIONS-PENDING` in `accrue/lib/accrue/config.ex:498` and `accrue/test/accrue/config_test.exs:157`. | closed |
| T-12-10-01 | Security Misconfiguration | `first_hour.md`, `troubleshooting.md` | mitigate | Both guides now use plural `:webhook_signing_secrets` snippets in `accrue/guides/first_hour.md:45` and `accrue/guides/troubleshooting.md:100`. | closed |
| T-12-10-02 | Repudiation | `verify_package_docs.sh` | mitigate | Verifier enforces plural presence and singular absence in `scripts/ci/verify_package_docs.sh:67`. | closed |
| T-12-10-03 | Information Disclosure | troubleshooting remediation text | mitigate | Published examples use env-var names and placeholder `whsec_test_host` only in `accrue/guides/troubleshooting.md:97`. | closed |
| T-12-10-04 | Tampering | docs/package tests | mitigate | Existing docs/package tests were extended, not replaced, in `accrue/test/accrue/docs/first_hour_guide_test.exs:24`, `accrue/test/accrue/docs/troubleshooting_guide_test.exs:41`, and `accrue/test/accrue/docs/package_docs_verifier_test.exs:13`. | closed |
| T-12-11-01 | Security Misconfiguration | `accrue/guides/troubleshooting.md` | mitigate | Missing remediation sections now exist for the five gap anchors in `accrue/guides/troubleshooting.md:132`, `accrue/guides/troubleshooting.md:167`, `accrue/guides/troubleshooting.md:201`, `accrue/guides/troubleshooting.md:246`, and `accrue/guides/troubleshooting.md:278`. | closed |
| T-12-11-02 | Tampering | `accrue/test/accrue/docs/troubleshooting_guide_test.exs` | mitigate | Full ten-anchor surface is locked in `accrue/test/accrue/docs/troubleshooting_guide_test.exs:5`. | closed |
| T-12-11-03 | Repudiation | docs-link contract between diagnostics and guide | mitigate | Diagnostic codes and anchors are authoritative in one test file and one diagnostic module: `accrue/test/accrue/docs/troubleshooting_guide_test.exs:5` and `accrue/lib/accrue/setup_diagnostic.ex:20`. | closed |
| T-12-11-04 | Information Disclosure | troubleshooting fix text | mitigate | Troubleshooting fixes stay on env names, commands, and public host surfaces in `accrue/guides/troubleshooting.md:147`, `accrue/guides/troubleshooting.md:181`, and `accrue/guides/troubleshooting.md:260`. | closed |
| T-12-11-05 | Denial of Service | misdirected remediation for webhook/admin setup | block | Broken remediation links are blocked by exact emitted anchors in `accrue/lib/accrue/setup_diagnostic.ex:20` and the guide/test inventory in `accrue/guides/troubleshooting.md:132` and `accrue/test/accrue/docs/troubleshooting_guide_test.exs:17`. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party) · block (phase-defined blocker)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-12-01 | T-12-09-04 | Unexpected migration inspection exceptions still stop boot. That loud failure is intentional because it avoids a false-green startup on a broken setup path. | gsd-security-auditor | 2026-04-16 |

---

## Unregistered Flags

None. Phase 12 summary files did not declare any `## Threat Flags` entries that required separate registration.

---

## Verification Evidence

- `bash scripts/ci/verify_package_docs.sh`
- `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/troubleshooting_guide_test.exs`
- `cd accrue && mix test test/accrue/config_test.exs test/accrue/auth_test.exs test/accrue/webhook/plug_test.exs`
- `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs`
- `bash scripts/ci/accrue_host_hex_smoke.sh`
- `cd examples/accrue_host && MIX_ENV=test mix test test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs`

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-16 | 39 | 39 | 0 | Codex gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition recorded from the phase plans
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-16
