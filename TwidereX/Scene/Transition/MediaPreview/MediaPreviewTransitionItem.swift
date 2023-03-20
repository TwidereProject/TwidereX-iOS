//
//  MediaPreviewTransitionItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

class MediaPreviewTransitionItem: Identifiable {
    
    let id: UUID
    let source: Source
    var previewableViewController: MediaPreviewableViewController

    // source
    var image: UIImage?
    var aspectRatio: CGSize?
    var initialFrame: CGRect? = nil     // start frame for .push animation
    var sourceImageViewCornerRadius: CGFloat?
    
    // target
    var targetFrame: CGRect? = nil
    
    // transitioning
    var transitionView: UIView?
    var snapshotRaw: UIView?
    var snapshotTransitioning: UIView?
    var touchOffset: CGVector = CGVector.zero
    var interactiveTransitionMaskView: UIView?
    var interactiveTransitionMaskLayer: CAShapeLayer?

    init(
        id: UUID = UUID(),
        source: Source,
        previewableViewController: MediaPreviewableViewController
    ) {
        self.id = id
        self.source = source
        self.previewableViewController = previewableViewController
    }
    
}

extension MediaPreviewTransitionItem {
    enum Source {
        case none
        case mediaView(MediaView.ViewModel)
        case profileAvatar(ProfileHeaderView)
        case profileBanner(ProfileHeaderView)
        
        func updateAppearance(
            position: UIViewAnimatingPosition,
            index: Int?
        ) {
            switch self {
            case .none:
                break
            case .mediaView(let viewModel):
                viewModel.shouldHideForTransitioning = position != .end
            case .profileAvatar(let view):
                // TODO:
                break
            case .profileBanner(let view):
                // TODO:
                break
            }
//            case .profileAvatar(let profileHeaderView):
//                profileHeaderView.avatarView.avatarButton.alpha = alpha
//            case .profileBanner:
//                break    // keep source
//            }
        }
    }
}
