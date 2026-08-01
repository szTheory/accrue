# Physical-device evidence record

**Record status:** blocked pending an authoritative Crosswake shell/core and an approved physical-device run.

## Run metadata

| Field | Value |
|---|---|
| Date (UTC) | `YYYY-MM-DD` |
| Crosswake source | Pinned repository URL and immutable revision; unavailable as of 2026-07-31 |
| Crosswake version | Pinned version; unavailable as of 2026-07-31 |
| Build invocation | Exact checked command; unavailable until the authoritative source is supplied |
| Device class | Model family and OS major/minor only; never a device identifier |
| Tester role | Maintainer role only; no adopter identity |
| Reviewer | Name or team alias with approval date |

## Required dated observations

Record the command, pass/fail result, and a redacted evidence location for every lane.

| Lane | Command / scenario | Required result | Result | Evidence location | Reviewer |
|---|---|---|---|---|---|
| Secure Enclave P-256 | Create non-exportable key, register public-key thumbprint, complete nonce proof | Private key cannot be exported; authenticated registration succeeds | Pending | Redacted approved location | Pending |
| Keychain `ThisDeviceOnly` | Verify secure state is excluded from migration/restore | State does not migrate | Pending | Redacted approved location | Pending |
| Lifecycle recovery | Foreground, background, and restart recovery | Authenticated reconciliation is coalesced; no local grant | Pending | Redacted approved location | Pending |
| Atomic replacement | Terminate during a verified newer allow and signed denial replacement | Recovery exposes only a complete verified state | Pending | Redacted approved location | Pending |
| Authenticated shell transport | Exercise the pinned Crosswake shell/core bridge | Account/device/nonce proof is authenticated | Pending | Redacted approved location | Pending |
| Reconnect recovery | Disconnect and reconnect through the pinned bridge | Reconciliation resumes without reachability granting access | Pending | Redacted approved location | Pending |

## Redaction attestation

I attest that this record contains no device identifier, private key, raw receipt, raw JWS, provider payload, adopter identity, or other PII. The linked evidence is redacted to command/result metadata and approved before this record changes from blocked.

- Attestor: `pending`
- Attested date (UTC): `YYYY-MM-DD`
- Reviewer approval: `pending`
