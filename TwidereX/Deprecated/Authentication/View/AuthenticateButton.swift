//
//  AuthenticateButton.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-15.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit

extension UIControl.State: Hashable { }

final class AuthenticateButton: UIControl {
    
    static let imageEdgePadding: CGFloat = 12
    static let titleEdgePadding: CGFloat = 16
    
    // UIControl.Event - Application: 0x0F000000
    static let primaryAction   = UIControl.Event(rawValue: 1 << 25)     // 0x01000000
    static let secondaryAction = UIControl.Event(rawValue: 1 << 26)     // 0x02000000
    
    let backgroundImageView = UIImageView()
    let leadingImageView = UIImageView()
    let trailingBackgroundImageView = UIImageView()
    let trailingImageView = UIImageView()
    let titleLabel = UILabel()
        
    private var backgroundImages: [UIControl.State: UIImage] = [:]
    private var trailingBackgroundImages: [UIControl.State: UIImage] = [:]
    private var leadingImages: [UIControl.State: UIImage] = [:]
    private var trailingImages: [UIControl.State: UIImage] = [:]
    private var titles: [UIControl.State: String] = [:]
    private var titleColors: [UIControl.State: UIColor] = [:]
        
    var style = Style.plain
    var primaryActionState: UIControl.State = .normal
    var secondaryActionState: UIControl.State = .normal
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension AuthenticateButton {
    
    enum Style {
        case plain
        case trailingOption
    }
    
    private func updateAppearance() {
        backgroundImageView.image = backgroundImage(for: primaryActionState)
        leadingImageView.image = leadingImage(for: primaryActionState)
        titleLabel.text = title(for: primaryActionState)
        titleLabel.textColor = titleColor(for: primaryActionState)
        
        trailingBackgroundImageView.image = trailingBackgroundImage(for: secondaryActionState)
        trailingImageView.image = trailingImage(for: secondaryActionState)
    }
    
    private func updateState(touch: UITouch, event: UIEvent?) {
        switch style {
        case .plain:
            primaryActionState = AuthenticateButton.isTouching(touch, view: backgroundImageView, event: event) ? .highlighted : .normal
        case .trailingOption:
            let isSecondaryActionHighlighted = AuthenticateButton.isTouching(touch, view: trailingBackgroundImageView, event: event)
            if isSecondaryActionHighlighted {
                primaryActionState = .normal
            } else {
                primaryActionState = AuthenticateButton.isTouching(touch, view: backgroundImageView, event: event) ? .highlighted : .normal
            }
            secondaryActionState = isSecondaryActionHighlighted ? .highlighted : .normal
        }
    }
    
    private func resetState() {
        primaryActionState = .normal
        secondaryActionState = .normal
    }
    
    private static func isTouching(_ touch: UITouch, view: UIView, event: UIEvent?) -> Bool {
        let location = touch.location(in: view)
        return view.point(inside: location, with: event)
    }
    
        
}

extension AuthenticateButton {
    
    private func _init() {
        titleLabel.textAlignment = traitCollection.layoutDirection == .rightToLeft ? .right : .left
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        leadingImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leadingImageView)
        NSLayoutConstraint.activate([
            leadingImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AuthenticateButton.imageEdgePadding),
            leadingImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        leadingImageView.setContentHuggingPriority(.defaultHigh + 2, for: .horizontal)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingImageView.trailingAnchor, constant: AuthenticateButton.imageEdgePadding + AuthenticateButton.titleEdgePadding),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        trailingBackgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trailingBackgroundImageView)
        NSLayoutConstraint.activate([
            trailingBackgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            trailingBackgroundImageView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: AuthenticateButton.titleEdgePadding),
            trailingBackgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trailingBackgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        trailingImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trailingImageView)
        NSLayoutConstraint.activate([
            trailingImageView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: AuthenticateButton.imageEdgePadding + AuthenticateButton.titleEdgePadding),
            trailingAnchor.constraint(equalTo: trailingImageView.trailingAnchor, constant: AuthenticateButton.imageEdgePadding),
            trailingImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        trailingImageView.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)

        
        setLeadingImage(UIImage.placeholder(size: CGSize(width: 1, height: 1), color: .clear), for: .normal)
        setTrailingImage(UIImage.placeholder(size: CGSize(width: 1, height: 1), color: .clear), for: .normal)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 44, height: 44)
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        defer { updateAppearance() }
        
        updateState(touch: touch, event: event)
        return super.beginTracking(touch, with: event)
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        defer { updateAppearance() }

        updateState(touch: touch, event: event)
        return super.continueTracking(touch, with: event)
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        defer { updateAppearance() }
        resetState()
        
        if let touch = touch {
            if AuthenticateButton.isTouching(touch, view: trailingBackgroundImageView, event: event) {
                sendActions(for: AuthenticateButton.secondaryAction)
            } else if AuthenticateButton.isTouching(touch, view: backgroundImageView, event: event) {
                sendActions(for: AuthenticateButton.primaryAction)
            } else {
                // do nothing
            }
        }
        
        super.endTracking(touch, with: event)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        defer { updateAppearance() }

        resetState()
        super.cancelTracking(with: event)
    }
    
}

extension AuthenticateButton {
    
    func setBackgroundImage(_ backgroundImage: UIImage?, for state: UIControl.State) {
        backgroundImages[state] = backgroundImage
        if self.primaryActionState == state {
            backgroundImageView.image = backgroundImage
        }
    }
    
    func backgroundImage(for state: UIControl.State) -> UIImage? {
        return backgroundImages[state] ?? backgroundImages[.normal]
    }
    
    func setTrailingBackgroundImage(_ backgroundImage: UIImage?, for state: UIControl.State) {
        trailingBackgroundImages[state] = backgroundImage
        if self.secondaryActionState == state {
            trailingBackgroundImageView.image = backgroundImage
        }
    }
    
    func trailingBackgroundImage(for state: UIControl.State) -> UIImage? {
        return trailingBackgroundImages[state] ?? trailingBackgroundImages[.normal]
    }
    
    func setTitle(_ title: String?, for state: UIControl.State) {
        titles[state] = title
        if self.primaryActionState == state {
            titleLabel.text = title
        }
    }
    
    func title(for state: UIControl.State) -> String? {
        return titles[state] ?? titles[.normal]
    }
    
    func setTitleColor(_ titleColor: UIColor?, for state: UIControl.State) {
        titleColors[state] = titleColor
        if self.primaryActionState == state {
            titleLabel.textColor = titleColor
        }
    }
    
    func titleColor(for state: UIControl.State) -> UIColor? {
        return titleColors[state] ?? titleColors[.normal]
    }
    
    func setLeadingImage(_ image: UIImage?, for state: UIControl.State) {
        leadingImages[state] = image
        if self.primaryActionState == state {
            leadingImageView.image = image
        }
    }
    
    func leadingImage(for state: UIControl.State) -> UIImage? {
        return leadingImages[state] ?? leadingImages[.normal]
    }
    
    func setTrailingImage(_ image: UIImage?, for state: UIControl.State) {
        trailingImages[state] = image
        if self.secondaryActionState == state {
            trailingImageView.image = image
        }
    }
    
    func trailingImage(for state: UIControl.State) -> UIImage? {
        return trailingImages[state] ?? trailingImages[.normal]
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct AuthenticateButton_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 400) {
                let button = AuthenticateButton()
                button.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.twitterBlue.color), for: .normal)
                button.setLeadingImage(Asset.Logo.twitter.image.withRenderingMode(.alwaysTemplate), for: .normal)
                button.setTrailingImage(Asset.Editing.ellipsis.image.withRenderingMode(.alwaysTemplate), for: .normal)
                button.setTitle("Sign in with Twitter", for: .normal)
                button.setTitleColor(.white, for: .normal)
                button.tintColor = .white
                return button
            }
            .previewLayout(.fixed(width: 800, height: 80))
            UIViewPreview(width: 400) {
                let button = AuthenticateButton()
                button.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.twitterBlue.color), for: .normal)
                button.setTrailingBackgroundImage(UIImage.placeholder(color: .systemGreen), for: .normal)
                button.setLeadingImage(Asset.Logo.twitter.image.withRenderingMode(.alwaysTemplate), for: .normal)
                button.setTrailingImage(Asset.Editing.ellipsis.image.withRenderingMode(.alwaysTemplate), for: .normal)
                button.setTitle("Sign in with Twitter", for: .normal)
                button.setTitleColor(.white, for: .normal)
                button.tintColor = .white
                return button
            }
            .previewLayout(.fixed(width: 800, height: 80))
        }
    }
    
}

#endif

