//
//  StatusActionToolbar.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-17.
//

import os.log
import UIKit

protocol StatusActionToolbarDelegate: class {
    func statusActionToolbar(_ toolbar: StatusActionToolbar, replayButtonDidPressed sender: UIButton)
    func statusActionToolbar(_ toolbar: StatusActionToolbar, retweetButtonDidPressed sender: UIButton)
    func statusActionToolbar(_ toolbar: StatusActionToolbar, favoriteButtonDidPressed sender: UIButton)
    func statusActionToolbar(_ toolbar: StatusActionToolbar, shareButtonDidPressed sender: UIButton)
}

final class StatusActionToolbar: UIView {
    
    weak var delegate: StatusActionToolbarDelegate?
    
    static let height: CGFloat = 40
    static let buttonTitleImagePadding: CGFloat = 4
    
    var retweetButtonHighligh: Bool = false {
        didSet {
            retweetButtonHighlightStateDidChange(to: retweetButtonHighligh)
        }
    }
    
    var likeButtonHighlight: Bool = false {
        didSet {
            likeButtonHighlightStateDidChange(to: likeButtonHighlight)
        }
    }
    
    let replyButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .secondaryLabel
        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.setImage(Asset.Arrows.arrowTurnUpLeftLarge.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle("", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: TimelinePostActionToolbar.buttonTitleImagePadding)
        return button
    }()
    
    let retweetButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .secondaryLabel
        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.setImage(Asset.Media.repeatLarge.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle("", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: TimelinePostActionToolbar.buttonTitleImagePadding)
        return button
    }()
    
    let favoriteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .secondaryLabel
        button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        button.setImage(Asset.Health.heartLarge.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle("", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: TimelinePostActionToolbar.buttonTitleImagePadding)
        return button
    }()
    
    let shareButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .secondaryLabel
        button.setImage(Asset.Arrows.squareAndArrowUp.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
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

extension StatusActionToolbar {
    
    private func _init() {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 8
        container.distribution = .fillEqually
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        container.addArrangedSubview(replyButton)
        container.addArrangedSubview(retweetButton)
        container.addArrangedSubview(favoriteButton)
        container.addArrangedSubview(shareButton)
        
        replyButton.addTarget(self, action: #selector(StatusActionToolbar.replyButtonDidPressed(_:)), for: .touchUpInside)
        retweetButton.addTarget(self, action: #selector(StatusActionToolbar.retweetButtonDidPressed(_:)), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(StatusActionToolbar.favoriteButtonDidPressed(_:)), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(StatusActionToolbar.shareButtonDidPressed(_:)), for: .touchUpInside)
    }
    
}

extension StatusActionToolbar {

    @objc private func replyButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.statusActionToolbar(self, replayButtonDidPressed: sender)
    }
    
    @objc private func retweetButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.statusActionToolbar(self, retweetButtonDidPressed: sender)
    }
    
    @objc private func favoriteButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.statusActionToolbar(self, favoriteButtonDidPressed: sender)
    }
    
    @objc private func shareButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.statusActionToolbar(self, shareButtonDidPressed: sender)
    }

}

extension StatusActionToolbar {
    
    private func retweetButtonHighlightStateDidChange(to isHighlight: Bool) {
        let tintColor = isHighlight ? Asset.Colors.hightLight.color : .secondaryLabel
        retweetButton.tintColor = tintColor
    }
    
    private func likeButtonHighlightStateDidChange(to isHighlight: Bool) {
        let tintColor = isHighlight ? Asset.Colors.heartPink.color : .secondaryLabel
        let buttonImage = isHighlight ? Asset.Health.heartFillLarge.image.withRenderingMode(.alwaysTemplate) :
            Asset.Health.heartLarge.image.withRenderingMode(.alwaysTemplate)
        favoriteButton.tintColor = tintColor
        favoriteButton.setImage(buttonImage, for: .normal)
    }
    
}

#if DEBUG
import SwiftUI

struct ConversationPostActionToolbar_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 300) {
            let toolbar = StatusActionToolbar()
            return toolbar
        }
        .previewLayout(.fixed(width: 300, height: 100))
    }
}
#endif
