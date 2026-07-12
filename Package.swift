// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SearchKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SearchKit", targets: ["SearchKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/carlosypunto/SQLiteVecKit", exact: "0.1.0")
    ],
    targets: [
        .target(
            name: "SearchKit",
            dependencies: [
                .product(name: "SQLiteVecStore", package: "SQLiteVecKit")
            ]
        ),
        .testTarget(
            name: "SearchKitTests",
            dependencies: ["SearchKit"]
        )
    ]
)
