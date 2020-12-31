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

protocol AvatarConfigurableView {
    static var configurableAvatarImageViewSize: CGSize { get }
    var configurableAvatarImageView: UIImageView? { get }
    var configurableAvatarButton: UIButton? { get }
    var configurableVerifiedBadgeImageView: UIImageView? { get }
    func configure(avatarImageURL: URL?, verified: Bool, placeholderImage: UIImage?)
    func avatarConfigurableView(_ avatarConfigurableView: AvatarConfigurableView, didFinishConfiguration configuration: AvatarConfigurableViewConfiguration)
}

extension AvatarConfigurableView {
    
    public func configure(avatarImageURL: URL?, verified: Bool = false, placeholderImage: UIImage? = nil) {
        // set verified
        configurableVerifiedBadgeImageView?.isHidden = !verified
        
        let avatarStyle = UserDefaults.shared.avatarStyle
        let roundedSquareCornerRadius = AvatarConfigurableViewConfiguration.roundedSquareCornerRadius(for: Self.configurableAvatarImageViewSize)
        let cornerRadius = AvatarConfigurableViewConfiguration.cornerRadius(for: Self.configurableAvatarImageViewSize, avatarStyle: avatarStyle)
        let scale = (configurableAvatarImageView ?? configurableAvatarButton)?.window?.screen.scale ?? UIScreen.main.scale

        let placeholderImage: UIImage = {
            let placeholderImage = placeholderImage ?? UIImage.placeholder(size: Self.configurableAvatarImageViewSize, color: .systemFill)
            switch avatarStyle {
            case .circle:           return placeholderImage.af.imageRoundedIntoCircle()
            case .roundedSquare:    return placeholderImage.af.imageRounded(withCornerRadius: roundedSquareCornerRadius * placeholderImage.scale, divideRadiusByImageScale: true)
            }
            
        }()
        
        // cancel previous task
        configurableAvatarImageView?.af.cancelImageRequest()
        configurableAvatarImageView?.kf.cancelDownloadTask()
        configurableAvatarButton?.af.cancelImageRequest(for: .normal)
        configurableAvatarButton?.kf.cancelImageDownloadTask()
        
        // reset layer attributes
        configurableAvatarImageView?.layer.masksToBounds = false
        configurableAvatarImageView?.layer.cornerRadius = 0
        configurableAvatarImageView?.layer.cornerCurve = .circular
        
        configurableAvatarButton?.layer.masksToBounds = false
        configurableAvatarButton?.layer.cornerRadius = 0
        configurableAvatarButton?.layer.cornerCurve = .circular
        
        defer {
            let configuration = AvatarConfigurableViewConfiguration(
                avatarImageURL: avatarImageURL,
                verified: verified,
                cornerRadius: cornerRadius
            )
            avatarConfigurableView(self, didFinishConfiguration: configuration)
        }
        
        // set placeholder if no asset
        guard let avatarImageURL = avatarImageURL else {
            configurableAvatarImageView?.image = placeholderImage
            configurableAvatarButton?.setImage(placeholderImage, for: .normal)
            return
        }

        if let avatarImageView = configurableAvatarImageView {
            // set avatar (GIF using Kingfisher)
            switch avatarImageURL.pathExtension {
            case "gif":
                avatarImageView.kf.setImage(
                    with: avatarImageURL,
                    placeholder: placeholderImage,
                    options: [
                        .transition(.fade(0.2))
                    ]
                )
                avatarImageView.layer.masksToBounds = true
                avatarImageView.layer.cornerRadius = cornerRadius
                switch avatarStyle {
                case .circle:               avatarImageView.layer.cornerCurve = .circular
                case .roundedSquare:        avatarImageView.layer.cornerCurve = .continuous
                }
            default:
                let filter = avatarImageFilter(for: avatarStyle, roundedSquareCornerRadius: roundedSquareCornerRadius, scale: scale)
                avatarImageView.af.setImage(
                    withURL: avatarImageURL,
                    placeholderImage: placeholderImage,
                    filter: filter,
                    imageTransition: .crossDissolve(0.3),
                    runImageTransitionIfCached: false,
                    completion: nil
                )
            }
        }
        
        if let avatarButton = configurableAvatarButton {
            switch avatarImageURL.pathExtension {
            case "gif":
                avatarButton.kf.setImage(
                    with: avatarImageURL,
                    for: .normal,
                    placeholder: placeholderImage,
                    options: [
                        .transition(.fade(0.2))
                    ]
                )
                avatarButton.layer.masksToBounds = true
                avatarButton.layer.cornerRadius = cornerRadius
                switch avatarStyle {
                case .circle:               avatarButton.layer.cornerCurve = .circular
                case .roundedSquare:        avatarButton.layer.cornerCurve = .continuous
                }
            default:
                let filter = avatarImageFilter(for: avatarStyle, roundedSquareCornerRadius: roundedSquareCornerRadius, scale: scale)
                avatarButton.af.setImage(
                    for: .normal,
                    url: avatarImageURL,
                    placeholderImage: placeholderImage,
                    filter: filter,
                    completion: nil
                )
            }
        }
    }
    
    func avatarConfigurableView(_ avatarConfigurableView: AvatarConfigurableView, didFinishConfiguration configuration: AvatarConfigurableViewConfiguration) { }
    
}

extension AvatarConfigurableView {
    
    private func avatarImageFilter(for avatarStyle: UserDefaults.AvatarStyle, roundedSquareCornerRadius radius: CGFloat, scale: CGFloat) -> ImageFilter {
        switch avatarStyle {
        case .circle:           return ScaledToSizeCircleFilter(size: Self.configurableAvatarImageViewSize)
        case .roundedSquare:    return AspectScaledToFillSizeWithRoundedCornersFilter(size: Self.configurableAvatarImageViewSize, radius: radius * scale, divideRadiusByImageScale: true)
        }
    }
    
}

struct AvatarConfigurableViewConfiguration {
    
    let avatarImageURL: URL?
    let verified: Bool
    let cornerRadius: CGFloat
    
    static func roundedSquareCornerRadius(for imageSize: CGSize) -> CGFloat {
        return CGFloat(Int(imageSize.width) / 8 * 2)  // even number from quoter of width
    }
    
    static func cornerRadius(for imageSize: CGSize, avatarStyle: UserDefaults.AvatarStyle) -> CGFloat {
        let roundedSquareCornerRadius = Self.roundedSquareCornerRadius(for: imageSize)
        let cornerRadius: CGFloat = {
            switch avatarStyle {
            case .circle:               return 0.5 * imageSize.width
            case .roundedSquare:        return roundedSquareCornerRadius
            }
        }()
        return cornerRadius
    }
    
}
