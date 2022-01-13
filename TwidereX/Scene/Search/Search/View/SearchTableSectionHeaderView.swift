//
//  SearchTableSectionHeaderView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-1-6.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit

final class SearchTableSectionHeaderView: UIView {
        
    let label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
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

extension SearchTableSectionHeaderView {
    private func _init() {
        preservesSuperviewLayoutMargins = true
        
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 6),
        ])
    }
}
