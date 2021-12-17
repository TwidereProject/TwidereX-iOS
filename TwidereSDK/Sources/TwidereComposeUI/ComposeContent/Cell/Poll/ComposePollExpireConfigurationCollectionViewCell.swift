//
//  ComposePollExpireConfigurationCollectionViewCell.swift
//  
//
//  Created by MainasuK on 2021-11-30.
//

import os.log
import UIKit
import Combine
import TwidereCore
import TwidereAsset
import TwidereLocalization

public protocol ComposePollExpireConfigurationCollectionViewCellDelegate: AnyObject {
    func composePollExpireConfigurationCollectionViewCell(_ cell: ComposePollExpireConfigurationCollectionViewCell, didSelectExpireConfigurationOption option: PollComposeItem.ExpireConfiguration.Option)
}

public final class ComposePollExpireConfigurationCollectionViewCell: UICollectionViewCell {
    
    static var height: CGFloat = 44
    
    let logger = Logger(subsystem: "ComposePollExpireConfigurationCollectionViewCell", category: "Cell")
    
    var disposeBag = Set<AnyCancellable>()
    public weak var delegate: ComposePollExpireConfigurationCollectionViewCellDelegate?
    
    public let button: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        // button.expandEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: -20, right: -20)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: 8)
        button.setImage(Asset.ObjectTools.clock.image.withTintColor(.secondaryLabel), for: .normal)
        button.setTitle(L10n.Scene.Compose.Vote.Expiration._1Day, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.contentHorizontalAlignment = .leading
        return button
    }()
    
    public let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.Arrows.tablerChevronDown.image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ComposePollExpireConfigurationCollectionViewCell {
        
    private func _init() {
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 10),
        ])
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chevronImageView)
        NSLayoutConstraint.activate([
            chevronImageView.leadingAnchor.constraint(equalTo: button.trailingAnchor),
            contentView.trailingAnchor.constraint(equalTo: chevronImageView.trailingAnchor),
            chevronImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        chevronImageView.setContentHuggingPriority(.required - 1, for: .horizontal)
        chevronImageView.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        let children = PollComposeItem.ExpireConfiguration.Option.allCases.map { option -> UIAction in
            UIAction(
                title: option.title,
                image: nil,
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: [],
                state: .off
            ) { [weak self] action in
                guard let self = self else { return }
                self.expireOptionActionHandler(action, option: option)
            }
        }
        button.menu = UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: children)
        button.showsMenuAsPrimaryAction = true
    }
    
}

extension ComposePollExpireConfigurationCollectionViewCell {

    private func expireOptionActionHandler(_ sender: UIAction, option: PollComposeItem.ExpireConfiguration.Option) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): select \(option.title)")
        
        delegate?.composePollExpireConfigurationCollectionViewCell(self, didSelectExpireConfigurationOption: option)
    }
    
}
