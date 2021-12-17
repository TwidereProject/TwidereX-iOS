//
//  AvatarConfigurableView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-23.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import AlamofireImage
import Kingfisher

//@available(*, deprecated, message: "")
//protocol AvatarConfigurableView {
//    static var configurableAvatarImageViewSize: CGSize { get }
//    static var configurableAvatarImageViewBadgeAppearanceStyle: AvatarConfigurableViewConfiguration.BadgeAppearanceStyle { get }
//    var configurableAvatarImageView: UIImageView? { get }
//    var configurableAvatarButton: UIButton? { get }
//    var configurableVerifiedBadgeImageView: UIImageView? { get }
//    func configure(withConfigurationInput input: AvatarConfigurableViewConfiguration.Input)
//    func avatarConfigurableView(_ avatarConfigurableView: AvatarConfigurableView, didFinishConfiguration configuration: AvatarConfigurableViewConfiguration)
//}
//
//@available(*, deprecated, message: "")
//extension AvatarConfigurableView {
//    
//    static var configurableAvatarImageViewBadgeAppearanceStyle: AvatarConfigurableViewConfiguration.BadgeAppearanceStyle { return .mini }
//    
//    public func configure(withConfigurationInput input: AvatarConfigurableViewConfiguration.Input) {
//        // set badge
//        switch (input.verified, input.blocked) {
//        case (_, true):
//            configurableVerifiedBadgeImageView?.isHidden = false
//            switch Self.configurableAvatarImageViewBadgeAppearanceStyle {
//            case .mini:
//                assertionFailure()
//                configurableVerifiedBadgeImageView?.image = Asset.ObjectTools.blockedBadge.image.withRenderingMode(.alwaysOriginal)
//            case .normal:
//                configurableVerifiedBadgeImageView?.image = Asset.ObjectTools.blockedBadge.image.withRenderingMode(.alwaysOriginal)
//            }
//        case (true, false):
//            configurableVerifiedBadgeImageView?.isHidden = false
//            switch Self.configurableAvatarImageViewBadgeAppearanceStyle {
//            case .mini:
//                break
////                configurableVerifiedBadgeImageView?.image = Asset.ObjectTools.verifiedBadgeMini.image.withRenderingMode(.alwaysOriginal)
//            case .normal:
//                break
////                configurableVerifiedBadgeImageView?.image = Asset.ObjectTools.verifiedBadge.image.withRenderingMode(.alwaysOriginal)
//            }
//        default:
//            configurableVerifiedBadgeImageView?.isHidden = true
//        }
//        
//        let avatarStyle = UserDefaults.shared.avatarStyle
//        let roundedSquareCornerRadius = AvatarConfigurableViewConfiguration.roundedSquareCornerRadius(for: Self.configurableAvatarImageViewSize)
//        let cornerRadius = AvatarConfigurableViewConfiguration.cornerRadius(for: Self.configurableAvatarImageViewSize, avatarStyle: avatarStyle)
//        let scale = (configurableAvatarImageView ?? configurableAvatarButton)?.window?.screen.scale ?? UIScreen.main.scale
//
//        let placeholderImage: UIImage = {
//            let placeholderImage = input.placeholderImage ?? UIImage.placeholder(size: Self.configurableAvatarImageViewSize, color: .systemFill)
//            switch avatarStyle {
//            case .circle:           return placeholderImage.af.imageRoundedIntoCircle()
//            case .roundedSquare:    return placeholderImage.af.imageRounded(withCornerRadius: roundedSquareCornerRadius * placeholderImage.scale, divideRadiusByImageScale: true)
//            }
//            
//        }()
//        
//        // cancel previous task
//        configurableAvatarImageView?.af.cancelImageRequest()
//        configurableAvatarImageView?.kf.cancelDownloadTask()
//        configurableAvatarButton?.af.cancelImageRequest(for: .normal)
//        configurableAvatarButton?.kf.cancelImageDownloadTask()
//        
//        // reset layer attributes
//        configurableAvatarImageView?.layer.masksToBounds = false
//        configurableAvatarImageView?.layer.cornerRadius = 0
//        configurableAvatarImageView?.layer.cornerCurve = .circular
//        
//        configurableAvatarButton?.layer.masksToBounds = false
//        configurableAvatarButton?.layer.cornerRadius = 0
//        configurableAvatarButton?.layer.cornerCurve = .circular
//        
//        defer {
//            let configuration = AvatarConfigurableViewConfiguration(
//                input: input,
//                output: AvatarConfigurableViewConfiguration.Output(cornerRadius: cornerRadius)
//            )
//            avatarConfigurableView(self, didFinishConfiguration: configuration)
//        }
//        
//        // set placeholder if no asset
//        guard let avatarImageURL = input.avatarImageURL else {
//            configurableAvatarImageView?.image = placeholderImage
//            configurableAvatarButton?.setImage(placeholderImage, for: .normal)
//            return
//        }
//
//        if let avatarImageView = configurableAvatarImageView {
//            // set avatar (GIF using Kingfisher)
//            switch avatarImageURL.pathExtension {
//            case "gif":
//                avatarImageView.kf.setImage(
//                    with: avatarImageURL,
//                    placeholder: placeholderImage,
//                    options: [
//                        .transition(.fade(0.2))
//                    ]
//                )
//                avatarImageView.layer.masksToBounds = true
//                avatarImageView.layer.cornerRadius = cornerRadius
//                switch avatarStyle {
//                case .circle:               avatarImageView.layer.cornerCurve = .circular
//                case .roundedSquare:        avatarImageView.layer.cornerCurve = .continuous
//                }
//            default:
//                let filter = avatarImageFilter(for: avatarStyle, roundedSquareCornerRadius: roundedSquareCornerRadius, scale: scale)
//                avatarImageView.af.setImage(
//                    withURL: avatarImageURL,
//                    placeholderImage: placeholderImage,
//                    filter: filter,
//                    imageTransition: .crossDissolve(0.3),
//                    runImageTransitionIfCached: false,
//                    completion: nil
//                )
//            }
//        }
//        
//        if let avatarButton = configurableAvatarButton {
//            switch avatarImageURL.pathExtension {
//            case "gif":
//                avatarButton.kf.setImage(
//                    with: avatarImageURL,
//                    for: .normal,
//                    placeholder: placeholderImage,
//                    options: [
//                        .transition(.fade(0.2))
//                    ]
//                )
//                avatarButton.layer.masksToBounds = true
//                avatarButton.layer.cornerRadius = cornerRadius
//                switch avatarStyle {
//                case .circle:               avatarButton.layer.cornerCurve = .circular
//                case .roundedSquare:        avatarButton.layer.cornerCurve = .continuous
//                }
//            default:
//                let filter = avatarImageFilter(for: avatarStyle, roundedSquareCornerRadius: roundedSquareCornerRadius, scale: scale)
//                avatarButton.af.setImage(
//                    for: .normal,
//                    url: avatarImageURL,
//                    placeholderImage: placeholderImage,
//                    filter: filter,
//                    completion: nil
//                )
//            }
//        }
//    }
//    
//    func avatarConfigurableView(_ avatarConfigurableView: AvatarConfigurableView, didFinishConfiguration configuration: AvatarConfigurableViewConfiguration) { }
//    
//}
//
//extension AvatarConfigurableView {
//    
//    private func avatarImageFilter(for avatarStyle: UserDefaults.AvatarStyle, roundedSquareCornerRadius radius: CGFloat, scale: CGFloat) -> ImageFilter {
//        switch avatarStyle {
//        case .circle:           return ScaledToSizeCircleFilter(size: Self.configurableAvatarImageViewSize)
//        case .roundedSquare:    return AspectScaledToFillSizeWithRoundedCornersFilter(size: Self.configurableAvatarImageViewSize, radius: radius * scale, divideRadiusByImageScale: true)
//        }
//    }
//    
//}
//
//struct AvatarConfigurableViewConfiguration {
//    
//    enum BadgeAppearanceStyle {
//        case mini
//        case normal
//    }
//    
//    struct Input {
//        let avatarImageURL: URL?
//        let placeholderImage: UIImage?
//        let blocked: Bool
//        let verified: Bool
//        
//        init(avatarImageURL: URL?, placeholderImage: UIImage? = nil, blocked: Bool = false, verified: Bool = false) {
//            self.avatarImageURL = avatarImageURL
//            self.placeholderImage = placeholderImage
//            self.blocked = blocked
//            self.verified = verified
//        }
//    }
//    
//    struct Output {
//        let cornerRadius: CGFloat
//    }
//    
//    let input: Input
//    let output: Output
//    
//    static func roundedSquareCornerRadius(for imageSize: CGSize) -> CGFloat {
//        return CGFloat(Int(imageSize.width) / 8 * 2)  // even number from quoter of width
//    }
//    
//    static func cornerRadius(for imageSize: CGSize, avatarStyle: UserDefaults.AvatarStyle) -> CGFloat {
//        let roundedSquareCornerRadius = Self.roundedSquareCornerRadius(for: imageSize)
//        let cornerRadius: CGFloat = {
//            switch avatarStyle {
//            case .circle:               return 0.5 * imageSize.width
//            case .roundedSquare:        return roundedSquareCornerRadius
//            }
//        }()
//        return cornerRadius
//    }
//    
//}
