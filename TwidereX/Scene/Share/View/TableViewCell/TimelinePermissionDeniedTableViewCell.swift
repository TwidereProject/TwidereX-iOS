//
//  TimelinePermissionDeniedTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class TimelinePermissionDeniedTableViewCell: UITableViewCell {
    
    let eyeSlashImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.image = Asset.Human.eyeSlash.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.text = L10n.Common.Alerts.PermissionDenied.title
        return label
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.textColor = .secondaryLabel
        label.text = L10n.Common.Alerts.PermissionDenied.message
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TimelinePermissionDeniedTableViewCell {
    
    private func _init() {
        eyeSlashImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(eyeSlashImageView)
        NSLayoutConstraint.activate([
            eyeSlashImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            eyeSlashImageView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            eyeSlashImageView.widthAnchor.constraint(equalToConstant: 24).priority(.defaultHigh),
            eyeSlashImageView.heightAnchor.constraint(equalToConstant: 24).priority(.defaultHigh),
        ])
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: eyeSlashImageView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: eyeSlashImageView.trailingAnchor, constant: 8),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
        ])
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor),
        ])
    }
    
}
