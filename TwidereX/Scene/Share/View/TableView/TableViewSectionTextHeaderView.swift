//
//  TableViewSectionTextHeaderView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class TableViewSectionTextHeaderView: UIView {
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.text = "Header"
        label.textColor = .secondaryLabel
        return label
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

extension TableViewSectionTextHeaderView {
    private func _init() {
        preservesSuperviewLayoutMargins = true
        
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
        ])
    }
}
