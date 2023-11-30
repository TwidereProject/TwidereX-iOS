//
//  TableViewPlainCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-31.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine
import MetaTextKit
import MetaLabel

public class TableViewPlainCell: UITableViewCell {
    
    private var _disposeBag = Set<AnyCancellable>()
    public var observations = Set<NSKeyValueObservation>()
    
    public let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = .label
        return imageView
    }()
    
    public let primaryTextLabel = MetaLabel(style: .listPrimaryText)
    
    public let secondaryTextLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .left : .right
        return label
    }()
    
    public let accessoryContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()
    
    public let accessoryImageView = UIImageView()
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        observations.removeAll()
        accessoryImageView.isHidden = true
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    func _init() {
        // container: H - [ iconImageView | textContainer | accessoryContainerView ]
        let container = UIStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 10),
        ])
        
        // iconImageView
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 24).priority(.required - 1),
            iconImageView.heightAnchor.constraint(equalToConstant: 24).priority(.required - 1),
        ])
        
        // textContainer
        let textContainer = UIStackView()
        textContainer.axis = .vertical
        container.addArrangedSubview(textContainer)
        
        textContainer.addArrangedSubview(primaryTextLabel)
        textContainer.addArrangedSubview(secondaryTextLabel)
        
        // accessoryContainerView
        container.addArrangedSubview(accessoryContainerView)
        accessoryContainerView.addArrangedSubview(accessoryImageView)
        accessoryImageView.setContentHuggingPriority(.required - 1, for: .horizontal)
        accessoryImageView.setContentHuggingPriority(.required - 1, for: .vertical)
        accessoryImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        accessoryImageView.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        iconImageView.isHidden = true
        secondaryTextLabel.isHidden = true
        accessoryImageView.isHidden = true
        
        primaryTextLabel.isUserInteractionEnabled = false
        
        // theme
        ThemeService.shared.$theme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setup(theme: theme)
            }
            .store(in: &_disposeBag)
    }
    
    public func setup(theme: Theme) {
        backgroundColor = theme.background
        contentView.backgroundColor = theme.foreground.withAlphaComponent(0.04)
    }
    
}
