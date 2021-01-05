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
    
    static func coordinateToStatusAuthorProfileScene(for target: Target, provider: StatusProvider, cell: UITableViewCell) {
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
                
                let twitterUser = tweet.author
                let profileViewModel = ProfileViewModel(context: provider.context, twitterUser: twitterUser)
                DispatchQueue.main.async {
                    provider.coordinator.present(scene: .profile(viewModel: profileViewModel), from: provider, transition: .show)
                }
            }
            .store(in: &provider.disposeBag)
    }
    
    static func coordinateToStatusConversationScene(for target: Target, provider: StatusProvider, cell: UITableViewCell) {
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
                
                provider.context.videoPlaybackService.markTransitioning(for: tweet)
                let tweetPostViewModel = TweetConversationViewModel(context: provider.context, tweetObjectID: tweet.objectID)
                DispatchQueue.main.async {
                    provider.coordinator.present(scene: .tweetConversation(viewModel: tweetPostViewModel), from: provider, transition: .show)
                }
            }
            .store(in: &provider.disposeBag)
    }
    
}

extension StatusProviderFacade {
    
    static func coordinateToStatusReplyScene(provider: StatusProvider, cell: UITableViewCell) {
        provider.tweet(for: cell, indexPath: nil)
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
    
    static func responseToStatusRetweetAction(provider: StatusProvider, cell: UITableViewCell) {
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
        
        provider.tweet(for: cell, indexPath: nil)
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
    
    static func responseToStatusLikeAction(provider: StatusProvider, cell: UITableViewCell) {
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
        
        provider.tweet(for: cell, indexPath: nil)
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
    
    static func responseToStatusMenuAction(provider: StatusProvider, cell: UITableViewCell, sender: UIButton) {
        provider.tweet(for: cell, indexPath: nil)
            .compactMap { $0?.activityItems }
            .sink { [weak provider] activityItems in
                guard let provider = provider else { return }
                let activityViewController = UIActivityViewController(
                    activityItems: activityItems,
                    applicationActivities: [SafariActivity(sceneCoordinator: provider.coordinator)]
                )
                activityViewController.popoverPresentationController?.sourceView = sender
                DispatchQueue.main.async {
                    provider.present(activityViewController, animated: true, completion: nil)
                }
            }
            .store(in: &provider.disposeBag)
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
