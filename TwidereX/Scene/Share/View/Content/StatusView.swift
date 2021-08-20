//
//  StatusView.swift
//  StatusView
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Combine
import UIKit
import MetaTextKit
import MetaTextArea

final class StatusView: UIView {
    
    var disposeBag = Set<AnyCancellable>()
    
    static let authorAvatarButtonSize = CGSize(width: 44, height: 44)
    
    let authorAvatarButton = AvatarButton()
    
    static var authorNameLabelStyle: Meta.Style { .statusAuthorName }
    let authorNameLabel = MetaLabel(style: StatusView.authorNameLabelStyle)
    
    let authorUsernameLabel = PlainMetaLabel(style: .statusAuthorUsername)
    
    let contentTextView: MetaTextAreaView = {
        let textView = MetaTextAreaView()
        return textView
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

extension StatusView {
    
    func prepareForReuse() {
        authorAvatarButton.avatarImageView.cancelTask()
        authorNameLabel.reset()
        authorUsernameLabel.text = ""
        contentTextView.setAttributedString(NSAttributedString(string: ""))
    }
    
    private func _init() {
        // container: V - [ header container | body container ]
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        // header container: H - [ icon | label ]
//        let headerContainerStackView = UIStackView()
//        headerContainerStackView.axis = .horizontal
//        containerStackView.addArrangedSubview(headerContainerStackView)
        
        // body container: H - [ authorAvatarButton | content container | … ]
        let bodyContainerStackView = UIStackView()
        bodyContainerStackView.axis = .horizontal
        bodyContainerStackView.alignment = .top
        containerStackView.addArrangedSubview(bodyContainerStackView)
        
        // authorAvatarButton
        authorAvatarButton.translatesAutoresizingMaskIntoConstraints = false
        bodyContainerStackView.addArrangedSubview(authorAvatarButton)
        NSLayoutConstraint.activate([
            authorAvatarButton.widthAnchor.constraint(equalToConstant: StatusView.authorAvatarButtonSize.width).priority(.required - 1),
            authorAvatarButton.heightAnchor.constraint(equalToConstant: StatusView.authorAvatarButtonSize.height).priority(.required - 1),
        ])
        authorAvatarButton.avatarImageView.imageViewSize = StatusView.authorAvatarButtonSize
        
        // content container: V - [ author content | contentTextView ]
        let contentContainerView = UIStackView()
        contentContainerView.axis = .vertical
        bodyContainerStackView.addArrangedSubview(contentContainerView)
        
        // author content: H - [ authorNameLabel | authorUsernameLabel | padding | timestampLabel ]
        let authorContentStackView = UIStackView()
        authorContentStackView.axis = .horizontal
        authorContentStackView.spacing = 6
        contentContainerView.addArrangedSubview(authorContentStackView)
        
        authorContentStackView.addArrangedSubview(authorNameLabel)
        authorNameLabel.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        authorContentStackView.addArrangedSubview(authorUsernameLabel)
        authorUsernameLabel.setContentCompressionResistancePriority(.required - 11, for: .horizontal)
        authorContentStackView.addArrangedSubview(UIView()) // padding
        
        contentTextView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addArrangedSubview(contentTextView)
        contentTextView.setContentHuggingPriority(.required - 1, for: .vertical)
        

//        let authorContentStackView = UIStackView()
//        authorContentStackView.axis = .horizontal
//        authorContentStackView.addArrangedSubview(authorNameLabel)
//        authorNameLabel.setContentHuggingPriority(.required - 1, for: .horizontal)
//        
//        authorContentStackView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(authorContentStackView)
//        NSLayoutConstraint.activate([
//            authorContentStackView.topAnchor.constraint(equalTo: topAnchor),
//            authorContentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            authorContentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            authorContentStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
//        ])
    }
}
