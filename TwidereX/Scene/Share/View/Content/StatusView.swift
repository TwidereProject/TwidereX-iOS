//
//  StatusView.swift
//  StatusView
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import MetaTextKit

final class StatusView: UIView {
    
    private(set) lazy var authorNameLabel = MetaLabel(style: .statusAuthorName)
    
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
    private func _init() {
        let authorContentStackView = UIStackView()
        authorContentStackView.axis = .horizontal
        authorContentStackView.addArrangedSubview(authorNameLabel)
        
        authorContentStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(authorContentStackView)
        NSLayoutConstraint.activate([
            authorContentStackView.topAnchor.constraint(equalTo: topAnchor),
            authorContentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            authorContentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            authorContentStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
