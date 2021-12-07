//
//  StatusTableViewCell.swift
//  StatusTableViewCell
//
//  Created by Cirno MainasuK on 2021-8-20.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

class StatusTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "StatusTableViewCell", category: "UI")
    
    weak var delegate: StatusViewTableViewCellDelegate?
    
    let topConversationLinkLineView = SeparatorLineView()
    let statusView = StatusView()
    let bottomConversationLinkLineView = SeparatorLineView()
    let separator = SeparatorLineView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        statusView.prepareForReuse()
        disposeBag.removeAll()
        topConversationLinkLineView.isHidden = true
        bottomConversationLinkLineView.isHidden = true
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

extension StatusTableViewCell {
    
    private func _init() {
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            statusView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        statusView.setup(style: .inline)
        statusView.toolbar.setup(style: .inline)
        
        topConversationLinkLineView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(topConversationLinkLineView)
        NSLayoutConstraint.activate([
            topConversationLinkLineView.topAnchor.constraint(equalTo: contentView.topAnchor),
            topConversationLinkLineView.centerXAnchor.constraint(equalTo: statusView.authorAvatarButton.centerXAnchor),
            topConversationLinkLineView.widthAnchor.constraint(equalToConstant: 1),
            statusView.authorAvatarButton.topAnchor.constraint(equalTo: topConversationLinkLineView.bottomAnchor, constant: 2),
        ])
        topConversationLinkLineView.isHidden = true
        
        bottomConversationLinkLineView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomConversationLinkLineView)
        NSLayoutConstraint.activate([
            bottomConversationLinkLineView.topAnchor.constraint(equalTo: statusView.authorAvatarButton.bottomAnchor, constant: 2),
            bottomConversationLinkLineView.centerXAnchor.constraint(equalTo: statusView.authorAvatarButton.centerXAnchor),
            bottomConversationLinkLineView.widthAnchor.constraint(equalToConstant: 1),
            contentView.bottomAnchor.constraint(equalTo: bottomConversationLinkLineView.bottomAnchor),
        ])
        bottomConversationLinkLineView.isHidden = true
        
        statusView.delegate = self
    }
    
}

extension StatusTableViewCell {

    func setTopConversationLinkLineViewDisplay() {
        topConversationLinkLineView.isHidden = false
    }
    
    func setBottomConversationLinkLineViewDisplay() {
        bottomConversationLinkLineView.isHidden = false
    }
    
}

// MARK: - StatusViewContainerTableViewCell
extension StatusTableViewCell: StatusViewContainerTableViewCell { }

// MARK: - StatusViewDelegate
extension StatusTableViewCell: StatusViewDelegate { }
