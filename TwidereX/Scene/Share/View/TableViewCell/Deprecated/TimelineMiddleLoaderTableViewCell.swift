//
//  TimelineMiddleLoaderTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-8.
//

import os.log
import UIKit
import Combine
import CoreData

protocol TimelineMiddleLoaderTableViewCellDelegate: class {
    func configure(cell: TimelineMiddleLoaderTableViewCell, upperTimelineIndexObjectID: NSManagedObjectID)
    func timelineMiddleLoaderTableViewCell(_ cell: TimelineMiddleLoaderTableViewCell, loadMoreButtonDidPressed button: UIButton)
}

final class TimelineMiddleLoaderTableViewCell: TimelineLoaderTableViewCell {
    
    weak var delegate: TimelineMiddleLoaderTableViewCellDelegate?
    
    override func _init() {
        super._init()
        
        backgroundColor = .secondarySystemBackground
        
        let separatorLine = UIView.separatorLine
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: separatorLine.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: separatorLine.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: separatorLine))
        ])
        
        loadMoreButton.isHidden = false
        loadMoreButton.setImage(Asset.Arrows.arrowTriangle2Circlepath.image.withRenderingMode(.alwaysTemplate), for: .normal)
        loadMoreButton.setInsets(forContentPadding: .zero, imageTitlePadding: 4)
        loadMoreButton.addTarget(self, action: #selector(TimelineMiddleLoaderTableViewCell.loadMoreButtonDidPressed(_:)), for: .touchUpInside)
    }
    
}

extension TimelineMiddleLoaderTableViewCell {
    @objc private func loadMoreButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.timelineMiddleLoaderTableViewCell(self, loadMoreButtonDidPressed: sender)
    }
}

#if DEBUG
import SwiftUI

struct TimelineMiddleLoaderTableViewCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 375) {
            TimelineMiddleLoaderTableViewCell()
        }
        .previewLayout(.fixed(width: 375, height: 80))
    }
}
#endif
