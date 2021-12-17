// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
public enum Asset {
  public static let accentColor = ColorAsset(name: "AccentColor")
  public enum Arrows {
    public static let arrowLeft = ImageAsset(name: "Arrows/arrow.left")
    public static let arrowRight = ImageAsset(name: "Arrows/arrow.right")
    public static let arrowTriangle2Circlepath = ImageAsset(name: "Arrows/arrow.triangle.2.circlepath")
    public static let arrowTurnUpLeft = ImageAsset(name: "Arrows/arrow.turn.up.left")
    public static let arrowTurnUpLeftMini = ImageAsset(name: "Arrows/arrow.turn.up.left.mini")
    public static let arrowshapeTurnUpLeftFill = ImageAsset(name: "Arrows/arrowshape.turn.up.left.fill")
    public static let squareAndArrowUp = ImageAsset(name: "Arrows/square.and.arrow.up")
    public static let squareAndArrowUpMini = ImageAsset(name: "Arrows/square.and.arrow.up.mini")
    public static let tablerChevronDown = ImageAsset(name: "Arrows/tabler.chevron.down")
    public static let trendingUp = ImageAsset(name: "Arrows/trending.up")
  }
  public enum Badge {
    public static let circleMask = ImageAsset(name: "Badge/circle.mask")
    public static let circleMastodon = ImageAsset(name: "Badge/circle.mastodon")
    public static let circleTwitter = ImageAsset(name: "Badge/circle.twitter")
    public static let robot = ImageAsset(name: "Badge/robot")
    public static let robotMask = ImageAsset(name: "Badge/robot.mask")
    public static let verified = ImageAsset(name: "Badge/verified")
    public static let verifiedMask = ImageAsset(name: "Badge/verified.mask")
  }
  public enum Colors {
    public enum Banner {
      public static let actionBackground = ColorAsset(name: "Colors/Banner/action.background")
      public static let actionLabel = ColorAsset(name: "Colors/Banner/action.label")
      public static let errorBackground = ColorAsset(name: "Colors/Banner/error.background")
      public static let errorLabel = ColorAsset(name: "Colors/Banner/error.label")
      public static let infoBackground = ColorAsset(name: "Colors/Banner/info.background")
      public static let infoLabel = ColorAsset(name: "Colors/Banner/info.label")
      public static let successBackground = ColorAsset(name: "Colors/Banner/success.background")
      public static let successLabel = ColorAsset(name: "Colors/Banner/success.label")
      public static let warningBackground = ColorAsset(name: "Colors/Banner/warning.background")
      public static let warningLabel = ColorAsset(name: "Colors/Banner/warning.label")
    }
    public enum Theme {
      public static let daylight = ColorAsset(name: "Colors/Theme/daylight")
      public static let goldenSpirit = ColorAsset(name: "Colors/Theme/golden.spirit")
      public static let grandBudapest = ColorAsset(name: "Colors/Theme/grand.budapest")
      public static let lime = ColorAsset(name: "Colors/Theme/lime")
      public static let maskBlue = ColorAsset(name: "Colors/Theme/mask.blue")
      public static let seafoam = ColorAsset(name: "Colors/Theme/seafoam")
      public static let violet = ColorAsset(name: "Colors/Theme/violet")
      public static let vulcan = ColorAsset(name: "Colors/Theme/vulcan")
    }
    public enum Tint {
      public static let pink = ColorAsset(name: "Colors/Tint/pink")
    }
    public static let hightLight = ColorAsset(name: "Colors/hight.light")
    public static let mastodonBlue = ColorAsset(name: "Colors/mastodon.blue")
    public static let twitterBlue = ColorAsset(name: "Colors/twitter.blue")
  }
  public enum Communication {
    public static let at = ImageAsset(name: "Communication/at")
    public static let ellipsesBubble = ImageAsset(name: "Communication/ellipses.bubble")
    public static let ellipsisBubblePlus = ImageAsset(name: "Communication/ellipsis.bubble.plus")
    public static let mail = ImageAsset(name: "Communication/mail")
    public static let mailMiniInline = ImageAsset(name: "Communication/mail.mini.inline")
    public static let textBubbleSmall = ImageAsset(name: "Communication/text.bubble.small")
  }
  public enum Editing {
    public static let ellipsisCircleFill = ImageAsset(name: "Editing/ellipsis.circle.fill")
    public static let ellipsis = ImageAsset(name: "Editing/ellipsis")
    public static let ellipsisLarge = ImageAsset(name: "Editing/ellipsis.large")
    public static let ellipsisMini = ImageAsset(name: "Editing/ellipsis.mini")
    public static let featherPen = ImageAsset(name: "Editing/feather.pen")
    public static let sliderHorizontal3 = ImageAsset(name: "Editing/slider.horizontal.3")
    public static let xmark = ImageAsset(name: "Editing/xmark")
    public static let xmarkRound = ImageAsset(name: "Editing/xmark.round")
  }
  public enum Health {
    public static let heartFill = ImageAsset(name: "Health/heart.fill")
    public static let heartFillMini = ImageAsset(name: "Health/heart.fill.mini")
    public static let heart = ImageAsset(name: "Health/heart")
    public static let heartMini = ImageAsset(name: "Health/heart.mini")
  }
  public enum Human {
    public static let eyeSlash = ImageAsset(name: "Human/eye.slash")
    public static let eyeSlashLarge = ImageAsset(name: "Human/eye.slash.large")
    public static let eyeSlashMini = ImageAsset(name: "Human/eye.slash.mini")
    public static let faceSmiling = ImageAsset(name: "Human/face.smiling")
    public static let personExclamationMini = ImageAsset(name: "Human/person.exclamation.mini")
    public static let person = ImageAsset(name: "Human/person")
    public static let personMini = ImageAsset(name: "Human/person.mini")
    public static let personPlusMini = ImageAsset(name: "Human/person.plus.mini")
  }
  public enum Indices {
    public static let checkmarkCircleFill = ImageAsset(name: "Indices/checkmark.circle.fill")
    public static let checkmarkCircle = ImageAsset(name: "Indices/checkmark.circle")
    public static let checkmarkSquareFill = ImageAsset(name: "Indices/checkmark.square.fill")
    public static let checkmarkSquare = ImageAsset(name: "Indices/checkmark.square")
    public static let circle = ImageAsset(name: "Indices/circle")
    public static let exclamationmarkCircle = ImageAsset(name: "Indices/exclamationmark.circle")
    public static let exclamationmarkOctagon = ImageAsset(name: "Indices/exclamationmark.octagon")
    public static let exclamationmarkTriangleLarge = ImageAsset(name: "Indices/exclamationmark.triangle.large")
    public static let infoCircle = ImageAsset(name: "Indices/info.circle")
    public static let square = ImageAsset(name: "Indices/square")
  }
  public enum Keyboard {
    public static let keyboard = ImageAsset(name: "Keyboard/keyboard")
  }
  public enum Logo {
    public static let githubCircle = ImageAsset(name: "Logo/github.circle")
    public static let mastodon = ImageAsset(name: "Logo/mastodon")
    public static let twitterCircle = ImageAsset(name: "Logo/twitter.circle")
    public static let twitter = ImageAsset(name: "Logo/twitter")
  }
  public enum Media {
    public static let altRectangle = ImageAsset(name: "Media/alt.rectangle")
    public static let `repeat` = ImageAsset(name: "Media/repeat")
    public static let repeatMini = ImageAsset(name: "Media/repeat.mini")
  }
  public enum ObjectTools {
    public static let bell = ImageAsset(name: "Object&Tools/bell")
    public static let bellRinging = ImageAsset(name: "Object&Tools/bell.ringing")
    public static let blockedBadge = ImageAsset(name: "Object&Tools/blocked.badge")
    public static let bookmarks = ImageAsset(name: "Object&Tools/bookmarks")
    public static let camera = ImageAsset(name: "Object&Tools/camera")
    public static let clock = ImageAsset(name: "Object&Tools/clock")
    public static let clothes = ImageAsset(name: "Object&Tools/clothes")
    public static let gif = ImageAsset(name: "Object&Tools/gif")
    public static let globe = ImageAsset(name: "Object&Tools/globe")
    public static let globeMini = ImageAsset(name: "Object&Tools/globe.mini")
    public static let globeMiniInline = ImageAsset(name: "Object&Tools/globe.mini.inline")
    public static let house = ImageAsset(name: "Object&Tools/house")
    public static let icRoundRefresh = ImageAsset(name: "Object&Tools/ic.round.refresh")
    public static let lock = ImageAsset(name: "Object&Tools/lock")
    public static let lockMini = ImageAsset(name: "Object&Tools/lock.mini")
    public static let lockMiniInline = ImageAsset(name: "Object&Tools/lock.mini.inline")
    public static let lockOpen = ImageAsset(name: "Object&Tools/lock.open")
    public static let lockOpenMiniInline = ImageAsset(name: "Object&Tools/lock.open.mini.inline")
    public static let magnifyingglass = ImageAsset(name: "Object&Tools/magnifyingglass")
    public static let mappin = ImageAsset(name: "Object&Tools/mappin")
    public static let mappinMini = ImageAsset(name: "Object&Tools/mappin.mini")
    public static let note = ImageAsset(name: "Object&Tools/note")
    public static let paperplane = ImageAsset(name: "Object&Tools/paperplane")
    public static let photo = ImageAsset(name: "Object&Tools/photo")
    public static let photos = ImageAsset(name: "Object&Tools/photos")
    public static let poll = ImageAsset(name: "Object&Tools/poll")
    public static let pollMini = ImageAsset(name: "Object&Tools/poll.mini")
    public static let speakerXmark = ImageAsset(name: "Object&Tools/speaker.xmark")
  }
  public enum Scene {
    public enum About {
      public static let twidereLarge = ImageAsset(name: "Scene/About/twidere.large")
    }
    public enum Preference {
      public static let twidereAvatar = ImageAsset(name: "Scene/Preference/twidere.avatar")
    }
    public enum Status {
      public enum Toolbar {
        public static let like = ColorAsset(name: "Scene/Status/Toolbar/like")
        public static let repost = ColorAsset(name: "Scene/Status/Toolbar/repost")
      }
    }
    public enum Welcome {
      public static let twidere = ImageAsset(name: "Scene/Welcome/twidere")
    }
  }
  public enum Symbol {
    public static let at = ImageAsset(name: "Symbol/at")
    public static let number = ImageAsset(name: "Symbol/number")
  }
  public enum TextFormatting {
    public static let capitalFloatLeft = ImageAsset(name: "TextFormatting/capital.float.left")
    public static let capitalFloatLeftLarge = ImageAsset(name: "TextFormatting/capital.float.left.large")
    public static let listBullet = ImageAsset(name: "TextFormatting/list.bullet")
    public static let textHeaderRedaction = ImageAsset(name: "TextFormatting/text.header.redaction")
    public static let textQuoteMini = ImageAsset(name: "TextFormatting/text.quote.mini")
  }
  public enum Transportation {
    public static let paperAirplane = ImageAsset(name: "Transportation/paper.airplane")
  }
  public static let sidebarLeft = ImageAsset(name: "sidebar.left")
  public static let window = ImageAsset(name: "window")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

public final class ColorAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  public private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  fileprivate init(name: String) {
    self.name = name
  }
}

public extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = Bundle.module
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

public struct ImageAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Image = UIImage
  #endif

  public var image: Image {
    let bundle = Bundle.module
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
}

public extension ImageAsset.Image {
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = Bundle.module
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}
