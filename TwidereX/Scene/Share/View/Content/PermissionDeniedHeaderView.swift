//
//  PermissionDeniedHeaderView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class PermissionDeniedHeaderView: UIView {
    
    let eyeSlashImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.image = Asset.Human.eyeSlash.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .secondaryLabel
        label.text = L10n.Common.Alerts.PermissionDenied.title
        return label
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.text = L10n.Common.Alerts.PermissionDenied.message
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension PermissionDeniedHeaderView {
    private func _init() {
        eyeSlashImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(eyeSlashImageView)
        NSLayoutConstraint.activate([
            eyeSlashImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            eyeSlashImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            eyeSlashImageView.widthAnchor.constraint(equalToConstant: 24).priority(.defaultHigh),
            eyeSlashImageView.heightAnchor.constraint(equalToConstant: 24).priority(.defaultHigh),
        ])
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: eyeSlashImageView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: eyeSlashImageView.trailingAnchor, constant: 8),
            trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
        ])
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor),
        ])
        messageLabel.setContentHuggingPriority(.defaultHigh - 1, for: .vertical)
        messageLabel.setContentCompressionResistancePriority(.required - 2, for: .vertical)
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct PermissionDeniedHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            PermissionDeniedHeaderView()
        }
        .previewLayout(.fixed(width: 375, height: 200))
    }
}

#endif

