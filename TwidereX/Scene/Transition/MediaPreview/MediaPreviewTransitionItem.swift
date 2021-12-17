//
//  MediaPreviewTransitionItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import TwidereUI

class MediaPreviewTransitionItem: Identifiable {
    
    let id: UUID
    let source: Source
    weak var transitionHostViewController: MediaPreviewTransitionHostViewController?

    // TODO:
    var transitionView: UIView?
    var snapshotRaw: UIView?
    var snapshotTransitioning: UIView?
    var initialFrame: CGRect? = nil
    var targetFrame: CGRect? = nil
    var touchOffset: CGVector = CGVector.zero

    init(
        id: UUID = UUID(),
        source: Source,
        transitionHostViewController: MediaPreviewTransitionHostViewController
    ) {
        self.id = id
        self.source = source
        self.transitionHostViewController = transitionHostViewController
    }
    
}

extension MediaPreviewTransitionItem {
    enum Source {
        case attachment(MediaView)
        case attachments(MediaGridContainerView)
        case profileAvatar(ProfileHeaderView)
        case profileBanner(ProfileHeaderView)
        
        func updateAppearance(
            position: UIViewAnimatingPosition,
            index: Int?
        ) {
            let alpha: CGFloat = position == .end ? 1 : 0
            switch self {
            case .attachment(let mediaView):
                mediaView.alpha = alpha
            case .attachments(let mediaGridContainerView):
                if let index = index {
                    mediaGridContainerView.setAlpha(0, index: index)
                } else {
                    mediaGridContainerView.setAlpha(alpha)
                }
            case .profileAvatar(let profileHeaderView):
                profileHeaderView.avatarView.avatarButton.alpha = alpha
            case .profileBanner:
                break    // keep source
            }
        }
    }
}
