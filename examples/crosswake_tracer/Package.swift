// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AccrueOfflineClient",
    platforms: [.macOS(.v10_15), .iOS(.v16)],
    products: [
        .library(name: "AccrueOfflineClientTracer", targets: ["AccrueOfflineClient"])
    ],
    dependencies: [
        .package(path: "../../packages/accrue-offline-client")
    ],
    targets: [
        .target(
            name: "AccrueOfflineClient",
            dependencies: [
                .product(name: "AccrueOfflineClientCore", package: "accrue-offline-client")
            ]
        ),
        .testTarget(
            name: "AccrueOfflineClientTracerTests",
            dependencies: ["AccrueOfflineClient"]
        )
    ]
)
