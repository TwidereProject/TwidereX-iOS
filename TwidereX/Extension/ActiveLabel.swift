//
//  ActiveLabel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-23.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import ActiveLabel

extension ActiveLabel {
    
    enum Style {
        case `default`
    }
    
    convenience init(style: Style) {
        self.init()
        
        numberOfLines = 0
        enabledTypes = [.mention, .hashtag, .url]
        mentionColor = Asset.Colors.hightLight.color
        hashtagColor = Asset.Colors.hightLight.color
        URLColor = Asset.Colors.hightLight.color
        textColor = UIColor.label.withAlphaComponent(0.8)
        font = .preferredFont(forTextStyle: .body)
        text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        urlMaximumLength = 30
    }
    
}
