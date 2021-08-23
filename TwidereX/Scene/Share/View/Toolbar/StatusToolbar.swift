//
//  StatusToolbar.swift
//  StatusToolbar
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit

protocol StatusToolbarDelegate: AnyObject {
    func statusToolbar(_ statusToolbar: StatusToolbar, actionDidPressed action: StatusToolbar.Action)
}

final class StatusToolbar: UIView {
    
    let replyButton     = HitTestExpandedButton()
    let repostButton    = HitTestExpandedButton()
    let likeButton      = HitTestExpandedButton()
    let menuButton      = HitTestExpandedButton()
    
    private let logger = Logger(subsystem: "StatusToolbar", category: "UI")
    private let container = UIStackView()
    private var style: Style?
    
    weak var delegate: StatusToolbarDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
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
    
    func setup(style: Style) {
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
                replyButton.heightAnchor.constraint(equalToConstant: 40).priority(.defaultHigh),
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
        }
    }
}

extension StatusToolbar {
    enum Action: String, CaseIterable {
        case reply
        case repost
        case like
        case menu
    }

    enum Style {
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
        delegate?.statusToolbar(self, actionDidPressed: action)
    }
    
}

extension StatusToolbar {

    func setReply(count: Int, isEnabled: Bool) {
        let text = NumberMetricFormatter().string(from: count) ?? ""
        replyButton.setTitle(text, for: .normal)
    }
    
    func setRepost(count: Int, isEnabled: Bool, isLocked: Bool) {
        // let text = NumberMetricFormatter().string(from: count) ?? ""
        // repostButton.setTitle(text, for: .normal)
    }
    
}
