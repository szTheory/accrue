import Foundation
import AccrueOfflineClient

// Test-only process boundary for deterministic cache crash points. It accepts only
// a canonical target path, replacement bytes, and one bounded fault-point token.
guard CommandLine.arguments.count == 4,
      let point = ["before-rename", "after-directory-sync"].first(where: { $0 == CommandLine.arguments[3] })
else {
    fputs("usage: AccrueOfflineCacheCrashHarness <cache-path> <payload> <before-rename|after-directory-sync>\n", stderr)
    exit(64)
}

let url = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
let payload = Data(CommandLine.arguments[2].utf8)
let cache = AtomicOfflineCache(url: url)

if point == "before-rename" {
    let candidate = url.deletingLastPathComponent()
        .appendingPathComponent(".\(url.lastPathComponent).candidate.crash-harness")
    try payload.write(to: candidate)
    fatalError("deterministic crash before rename")
}

do {
    try cache.replace(with: payload, fault: .afterRename)
} catch {
    // The cache has completed candidate sync, rename, and parent-directory sync.
    fatalError("deterministic crash after directory sync")
}
