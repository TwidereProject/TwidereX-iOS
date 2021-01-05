//
//  StatusProvider+ConversationPostTableViewCellDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-13.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI
import ActiveLabel

extension ConversationPostTableViewCellDelegate where Self: StatusProvider {
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, retweetInfoLabelDidPressed label: UILabel) {
        StatusProviderFacade.coordinateToStatusAuthorProfileScene(for: .retweet, provider: self, cell: cell)
    }
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, avatarImageViewDidPressed imageView: UIImageView) {
        StatusProviderFacade.coordinateToStatusAuthorProfileScene(for: .tweet, provider: self, cell: cell)
    }
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, quoteAvatarImageViewDidPressed imageView: UIImageView) {
        StatusProviderFacade.coordinateToStatusAuthorProfileScene(for: .quote, provider: self, cell: cell)
    }
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, quotePostViewDidPressed quotePostView: QuotePostView) {
        StatusProviderFacade.coordinateToStatusConversationScene(for: .quote, provider: self, cell: cell)
    }
    
}

// MARK: - ActionToolbarContainerDelegate
extension ConversationPostTableViewCellDelegate where Self: StatusProvider {

    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, actionToolbar: StatusActionToolbar, replayButtonDidPressed sender: UIButton) {
        StatusProviderFacade.coordinateToStatusReplyScene(provider: self, cell: cell)
    }
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, actionToolbar: StatusActionToolbar, retweetButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusRetweetAction(provider: self, cell: cell)
    }
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, actionToolbar: StatusActionToolbar, favoriteButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusLikeAction(provider: self, cell: cell)
    }
    
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, actionToolbar: StatusActionToolbar, shareButtonDidPressed sender: UIButton) {
        StatusProviderFacade.responseToStatusMenuAction(provider: self, cell: cell, sender: sender)
    }
    
}

// MARK: - MosaicImageViewDelegate
extension ConversationPostTableViewCellDelegate where Self: StatusProvider & MediaPreviewableViewController {
    // MARK: - MosaicImageViewDelegate
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, mosaicImageView: MosaicImageView, didTapImageView imageView: UIImageView, atIndex index: Int) {
        StatusProviderFacade.coordinateToStatusMediaPreviewScene(provider: self, cell: cell, mosaicImageView: mosaicImageView, didTapImageView: imageView, atIndex: index)
    }
}

extension ConversationPostTableViewCellDelegate where Self: StatusProvider {
    func conversationPostTableViewCell(_ cell: ConversationPostTableViewCell, activeLabel: ActiveLabel, didTapEntity entity: ActiveEntity) {
        StatusProviderFacade.responseToStatusActiveLabelAction(provider: self, cell: cell, activeLabel: activeLabel, didTapEntity: entity)
    }
}
