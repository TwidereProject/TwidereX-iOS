//
//  StatusTableViewCell.swift
//  StatusTableViewCell
//
//  Created by Cirno MainasuK on 2021-8-20.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

protocol StatusTableViewCellDelegate: AnyObject {
    func statusTableViewCell(_ cell: StatusTableViewCell, mediaGridContainerView containerView: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int)
}

final class StatusTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "StatusTableViewCell", category: "UI")
    
    weak var delegate: StatusTableViewCellDelegate?
    let statusView = StatusView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        statusView.prepareForReuse()
        disposeBag.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension StatusTableViewCell {
    
    private func _init() {
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            statusView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        statusView.setup(style: .inline)
        statusView.toolbar.setup(style: .inline)
        
        statusView.mediaGridContainerView.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateSeparatorInset()
    }
    
    func updateSeparatorInset() {
        let readableLayoutFrame = contentView.readableContentGuide.layoutFrame
        switch traitCollection.horizontalSizeClass {
        case .compact:
            separatorInset = UIEdgeInsets(
                top: 0,
                left: readableLayoutFrame.minX + statusView.contentLayoutInset.left,
                bottom: 0,
                right: 0
            )
        default:
            separatorInset = UIEdgeInsets(
                top: 0,
                left: readableLayoutFrame.minX,
                bottom: 0,
                right: frame.width - readableLayoutFrame.maxX
            )
        }
    }
    
}

// MARK: - MediaGridContainerViewDelegate
extension StatusTableViewCell: MediaGridContainerViewDelegate {
    func mediaGridContainerView(_ container: MediaGridContainerView, didTapMediaView mediaView: MediaView, at index: Int) {
        switch container {
        case statusView.mediaGridContainerView:
            delegate?.statusTableViewCell(self, mediaGridContainerView: container, didTapMediaView: mediaView, at: index)
        default:
            assertionFailure()
            return
        }
    }
}
