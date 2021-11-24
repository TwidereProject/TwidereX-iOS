// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TwidereSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TwitterSDK",
            targets: ["TwitterSDK"]
        ),
        .library(
            name: "MastodonSDK",
            targets: ["MastodonSDK"]
        ),
        .library(
            name: "TwidereAsset",
            targets: ["TwidereAsset"]
        ),
        .library(
            name: "TwidereCommon",
            targets: ["TwidereCommon"]
        ),
        .library(
            name: "TwidereCore",
            targets: ["TwidereCore"]
        ),
        .library(
            name: "TwidereLocalization",
            targets: ["TwidereLocalization"]
        ),
        .library(
            name: "TwidereUI",
            targets: ["TwidereUI"]
        ),
        .library(
            name: "CoreDataStack",
            targets: ["CoreDataStack"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.34.0"),
        .package(url: "https://github.com/Flipboard/FLAnimatedImage.git", from: "1.0.0"),
        .package(url: "https://github.com/MainasuK/CommonOSLog", from: "0.1.1"),
        .package(url: "https://github.com/TwidereProject/MetaTextKit.git", .exact("3.1.0")),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.4.0"),
        .package(url: "https://github.com/Alamofire/AlamofireImage.git", from: "4.1.0"),
        .package(url: "https://github.com/MainasuK/UITextView-Placeholder.git", from: "1.4.1"),
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
        .testTarget(
            name: "TwitterSDKTests",
            dependencies: ["TwitterSDK"]
        ),
        .target(
            name: "MastodonSDK",
            dependencies: [
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]
        ),
        .target(
            name: "TwidereAsset",
            dependencies: []
        ),
        .target(
            name: "TwidereCommon",
            dependencies: [
                "TwitterSDK",
            ]
        ),
        .target(
            name: "TwidereCore",
            dependencies: [
                "TwidereAsset",
                "TwidereCommon",
                "TwidereLocalization",
                "TwitterSDK",
                "MastodonSDK",
                "CoreDataStack",
                .product(name: "CommonOSLog", package: "CommonOSLog"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "AlamofireImage", package: "AlamofireImage"),
                .product(name: "MetaTextKit", package: "MetaTextKit"),
                .product(name: "MetaTextArea", package: "MetaTextKit"),
                .product(name: "TwitterMeta", package: "MetaTextKit"),
                .product(name: "MastodonMeta", package: "MetaTextKit"),
            ]
        ),
        .target(
            name: "TwidereLocalization",
            dependencies: []
        ),
        .target(
            name: "TwidereUI",
            dependencies: [
                "TwidereCore",
                .product(name: "FLAnimatedImage", package: "FLAnimatedImage"),
                .product(name: "UITextView+Placeholder", package: "UITextView-Placeholder"),
            ]
        ),
        .target(
            name: "CoreDataStack",
            dependencies: [
                "TwidereCommon"
            ],
            exclude: [
                "Template/Stencil"
            ]
        )
    ]
)
