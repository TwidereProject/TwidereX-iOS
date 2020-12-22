//
//  TweetProvider+UITableViewDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/13.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import AVKit
import Combine
import CoreDataStack
import AlamofireImage

extension UITableViewDelegate where Self: TweetProvider {
    
    func handleTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        os_log("%{public}s[%{public}ld], %{public}s: indexPath %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
        guard let cell = tableView.cellForRow(at: indexPath) as? TimelinePostTableViewCell else { return }
        tweet(for: cell, indexPath: indexPath)
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = tweet else { return }
                
                self.context.videoPlaybackService.markTransitioning(for: tweet)
                let tweetPostViewModel = TweetConversationViewModel(context: self.context, tweetObjectID: tweet.objectID)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .tweetConversation(viewModel: tweetPostViewModel), from: self, transition: .show)
                }
            }
            .store(in: &disposeBag)
    }
    
    func handleTableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // os_log("%{public}s[%{public}ld], %{public}s: indexPath %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)

        var _tweet: Future<Tweet?, Never>?
        
        if let cell = cell as? TimelinePostTableViewCell {
            _tweet = tweet(for: cell, indexPath: indexPath)
        }
        if let cell = cell as? ConversationPostTableViewCell {
            _tweet = tweet(for: cell, indexPath: indexPath)
        }
        
        guard let tweet = _tweet else { return }
        
        tweet
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = (tweet?.retweet ?? tweet) else { return }
                guard let media = (tweet.media ?? Set()).first else { return }
                guard let videoPlayerViewModel = self.context.videoPlaybackService.dequeueVideoPlayerViewModel(for: media) else { return }
                
                DispatchQueue.main.async {
                    videoPlayerViewModel.willDisplay()
                }
            }
            .store(in: &disposeBag)
    }
    
    func handleTableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // os_log("%{public}s[%{public}ld], %{public}s: indexPath %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
        
        var _tweet: Future<Tweet?, Never>?
        
        if let cell = cell as? TimelinePostTableViewCell {
            _tweet = tweet(for: cell, indexPath: indexPath)
        }
        if let cell = cell as? ConversationPostTableViewCell {
            _tweet = tweet(for: cell, indexPath: indexPath)
        }
        
        guard let tweet = _tweet else { return }
        
        tweet
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = (tweet?.retweet ?? tweet) else { return }
                guard let media = (tweet.media ?? Set()).first else { return }
                guard let videoPlayerViewModel = self.context.videoPlaybackService.dequeueVideoPlayerViewModel(for: media) else { return }
                DispatchQueue.main.async {
                    videoPlayerViewModel.didEndDisplaying()
                }
            }
            .store(in: &disposeBag)
    }
    
}


// context menu
extension UITableViewDelegate where Self: TweetProvider {

    private typealias ImagePreviewPresentableCell = UITableViewCell & DisposeBagCollectable & MosaicImageViewPresentable
    
    private func optionalTweet(for cell: ImagePreviewPresentableCell) -> Future<Tweet?, Never>? {
        if let cell = cell as? TimelinePostTableViewCell {
            return tweet(for: cell, indexPath: nil)
        } else if let cell = cell as? ConversationPostTableViewCell {
            return tweet(for: cell, indexPath: nil)
        } else {
            return nil
        }
    }
    
    private func contextMenuConfiguration(_ tableView: UITableView, cell: ImagePreviewPresentableCell, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let tweet = optionalTweet(for: cell) else { return nil }
        
        let imageViews = cell.mosaicImageView.imageViews
        guard !imageViews.isEmpty else { return nil }
        
        for (i, imageView) in imageViews.enumerated() {
            let pointInImageView = imageView.convert(point, from: tableView)
            guard imageView.point(inside: pointInImageView, with: nil) else {
                continue
            }
            guard let image = imageView.image else {
                // not provide preview until thumbnail ready
                return nil
                
            }
            let contextMenuImagePreviewViewModel = ContextMenuImagePreviewViewModel(aspectRatio: image.size, thumbnail: image)
            tweet
                .sink { tweet in
                    guard let tweet = (tweet?.retweet ?? tweet),
                          let media = tweet.media?.sorted(by: { $0.index.compare($1.index) == .orderedAscending }),
                          i < media.count, let url = media[i].photoURL(sizeKind: .original)?.0 else {
                        return
                    }
                    
                    contextMenuImagePreviewViewModel.url.value = url
                }
                .store(in: &contextMenuImagePreviewViewModel.disposeBag)
            
            let contextMenuConfiguration = TimelineTableViewCellContextMenuConfiguration(identifier: nil) { () -> UIViewController? in
                if UIDevice.current.userInterfaceIdiom == .pad && imageViews.count == 1 {
                    return nil
                }
                let previewProvider = ContextMenuImagePreviewViewController()
                previewProvider.viewModel = contextMenuImagePreviewViewModel
                return previewProvider
            } actionProvider: { _ -> UIMenu? in
                return UIMenu(
                    title: "",
                    image: nil,
                    children: [
                        UIAction(
                            title: L10n.Common.Controls.Actions.savePhoto,
                            image: UIImage(systemName: "square.and.arrow.down"),
                            attributes: [],
                            state: .off
                        ) { [weak self] _ in
                            guard let self = self else { return }
                            tweet
                                .sink { tweet in
                                    guard let tweet = (tweet?.retweet ?? tweet),
                                          let media = tweet.media?.sorted(by: { $0.index.compare($1.index) == .orderedAscending }),
                                          i < media.count, let url = media[i].photoURL(sizeKind: .original)?.0 else {
                                        return
                                    }
                                    ImageDownloader.default.download(URLRequest(url: url), completion: { [weak self] response in
                                        guard let self = self else { return }
                                        switch response.result {
                                        case .failure(let error):
                                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: download image %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, url.debugDescription, error.localizedDescription)
                                        case .success(let image):
                                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: download image %s success", ((#file as NSString).lastPathComponent), #line, #function, url.debugDescription)
                                            self.context.photoLibraryService.save(image: image)
                                        }
                                    })
                                }
                                .store(in: &self.disposeBag)
                        }
                    ]
                )
            }
            contextMenuConfiguration.indexPath = indexPath
            contextMenuConfiguration.index = i
            return contextMenuConfiguration
        }
        
        return nil
    }
    
    func handleTableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if #available(iOS 14.0, *) {
            guard let cell = tableView.cellForRow(at: indexPath) as? ImagePreviewPresentableCell else { return nil }
            return contextMenuConfiguration(tableView, cell: cell, contextMenuConfigurationForRowAt: indexPath, point: point)
        } else {
            // Fallback on earlier versions
            return nil
        }
    }
    
    private func _handleTableView(_ tableView: UITableView, configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let configuration = configuration as? TimelineTableViewCellContextMenuConfiguration else { return nil }
        guard let indexPath = configuration.indexPath, let index = configuration.index else { return nil }
        if let cell = tableView.cellForRow(at: indexPath) as? TimelinePostTableViewCell {
            let imageViews = cell.timelinePostView.mosaicImageView.imageViews
            guard index < imageViews.count else { return nil }
            let imageView = imageViews[index]
            return UITargetedPreview(view: imageView, parameters: UIPreviewParameters())
        } else if let cell = tableView.cellForRow(at: indexPath) as? ConversationPostTableViewCell {
            let imageViews = cell.conversationPostView.mosaicImageView.imageViews
            guard index < imageViews.count else { return nil }
            let imageView = imageViews[index]
            return UITargetedPreview(view: imageView, parameters: UIPreviewParameters())
        } else {
            return nil
        }
    }

    func handleTableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return _handleTableView(tableView, configuration: configuration)
    }
    
    func handleTableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return _handleTableView(tableView, configuration: configuration)
    }
    
}

extension UITableViewDelegate where Self: TweetProvider & MediaPreviewableViewController {
    func handleTableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let configuration = configuration as? TimelineTableViewCellContextMenuConfiguration else { return }
        guard let indexPath = configuration.indexPath, let index = configuration.index else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? ImagePreviewPresentableCell else { return }
        guard let tweet = optionalTweet(for: cell) else { return }
        
        animator.addCompletion { [weak self] in
            guard let self = self else { return }
            tweet
                .sink { [weak self] tweet in
                    guard let self = self else { return }
                    guard let tweet = (tweet?.retweet ?? tweet) else { return }
                    
                    let root = MediaPreviewViewModel.TweetImagePreviewMeta(
                        tweetObjectID: tweet.objectID,
                        initialIndex: index,
                        preloadThumbnailImages: cell.mosaicImageView.imageViews.map { $0.image }
                    )
                    let mediaPreviewViewModel = MediaPreviewViewModel(context: self.context, meta: root)
                    DispatchQueue.main.async {
                        self.coordinator.present(scene: .mediaPreview(viewModel: mediaPreviewViewModel), from: self, transition: .custom(transitioningDelegate: self.mediaPreviewTransitionController))
                    }
                }
                .store(in: &cell.disposeBag)
        }
    }
}
