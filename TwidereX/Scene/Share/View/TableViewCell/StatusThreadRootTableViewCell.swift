//
//  StatusThreadRootTableViewCell.swift
//  StatusThreadRootTableViewCell
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class StatusThreadRootTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "StatusThreadRootTableViewCell", category: "UI")
    
    weak var delegate: StatusViewTableViewCellDelegate?
    
    let conversationLinkLineView = SeparatorLineView()
    let statusView = StatusView()
    let toolbarSeparator = SeparatorLineView()
    let separator = SeparatorLineView()

    override func prepareForReuse() {
        super.prepareForReuse()
        
        statusView.prepareForReuse()
        disposeBag.removeAll()
        conversationLinkLineView.isHidden = true
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension StatusThreadRootTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            statusView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        statusView.setup(style: .plain)
        statusView.toolbar.setup(style: .plain)
        
        conversationLinkLineView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(conversationLinkLineView)
        NSLayoutConstraint.activate([
            conversationLinkLineView.topAnchor.constraint(equalTo: contentView.topAnchor),
            conversationLinkLineView.centerXAnchor.constraint(equalTo: statusView.authorAvatarButton.centerXAnchor),
            conversationLinkLineView.widthAnchor.constraint(equalToConstant: 1),
            statusView.authorAvatarButton.topAnchor.constraint(equalTo: conversationLinkLineView.bottomAnchor, constant: 2),
        ])
        conversationLinkLineView.isHidden = true
        
        toolbarSeparator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(toolbarSeparator)
        NSLayoutConstraint.activate([
            toolbarSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            toolbarSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            toolbarSeparator.bottomAnchor.constraint(equalTo: statusView.toolbar.topAnchor),
        ])
        
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        statusView.delegate = self
    }
    
}

extension StatusThreadRootTableViewCell {

    func setConversationLinkLineViewDisplay() {
        conversationLinkLineView.isHidden = false
    }
    
}

// MARK: - StatusViewContainerTableViewCell
extension StatusThreadRootTableViewCell: StatusViewContainerTableViewCell { }

// MARK: - StatusViewDelegate
extension StatusThreadRootTableViewCell: StatusViewDelegate { }
