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
    func configure(avatarImageURL: URL?, verified: Bool)
}

extension AvatarConfigurableView {
    public func configure(avatarImageURL: URL?, verified: Bool = false) {
        // set verified
        configurableVerifiedBadgeImageView?.isHidden = !verified
        
        let placeholderImage = UIImage
            .placeholder(size: Self.configurableAvatarImageViewSize, color: .systemFill)
            .af.imageRoundedIntoCircle()
        
        
        // cancel previous task
        configurableAvatarImageView?.af.cancelImageRequest()
        configurableAvatarImageView?.kf.cancelDownloadTask()
        configurableAvatarButton?.af.cancelImageRequest(for: .normal)
        configurableAvatarButton?.kf.cancelImageDownloadTask()
        
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
                        .processor(
                            CroppingImageProcessor(size: Self.configurableAvatarImageViewSize, anchor: CGPoint(x: 0.5, y: 0.5)) |>
                                RoundCornerImageProcessor(cornerRadius: 0.5 * Self.configurableAvatarImageViewSize.width)
                        ),
                        .transition(.fade(0.2))
                    ]
                )
            default:
                let filter = ScaledToSizeCircleFilter(size: Self.configurableAvatarImageViewSize)
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
                        .processor(
                            CroppingImageProcessor(size: Self.configurableAvatarImageViewSize, anchor: CGPoint(x: 0.5, y: 0.5)) |>
                                RoundCornerImageProcessor(cornerRadius: 0.5 * Self.configurableAvatarImageViewSize.width)
                        ),
                        .transition(.fade(0.2))
                    ]
                )
            default:
                let filter = ScaledToSizeCircleFilter(size: Self.configurableAvatarImageViewSize)
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
}
