//
//  ComposePollMultipleConfigurationCollectionViewCell.swift
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

public protocol ComposePollMultipleConfigurationCollectionViewCellDelegate: AnyObject {
    func composePollMultipleConfigurationCollectionViewCell(_ cell: ComposePollMultipleConfigurationCollectionViewCell, multipleSelectionDidChange isMultiple: Bool)
}

public final class ComposePollMultipleConfigurationCollectionViewCell: UICollectionViewCell {
    
    static var height: CGFloat = 44
    
    let logger = Logger(subsystem: "ComposePollMultipleConfigurationCollectionViewCell", category: "Cell")
    
    var disposeBag = Set<AnyCancellable>()
    public weak var delegate: ComposePollMultipleConfigurationCollectionViewCellDelegate?
    
    public let button: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        // button.expandEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: -20, right: -20)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: 8)
        button.setImage(Asset.Indices.square.image.withTintColor(.secondaryLabel), for: .normal)
        button.setTitle(L10n.Scene.Compose.Vote.multiple, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.contentHorizontalAlignment = .leading
        return button
    }()
    
    public private(set) var isMultiple: Bool = false
    
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

extension ComposePollMultipleConfigurationCollectionViewCell {
    
    private func _init() {
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 10),
            contentView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
        ])
        
        button.addTarget(self, action: #selector(ComposePollMultipleConfigurationCollectionViewCell.buttonDidPressed(_:)), for: .touchUpInside)
    }
    
    public func configure(isMultiple: Bool) {
        self.isMultiple = isMultiple
        
        let image = isMultiple ? Asset.Indices.checkmarkSquare.image.withTintColor(.secondaryLabel) : Asset.Indices.square.image.withTintColor(.secondaryLabel)
        button.setImage(image, for: .normal)
    }
    
}

extension ComposePollMultipleConfigurationCollectionViewCell {
    @objc private func buttonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        delegate?.composePollMultipleConfigurationCollectionViewCell(self, multipleSelectionDidChange: !isMultiple)
    }
}
