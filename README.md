# Twidere X

![CI](https://github.com/TwidereProject/TwidereX-iOS/workflows/CI/badge.svg)

## Requirements

- Xcode 11+
- Swift 5.1+


## Quick Start

Before clone and install the dependency. You need [apply](https://developer.twitter.com/en/apply-for-access) for the Twitter developer and setup Twitter [APIv2](https://blog.twitter.com/developer/en_us/topics/tools/2020/introducing_new_twitter_api.html) App to use the OAuth API key. Make the app permissions to "Read, Write, and Direct Messages" and enable "3-legged OAuth". Copy and save your API key and API key secret.

All you need

- Your app `API key` and `API key secret`
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
the `host_key_public` is preserved by App Store release and not needs for open-source build.


## Acknowledgements

- [ActiveLabel](https://github.com/optonaut/ActiveLabel.swift)
- [AlamofireImage](https://github.com/Alamofire/AlamofireImage)
- [Alamofire](https://github.com/Alamofire/Alamofire)
- [CommonOSLog](https://github.com/mainasuk/CommonOSLog)
- [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift)
- [DateToolSwift](https://github.com/MatthewYork/DateTools)
- [Floaty](https://github.com/kciter/Floaty)
- [Kanna](https://github.com/tid-kijyun/Kanna)
- [Kingfisher](https://github.com/onevcat/Kingfisher)
- [PageBoy](https://github.com/uias/Pageboy)
- [SwiftGen](https://github.com/SwiftGen/SwiftGen)
- [SwiftMessages](https://github.com/SwiftKickMobile/SwiftMessages)
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
- [Tabman](https://github.com/uias/Tabman)
- [TwitterProfile](https://github.com/OfTheWolf/TwitterProfile)
- [cocoapods-keys](https://github.com/orta/cocoapods-keys)
- [twitter-text](https://github.com/twitter/twitter-text)

## License

TwidereX-iOS is released under the GPLv3 license. See [LICENSE](./LICENSE) for details.
