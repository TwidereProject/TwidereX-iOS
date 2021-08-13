//
//  StatusProvider+TimelinePostTableViewCellDelegate.swift
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
import TwitterSDK
import ActiveLabel

extension TimelinePostTableViewCellDelegate where Self: StatusProvider {
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, retweetInfoLabelDidPressed label: UILabel) {
        StatusProviderFacade.coordinateToStatusAuthorProfileScene(for: .retweet, provider: self, cell: cell)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, avatarImageViewDidPressed imageView: UIImageView) {
        StatusProviderFacade.coordinateToStatusAuthorProfileScene(for: .tweet, provider: self, cell: cell)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView) {
        StatusProviderFacade.coordinateToStatusAuthorProfileScene(for: .quote, provider: self, cell: cell)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, quotePostViewDidPressed quotePostView: QuotePostView) {
        StatusProviderFacade.coordinateToStatusConversationScene(for: .quote, provider: self, cell: cell)
    }
    
}
    
// MARK: - ActionToolbarContainerDelegate
extension TimelinePostTableViewCellDelegate where Self: StatusProvider {

    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbarContainer: ActionToolbarContainer, replayButtonDidPressed sender: UIButton) {
        StatusProviderFacade.coordinateToStatusReplyScene(provider: self, cell: cell)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbarContainer: ActionToolbarContainer, retweetButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusRetweetAction(provider: self, cell: cell)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbarContainer: ActionToolbarContainer, likeButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusLikeAction(provider: self, cell: cell)
    }
    
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, actionToolbarContainer: ActionToolbarContainer, menuButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusMenuAction(provider: self, cell: cell, sender: sender)
    }
    
}

// MARK: - MosaicImageViewDelegate
extension TimelinePostTableViewCellDelegate where Self: StatusProvider & MediaPreviewableViewController {
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, mosaicImageView: MosaicImageView, didTapImageView imageView: UIImageView, atIndex index: Int) {
        StatusProviderFacade.coordinateToStatusMediaPreviewScene(provider: self, cell: cell, mosaicImageView: mosaicImageView, didTapImageView: imageView, atIndex: index)
    }
}

extension TimelinePostTableViewCellDelegate where Self: StatusProvider {
    func timelinePostTableViewCell(_ cell: TimelinePostTableViewCell, activeLabel: ActiveLabel, didTapEntity entity: ActiveEntity) {
        StatusProviderFacade.responseToStatusActiveLabelAction(provider: self, cell: cell, activeLabel: activeLabel, didTapEntity: entity)
    }
}
