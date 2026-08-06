import CryptoKit
import Foundation
import AccrueOfflineClientCore

let arguments = CommandLine.arguments
guard arguments.count == 4,
      let keyText = ProcessInfo.processInfo.environment["ACCRUE_CACHE_TEST_KEY_BASE64"], let key = Data(base64Encoded: keyText),
      let jwksText = ProcessInfo.processInfo.environment["ACCRUE_CACHE_JWKS_BASE64"], let jwks = Data(base64Encoded: jwksText),
      let proof = Data(base64Encoded: arguments[3])
else { exit(64) }

let cacheURL = URL(fileURLWithPath: arguments[1])
if arguments[2] == "crash-before-apply" {
    let candidate = cacheURL.deletingLastPathComponent().appendingPathComponent(".\(cacheURL.lastPathComponent).candidate.crashed-child")
    try FileManager.default.createDirectory(at: candidate.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("incomplete".utf8).write(to: candidate)
    exit(75)
}
let client = OfflineEntitlementClient(configuration: .init(
    issuer: "accrue.test.offline", audience: "accrue-offline-client", accountSubject: "synthetic-account",
    deviceThumbprint: "IVw958D_sxKYMg6iCHQs-vmxkOVIiRwwKlfeV6ykrCg", publicJWKS: jwks, cacheURL: cacheURL,
    cacheAuthenticationKey: SymmetricKey(data: key)
))
let state = client.applyServerProof(proof, now: Date(timeIntervalSince1970: 1_700_000_001))
if arguments[2] == "crash-after-apply" { exit(75) }
if case .invalid = state { exit(65) }
exit(0)
