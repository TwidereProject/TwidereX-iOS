//
//  TimelineHeaderCollectionViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import ActiveLabel

protocol TimelineHeaderCollectionViewCellDelegate: class {
    func timelineHeaderCollectionViewCell(_ timelineHeaderCollectionViewCell: TimelineHeaderCollectionViewCell, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity)
}

extension NeedsDependency where Self: TimelineHeaderCollectionViewCellDelegate {
    func timelineHeaderCollectionViewCell(_ timelineHeaderCollectionViewCell: TimelineHeaderCollectionViewCell, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        switch entity.type {
        case .url(let original, _):
            guard let url = URL(string: original) else { return }
            coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        default:
            break
        }
    }
}

final class TimelineHeaderCollectionViewCell: UICollectionViewCell {
    
    let timelineHeaderView = TimelineHeaderView()
    
    weak var delegate: TimelineHeaderCollectionViewCellDelegate?
    
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
        
        timelineHeaderView.messageLabel.delegate = self
    }
    
}

// MARK: - ActiveLabelDelegate
extension TimelineHeaderCollectionViewCell: ActiveLabelDelegate {
    func activeLabel(_ activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        delegate?.timelineHeaderCollectionViewCell(self, activeLabel: activeLabel, didSelectActiveEntity: entity)
    }
}
