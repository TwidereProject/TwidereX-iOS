//
//  TweetProvider+UICollectionViewDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-13.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit

// needs manually dispath
extension UICollectionViewDelegate where Self: TweetProvider & MediaPreviewableViewController {
    
    func handleCollectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        os_log("%{public}s[%{public}ld], %{public}s: indexPath %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
        guard let cell = collectionView.cellForItem(at: indexPath) as? SearchMediaCollectionViewCell else { return }
        self.tweet(for: cell)
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = (tweet?.retweet ?? tweet) else { return }
                
                guard let selectIndexPathInNestedCollectionView = cell.previewCollectionView.indexPathsForVisibleItems.first,
                      let selectCellInNestedCollectionView = cell.previewCollectionView.cellForItem(at: selectIndexPathInNestedCollectionView) as? SearchMediaPreviewCollectionViewCell else { return }
                
                let mediaArray = Array(tweet.media ?? Set()).sorted(by: { $0.index.compare($1.index) == .orderedAscending })
                let photoMedia = mediaArray.filter { $0.type == "photo" }
                let initialIndex = selectIndexPathInNestedCollectionView.item
                let preloadImageAtInitialIndex = selectCellInNestedCollectionView.previewImageView.image
                let preloadThumbnailImages = photoMedia.enumerated().map { i, element -> UIImage? in
                    return i == initialIndex ? preloadImageAtInitialIndex : nil
                }
                
                let root = MediaPreviewViewModel.TweetImagePreviewMeta(
                    tweetObjectID: tweet.objectID,
                    initialIndex: initialIndex,
                    preloadThumbnailImages: preloadThumbnailImages
                )
                let mediaPreviewViewModel = MediaPreviewViewModel(context: self.context, meta: root)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .mediaPreview(viewModel: mediaPreviewViewModel), from: self, transition: .custom(transitioningDelegate: self.mediaPreviewTransitionController))
                }
            }
            .store(in: &disposeBag)
    }
    
}
