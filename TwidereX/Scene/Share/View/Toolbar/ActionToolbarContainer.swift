//
//  ActionToolbarContainer.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-4.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit

protocol ActionToolbarContainerDelegate: AnyObject {
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, replayButtonDidPressed sender: UIButton)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, retweetButtonDidPressed sender: UIButton)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, likeButtonDidPressed sender: UIButton)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, menuButtonDidPressed sender: UIButton)
}


final class ActionToolbarContainer: UIView {
        
    let replyButton     = HitTestExpandedButton()
    let retweetButton   = HitTestExpandedButton()
    let likeButton      = HitTestExpandedButton()
    let menuButton      = HitTestExpandedButton()
    
    var isRetweetButtonHighlight: Bool = false {
        didSet { isRetweetButtonHighlightStateDidChange(to: isRetweetButtonHighlight) }
    }
    
    var isLikeButtonHighlight: Bool = false {
        didSet { isLikeButtonHighlightStateDidChange(to: isLikeButtonHighlight) }
    }
    
    weak var delegate: ActionToolbarContainerDelegate?
    
    private let container = UIStackView()
    private var style: Style?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ActionToolbarContainer {

    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        replyButton.addTarget(self, action: #selector(ActionToolbarContainer.replyButtonDidPressed(_:)), for: .touchUpInside)
        retweetButton.addTarget(self, action: #selector(ActionToolbarContainer.retweetButtonDidPressed(_:)), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(ActionToolbarContainer.likeButtonDidPressed(_:)), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(ActionToolbarContainer.menuButtonDidPressed(_:)), for: .touchUpInside)
    }
    
}

extension ActionToolbarContainer {
    
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
    
    func configure(for style: Style) {
        guard needsConfigure(for: style) else {
            return
        }
        
        self.style = style
        container.arrangedSubviews.forEach { subview in
            container.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        let buttons = [replyButton, retweetButton, likeButton, menuButton]
        buttons.forEach { button in
            button.tintColor = .secondaryLabel
            button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            button.setTitle("", for: .normal)
            button.setTitleColor(.secondaryLabel, for: .normal)
            button.setInsets(forContentPadding: .zero, imageTitlePadding: style.buttonTitleImagePadding)
        }
        
        switch style {
        case .inline:
            buttons.forEach { button in
                button.contentHorizontalAlignment = .leading
            }
            replyButton.setImage(Asset.Arrows.arrowTurnUpLeftMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
            retweetButton.setImage(Asset.Media.repeatMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
            likeButton.setImage(Asset.Health.heartMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
            menuButton.setImage(Asset.Editing.ellipsisMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
            
            container.axis = .horizontal
            container.distribution = .fill
            
            replyButton.translatesAutoresizingMaskIntoConstraints = false
            retweetButton.translatesAutoresizingMaskIntoConstraints = false
            likeButton.translatesAutoresizingMaskIntoConstraints = false
            menuButton.translatesAutoresizingMaskIntoConstraints = false
            container.addArrangedSubview(replyButton)
            container.addArrangedSubview(retweetButton)
            container.addArrangedSubview(likeButton)
            container.addArrangedSubview(menuButton)
            NSLayoutConstraint.activate([
                replyButton.heightAnchor.constraint(equalToConstant: 40).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: retweetButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: likeButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: menuButton.heightAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: retweetButton.widthAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: likeButton.widthAnchor).priority(.defaultHigh),
            ])
            menuButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            menuButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            
        case .plain:
            buttons.forEach { button in
                button.contentHorizontalAlignment = .center
            }
            replyButton.setImage(Asset.Arrows.arrowTurnUpLeft.image.withRenderingMode(.alwaysTemplate), for: .normal)
            retweetButton.setImage(Asset.Media.repeat.image.withRenderingMode(.alwaysTemplate), for: .normal)
            likeButton.setImage(Asset.Health.heart.image.withRenderingMode(.alwaysTemplate), for: .normal)
            menuButton.setImage(Asset.Editing.ellipsis.image.withRenderingMode(.alwaysTemplate), for: .normal)
            
            container.axis = .horizontal
            container.spacing = 8
            container.distribution = .fillEqually
            
            container.addArrangedSubview(replyButton)
            container.addArrangedSubview(retweetButton)
            container.addArrangedSubview(likeButton)
            container.addArrangedSubview(menuButton)
        }
    }
    
    private func needsConfigure(for style: Style) -> Bool {
        guard let oldStyle = self.style else { return true }
        return oldStyle != style
    }
    
    private func isRetweetButtonHighlightStateDidChange(to isHighlight: Bool) {
        let tintColor = isHighlight ? Asset.Colors.hightLight.color : .secondaryLabel
        retweetButton.tintColor = tintColor
        retweetButton.setTitleColor(tintColor, for: .normal)
        retweetButton.setTitleColor(tintColor.withAlphaComponent(0.8), for: .highlighted)
    }
    
    private func isLikeButtonHighlightStateDidChange(to isHighlight: Bool) {
        let tintColor = isHighlight ? Asset.Colors.heartPink.color : .secondaryLabel
        likeButton.tintColor = tintColor
        likeButton.setTitleColor(tintColor, for: .normal)
        likeButton.setTitleColor(tintColor.withAlphaComponent(0.8), for: .highlighted)
        
        guard let style = self.style else { return }
        let buttonImage: UIImage = {
            switch style {
            case .inline:
                return isHighlight ? Asset.Health.heartFillMini.image.withRenderingMode(.alwaysTemplate) :
                    Asset.Health.heartMini.image.withRenderingMode(.alwaysTemplate)
            case .plain:
                return isHighlight ? Asset.Health.heartFill.image.withRenderingMode(.alwaysTemplate) :
                    Asset.Health.heart.image.withRenderingMode(.alwaysTemplate)
            }
        }()
        likeButton.setImage(buttonImage, for: .normal)
    }
}

extension ActionToolbarContainer {
    
    @objc private func replyButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.actionToolbarContainer(self, replayButtonDidPressed: sender)
    }
    
    @objc private func retweetButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.actionToolbarContainer(self, retweetButtonDidPressed: sender)
    }
    
    @objc private func likeButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.actionToolbarContainer(self, likeButtonDidPressed: sender)
    }
    
    @objc private func menuButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.actionToolbarContainer(self, menuButtonDidPressed: sender)
    }
    
}

#if DEBUG
import SwiftUI

struct ActionToolbarContainer_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewPreview(width: 300) {
                let toolbar = ActionToolbarContainer()
                toolbar.configure(for: .inline)
                return toolbar
            }
            .previewLayout(.fixed(width: 300, height: 44))
            .previewDisplayName("Inline")
            UIViewPreview(width: 300) {
                let toolbar = ActionToolbarContainer()
                toolbar.configure(for: .inline)
                toolbar.isRetweetButtonHighlight = true
                toolbar.isLikeButtonHighlight = true
                return toolbar
            }
            .previewLayout(.fixed(width: 300, height: 44))
            .previewDisplayName("Inline - Retweeted & Liked")
            UIViewPreview(width: 300) {
                let toolbar = ActionToolbarContainer()
                toolbar.configure(for: .plain)
                return toolbar
            }
            .previewLayout(.fixed(width: 300, height: 44))
            .previewDisplayName("Plain")
            UIViewPreview(width: 300) {
                let toolbar = ActionToolbarContainer()
                toolbar.configure(for: .plain)
                toolbar.isRetweetButtonHighlight = true
                toolbar.isLikeButtonHighlight = true
                return toolbar
            }
            .previewLayout(.fixed(width: 300, height: 44))
            .previewDisplayName("Plain - Retweeted & Liked")
        }
    }
}
#endif
