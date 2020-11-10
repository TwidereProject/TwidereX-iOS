//
//  TweetConversationViewController+TimelinePostTableViewCellDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/10.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import TwitterAPI

// MARK: - TimelinePostTableViewCellDelegate
extension TweetConversationViewController: TimelinePostTableViewCellDelegate {
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, retweetInfoLabelDidPressed label: UILabel) {
        assertionFailure("no retweet in conversation")
    }
    
    // MARK: - ActionToolbar
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView) {
        assertionFailure("no quote in conversation")
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, retweetButtonDidPressed sender: UIButton) {
        // TODO:
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbar: TimelinePostActionToolbar, favoriteButtonDidPressed sender: UIButton) {
        // TODO:
    }
    
    // MARK: - MosaicImageViewDelegate
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, mosaicImageView: MosaicImageView, didTapImageView imageView: UIImageView, atIndex index: Int) {
        // TODO:
    }
    
}
