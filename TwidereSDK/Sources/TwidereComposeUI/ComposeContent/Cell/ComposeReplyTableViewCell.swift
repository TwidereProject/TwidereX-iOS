//
//  ComposeReplyTableViewCell.swift
//  
//
//  Created by MainasuK on 2021/11/22.
//

import os.log
import UIKit
import Combine
import TwidereCore
import TwidereUI

public final class ComposeReplyTableViewCell: UITableViewCell {
    
    let logger = Logger(subsystem: "ComposeReplyTableViewCell", category: "UI")
    
    var disposeBag = Set<AnyCancellable>()
    
    public let statusView = StatusView()
    
    public let conversationLinkLineView = SeparatorLineView()
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        statusView.prepareForReuse()
        statusView.toolbar.isHidden = true
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ComposeReplyTableViewCell {
    
    private func _init() {
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            statusView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        statusView.setup(style: .composeReply)
        
        conversationLinkLineView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(conversationLinkLineView)
        NSLayoutConstraint.activate([
            conversationLinkLineView.topAnchor.constraint(equalTo: statusView.authorAvatarButton.bottomAnchor, constant: 2),
            conversationLinkLineView.centerXAnchor.constraint(equalTo: statusView.authorAvatarButton.centerXAnchor),
            contentView.bottomAnchor.constraint(equalTo: conversationLinkLineView.bottomAnchor),
            conversationLinkLineView.widthAnchor.constraint(equalToConstant: 1),
        ])
        
        statusView.toolbar.isHidden = true
    }
    
}
