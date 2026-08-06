// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AccrueOfflineClientCore",
    platforms: [.macOS(.v10_15), .iOS(.v16)],
    products: [
        .library(name: "AccrueOfflineClientCore", targets: ["AccrueOfflineClientCore"]),
        .library(name: "AccrueOfflineClientApple", targets: ["AccrueOfflineClientApple"])
    ],
    targets: [
        .target(name: "AccrueOfflineClientCore"),
        .target(name: "AccrueOfflineClientApple"),
        .executableTarget(name: "AccrueOfflineCacheCrashHarness", dependencies: ["AccrueOfflineClientCore"]),
        .testTarget(name: "AccrueOfflineClientCoreTests", dependencies: ["AccrueOfflineClientCore"]),
        .testTarget(name: "AccrueOfflineClientAppleTests", dependencies: ["AccrueOfflineClientApple"]),
        .testTarget(name: "AccrueOfflineClientProcessTests", dependencies: ["AccrueOfflineClientCore"])
    ]
)
