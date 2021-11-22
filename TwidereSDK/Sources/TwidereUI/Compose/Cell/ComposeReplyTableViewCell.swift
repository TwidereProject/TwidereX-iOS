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

public final class ComposeReplyTableViewCell: UITableViewCell {
    
    let logger = Logger(subsystem: "ComposeReplyTableViewCell", category: "UI")
    
    var disposeBag = Set<AnyCancellable>()
    
    public let statusView = StatusView()
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        statusView.prepareForReuse()
        disposeBag.removeAll()
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
        statusView.toolbar.isHidden = true
    }
    
}
