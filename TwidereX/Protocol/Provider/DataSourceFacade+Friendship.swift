//
//  DataSourceProvider+Friendship.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import CoreData
import CoreDataStack

extension DataSourceFacade {
    static func responseToFriendshipButtonAction(
        provider: DataSourceProvider,
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async {
        let impactFeedbackGenerator = await UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        await impactFeedbackGenerator.impactOccurred()
        do {
            try await provider.context.apiService.friendship(
                user: user,
                authenticationContext: authenticationContext
            )
            await notificationFeedbackGenerator.notificationOccurred(.success)
        } catch {
            await notificationFeedbackGenerator.notificationOccurred(.error)
        }
    }
}
