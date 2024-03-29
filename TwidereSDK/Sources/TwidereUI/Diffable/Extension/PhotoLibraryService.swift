//
//  PhotoLibraryService.swift
//  
//
//  Created by MainasuK on 2021-12-13.
//

import os.log
import Foundation
import TwidereCore
import SwiftMessages

extension PhotoLibraryService {
    
    @MainActor
    public func presentSuccessNotification(title: String) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: save image success", ((#file as NSString).lastPathComponent), #line, #function)
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
    public func presentFailureNotification(
        error: Error,
        title: String,
        message: String
    ) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: save image fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
        var config = SwiftMessages.defaultConfig
        config.duration = .seconds(seconds: 3)
        config.interactiveHide = true
        let bannerView = NotificationBannerView()
        bannerView.configure(style: .warning)
        bannerView.titleLabel.text = title
        bannerView.messageLabel.text = {
            return [
                message,
                (error as? LocalizedError)?.errorDescription
            ]
            .compactMap { $0 }
            .joined(separator: ". ")
        }()
        
        SwiftMessages.show(config: config, view: bannerView)
    }

}

