//
//  TimelineHeaderTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import ActiveLabel

protocol TimelineHeaderTableViewCellDelegate: class {
    func timelineHeaderTableViewCell(_ timelineHeaderTableViewCell: TimelineHeaderTableViewCell, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity)
}


extension NeedsDependency where Self: TimelineHeaderTableViewCellDelegate {
    func timelineHeaderTableViewCell(_ timelineHeaderTableViewCell: TimelineHeaderTableViewCell, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        switch entity.type {
        case .url(let original, _):
            guard let url = URL(string: original) else { return }
            coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        default:
            break
        }
    }
}


final class TimelineHeaderTableViewCell: UITableViewCell {
    
    let timelineHeaderView = TimelineHeaderView()
    
    weak var delegate: TimelineHeaderTableViewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TimelineHeaderTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
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
extension TimelineHeaderTableViewCell: ActiveLabelDelegate {
    func activeLabel(_ activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        delegate?.timelineHeaderTableViewCell(self, activeLabel: activeLabel, didSelectActiveEntity: entity)
    }
}
