//
//  EntityProvider+TimelinePostTableViewCellDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/10.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI
import ActiveLabel

extension TimelinePostTableViewCellDelegate where Self: TweetProvider {
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, retweetInfoLabelDidPressed label: UILabel) {
        tweet(for: cell)
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = tweet else { return }
                let twitterUser = tweet.author
                
                let profileViewModel = ProfileViewModel(twitterUser: twitterUser)
                self.context.authenticationService.activeAuthenticationIndex
                    .map { $0?.twitterAuthentication?.twitterUser }
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser)
                    .store(in: &profileViewModel.disposeBag)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
                }
            }
            .store(in: &disposeBag)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, avatarImageViewDidPressed imageView: UIImageView) {
        tweet(for: cell)
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = tweet?.retweet ?? tweet else { return }
                let twitterUser = tweet.author
                
                let profileViewModel = ProfileViewModel(twitterUser: twitterUser)
                self.context.authenticationService.activeAuthenticationIndex
                    .map { $0?.twitterAuthentication?.twitterUser }
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser)
                    .store(in: &profileViewModel.disposeBag)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
                }
            }
            .store(in: &disposeBag)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView) {
        tweet(for: cell)
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = tweet?.retweet?.quote ?? tweet?.quote else { return }
                let twitterUser = tweet.author
                
                let profileViewModel = ProfileViewModel(twitterUser: twitterUser)
                self.context.authenticationService.activeAuthenticationIndex
                    .map { $0?.twitterAuthentication?.twitterUser }
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser)
                    .store(in: &profileViewModel.disposeBag)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
                }
            }
            .store(in: &disposeBag)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, quotePostViewDidPressed quotePostView: QuotePostView) {
        tweet(for: cell)
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = (tweet?.retweet ?? tweet)?.quote else { return }
                
                let tweetPostViewModel = TweetConversationViewModel(context: self.context, tweetObjectID: tweet.objectID)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .tweetConversation(viewModel: tweetPostViewModel), from: self, transition: .show)
                }
            }
            .store(in: &disposeBag)
    }
    
    // MARK: - ActionToolbar
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, replayButtonDidPressed sender: UIButton) {
        tweet(for: cell)
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = (tweet?.retweet ?? tweet) else { return }
                let tweetObjectID = tweet.objectID
                
                let composeTweetViewModel = ComposeTweetViewModel(context: self.context, repliedTweetObjectID: tweetObjectID)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .composeTweet(viewModel: composeTweetViewModel), from: self, transition: .modal(animated: true, completion: nil))
                }
            }
            .store(in: &disposeBag)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, retweetButtonDidPressed sender: UIButton) {
        // prepare authentication
        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
            assertionFailure()
            return
        }
        
        // prepare current user infos
        guard let _currentTwitterUser = context.authenticationService.activeAuthenticationIndex.value?.twitterAuthentication?.twitterUser else {
            assertionFailure()
            return
        }
        let twitterUserID = activeTwitterAuthenticationBox.twitterUserID
        assert(_currentTwitterUser.id == twitterUserID)
        let twitterUserObjectID = _currentTwitterUser.objectID
        
        guard let context = self.context else { return }
        
        // haptic feedback generator
        let generator = UIImpactFeedbackGenerator(style: .light)
        let responseFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        
        tweet(for: cell)
            .compactMap { tweet -> (NSManagedObjectID, Twitter.API.Statuses.RetweetKind)? in
                guard let tweet = tweet else { return nil }
                let retweetKind: Twitter.API.Statuses.RetweetKind = {
                    let targetTweet = (tweet.retweet ?? tweet)
                    let isRetweeted = targetTweet.retweetBy.flatMap { $0.contains(where: { $0.id == twitterUserID }) } ?? false
                    return isRetweeted ? .unretweet : .retweet
                }()
                return (tweet.objectID, retweetKind)
            }
            .map { tweetObjectID, retweetKind -> AnyPublisher<(Tweet.ID, Twitter.API.Statuses.RetweetKind), Error>  in
                return context.apiService.retweet(
                    tweetObjectID: tweetObjectID,
                    twitterUserObjectID: twitterUserObjectID,
                    retweetKind: retweetKind,
                    twitterAuthenticationBox: activeTwitterAuthenticationBox
                )
                .map { tweetID in (tweetID, retweetKind) }
                .eraseToAnyPublisher()
            }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .handleEvents { _ in
                generator.prepare()
                responseFeedbackGenerator.prepare()
            } receiveOutput: { _, retweetKind in
                generator.impactOccurred()
                os_log("%{public}s[%{public}ld], %{public}s: [Retweet] update local tweet retweet status to: %s", ((#file as NSString).lastPathComponent), #line, #function, retweetKind == .retweet ? "retweet" : "unretweet")
            } receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    // TODO: handle error
                    break
                case .finished:
                    break
                }
            }
            .map { tweetID, retweetKind in
                return context.apiService.retweet(
                    tweetID: tweetID,
                    retweetKind: retweetKind,
                    twitterAuthenticationBox: activeTwitterAuthenticationBox
                )
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                if self.view.window != nil {
                    responseFeedbackGenerator.impactOccurred()
                }
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: [Retweet] remote retweet request fail: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                case .finished:
                    os_log("%{public}s[%{public}ld], %{public}s: [Retweet] remote retweet request success", ((#file as NSString).lastPathComponent), #line, #function)
                }
            } receiveValue: { response in
                // do nothing
            }
            .store(in: &disposeBag)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, favoriteButtonDidPressed sender: UIButton) {
        // prepare authentication
        guard let activeTwitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else {
            assertionFailure()
            return
        }
        
        // prepare current user infos
        guard let _currentTwitterUser = context.authenticationService.activeAuthenticationIndex.value?.twitterAuthentication?.twitterUser else {
            assertionFailure()
            return
        }
        let twitterUserID = activeTwitterAuthenticationBox.twitterUserID
        assert(_currentTwitterUser.id == twitterUserID)
        let twitterUserObjectID = _currentTwitterUser.objectID
        
        guard let context = self.context else { return }
        
        // haptic feedback generator
        let generator = UIImpactFeedbackGenerator(style: .light)
        let responseFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

        tweet(for: cell)
            .compactMap { tweet -> (NSManagedObjectID, Twitter.API.Favorites.FavoriteKind)? in
                guard let tweet = tweet else { return nil }
                let favoriteKind: Twitter.API.Favorites.FavoriteKind = {
                    let targetTweet = (tweet.retweet ?? tweet)
                    let isLiked = targetTweet.likeBy.flatMap { $0.contains(where: { $0.id == twitterUserID }) } ?? false
                    return isLiked ? .destroy : .create
                }()
                return (tweet.objectID, favoriteKind)
            }
            .map { tweetObjectID, favoriteKind -> AnyPublisher<(Tweet.ID, Twitter.API.Favorites.FavoriteKind), Error>  in
                return context.apiService.like(
                    tweetObjectID: tweetObjectID,
                    twitterUserObjectID: twitterUserObjectID,
                    favoriteKind: favoriteKind
                )
                .map { tweetID in (tweetID, favoriteKind) }
                .eraseToAnyPublisher()
            }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .handleEvents { _ in
                generator.prepare()
                responseFeedbackGenerator.prepare()
            } receiveOutput: { _, favoriteKind in
                generator.impactOccurred()
                os_log("%{public}s[%{public}ld], %{public}s: [Like] update local tweet like status to: %s", ((#file as NSString).lastPathComponent), #line, #function, favoriteKind == .create ? "like" : "unlike")
            } receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    // TODO: handle error
                    break
                case .finished:
                    break
                }
            }
            .map { tweetID, favoriteKind in
                return context.apiService.like(
                    tweetID: tweetID,
                    favoriteKind: favoriteKind,
                    twitterAuthenticationBox: activeTwitterAuthenticationBox
                )
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                if self.view.window != nil {
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
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, shareButtonDidPressed sender: UIButton) {
        tweet(for: cell)
            .compactMap { $0?.activityItems }
            .sink { [weak self] activityItems in
                guard let self = self else { return }
                let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: [SafariActivity(sceneCoordinator: self.coordinator)])
                activityViewController.popoverPresentationController?.sourceView = sender
                self.present(activityViewController, animated: true, completion: nil)
            }
            .store(in: &disposeBag)
    }
    
}

extension TimelinePostTableViewCellDelegate where Self: TweetProvider & MediaPreviewableViewController {
    // MARK: - MosaicImageViewDelegate
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, mosaicImageView: MosaicImageView, didTapImageView imageView: UIImageView, atIndex index: Int) {
        tweet(for: cell)
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = (tweet?.retweet ?? tweet) else { return }
                
                let root = MediaPreviewViewModel.TweetImagePreviewMeta(
                    tweetObjectID: tweet.objectID,
                    initialIndex: index,
                    preloadThumbnailImages: mosaicImageView.imageViews.map { $0.image }
                )
                let mediaPreviewViewModel = MediaPreviewViewModel(context: self.context, meta: root)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .mediaPreview(viewModel: mediaPreviewViewModel), from: self, transition: .custom(transitioningDelegate: self.mediaPreviewTransitionController))
                }
            }
            .store(in: &disposeBag)
    }
}

extension TimelinePostTableViewCellDelegate where Self: TweetProvider {

    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, activeLabel: ActiveLabel, didTapEntity entity: ActiveEntity) {
        switch entity.type {
        case .mention(let text):
            timelinePostTableViewCell(cell, didTapMention: text, isQuote: false)
        case .url(let originalURL, _):
            guard let url = URL(string: originalURL) else { return }
            coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        default:
            break
        }
    }
    
    private func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, didTapMention mention: String, isQuote: Bool) {
        tweet(for: cell)
            .sink { [weak self] tweet in
                guard let self = self else { return }
                let _tweet: Tweet? = isQuote ? (tweet?.retweet?.quote ?? tweet?.quote) : (tweet?.retweet ?? tweet)
                guard let tweet = _tweet else { return }
                
                let profileViewModel: ProfileViewModel = {
                    let targetUsername: String
                    var targetUserID: TwitterUser.ID?
                    var targetUser: TwitterUser?
                    if let mentionEntity = (tweet.entities?.mentions ?? Set()).first(where: { $0.username == mention }) {
                        targetUsername = mentionEntity.username ?? mention
                        targetUserID = mentionEntity.userID
                        targetUser = mentionEntity.user
                    } else {
                        targetUsername = mention
                        targetUserID = nil
                        targetUser = nil
                    }
                    
                    if targetUser == nil {
                        targetUser = {
                            let userRequest = TwitterUser.sortedFetchRequest
                            userRequest.fetchLimit = 1
                            userRequest.predicate = {
                                if let targetUserID = targetUserID {
                                    return TwitterUser.predicate(idStr: targetUserID)
                                } else {
                                    return TwitterUser.predicate(username: targetUsername)
                                }
                            }()
                            do {
                                return try self.context.managedObjectContext.fetch(userRequest).first
                            } catch {
                                assertionFailure(error.localizedDescription)
                                return nil
                            }
                        }()
                    }
                    
                    if let targetUser = targetUser {
                        let activeAuthenticationIndex = self.context.authenticationService.activeAuthenticationIndex.value
                        let currentTwitterUser = activeAuthenticationIndex?.twitterAuthentication?.twitterUser
                        if targetUser.id == currentTwitterUser?.id {
                            return MeProfileViewModel(activeAuthenticationIndex: activeAuthenticationIndex)
                        } else {
                            return ProfileViewModel(twitterUser: targetUser)
                        }
                    } else {
                        if let targetUserID = targetUserID {
                            return ProfileViewModel(context: self.context, userID: targetUserID)
                        } else {
                            return ProfileViewModel(context: self.context, username: targetUsername)
                        }
                    }
                }()
                self.context.authenticationService.activeAuthenticationIndex
                    .map { $0?.twitterAuthentication?.twitterUser }
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser)
                    .store(in: &profileViewModel.disposeBag)
                
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
                }
            }
            .store(in: &disposeBag)
    }

}
