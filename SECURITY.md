# Security Policy

Accrue treats billing data paths, webhook verification, and release automation as
security-sensitive surfaces. Report suspected vulnerabilities privately so we
can validate and coordinate a fix before disclosure.

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 1.x     | Yes       |
| main    | Yes       |

## Reporting a Vulnerability

Email security@accrue.dev with:

- a description of the issue
- affected package and version
- reproduction steps or proof-of-concept details
- impact assessment, if known

Do not open a public GitHub issue for unpatched vulnerabilities.

We will acknowledge receipt, triage severity, and coordinate remediation and
disclosure timing through the private report.

## Secret Handling

Webhook secrets, Hex API keys, and Release Please tokens must never be
committed to the repository or printed in CI logs.

Keep Stripe API keys, signing secrets, and release credentials in runtime
environment variables or the CI secret store. Sanitize examples, screenshots,
and copied terminal output before sharing them in issues, pull requests, docs,
or chat.
