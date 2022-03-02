//
//  TimelineBottomLoaderTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-8.
//

import UIKit
import Combine

final class TimelineBottomLoaderTableViewCell: TimelineLoaderTableViewCell {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        activityIndicatorView.startAnimating()
    }
    
    override func _init() {
        super._init()
        
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
    }
}
