// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CrosswakeTracer",
    products: [
        .library(name: "AccrueOfflineClient", targets: ["AccrueOfflineClient"])
    ],
    targets: [
        .target(name: "AccrueOfflineClient"),
        .testTarget(
            name: "AccrueOfflineClientTests",
            dependencies: ["AccrueOfflineClient"]
        )
    ]
)
