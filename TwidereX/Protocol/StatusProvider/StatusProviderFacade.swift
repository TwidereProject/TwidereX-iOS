//
//  StatusProviderFacade.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI
import ActiveLabel

enum StatusProviderFacade {
    
    static func coordinateToStatusAuthorProfileScene(for target: Target, provider: StatusProvider) {
        _coordinateToStatusAuthorProfileScene(
            for: target,
            provider: provider,
            tweet: provider.tweet()
        )
    }
    
    static func coordinateToStatusAuthorProfileScene(for target: Target, provider: StatusProvider, cell: UITableViewCell) {
        _coordinateToStatusAuthorProfileScene(
            for: target,
            provider: provider,
            tweet: provider.tweet(for: cell, indexPath: nil)
        )
    }
    
    private static func _coordinateToStatusAuthorProfileScene(for target: Target, provider: StatusProvider, tweet: Future<Tweet?, Never>) {
        tweet
            .sink { [weak provider] tweet in
                guard let provider = provider else { return }
                let _tweet: Tweet? = {
                    switch target {
                    case .tweet:    return tweet?.retweet ?? tweet
                    case .retweet:  return tweet
                    case .quote:    return tweet?.retweet?.quote ?? tweet?.quote
                    }
                }()
                guard let tweet = _tweet else { return }
                
                let twitterUser = tweet.author
                let profileViewModel = ProfileViewModel(context: provider.context, twitterUser: twitterUser)
                DispatchQueue.main.async {
                    let from = provider.presentingViewController ?? provider
                    if provider.navigationController == nil {
                        provider.dismiss(animated: true) {
                            provider.coordinator.present(scene: .profile(viewModel: profileViewModel), from: from, transition: .show)
                        }
                    } else {
                        provider.coordinator.present(scene: .profile(viewModel: profileViewModel), from: from, transition: .show)
                    }
                }
            }
            .store(in: &provider.disposeBag)
    }

    static func coordinateToStatusConversationScene(for target: Target, provider: StatusProvider) {
        _coordinateToStatusConversationScene(
            for: target,
            provider: provider,
            tweet: provider.tweet()
        )
    }
    
    static func coordinateToStatusConversationScene(for target: Target, provider: StatusProvider, cell: UITableViewCell, indexPath: IndexPath? = nil) {
        _coordinateToStatusConversationScene(
            for: target,
            provider: provider,
            tweet: provider.tweet(for: cell, indexPath: indexPath)
        )
    }
    
    private static func _coordinateToStatusConversationScene(for target: Target, provider: StatusProvider, tweet: Future<Tweet?, Never>) {
        tweet
            .sink { [weak provider] tweet in
                guard let provider = provider else { return }
                let _tweet: Tweet? = {
                    switch target {
                    case .tweet:    return tweet?.retweet ?? tweet
                    case .retweet:  return tweet
                    case .quote:    return tweet?.retweet?.quote ?? tweet?.quote
                    }
                }()
                guard let tweet = _tweet else { return }
                
                provider.context.videoPlaybackService.markTransitioning(for: tweet)
                let tweetPostViewModel = TweetConversationViewModel(context: provider.context, tweetObjectID: tweet.objectID)
                DispatchQueue.main.async {
                    let from = provider.presentingViewController ?? provider
                    if provider.navigationController == nil {
                        provider.dismiss(animated: true) {
                            provider.coordinator.present(scene: .tweetConversation(viewModel: tweetPostViewModel), from: from, transition: .show)
                        }
                    } else {
                        provider.coordinator.present(scene: .tweetConversation(viewModel: tweetPostViewModel), from: from, transition: .show)
                    }
                }
            }
            .store(in: &provider.disposeBag)
    }
}

extension StatusProviderFacade {
    
    static func coordinateToStatusReplyScene(provider: StatusProvider) {
        _coordinateToStatusReplyScene(
            provider: provider,
            tweet: provider.tweet()
        )
    }
    
    static func coordinateToStatusReplyScene(provider: StatusProvider, cell: UITableViewCell) {
        _coordinateToStatusReplyScene(
            provider: provider,
            tweet: provider.tweet(for: cell, indexPath: nil)
        )
    }
    
    private static func _coordinateToStatusReplyScene(provider: StatusProvider, tweet: Future<Tweet?, Never>) {
        tweet
            .sink { [weak provider] tweet in
                guard let provider = provider else { return }
                guard let tweet = (tweet?.retweet ?? tweet) else { return }
                
                let tweetObjectID = tweet.objectID
                let composeTweetViewModel = ComposeTweetViewModel(context: provider.context, repliedTweetObjectID: tweetObjectID)
                DispatchQueue.main.async {
                    provider.coordinator.present(scene: .composeTweet(viewModel: composeTweetViewModel), from: provider, transition: .modal(animated: true, completion: nil))
                }
            }
            .store(in: &provider.disposeBag)
    }
    
    static func responseToStatusRetweetAction(provider: StatusProvider) {
        _responseToStatusRetweetAction(
            provider: provider,
            tweet: provider.tweet()
        )
    }
    
    static func responseToStatusRetweetAction(provider: StatusProvider, cell: UITableViewCell) {
        _responseToStatusRetweetAction(
            provider: provider,
            tweet: provider.tweet(for: cell, indexPath: nil)
        )
    }
    
    private static func _responseToStatusRetweetAction(provider: StatusProvider, tweet: Future<Tweet?, Never>) {
        // prepare authentication
        guard let activeTwitterAuthenticationBox = provider.context.authenticationService.activeTwitterAuthenticationBox.value else {
            assertionFailure()
            return
        }
        
        // prepare current user infos
        guard let _currentTwitterUser = provider.context.authenticationService.activeAuthenticationIndex.value?.twitterAuthentication?.twitterUser else {
            assertionFailure()
            return
        }
        let twitterUserID = activeTwitterAuthenticationBox.twitterUserID
        assert(_currentTwitterUser.id == twitterUserID)
        let twitterUserObjectID = _currentTwitterUser.objectID
        
        guard let context = provider.context else { return }
        
        // haptic feedback generator
        let generator = UIImpactFeedbackGenerator(style: .light)
        let responseFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        
        tweet
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
            .sink { [weak provider] completion in
                guard let provider = provider else { return }
                if provider.view.window != nil {
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
            .store(in: &provider.disposeBag)
    }
    
    static func responseToStatusLikeAction(provider: StatusProvider) {
        _responseToStatusLikeAction(
            provider: provider,
            tweet: provider.tweet()
        )
    }
    
    static func responseToStatusLikeAction(provider: StatusProvider, cell: UITableViewCell) {
        _responseToStatusLikeAction(
            provider: provider,
            tweet: provider.tweet(for: cell, indexPath: nil)
        )
    }
    
    private static func _responseToStatusLikeAction(provider: StatusProvider, tweet: Future<Tweet?, Never>) {
        // prepare authentication
        guard let activeTwitterAuthenticationBox = provider.context.authenticationService.activeTwitterAuthenticationBox.value else {
            assertionFailure()
            return
        }
        
        // prepare current user infos
        guard let _currentTwitterUser = provider.context.authenticationService.activeAuthenticationIndex.value?.twitterAuthentication?.twitterUser else {
            assertionFailure()
            return
        }
        let twitterUserID = activeTwitterAuthenticationBox.twitterUserID
        assert(_currentTwitterUser.id == twitterUserID)
        let twitterUserObjectID = _currentTwitterUser.objectID
        
        guard let context = provider.context else { return }
        
        // haptic feedback generator
        let generator = UIImpactFeedbackGenerator(style: .light)
        let responseFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        
        tweet
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
            .sink { [weak provider] completion in
                guard let provider = provider else { return }
                if provider.view.window != nil {
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
            .store(in: &provider.disposeBag)
    }
    
    static func responseToStatusMenuAction(provider: StatusProvider, sender: UIButton) {
        _responseToStatusMenuAction(
            provider: provider,
            tweet: provider.tweet(),
            sender: sender
        )
    }
    
    static func responseToStatusMenuAction(provider: StatusProvider, cell: UITableViewCell, sender: UIButton) {
        _responseToStatusMenuAction(
            provider: provider,
            tweet: provider.tweet(for: cell, indexPath: nil),
            sender: sender
        )
    }

    private static func _responseToStatusMenuAction(provider: StatusProvider, tweet: Future<Tweet?, Never>, sender: UIButton) {
        tweet
            .sink { [weak provider, weak sender] tweet in
                guard let tweet = tweet else { return }
                guard let provider = provider else { return }
                guard let sender = sender else { return }
                
                let activityViewController = createActivityViewControllerForStatus(tweet: tweet, dependency: provider)
                DispatchQueue.main.async {
                    provider.coordinator.present(
                        scene: .activityViewController(activityViewController: activityViewController, sourceView: sender),
                        from: provider,
                        transition: .activityViewControllerPresent(animated: true, completion: nil)
                    )
                }
            }
            .store(in: &provider.disposeBag)
    }
    
}

extension StatusProviderFacade {
    
    static func createMenuForStatus(tweet: Tweet, sender: UIButton, dependency: NeedsDependency) -> UIMenu {
        let copiedText = (tweet.retweet ?? tweet).displayText
        let copiedLink = tweet.tweetURL.absoluteString
        
        var children: [UIMenuElement] = [
            UIAction(title: L10n.Common.Controls.Status.Actions.copyText.capitalized, image: UIImage(systemName: "doc.on.doc"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { _ in
                UIPasteboard.general.string = copiedText
            },
            UIAction(title: L10n.Common.Controls.Status.Actions.copyLink.capitalized, image: UIImage(systemName: "link"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { _ in
                UIPasteboard.general.string = copiedLink
            },
            UIAction(title: L10n.Common.Controls.Status.Actions.shareLink.capitalized, image: UIImage(systemName: "square.and.arrow.up"), identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { [weak sender, weak dependency] _ in
                guard let sender = sender else { return }
                guard let dependency = dependency else { return }
                let activityViewController = StatusProviderFacade.createActivityViewControllerForStatus(tweet: tweet, dependency: dependency)
                DispatchQueue.main.async {
                    dependency.coordinator.present(
                        scene: .activityViewController(activityViewController: activityViewController, sourceView: sender),
                        from: nil,
                        transition: .activityViewControllerPresent(animated: true, completion: nil)
                    )
                }
            }
        ]
        
        if let activeTwitterAuthenticationBox = dependency.context.authenticationService.activeTwitterAuthenticationBox.value {
            let activeTwitterUserID = activeTwitterAuthenticationBox.twitterUserID
            if tweet.author.id == activeTwitterUserID || tweet.retweet?.id == activeTwitterUserID {
                let deleteTweetAction = UIAction(title: L10n.Common.Controls.Status.Actions.deleteTweet.capitalized, image: UIImage(systemName: "trash"), identifier: nil, discoverabilityTitle: nil, attributes: .destructive, state: .off) { [weak dependency] _ in
                    guard let dependency = dependency else { return }
                    guard let activeTwitterAuthenticationBox = dependency.context.authenticationService.activeTwitterAuthenticationBox.value else {
                        return
                    }
                    dependency.context.apiService.delete(
                        tweetObjectID: tweet.objectID,
                        twitterAuthenticationBox: activeTwitterAuthenticationBox
                    )
                    .sink { completion in
                        
                    } receiveValue: { response in
                        
                    }
                    .store(in: &dependency.context.disposeBag)
                }
                children.append(deleteTweetAction)
            }
        }
        
        return UIMenu(title: "", options: [], children: children)
    }
    
    static func createActivityViewControllerForStatus(tweet: Tweet, dependency: NeedsDependency) -> UIActivityViewController {
        let activityItems: [Any] = {
            if #available(iOS 14, *) {
                // only share tweet link due to context menu contains text copy option
                return [tweet.tweetURL]
            } else {
                return tweet.activityItems
            }
        }()
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: [SafariActivity(sceneCoordinator: dependency.coordinator)]
        )
        return activityViewController
    }
    
}

extension StatusProviderFacade {
    static func coordinateToStatusMediaPreviewScene(provider: StatusProvider & MediaPreviewableViewController, cell: UITableViewCell, mosaicImageView: MosaicImageView, didTapImageView imageView: UIImageView, atIndex index: Int) {
        provider.tweet(for: cell, indexPath: nil)
            .sink { [weak provider] tweet in
                guard let provider = provider else { return }
                guard let tweet = (tweet?.retweet ?? tweet) else { return }
                
                let root = MediaPreviewViewModel.TweetImagePreviewMeta(
                    tweetObjectID: tweet.objectID,
                    initialIndex: index,
                    preloadThumbnailImages: mosaicImageView.imageViews.map { $0.image }
                )
                let mediaPreviewViewModel = MediaPreviewViewModel(context: provider.context, meta: root)
                DispatchQueue.main.async {
                    provider.coordinator.present(scene: .mediaPreview(viewModel: mediaPreviewViewModel), from: provider, transition: .custom(transitioningDelegate: provider.mediaPreviewTransitionController))
                }
            }
            .store(in: &provider.disposeBag)
    }
}

extension StatusProviderFacade {

    static func responseToStatusActiveLabelAction(provider: StatusProvider, cell: UITableViewCell, activeLabel: ActiveLabel, didTapEntity entity: ActiveEntity) {
        switch entity.type {
        case .mention(let text):
            coordinateToStatusMentionProfileScene(for: .tweet, provider: provider, cell: cell, mention: text)
        case .url(let originalURL, _):
            guard let url = URL(string: originalURL) else { return }
            provider.coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        default:
            break
        }
    }
    
    private static func coordinateToStatusMentionProfileScene(for target: Target, provider: StatusProvider, cell: UITableViewCell, mention: String) {
        provider.tweet(for: cell, indexPath: nil)
            .sink { [weak provider] tweet in
                guard let provider = provider else { return }
                let _tweet: Tweet? = {
                    switch target {
                    case .tweet:    return tweet?.retweet ?? tweet
                    case .retweet:  return tweet
                    case .quote:    return tweet?.retweet?.quote ?? tweet?.quote
                    }
                }()
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
                                return try provider.context.managedObjectContext.fetch(userRequest).first
                            } catch {
                                assertionFailure(error.localizedDescription)
                                return nil
                            }
                        }()
                    }
                    
                    if let targetUser = targetUser {
                        let activeAuthenticationIndex = provider.context.authenticationService.activeAuthenticationIndex.value
                        let currentTwitterUser = activeAuthenticationIndex?.twitterAuthentication?.twitterUser
                        if targetUser.id == currentTwitterUser?.id {
                            return MeProfileViewModel(context: provider.context)
                        } else {
                            return ProfileViewModel(context: provider.context, twitterUser: targetUser)
                        }
                    } else {
                        if let targetUserID = targetUserID {
                            return ProfileViewModel(context: provider.context, userID: targetUserID)
                        } else {
                            return ProfileViewModel(context: provider.context, username: targetUsername)
                        }
                    }
                }()
                
                DispatchQueue.main.async {
                    provider.coordinator.present(scene: .profile(viewModel: profileViewModel), from: provider, transition: .show)
                }
            }
            .store(in: &provider.disposeBag)
    }

}

extension StatusProviderFacade {
    enum Target {
        case tweet
        case retweet
        case quote
    }
}
 
