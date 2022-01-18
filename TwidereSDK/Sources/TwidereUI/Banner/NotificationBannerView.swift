//
//  NotificationBannerView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-24.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import TwidereAsset
import TwidereCommon

public final class NotificationBannerView: UIView {

    public let containerShadowView = UIView()
    public let containerBackgroundView = UIView()
    
    public let containerView = UIView()

    public let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.Indices.exclamationmarkCircle.image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .white
        return imageView
    }()
    
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Message Title"
        label.textColor = .white
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    public let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Message"
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .regular)
        return label
    }()
    
    public let actionButton: UIButton = {
        let button = HitTestExpandedButton(type: .custom)
        button.tintColor = .white
        button.setImage(UIImage(systemName: "arrow.right"), for: .normal)
        return button
    }()

    public var actionButtonTapHandler: ((_ button: UIButton) -> Void)? {
        didSet {
            actionButton.isHidden = actionButtonTapHandler == nil
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension NotificationBannerView {

    private func _init() {
        containerBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerBackgroundView)
        NSLayoutConstraint.activate([
            containerBackgroundView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 8),      // use margin guide to prevent overlap the status bar
            containerBackgroundView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            containerBackgroundView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerBackgroundView.bottomAnchor, constant: 16),
        ])
        
        containerShadowView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerShadowView)
        sendSubviewToBack(containerShadowView)
        NSLayoutConstraint.activate([
            containerShadowView.topAnchor.constraint(equalTo: containerBackgroundView.topAnchor),
            containerShadowView.leadingAnchor.constraint(equalTo: containerBackgroundView.leadingAnchor),
            containerShadowView.trailingAnchor.constraint(equalTo: containerBackgroundView.trailingAnchor),
            containerShadowView.bottomAnchor.constraint(equalTo: containerBackgroundView.bottomAnchor),
        ])
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerBackgroundView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: containerBackgroundView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: containerBackgroundView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: containerBackgroundView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: containerBackgroundView.bottomAnchor),
        ])

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

        actionButton.addTarget(self, action: #selector(NotificationBannerView.actionButtonPressed(_:)), for: .touchUpInside)
        actionButton.isHidden = true
        
        configure(style: .error)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        containerBackgroundView.layer.masksToBounds = true
        containerBackgroundView.layer.cornerCurve = .continuous
        containerBackgroundView.layer.cornerRadius = 12
        containerShadowView.layer.setupShadow(
            alpha: 0.25,
            roundedRect: containerBackgroundView.bounds,
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: 12, height: 12)
        )
    }

}

extension NotificationBannerView {

    @objc private func actionButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        actionButtonTapHandler?(sender)
    }
}

extension NotificationBannerView {

    public func configure(error: LocalizedError) {
        let title = error.errorDescription ?? error.failureReason ?? "Internal Error"
        let message = error.failureReason

        titleLabel.text = title
        
        if let message = message {
            messageLabel.text = message
        } else {
            messageLabel.isHidden = true
            titleLabel.numberOfLines = 2
        }
    }
}

extension NotificationBannerView {

    public enum Style: String, CaseIterable {
        case success
        case error
        case info
        case warning
        case action
        
        public var backgroundColor: UIColor {
            switch self {
            case .success:      return Asset.Colors.Banner.successBackground.color
            case .error:        return Asset.Colors.Banner.errorBackground.color
            case .info:         return Asset.Colors.Banner.infoBackground.color
            case .warning:      return Asset.Colors.Banner.warningBackground.color
            case .action:       return Asset.Colors.Banner.actionBackground.color
            }
        }
        
        public var labelColor: UIColor {
            switch self {
            case .success:      return Asset.Colors.Banner.successLabel.color
            case .error:        return Asset.Colors.Banner.errorLabel.color
            case .info:         return Asset.Colors.Banner.infoLabel.color
            case .warning:      return Asset.Colors.Banner.warningLabel.color
            case .action:       return Asset.Colors.Banner.actionLabel.color
            }
        }
        
        public var iconImage: UIImage {
            switch self {
            case .success:      return Asset.Indices.checkmarkCircle.image.withRenderingMode(.alwaysTemplate)
            case .error:        return Asset.Indices.exclamationmarkCircle.image.withRenderingMode(.alwaysTemplate)
            case .info:         return Asset.Indices.infoCircle.image.withRenderingMode(.alwaysTemplate)
            case .warning:      return Asset.Indices.exclamationmarkCircle.image.withRenderingMode(.alwaysTemplate)
            case .action:       return Asset.Arrows.arrowTriangle2Circlepath.image.withRenderingMode(.alwaysTemplate)
            }
        }
    }

    public func configure(style: Style) {
        containerBackgroundView.backgroundColor = .systemBackground
        containerView.backgroundColor = style.backgroundColor
        iconImageView.image = style.iconImage
        iconImageView.tintColor = style.labelColor
        titleLabel.textColor = style.labelColor
        messageLabel.textColor = style.labelColor
        actionButton.tintColor = style.labelColor
    }

}

// Note: Xcode 13.1 (13A1030d) fail to preview UI with packaged assets
// ref: https://forums.swift.org/t/unable-to-find-bundle-in-package-target-tests-when-package-depends-on-another-package-containing-resources-accessed-via-bundle-module/43974
#if DEBUG
    import SwiftUI
    struct NotificationBannerView_Preview: PreviewProvider {
        static var previews: some View {
            UIViewPreview {
                let banner = NotificationBannerView()
                return banner
            }
        }
    }
#endif
