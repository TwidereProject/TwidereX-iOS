// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TwidereSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TwidereSDK",
            type: .dynamic,
            targets: ["TwitterSDK", "MastodonSDK"]),
        .library(
            name: "TwidereCommon",
            targets: ["TwidereCommon"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "TwitterSDK",
            dependencies: [
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]
        ),
        .target(
            name: "MastodonSDK",
            dependencies: [
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]
        ),
        .target(
            name: "TwidereCommon",
            dependencies: []
        ),
        .testTarget(
            name: "TwitterSDKTests",
            dependencies: ["TwitterSDK"]
        ),
    ]
)
