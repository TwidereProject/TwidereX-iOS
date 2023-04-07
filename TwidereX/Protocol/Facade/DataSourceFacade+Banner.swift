//
//  DataSourceFacade+Banner.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-22.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
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

extension DataSourceFacade {
    
    @MainActor
    public static func presentErrorBanner(
        error: LocalizedError
    ) {
        var config = SwiftMessages.defaultConfig
        config.duration = .seconds(seconds: 3)
        config.interactiveHide = true
        let bannerView = NotificationBannerView()
        bannerView.configure(style: .warning)
        bannerView.titleLabel.text = error.errorDescription ?? "Unknown Error"
        let message = [error.failureReason, error.recoverySuggestion].compactMap { $0 }.joined(separator: "\n")
        bannerView.messageLabel.text = message
        bannerView.messageLabel.isHidden = message.isEmpty
        SwiftMessages.show(config: config, view: bannerView)
    }

    @MainActor
    public static func presentForbiddenBanner(
        error: Error,
        dependency: NeedsDependency
    ) {
        var config = SwiftMessages.defaultConfig
        config.duration = .seconds(seconds: 15)
        config.interactiveHide = true
        let bannerView = NotificationBannerView()
        bannerView.configure(style: .warning)
        bannerView.titleLabel.text = "Forbidden"    // TODO: i18n
        bannerView.messageLabel.text = "Application token expired. Please sign in the app again to reactive."
        bannerView.messageLabel.numberOfLines = 0
        bannerView.actionButtonTapHandler = { [weak dependency] _ in
            guard let dependency = dependency else { return }
            let welcomeViewModel = WelcomeViewModel(
                context: dependency.context,
                configuration: WelcomeViewModel.Configuration(allowDismissModal: true)
            )
            dependency.coordinator.present(
                scene: .welcome(viewModel: welcomeViewModel),
                from: nil,
                transition: .modal(animated: true, completion: nil)
            )
        }
        SwiftMessages.show(config: config, view: bannerView)
    }
    
}
