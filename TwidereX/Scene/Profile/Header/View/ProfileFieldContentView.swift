//
//  ProfileFieldContentView.swift
//  ProfileFieldContentView
//
//  Created by Cirno MainasuK on 2021-9-10.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import MetaTextKit

protocol ProfileFieldContentViewDelegate: AnyObject {
    func profileFieldContentView(_ contentView: ProfileFieldContentView, metaLabel: MetaLabel, didSelectMeta meta: Meta)
}

// Ref: https://swiftsenpai.com/development/uicollectionview-list-custom-cell/
final class ProfileFieldContentView: UIView, UIContentView {
    
    static let verticalMargin: CGFloat = 4
    
    let logger = Logger(subsystem: "ProfileFieldContentView", category: "UI")
    weak var delegate: ProfileFieldContentViewDelegate?
    
    let container: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = 8
        return stackView
    }()
    
    private let _placeholderMetaLabel = MetaLabel(style: .profileFieldKey)
    let symbolContainer = UIView()
    let symbolImageView = UIImageView()
    let keyMetaLabel = MetaLabel(style: .profileFieldKey)
    let valueMetaLabel = MetaLabel(style: .profileFieldValue)
    
    private var currentConfiguration: ContentConfiguration!
    var configuration: UIContentConfiguration {
        get {
            currentConfiguration
        }
        set {
            guard let newConfiguration = newValue as? ContentConfiguration else { return }
            apply(configuration: newConfiguration)
        }
    }
    init(configuration: ContentConfiguration) {
        super.init(frame: .zero)
        
        _init()
        apply(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileFieldContentView {
    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: ProfileFieldContentView.verticalMargin),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: ProfileFieldContentView.verticalMargin),
        ])
        
        _placeholderMetaLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(_placeholderMetaLabel)
        NSLayoutConstraint.activate([
            _placeholderMetaLabel.topAnchor.constraint(equalTo: container.topAnchor),
            _placeholderMetaLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            _placeholderMetaLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        _placeholderMetaLabel.configure(content: PlaintextMetaContent(string: " "))
        _placeholderMetaLabel.setContentHuggingPriority(.required - 1, for: .vertical)
        _placeholderMetaLabel.isHidden = true
        
        symbolContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(symbolContainer)
        container.addArrangedSubview(keyMetaLabel)
        container.addArrangedSubview(valueMetaLabel)
        NSLayoutConstraint.activate([
            symbolContainer.heightAnchor.constraint(equalTo: _placeholderMetaLabel.heightAnchor, multiplier: 1.0).priority(.required - 1),
            symbolContainer.widthAnchor.constraint(equalTo: symbolContainer.heightAnchor, multiplier: 1.0).priority(.required - 2),
        ])
        symbolContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        symbolContainer.setContentHuggingPriority(.defaultLow, for: .vertical)
        _placeholderMetaLabel.setContentHuggingPriority(.required - 1, for: .vertical)
        _placeholderMetaLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)

        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        symbolContainer.addSubview(symbolImageView)
        NSLayoutConstraint.activate([
            symbolImageView.centerXAnchor.constraint(equalTo: symbolContainer.centerXAnchor),
            symbolImageView.centerYAnchor.constraint(equalTo: symbolContainer.centerYAnchor, constant: -1),
            symbolImageView.widthAnchor.constraint(equalTo: symbolContainer.widthAnchor, multiplier: 0.6).priority(.required - 5),
            symbolImageView.heightAnchor.constraint(equalTo: symbolContainer.heightAnchor, multiplier: 0.6).priority(.required - 5),
        ])
        symbolImageView.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        symbolImageView.setContentHuggingPriority(.defaultLow - 1, for: .vertical)
        keyMetaLabel.setContentHuggingPriority(.required - 9, for: .horizontal)
        keyMetaLabel.setContentCompressionResistancePriority(.required - 9, for: .horizontal)
        valueMetaLabel.setContentHuggingPriority(.required - 10, for: .horizontal)
        valueMetaLabel.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
        
        valueMetaLabel.linkDelegate = self
    }
    
    private func apply(configuration: ContentConfiguration) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard currentConfiguration != configuration else { return }
        
        // Replace current configuration with new configuration
        currentConfiguration = configuration
        
        guard let item = configuration.item else { return }
        
        _placeholderMetaLabel.setupAttributes(style: .profileFieldValue)
        _placeholderMetaLabel.configure(content: Meta.convert(from: .plaintext(string: " ")))
        
        if let symbol = item.symbol {
            symbolImageView.image = symbol.withRenderingMode(.alwaysTemplate)
            symbolImageView.tintColor = .secondaryLabel
            symbolContainer.isHidden = false
        } else {
            symbolContainer.isHidden = true
        }
        if let content = item.key {
            keyMetaLabel.setupAttributes(style: .profileFieldKey)
            keyMetaLabel.configure(content: content)
            keyMetaLabel.isHidden = false
        } else {
            keyMetaLabel.isHidden = true
        }
        if let content = item.value {
            valueMetaLabel.setupAttributes(style: .profileFieldValue)
            valueMetaLabel.configure(content: content)
            valueMetaLabel.isHidden = false
        } else {
            valueMetaLabel.isHidden = true
        }
    }
}


extension ProfileFieldContentView {
    struct ContentConfiguration: UIContentConfiguration, Hashable {
        let logger = Logger(subsystem: "ProfileFieldContentView.ContentConfiguration", category: "ContentConfiguration")
        
        var item: ProfileFieldListView.Item?
        
        func makeContentView() -> UIView & UIContentView {
            ProfileFieldContentView(configuration: self)
        }
        
        func updated(for state: UIConfigurationState) -> ProfileFieldContentView.ContentConfiguration {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
            
            var updatedConfiguration = self
            // TODO:
            
            return updatedConfiguration
        }
        
        static func == (
            lhs: ProfileFieldContentView.ContentConfiguration,
            rhs: ProfileFieldContentView.ContentConfiguration
        ) -> Bool {
            return lhs.item == rhs.item
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(item)
        }
    }
}

// MARK: - MetaLabelDelegate
extension ProfileFieldContentView: MetaLabelDelegate {
    func metaLabel(_ metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did select meta: \(meta.debugDescription)")
        delegate?.profileFieldContentView(self, metaLabel: metaLabel, didSelectMeta: meta)
    }
}
