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
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, retweetButtonDidPressed sender: UIButton) {
        // prepare authentication
        guard let twitterAuthentication = viewModel.currentTwitterAuthentication.value,
              let authorization = try? twitterAuthentication.authorization(appSecret: AppSecret.shared) else {
            assertionFailure()
            return
        }
        
        // prepare current user infos
        guard let _currentTwitterUser = context.authenticationService.currentTwitterUser.value else {
            assertionFailure()
            return
        }
        let twitterUserID = twitterAuthentication.userID
        assert(_currentTwitterUser.id == twitterUserID)
        let twitterUserObjectID = _currentTwitterUser.objectID
        
        // retrieve target tweet infos
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let timelineItem = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .homeTimelineIndex(timelineIndexObjectID, _) = timelineItem else { return }
        let timelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: timelineIndexObjectID) as! TimelineIndex
        guard let tweet = timelineIndex.tweet else { return }
        let tweetObjectID = tweet.objectID
        
        let targetRetweetKind: Twitter.API.Statuses.RetweetKind = {
            let targetTweet = (tweet.retweet ?? tweet)
            let isRetweeted = targetTweet.retweetBy.flatMap { $0.contains(where: { $0.id == twitterUserID }) } ?? false
            return isRetweeted ? .unretweet : .retweet
        }()
        
        // trigger like action
        let generator = UIImpactFeedbackGenerator(style: .light)
        let responseFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        context.apiService.retweet(
            tweetObjectID: tweetObjectID,
            twitterUserObjectID: twitterUserObjectID,
            retweetKind: targetRetweetKind,
            authorization: authorization,
            twitterUserID: twitterUserID
        )
        .receive(on: DispatchQueue.main)
        .handleEvents { _ in
            generator.prepare()
            responseFeedbackGenerator.prepare()
        } receiveOutput: { _ in
            generator.impactOccurred()
        } receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                // TODO: handle error
                break
            case .finished:
                os_log("%{public}s[%{public}ld], %{public}s: [Retweet] update local tweet retweet status to: %s", ((#file as NSString).lastPathComponent), #line, #function, targetRetweetKind == .retweet ? "retweet" : "unretweet")
                
                // reload item
                DispatchQueue.main.async {
                    var snapshot = diffableDataSource.snapshot()
                    snapshot.reloadItems([timelineItem])
                    diffableDataSource.defaultRowAnimation = .none
                    diffableDataSource.apply(snapshot)
                    diffableDataSource.defaultRowAnimation = .automatic
                }
            }
        }
        .map { targetTweetID in
            self.context.apiService.retweet(
                tweetID: targetTweetID,
                retweetKind: targetRetweetKind,
                authorization: authorization,
                twitterUserID: twitterUserID
            )
        }
        .switchToLatest()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            if self.view.window != nil, (self.tableView.indexPathsForVisibleRows ?? []).contains(indexPath) {
                responseFeedbackGenerator.impactOccurred()
            }
            switch completion {
            case .failure(let error):
                os_log("%{public}s[%{public}ld], %{public}s: [Retweet] remote retweet request fail: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            case .finished:
                os_log("%{public}s[%{public}ld], %{public}s: [Retweet] remote retweet request success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        } receiveValue: { response in
            
        }
        .store(in: &disposeBag)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, favoriteButtonDidPressed sender: UIButton) {
        // prepare authentication
        guard let twitterAuthentication = viewModel.currentTwitterAuthentication.value,
              let authorization = try? twitterAuthentication.authorization(appSecret: AppSecret.shared) else {
            assertionFailure()
            return
        }
        
        // prepare current user infos
        guard let _currentTwitterUser = context.authenticationService.currentTwitterUser.value else {
            assertionFailure()
            return
        }
        let twitterUserID = twitterAuthentication.userID
        assert(_currentTwitterUser.id == twitterUserID)
        let twitterUserObjectID = _currentTwitterUser.objectID
        
        // retrieve target tweet infos
        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let timelineItem = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case let .homeTimelineIndex(timelineIndexObjectID, _) = timelineItem else { return }
        let timelineIndex = viewModel.fetchedResultsController.managedObjectContext.object(with: timelineIndexObjectID) as! TimelineIndex
        guard let tweet = timelineIndex.tweet else { return }
        let tweetObjectID = tweet.objectID
        
        let targetFavoriteKind: Twitter.API.Favorites.FavoriteKind = {
            let targetTweet = (tweet.retweet ?? tweet)
            let isLiked = targetTweet.likeBy.flatMap { $0.contains(where: { $0.id == twitterUserID }) } ?? false
            return isLiked ? .destroy : .create
        }()
        
        // trigger like action
        let generator = UIImpactFeedbackGenerator(style: .light)
        let responseFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        context.apiService.like(
            tweetObjectID: tweetObjectID,
            twitterUserObjectID: twitterUserObjectID,
            favoriteKind: targetFavoriteKind,
            authorization: authorization,
            twitterUserID: twitterUserID
        )
        .receive(on: DispatchQueue.main)
        .handleEvents { _ in
            generator.prepare()
            responseFeedbackGenerator.prepare()
        } receiveOutput: { _ in
            generator.impactOccurred()
        } receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                // TODO: handle error
                break
            case .finished:
                os_log("%{public}s[%{public}ld], %{public}s: [Like] update local tweet like status to: %s", ((#file as NSString).lastPathComponent), #line, #function, targetFavoriteKind == .create ? "like" : "unlike")
                
                // reload item
                DispatchQueue.main.async {
                    var snapshot = diffableDataSource.snapshot()
                    snapshot.reloadItems([timelineItem])
                    diffableDataSource.defaultRowAnimation = .none
                    diffableDataSource.apply(snapshot)
                    diffableDataSource.defaultRowAnimation = .automatic
                }
            }
        }
        .map { targetTweetID in
            self.context.apiService.like(
                tweetID: targetTweetID,
                favoriteKind: targetFavoriteKind,
                authorization: authorization,
                twitterUserID: twitterUserID
            )
        }
        .switchToLatest()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            if self.view.window != nil, (self.tableView.indexPathsForVisibleRows ?? []).contains(indexPath) {
                responseFeedbackGenerator.impactOccurred()
            }
            switch completion {
            case .failure(let error):
                os_log("%{public}s[%{public}ld], %{public}s: [Like] remote like request fail: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            case .finished:
                os_log("%{public}s[%{public}ld], %{public}s: [Like] remote like request success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        } receiveValue: { response in
            // do nothing
        }
        .store(in: &disposeBag)
    }
    
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
