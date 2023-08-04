//
//  TimelineBottomLoaderTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-8.
//

import UIKit
import Combine

public final class TimelineBottomLoaderTableViewCell: TimelineLoaderTableViewCell {
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        activityIndicatorView.startAnimating()
    }
    
    override func _init() {
        super._init()
        
        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
    }
}
