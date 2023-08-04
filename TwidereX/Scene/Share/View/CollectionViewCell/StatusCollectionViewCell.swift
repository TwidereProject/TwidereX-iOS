//
//  StatusCollectionViewCell.swift
//  StatusCollectionViewCell
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

final class StatusCollectionViewCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
//    private(set) lazy var statusView = StatusView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
//        statusView.prepareForReuse()
        disposeBag.removeAll()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension StatusCollectionViewCell {
    
    private func _init() {
//        statusView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(statusView)
//        NSLayoutConstraint.activate([
//            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
//            statusView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
//            statusView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
//            statusView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//        ])
    }
    
}
