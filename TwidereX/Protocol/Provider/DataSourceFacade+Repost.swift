//
//  DataSourceFacade+Repost.swift
//  DataSourceFacade+Repost
//
//  Created by Cirno MainasuK on 2021-9-6.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack

extension DataSourceFacade {
    static func responseToStatusRepostAction(
        provider: DataSourceProvider,
        status: DataSourceItem.Status,
        authenticationContext: AuthenticationContext
    ) async throws {
        let impactFeedbackGenerator = await UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        await impactFeedbackGenerator.impactOccurred()
        do {
            try await provider.context.apiService.repost(
                status: status,
                authenticationContext: authenticationContext
            )
            await notificationFeedbackGenerator.notificationOccurred(.success)
        } catch {
            await notificationFeedbackGenerator.notificationOccurred(.error)
        }
    }
}
