// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AccrueOfflineClientCore",
    platforms: [.macOS(.v10_15), .iOS(.v16)],
    products: [.library(name: "AccrueOfflineClientCore", targets: ["AccrueOfflineClientCore"])],
    targets: [
        .target(name: "AccrueOfflineClientCore"),
        .executableTarget(name: "AccrueOfflineCacheCrashHarness", dependencies: ["AccrueOfflineClientCore"]),
        .testTarget(name: "AccrueOfflineClientCoreTests", dependencies: ["AccrueOfflineClientCore"]),
        .testTarget(name: "AccrueOfflineClientProcessTests", dependencies: ["AccrueOfflineClientCore"])
    ]
)
