//
//  RepliedToTweetContentTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-23.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

final class RepliedToTweetContentTableViewCell: UITableViewCell {
    
    static let avatarImageViewSize = CGSize(width: 44, height: 44)
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    let timelinePostView = TimelinePostView()
    let conversationLinkUpper = UIView.separatorLine
    let conversationLinkLower = UIView.separatorLine
    
    let framePublisher = PassthroughSubject<CGRect, Never>()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        timelinePostView.mosaicImageView.reset()
        timelinePostView.mosaicImageView.isHidden = true
        timelinePostView.quotePostView.isHidden = true
        timelinePostView.avatarImageView.af.cancelImageRequest()
        conversationLinkUpper.isHidden = true
        conversationLinkLower.isHidden = true
        disposeBag.removeAll()
        observations.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        framePublisher.send(bounds)
    }
    
}

extension RepliedToTweetContentTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        timelinePostView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timelinePostView)
        NSLayoutConstraint.activate([
            timelinePostView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: TimelinePostTableViewCell.verticalMargin),
            timelinePostView.leadingAnchor.constraint(equalTo:  contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: timelinePostView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: timelinePostView.bottomAnchor, constant: 8),
        ])
        
        conversationLinkUpper.translatesAutoresizingMaskIntoConstraints = false
        conversationLinkLower.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(conversationLinkUpper)
        contentView.addSubview(conversationLinkLower)
        NSLayoutConstraint.activate([
            conversationLinkUpper.topAnchor.constraint(equalTo: contentView.topAnchor),
            conversationLinkUpper.centerXAnchor.constraint(equalTo: timelinePostView.avatarImageView.centerXAnchor),
            timelinePostView.avatarImageView.topAnchor.constraint(equalTo: conversationLinkUpper.bottomAnchor, constant: 2),
            conversationLinkUpper.widthAnchor.constraint(equalToConstant: 1),
            conversationLinkLower.topAnchor.constraint(equalTo: timelinePostView.avatarImageView.bottomAnchor, constant: 2),
            conversationLinkLower.centerXAnchor.constraint(equalTo: timelinePostView.avatarImageView.centerXAnchor),
            contentView.bottomAnchor.constraint(equalTo: conversationLinkLower.bottomAnchor),
            conversationLinkLower.widthAnchor.constraint(equalToConstant: 1),
        ])
        
        timelinePostView.actionToolbarContainer.isHidden = true
        conversationLinkUpper.isHidden = true
        conversationLinkLower.isHidden = true
    }
    
}
