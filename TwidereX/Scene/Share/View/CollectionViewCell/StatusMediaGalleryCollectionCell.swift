//
//  StatusMediaGalleryCollectionCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoverFlowStackCollectionViewLayout

protocol StatusMediaGalleryCollectionCellDelegate: AnyObject {
    func statusMediaGalleryCollectionCell(_ cell: StatusMediaGalleryCollectionCell, mediaStackContainerViewModel: MediaStackContainerView.ViewModel, didSelectMediaView mediaViewModel: MediaView.ViewModel)
    // func statusMediaGalleryCollectionCell(_ cell: StatusMediaGalleryCollectionCell, toggleContentWarningOverlayViewDisplay contentWarningOverlayView: ContentWarningOverlayView)
}

final class StatusMediaGalleryCollectionCell: UICollectionViewCell {
    
    let logger = Logger(subsystem: "StatusMediaGalleryCollectionCell", category: "Cell")

    weak var delegate: StatusMediaGalleryCollectionCellDelegate?
        
    override func prepareForReuse() {
        super.prepareForReuse()
    
        contentConfiguration = nil
        delegate = nil
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

extension StatusMediaGalleryCollectionCell {
    
    private func _init() {        
        // nothing
    }
    
}
