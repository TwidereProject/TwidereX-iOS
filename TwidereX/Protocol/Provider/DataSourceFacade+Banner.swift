//
//  DataSourceFacade+Banner.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-22.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import SwiftMessages

extension DataSourceFacade {
    
    @MainActor
    public static func presentSuccessBanner(
        title: String
    ) {
        var config = SwiftMessages.defaultConfig
        config.duration = .seconds(seconds: 3)
        config.interactiveHide = true
        let bannerView = NotificationBannerView()
        bannerView.configure(style: .success)
        bannerView.titleLabel.text = title
        bannerView.messageLabel.isHidden = true
        SwiftMessages.show(config: config, view: bannerView)
    }
    
    @MainActor
    public static func presentWarningBanner(
        title: String,
        message: String,
        error: Error
    ) {
        var config = SwiftMessages.defaultConfig
        config.duration = .seconds(seconds: 3)
        config.interactiveHide = true
        let bannerView = NotificationBannerView()
        bannerView.configure(style: .warning)
        bannerView.titleLabel.text = title
        bannerView.messageLabel.text = message
        SwiftMessages.show(config: config, view: bannerView)
    }
    
}
