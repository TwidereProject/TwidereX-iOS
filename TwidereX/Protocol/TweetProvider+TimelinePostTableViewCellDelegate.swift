//
//  EntityProvider+TimelinePostTableViewCellDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/10.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

extension TimelinePostTableViewCellDelegate where Self: TweetProvider {
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, retweetInfoLabelDidPressed label: UILabel) {
        tweet(for: cell)
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = tweet else { return }
                let twitterUser = tweet.author
                
                let profileViewModel = ProfileViewModel(twitterUser: twitterUser)
                self.context.authenticationService.currentTwitterUser
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser).store(in: &profileViewModel.disposeBag)
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
                self.context.authenticationService.currentTwitterUser
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser).store(in: &profileViewModel.disposeBag)
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
                self.context.authenticationService.currentTwitterUser
                    .assign(to: \.value, on: profileViewModel.currentTwitterUser).store(in: &profileViewModel.disposeBag)
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
                guard let tweet = tweet?.quote else { return }
                
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
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, shareButtonDidPressed sender: UIButton) {
        tweet(for: cell)
            .compactMap { $0?.activityItems }
            .sink { [weak self] activityItems in
                guard let self = self else { return }
                let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                self.present(activityViewController, animated: true, completion: nil)
            }
            .store(in: &disposeBag)
        
    }
    
}
