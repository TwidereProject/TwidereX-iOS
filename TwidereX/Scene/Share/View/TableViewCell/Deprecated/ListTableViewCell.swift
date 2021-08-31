//
//  ListTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-31.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

class ListTableViewCell: UITableViewCell {
    
    var observations = Set<NSKeyValueObservation>()
    
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = .label
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()
    
    let secondaryTextLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .left : .right
        return label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        observations.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    func _init() {
        let container = UIStackView()
        container.axis = .horizontal
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 24).priority(.defaultHigh),
            iconImageView.heightAnchor.constraint(equalToConstant: 24).priority(.defaultHigh),
        ])
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        secondaryTextLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(secondaryTextLabel)
        secondaryTextLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        iconImageView.isHidden = true
        secondaryTextLabel.isHidden = true
    }
    
}
