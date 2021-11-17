//
//  StubTimelineCollectionViewCell.swift
//  StubTimelineCollectionViewCell
//
//  Created by Cirno MainasuK on 2021-8-2.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

final class StubTimelineCollectionViewCell: UICollectionViewCell {
    
    let primaryLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension StubTimelineCollectionViewCell {
    
    private func _init() {
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(primaryLabel)
        NSLayoutConstraint.activate([
            primaryLabel.topAnchor.constraint(equalTo: topAnchor),
            primaryLabel.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            primaryLabel.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
            primaryLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            primaryLabel.heightAnchor.constraint(equalToConstant: 44).priority(.required - 1),
        ])
    }
    
}

extension StubTimelineCollectionViewCell {
    struct ViewModel: Hashable {
        let title: String
    }
}
