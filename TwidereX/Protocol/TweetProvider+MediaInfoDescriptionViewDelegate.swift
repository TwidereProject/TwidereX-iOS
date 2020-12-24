//
//  TweetProvider+MediaInfoDescriptionViewDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-16.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import ActiveLabel
import TwitterAPI

extension MediaInfoDescriptionViewDelegate where Self: TweetProvider {
    
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, avatarImageViewDidPressed imageView: UIImageView) {
        tweet()
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = tweet?.retweet ?? tweet else { return }
                let twitterUser = tweet.author
                
                let profileViewModel = ProfileViewModel(context: self.context, twitterUser: twitterUser)
                DispatchQueue.main.async {
                    let from: UIViewController? = {
                        guard let tabBarController = self.presentingViewController as? UITabBarController else {
                            assertionFailure()
                            return nil
                        }
                        return tabBarController.selectedViewController
                    }()
                    self.dismiss(animated: true) {
                        self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: from, transition: .show)
                    }
                }
            }
            .store(in: &disposeBag)
    }
    
    func mediaInfoDescriptionView(_ mediaInfoDescriptionView: MediaInfoDescriptionView, activeLabelDidPressed activeLabel: ActiveLabel) {
        tweet()
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = (tweet?.retweet ?? tweet) else { return }
                
                let tweetPostViewModel = TweetConversationViewModel(context: self.context, tweetObjectID: tweet.objectID)
                DispatchQueue.main.async {
                    let from: UIViewController? = {
                        guard let tabBarController = self.presentingViewController as? UITabBarController else {
                            assertionFailure()
                            return nil
                        }
                        return tabBarController.selectedViewController
                    }()
                    self.dismiss(animated: true) {
                        self.coordinator.present(scene: .tweetConversation(viewModel: tweetPostViewModel), from: from, transition: .show)
                    }
                }
            }
            .store(in: &disposeBag)
    }
    
}
