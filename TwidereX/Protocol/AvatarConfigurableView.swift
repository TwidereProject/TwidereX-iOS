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
    static var avatarImageViewSize: CGSize { get }
    var avatarImageView: UIImageView { get }
    var verifiedBadgeImageView: UIImageView { get }
    func configure(avatarImageURL: URL?, verified: Bool)
}

extension AvatarConfigurableView {
    public func configure(avatarImageURL: URL?, verified: Bool = false) {
        // set verified
        verifiedBadgeImageView.isHidden = !verified
        
        // cancel previous task
        avatarImageView.af.cancelImageRequest()
        avatarImageView.kf.cancelDownloadTask()
        
        let placeholderImage = UIImage
            .placeholder(size: Self.avatarImageViewSize, color: .systemFill)
            .af.imageRoundedIntoCircle()
        
        // set placeholder if no asset
        guard let avatarImageURL = avatarImageURL else {
            avatarImageView.image = placeholderImage
            return
        }
        
        // set avatar (GIF using Kingfisher)
        switch avatarImageURL.pathExtension {
        case "gif":
            avatarImageView.kf.setImage(
                with: avatarImageURL,
                placeholder: placeholderImage,
                options: [
                    .processor(
                        CroppingImageProcessor(size: Self.avatarImageViewSize, anchor: CGPoint(x: 0.5, y: 0.5)) |>
                        RoundCornerImageProcessor(cornerRadius: 0.5 * Self.avatarImageViewSize.width)
                    ),
                    .transition(.fade(0.2))
                ]
            )
        default:
            let filter = ScaledToSizeCircleFilter(size: Self.avatarImageViewSize)
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
}
