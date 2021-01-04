//
//  TimelineHeaderCollectionViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class TimelineHeaderCollectionViewCell: UICollectionViewCell {
    
    let timelineHeaderView = TimelineHeaderView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TimelineHeaderCollectionViewCell {
    
    private func _init() {
        timelineHeaderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timelineHeaderView)
        NSLayoutConstraint.activate([
            timelineHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            timelineHeaderView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            timelineHeaderView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            timelineHeaderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
}

