//
//  HashtagTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereCore
import MetaTextKit
import MetaLabel

final class HashtagTableViewCell: UITableViewCell {
    
    let primaryLabel = MetaLabel(style: .hashtagTitle)
    let secondaryLabel = MetaLabel(style: .hashtagDescription)
    
    let separatorLine = SeparatorLineView()
    
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(cell: self)
        return viewModel
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension HashtagTableViewCell {
    
    private func _init() {
        let container = UIStackView()
        container.axis = .vertical
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 9),
            container.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 12),
        ])
        
        container.addArrangedSubview(primaryLabel)
        container.addArrangedSubview(secondaryLabel)
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
        ])
        
        primaryLabel.isUserInteractionEnabled = false
        secondaryLabel.isUserInteractionEnabled = false
    }
    
}

