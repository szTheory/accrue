// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CrosswakeTracer",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "AccrueOfflineClient", targets: ["AccrueOfflineClient"]),
        .executable(name: "AccrueOfflineCacheCrashHarness", targets: ["AccrueOfflineCacheCrashHarness"])
    ],
    targets: [
        .target(name: "AccrueOfflineClient"),
        .executableTarget(
            name: "AccrueOfflineCacheCrashHarness",
            dependencies: ["AccrueOfflineClient"]
        ),
        .testTarget(
            name: "AccrueOfflineClientTests",
            dependencies: ["AccrueOfflineClient"]
        )
    ]
)
