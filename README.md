# Twidere X

![CI](https://github.com/TwidereProject/TwidereX-iOS/workflows/CI/badge.svg)
[![Crowdin](https://badges.crowdin.net/twidere-x/localized.svg)](https://crowdin.com/project/twidere-x)

Next generation of Twidere for iOS.

[![Download on the App Store](./Press/Download_on_the_App_Store_Badge_US-UK_RGB_blk_092917.svg)](https://apps.apple.com/app/twidere-x/id1530314034)

## Requirements

- Xcode 13.0+
- Swift 5.5+
- iOS 15+


## Quick Start

Before clone and install the dependency. You need [apply](https://developer.twitter.com/en/apply-for-access) for the Twitter developer and setup Twitter [APIv2](https://blog.twitter.com/developer/en_us/topics/tools/2020/introducing_new_twitter_api.html) App to use the OAuth API key. Make the app permissions to "Read, Write, and Direct Messages" and enable "3-legged OAuth". Copy and save your API key and API key secret.

All you need

- Twitter app `API key` and `API key secret`
- The latest Xcode from the App Store
- [CocoaPods](https://cocoapods.org)
- [cocoapods-keys](https://github.com/orta/cocoapods-keys)

```zsh
git clone https://github.com/TwidereProject/TwidereX-iOS
cd TwidereX-iOS
pod install

# setup cocoapods-keys
> app_secret: "Twidere"
> consumer_key: "<API key>"
> consumer_key_secret: "<API key secret>"
> host_key_public: ""
> oauth_endpoint: "oob"
> oauth_endpoint_debug: "oob"

open TwidereX.xcworkspace  
```

After open the project in the Xcode. Choose TwidereX scheme and build and run the app by ⌘R.

Note:  
The `host_key_public` is preserved by App Store release and not needs for the open-source build. And you may needs to change bundle identifier in the Xcode to avoid conflict.

## Translation
The localization resource files locate in [TwidereX-Localization](https://github.com/TwidereProject/TwidereX-Localization) repo. We are welcome translator use our [Crowdin](https://crowdin.com/project/twidere-x) project contribute.

## Acknowledgements

- [Alamofire](https://github.com/Alamofire/Alamofire)
- [AlamofireImage](https://github.com/Alamofire/AlamofireImage)
- [AlamofireNetworkActivityIndicator](https://github.com/Alamofire/AlamofireNetworkActivityIndicator)
- [cocoapods-keys](https://github.com/orta/cocoapods-keys)
- [CommonOSLog](https://github.com/mainasuk/CommonOSLog)
- [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift)
- [DateToolSwift](https://github.com/MatthewYork/DateTools)
- [Floaty](https://github.com/kciter/Floaty)
- [Kanna](https://github.com/tid-kijyun/Kanna)
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)
- [Kingfisher](https://github.com/onevcat/Kingfisher)
- [LineChart](https://github.com/nhatminh12369/LineChart)
- [PageBoy](https://github.com/uias/Pageboy)
- [Popovers](https://github.com/aheze/Popovers)
- [swift-nio](https://github.com/apple/swift-nio)
- [SwiftGen](https://github.com/SwiftGen/SwiftGen)
- [SwiftMessages](https://github.com/SwiftKickMobile/SwiftMessages)
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
- [Tabman](https://github.com/uias/Tabman)
- [TOCropViewController](https://github.com/TimOliver/TOCropViewController)
- [twitter-text](https://github.com/twitter/twitter-text)
- [TwitterProfile](https://github.com/OfTheWolf/TwitterProfile)
- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation)

## License

TwidereX-iOS is released under the GPLv3 license. See [LICENSE](./LICENSE) for details.
