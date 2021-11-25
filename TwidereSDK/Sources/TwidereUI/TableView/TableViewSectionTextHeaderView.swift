//
//  TableViewSectionTextHeaderView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

public final class TableViewSectionTextHeaderView: UIView {
    
    public let headerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.text = "Header"
        label.textColor = .secondaryLabel
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
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
            headerLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
            headerLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
        ])
    }
}
