//
//  PermissionDeniedHeaderView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import ActiveLabel

final class TimelineHeaderView: UIView {
        
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.image = Asset.Indices.infoCircle.image.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .secondaryLabel
        label.text = "Title"
        return label
    }()
    
    let messageLabel = ActiveLabel(style: .timelineHeaderView)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TimelineHeaderView {
    private func _init() {
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24).priority(.defaultHigh),
            iconImageView.heightAnchor.constraint(equalToConstant: 24).priority(.defaultHigh),
        ])
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
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
            TimelineHeaderView()
        }
        .previewLayout(.fixed(width: 375, height: 80))
    }
}

#endif

