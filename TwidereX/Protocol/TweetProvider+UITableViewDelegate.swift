//
//  TweetProvider+UITableViewDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/13.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit

// needs manually dispath
extension UITableViewDelegate where Self: TweetProvider {
    
    func handleTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        os_log("%{public}s[%{public}ld], %{public}s: indexPath %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
        guard let cell = tableView.cellForRow(at: indexPath) as? TimelinePostTableViewCell else { return }
        self.tweet(for: cell)
            .sink { [weak self] tweet in
                guard let self = self else { return }
                guard let tweet = (tweet?.retweet ?? tweet) else { return }
                
                let tweetPostViewModel = TweetConversationViewModel(context: self.context, tweetObjectID: tweet.objectID)
                DispatchQueue.main.async {
                    self.coordinator.present(scene: .tweetConversation(viewModel: tweetPostViewModel), from: self, transition: .show)
                }
            }
            .store(in: &disposeBag)
    }
    
}
