//
//  DataSourceFacade+Report.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereAsset
import TwidereLocalization
import SwiftMessages

extension DataSourceFacade {
    @MainActor
    static func presentUserReportAlert(
        provider: DataSourceProvider,
        user: UserRecord,
        performBlock: Bool,
        authenticationContext: AuthenticationContext
    ) async {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

        do {
            let alertController = try await DataSourceFacade.createUserReportAlert(
                provider: provider,
                user: user,
                performBlock: performBlock,
                authenticationContext: authenticationContext
            )
            impactFeedbackGenerator.impactOccurred()
            provider.coordinator.present(
                scene: .alertController(alertController: alertController),
                from: provider,
                transition: .alertController(animated: true, completion: nil)
            )
        } catch {
            notificationFeedbackGenerator.notificationOccurred(.error)
        }
    }
}

extension DataSourceFacade {
    
    private struct ReportAlertContext {
        let name: String
    }

    @MainActor
    static func createUserReportAlert(
        provider: DataSourceProvider,
        user: UserRecord,
        performBlock: Bool,
        authenticationContext: AuthenticationContext
    ) async throws -> UIAlertController {
        let managedObjectContext = provider.context.managedObjectContext
        let reportAlertContext: ReportAlertContext = try await managedObjectContext.perform {
            switch (user, authenticationContext) {
            case (.twitter(let record), .twitter(let authenticationContext)):
                guard let user = record.object(in: managedObjectContext),
                      let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
                else {
                    throw AppError.implicit(.badRequest)
                }
                // let me = authentication.user
                return ReportAlertContext(
                    name: user.name
                )
                
            case (.mastodon(let record), .mastodon(let authenticationContext)):
                guard let user = record.object(in: managedObjectContext),
                      let authentication = authenticationContext.authenticationRecord.object(in: managedObjectContext)
                else {
                    throw AppError.implicit(.badRequest)
                }
                // let me = authentication.user
                return ReportAlertContext(
                    name: user.name
                )
                
            default:
                throw AppError.implicit(.badRequest)
            }
        }
        
        let alertControllerTitle = performBlock ? L10n.Common.Controls.Friendship.doYouWantToReportAndBlockUser(reportAlertContext.name) : L10n.Common.Controls.Friendship.doYouWantToReportUser(reportAlertContext.name)
        
        let alertController = UIAlertController(
            title: alertControllerTitle,
            message: nil,
            preferredStyle: .alert
        )
        let reportAction = UIAlertAction(
            title: L10n.Common.Controls.Friendship.Actions.report,
            style: .destructive
        ) { [weak provider] _ in
            guard let provider = provider else { return }
            Task {
                do {
                    try await provider.context.apiService.reportForSpam(
                        user: user,
                        performBlock: performBlock,
                        authenticationContext: authenticationContext
                    )
                    DispatchQueue.main.async {
                        var config = SwiftMessages.defaultConfig
                        config.duration = .seconds(seconds: 3)
                        config.interactiveHide = true
                        let bannerView = NotificationBannerView()
                        bannerView.configure(style: .success)
                        bannerView.titleLabel.text = performBlock ? L10n.Common.Alerts.ReportAndBlockUserSuccess.title(reportAlertContext.name) : L10n.Common.Alerts.ReportUserSuccess.title(reportAlertContext.name)
                        bannerView.titleLabel.numberOfLines = 2
                        bannerView.messageLabel.isHidden = true
                        SwiftMessages.show(config: config, view: bannerView)
                    }
                } catch {
                    DispatchQueue.main.async {
                        var config = SwiftMessages.defaultConfig
                        config.duration = .seconds(seconds: 3)
                        config.interactiveHide = true
                        let bannerView = NotificationBannerView()
                        bannerView.configure(style: .warning)
                        bannerView.titleLabel.text = performBlock ? L10n.Common.Alerts.FailedToReportAndBlockUser.title(reportAlertContext.name) : L10n.Common.Alerts.FailedToReportUser.title(reportAlertContext.name)
                        bannerView.messageLabel.text = performBlock ? L10n.Common.Alerts.FailedToReportAndBlockUser.message : L10n.Common.Alerts.FailedToReportUser.message
                        SwiftMessages.show(config: config, view: bannerView)
                    }
                }
            }
        }
        alertController.addAction(reportAction)
        
        let cancelAction = UIAlertAction.cancel
        alertController.addAction(cancelAction)
        
        return alertController
    }
    
}

