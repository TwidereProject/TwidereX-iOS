//
//  HomeTimelineViewController+TimelinePostTableViewCellDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import TwitterAPI

// MARK: - TimelinePostTableViewCellDelegate
extension HomeTimelineViewController: TimelinePostTableViewCellDelegate {
    
    // MARK: - MosaicImageViewDelegate
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, mosaicImageView: MosaicImageView, didTapImageView imageView: UIImageView, atIndex index: Int) {
        tweet(for: cell)
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = tweet else { return }
                
                let root = MediaPreviewViewModel.Root(
                    tweetObjectID: tweet.objectID,
                    initialIndex: index,
                    preloadThumbnailImages: mosaicImageView.imageViews.map { $0.image }
                )
                let mediaPreviewViewModel = MediaPreviewViewModel(context: self.context, root: root)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .mediaPreview(viewModel: mediaPreviewViewModel), from: self, transition: .custom(transitioningDelegate: self.mediaPreviewTransitionController))
                }
            }
            .store(in: &disposeBag)
    }
    
}
