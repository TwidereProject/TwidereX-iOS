//
//  NotifyBannerView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-24.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit

final class NotifyBannerView: UIView {
    
    let containerView = UIView()

    let iconImageView = UIImageView()
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Message Title"
        label.textColor = .white
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Message"
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .regular)
        return label
    }()
    let actionButton: UIButton = {
        let button = HitTestExpandedButton(type: .custom)
        button.tintColor = .white
        button.setImage(UIImage(systemName: "arrow.right"), for: .normal)
        return button
    }()
    
    var actionButtonTapHandler: ((_ button: UIButton) -> Void)? {
        didSet {
            actionButton.isHidden = actionButtonTapHandler == nil
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension NotifyBannerView {
    
    private func _init() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 16),
        ])
        
        containerView.backgroundColor = .systemRed
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = 12
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 19),
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 19),
            containerView.bottomAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 19),
        ])
        iconImageView.setContentHuggingPriority(.defaultHigh + 2, for: .horizontal)
        
        let textContainer = UIStackView()
        textContainer.axis = .vertical
        textContainer.distribution = .fillEqually
        textContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textContainer)
        NSLayoutConstraint.activate([
            textContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            textContainer.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 19),
            containerView.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor, constant: 8),
        ])
        textContainer.addArrangedSubview(titleLabel)
        textContainer.addArrangedSubview(messageLabel)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        messageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(actionButton)
        NSLayoutConstraint.activate([
            actionButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            actionButton.leadingAnchor.constraint(equalTo: textContainer.trailingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: 19),
        ])
        actionButton.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
        
        iconImageView.image = Asset.Indices.exclamationmarkCircle.image.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = .white
        
        actionButton.addTarget(self, action: #selector(NotifyBannerView.actionButtonPressed(_:)), for: .touchUpInside)
        actionButton.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.setupShadow(alpha: 0.25, roundedRect: containerView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 12, height: 12))
    }
    
}

extension NotifyBannerView {
    
    enum Style {
        case error
        case warning
        case info
        case normal
    }
    
    func configure(for style: Style) {
        switch style {
        case .error:
            containerView.backgroundColor = .systemRed
            iconImageView.image = Asset.Indices.exclamationmarkCircle.image.withRenderingMode(.alwaysTemplate)
        case .warning:
            containerView.backgroundColor = .systemYellow
            iconImageView.image = Asset.Indices.exclamationmarkCircle.image.withRenderingMode(.alwaysTemplate)
        case .info:
            containerView.backgroundColor = .systemGray
            iconImageView.image = Asset.Indices.infoCircle.image.withRenderingMode(.alwaysTemplate)
        case .normal:
            containerView.backgroundColor = .systemGreen
            iconImageView.image = Asset.Indices.checkmarkCircle.image.withRenderingMode(.alwaysTemplate)
        }
    }

}


extension NotifyBannerView {
    
    @objc private func actionButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        actionButtonTapHandler?(sender)
    }
}
