//
//  DataSourceFacade+Like.swift
//  DataSourceFacade+Like
//
//  Created by Cirno MainasuK on 2021-9-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack
import TwitterSDK

extension DataSourceFacade {
    static func responseToStatusLikeAction(
        provider: DataSourceProvider,
        status: StatusRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        let impactFeedbackGenerator = await UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = await UINotificationFeedbackGenerator()
        
        await impactFeedbackGenerator.impactOccurred()
        do {
            try await provider.context.apiService.like(
                status: status,
                authenticationContext: authenticationContext
            )
            await notificationFeedbackGenerator.notificationOccurred(.success)
        } catch let error as Twitter.API.Error.ResponseError where error.httpResponseStatus == .forbidden {
            await notificationFeedbackGenerator.notificationOccurred(.error)
            await presentForbiddenBanner(
                error: error,
                dependency: provider
            )
        } catch {
            await notificationFeedbackGenerator.notificationOccurred(.error)
        }
    }
}
