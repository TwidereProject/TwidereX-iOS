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
        .library(
            name: "TwidereSDK",
            targets: [
                "TwitterSDK",
                "MastodonSDK",
                "CoreDataStack",
                "TwidereAsset",
                "TwidereCommon",
                "TwidereCore",
                "TwidereLocalization",
                "TwidereUI",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.34.0"),
        .package(url: "https://github.com/Flipboard/FLAnimatedImage.git", from: "1.0.0"),
        .package(url: "https://github.com/MainasuK/CommonOSLog", from: "0.1.1"),
        .package(url: "https://github.com/TwidereProject/MetaTextKit.git", .exact("3.3.2")),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.5.0"),
        .package(url: "https://github.com/Alamofire/AlamofireImage.git", from: "4.1.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.1.1"),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.12.0"),
        .package(url: "https://github.com/MainasuK/UITextView-Placeholder.git", from: "1.4.1"),
        .package(url: "https://github.com/TimOliver/TOCropViewController.git", from: "2.6.1"),
        .package(url: "https://github.com/MainasuK/KeyboardLayoutGuide.git", branch: "fix/iOS15"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.2"),
        .package(url: "https://github.com/SwiftKickMobile/SwiftMessages.git", from: "9.0.5"),
        .package(url: "https://github.com/aheze/Popovers.git", from: "1.3.2"),
        .package(name: "Introspect", url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "0.1.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CoreDataStack",
            dependencies: [
                "TwidereCommon"
            ],
            exclude: [
                "Template/Stencil"
            ]
        ),
        .target(
            name: "TwitterSDK",
            dependencies: [
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]
        ),
        .testTarget(
            name: "TwitterSDKTests",
            dependencies: [
                "TwitterSDK",
                .product(name: "CommonOSLog", package: "CommonOSLog"),
            ]
        ),
        .target(
            name: "MastodonSDK",
            dependencies: [
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "Collections", package: "swift-collections"),
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
                .product(name: "CropViewController", package: "TOCropViewController"),
                .product(name: "FLAnimatedImage", package: "FLAnimatedImage"),
                .product(name: "Introspect", package: "Introspect"),
                .product(name: "KeyboardLayoutGuide", package: "KeyboardLayoutGuide"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "Popovers", package: "Popovers"),
                .product(name: "SDWebImage", package: "SDWebImage"),
                .product(name: "SwiftMessages", package: "SwiftMessages"),
                .product(name: "UITextView+Placeholder", package: "UITextView-Placeholder"),
            ]
        ),
    ]
)
