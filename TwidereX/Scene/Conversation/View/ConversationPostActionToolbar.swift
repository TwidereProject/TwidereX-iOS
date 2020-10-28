//
//  ConversationPostActionToolbar.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-17.
//

import UIKit

final class ConversationPostActionToolbar: UIView {
    
    static let height: CGFloat = 40
    static let buttonTitleImagePadding: CGFloat = 4
    
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

extension ConversationPostActionToolbar {
    
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
    }
    
}

#if DEBUG
import SwiftUI

struct ConversationPostActionToolbar_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 300) {
            let toolbar = ConversationPostActionToolbar()
            return toolbar
        }
        .previewLayout(.fixed(width: 300, height: 100))
    }
}
#endif
