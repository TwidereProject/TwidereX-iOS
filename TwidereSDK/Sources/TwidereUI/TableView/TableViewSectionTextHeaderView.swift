//
//  TableViewSectionTextHeaderView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

public final class TableViewSectionTextHeaderView: UIView {
    
    public let stackView = UIStackView()
    
    public let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.text = "Header"
        label.textColor = .secondaryLabel
        return label
    }()
    
    public let button = HitTestExpandedButton()
    
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
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 8),
        ])
        
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(button)
        
        // default hidden
        button.isHidden = true
    }
}
