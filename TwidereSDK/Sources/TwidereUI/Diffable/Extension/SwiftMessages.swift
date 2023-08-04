//
//  SwiftMessages.swift
//  
//
//  Created by MainasuK on 2021-12-27.
//

import os.log
import Foundation
import SwiftMessages

extension SwiftMessages {
    
    @MainActor
    public static func presentFailureNotification(error: Error) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: error notification: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
        
        var config = SwiftMessages.defaultConfig
        config.duration = .seconds(seconds: 3)
        config.interactiveHide = true
        let bannerView = NotificationBannerView()
        bannerView.configure(style: .error)
        if let error = error as? LocalizedError {
            bannerView.titleLabel.text = error.errorDescription
            bannerView.messageLabel.text = error.failureReason
        } else {
            bannerView.titleLabel.text = error.localizedDescription
            bannerView.messageLabel.text = ""
            bannerView.messageLabel.isHidden = true
        }
        
        SwiftMessages.show(config: config, view: bannerView)
    }
}

