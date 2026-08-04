import Foundation
import CryptoKit
import AccrueOfflineClient

let arguments = CommandLine.arguments

guard arguments.count == 4,
      let keyText = ProcessInfo.processInfo.environment["ACCRUE_CACHE_TEST_KEY_BASE64"],
      let keyData = Data(base64Encoded: keyText),
      ["replace", "crash-before-rename", "crash-after-directory-sync"].contains(arguments[2])
else {
    fputs("usage: AccrueOfflineCacheCrashHarness <cache-path> <replace|crash-before-rename|crash-after-directory-sync> <fixture-id>\n", stderr)
    exit(64)
}

let cache = AtomicOfflineCache(url: URL(fileURLWithPath: arguments[1]), authenticationKey: SymmetricKey(data: keyData))
switch arguments[2] {
case "replace": try OfflineGoldenVectorVerifier.replaceVerifiedFixture(arguments[3], in: cache)
case "crash-before-rename": try OfflineGoldenVectorVerifier.replaceVerifiedFixture(arguments[3], in: cache, fault: .beforeRename)
default: try OfflineGoldenVectorVerifier.replaceVerifiedFixture(arguments[3], in: cache, fault: .afterRename)
}
