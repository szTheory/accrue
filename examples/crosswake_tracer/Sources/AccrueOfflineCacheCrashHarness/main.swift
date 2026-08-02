import Foundation
import CryptoKit
import AccrueOfflineClient

let arguments = CommandLine.arguments

guard arguments.count == 6,
      let keyText = ProcessInfo.processInfo.environment["ACCRUE_CACHE_TEST_KEY_BASE64"],
      let keyData = Data(base64Encoded: keyText),
      let disposition = AtomicOfflineCache.Disposition(rawValue: arguments[3]),
      let revision = Int64(arguments[4]),
      ["replace", "crash-before-rename", "crash-after-directory-sync"].contains(arguments[2])
else {
    fputs("usage: AccrueOfflineCacheCrashHarness <cache-path> <replace|crash-before-rename|crash-after-directory-sync> <allow|deny> <revision> <payload>\n", stderr)
    exit(64)
}

let cache = AtomicOfflineCache(url: URL(fileURLWithPath: arguments[1]), authenticationKey: SymmetricKey(data: keyData))
let payload = Data(arguments[5].utf8)
switch arguments[2] {
case "replace": try cache.replace(with: payload, disposition: disposition, revision: revision)
case "crash-before-rename": try cache.replace(with: payload, disposition: disposition, revision: revision, fault: .beforeRename)
default: try cache.replace(with: payload, disposition: disposition, revision: revision, fault: .afterRename)
}
