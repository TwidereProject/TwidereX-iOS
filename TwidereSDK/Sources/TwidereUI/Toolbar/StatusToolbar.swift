//
//  StatusToolbar.swift
//  StatusToolbar
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import TwidereCore

public protocol StatusToolbarDelegate: AnyObject {
    func statusToolbar(_ statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action, button: UIButton)
    func statusToolbar(_ statusToolbar: StatusToolbar, menuActionDidPressed action: StatusToolbar.MenuAction, menuButton button: UIButton)
}

public final class StatusToolbar: UIView {
    
    public static let numberMetricFormatter = NumberMetricFormatter()
    
    public let replyButton     = HitTestExpandedButton()
    public let repostButton    = HitTestExpandedButton()
    public let likeButton      = HitTestExpandedButton()
    public let menuButton      = HitTestExpandedButton()
    
    private let logger = Logger(subsystem: "StatusToolbar", category: "UI")
    private let container = UIStackView()
    private var style: Style?
    
    public weak var delegate: StatusToolbarDelegate?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        assert(style != nil, "Needs setup style before use")
    }
    
}

extension StatusToolbar {
    
    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    public func setup(style: Style) {
        self.style = style
        
        container.arrangedSubviews.forEach { subview in
            container.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        let buttons = [replyButton, repostButton, likeButton, menuButton]
        buttons.forEach { button in
            button.tintColor = .secondaryLabel
            button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            button.setTitle("", for: .normal)
            button.setTitleColor(.secondaryLabel, for: .normal)
            button.setInsets(forContentPadding: .zero, imageTitlePadding: style.buttonTitleImagePadding)
            button.addTarget(self, action: #selector(StatusToolbar.buttonDidPressed(_:)), for: .touchUpInside)
        }
        
        switch style {
        case .inline:
            buttons.forEach { button in
                button.contentHorizontalAlignment = .leading
            }
            replyButton.setImage(Asset.Arrows.arrowTurnUpLeftMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
            repostButton.setImage(Asset.Media.repeatMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
            likeButton.setImage(Asset.Health.heartMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
            menuButton.setImage(Asset.Editing.ellipsisMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
            
            container.axis = .horizontal
            container.distribution = .fill
            
            replyButton.translatesAutoresizingMaskIntoConstraints = false
            repostButton.translatesAutoresizingMaskIntoConstraints = false
            likeButton.translatesAutoresizingMaskIntoConstraints = false
            menuButton.translatesAutoresizingMaskIntoConstraints = false
            container.addArrangedSubview(replyButton)
            container.addArrangedSubview(repostButton)
            container.addArrangedSubview(likeButton)
            container.addArrangedSubview(menuButton)
            NSLayoutConstraint.activate([
                replyButton.heightAnchor.constraint(equalToConstant: 40).priority(.required - 10),
                replyButton.heightAnchor.constraint(equalTo: repostButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: likeButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: menuButton.heightAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: repostButton.widthAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: likeButton.widthAnchor).priority(.defaultHigh),
            ])
            menuButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            menuButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            
        case .plain:
            buttons.forEach { button in
                button.contentHorizontalAlignment = .center
            }
            replyButton.setImage(Asset.Arrows.arrowTurnUpLeft.image.withRenderingMode(.alwaysTemplate), for: .normal)
            repostButton.setImage(Asset.Media.repeat.image.withRenderingMode(.alwaysTemplate), for: .normal)
            likeButton.setImage(Asset.Health.heart.image.withRenderingMode(.alwaysTemplate), for: .normal)
            menuButton.setImage(Asset.Editing.ellipsis.image.withRenderingMode(.alwaysTemplate), for: .normal)
            
            container.axis = .horizontal
            container.spacing = 8
            container.distribution = .fillEqually
            
            container.addArrangedSubview(replyButton)
            container.addArrangedSubview(repostButton)
            container.addArrangedSubview(likeButton)
            container.addArrangedSubview(menuButton)
            
            NSLayoutConstraint.activate([
                replyButton.heightAnchor.constraint(equalToConstant: 47).priority(.required - 10),
                replyButton.heightAnchor.constraint(equalTo: repostButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: likeButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: menuButton.heightAnchor).priority(.defaultHigh),
            ])
        }
    }
}

extension StatusToolbar {
    public enum Action: String, CaseIterable {
        case reply
        case repost
        case like
        case menu
    }
    
    public enum MenuAction: String, CaseIterable {
        case remove
    }

    public enum Style {
        case inline
        case plain
        
        var buttonTitleImagePadding: CGFloat {
            switch self {
            case .inline:       return 4.0
            case .plain:        return 0
            }
        }
    }
}

extension StatusToolbar {
    
    @objc private func buttonDidPressed(_ sender: UIButton) {
        let _action: Action?
        switch sender {
        case replyButton:       _action = .reply
        case repostButton:      _action = .repost
        case likeButton:        _action = .like
        case menuButton:        _action = .menu
        default:                _action = nil
        }
        
        guard let action = _action else {
            assertionFailure()
            return
        }
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(action.rawValue) button pressed")
        delegate?.statusToolbar(self, actionDidPressed: action, button: sender)
    }
    
}

extension StatusToolbar {
    
    private func metricText(count: Int) -> String {
        guard count > 0 else { return "" }
        return StatusToolbar.numberMetricFormatter.string(from: count) ?? ""
    }

    public func setupReply(count: Int, isEnabled: Bool) {
        let text = metricText(count: count)
        switch style {
        case .inline:
            replyButton.setTitle(text, for: .normal)
        case .plain:
            break
        case .none:
            break
        }
        
        replyButton.accessibilityLabel = L10n.Accessibility.Common.Status.Actions.reply
    }
    
    public func setupRepost(count: Int, isRepost: Bool, isLocked: Bool) {
        // set title
        let text = metricText(count: count)
        switch style {
        case .inline:
            repostButton.setTitle(text, for: .normal)
        case .plain:
            break
        case .none:
            break
        }
        
        // set color
        let tintColor = isRepost ? Asset.Scene.Status.Toolbar.repost.color : .secondaryLabel
        repostButton.tintColor = tintColor
        repostButton.setTitleColor(tintColor, for: .normal)
        repostButton.setTitleColor(tintColor.withAlphaComponent(0.8), for: .highlighted)
        
        // TODO: loked
        
        repostButton.accessibilityLabel = L10n.Accessibility.Common.Status.Actions.retweet
        if isRepost {
            repostButton.accessibilityTraits.insert(.selected)
        } else {
            repostButton.accessibilityTraits.remove(.selected)
        }
    }
    
    public func setupLike(count: Int, isLike: Bool) {
        // set title
        let text = metricText(count: count)
        switch style {
        case .inline:
            let image: UIImage = isLike ? Asset.Health.heartFillMini.image : Asset.Health.heartMini.image
            likeButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
            likeButton.setTitle(text, for: .normal)
        case .plain:
            let image: UIImage = isLike ? Asset.Health.heartFill.image : Asset.Health.heart.image
            likeButton.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
            // no title
        case .none:
            break
        }
        
        // set color
        let tintColor = isLike ? Asset.Scene.Status.Toolbar.like.color : .secondaryLabel
        likeButton.tintColor = tintColor
        likeButton.setTitleColor(tintColor, for: .normal)
        likeButton.setTitleColor(tintColor.withAlphaComponent(0.8), for: .highlighted)
        
        likeButton.accessibilityLabel = L10n.Accessibility.Common.Status.Actions.like
        if isLike {
            likeButton.accessibilityTraits.insert(.selected)
        } else {
            likeButton.accessibilityTraits.remove(.selected)
        }
    }
    
    public struct MenuContext {
        let shareText: String?
        let shareLink: String?
        let displayDeleteAction: Bool
    }
    
    public func setupMenu(menuContext: MenuContext) {
        menuButton.menu = {
            var children: [UIMenuElement] = [
                UIAction(
                    title: L10n.Common.Controls.Status.Actions.copyText.capitalized,
                    image: UIImage(systemName: "doc.on.doc"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: [],
                    state: .off
                ) { _ in
                    guard let text = menuContext.shareText else { return }
                    UIPasteboard.general.string = text
                },
                UIAction(
                    title: L10n.Common.Controls.Status.Actions.copyLink.capitalized,
                    image: UIImage(systemName: "link"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: [],
                    state: .off
                ) { _ in
                    guard let text = menuContext.shareLink else { return }
                    UIPasteboard.general.string = text
                },
                UIAction(
                    title: L10n.Common.Controls.Status.Actions.shareLink.capitalized,
                    image: UIImage(systemName: "square.and.arrow.up"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: [],
                    state: .off
                ) { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.statusToolbar(self, actionDidPressed: .menu, button: self.menuButton)
                }
            ]
            
            if menuContext.displayDeleteAction {
                let removeAction = UIAction(
                    title: L10n.Common.Controls.Actions.delete,
                    image: UIImage(systemName: "minus.circle"),
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: .destructive,
                    state: .off
                ) { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.statusToolbar(self, menuActionDidPressed: .remove, menuButton: self.menuButton)
                }
                children.append(removeAction)
            }
            
            return UIMenu(title: "", options: [], children: children)
        }()
        
        
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.accessibilityLabel = "Menu"      // TODO: i18n
    }
    
}
