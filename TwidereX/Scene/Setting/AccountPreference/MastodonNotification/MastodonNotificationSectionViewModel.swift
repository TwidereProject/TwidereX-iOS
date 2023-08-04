//
//  MastodonNotificationSectionViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-14.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import CoreDataStack
import TwidereCore

final class MastodonNotificationSectionViewModel: ObservableObject {
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let notificationSubscription: MastodonNotificationSubscription
    
    // output
    @Published var isActive: Bool
    
    @Published var isNewFollowEnabled: Bool
    @Published var isReblogEnabled: Bool
    @Published var isFavoriteEnabled: Bool
    @Published var isPollEnabled: Bool
    @Published var isMentionEnabled: Bool
    
    @Published var mentionPreference: MastodonNotificationSubscription.MentionPreference.Preference
    
    init(
        context: AppContext,
        authContext: AuthContext,
        notificationSubscription: MastodonNotificationSubscription
    ) {
        self.context = context
        self.authContext = authContext
        self.notificationSubscription = notificationSubscription
        self.isActive = notificationSubscription.isActive
        self.isNewFollowEnabled = notificationSubscription.follow
        self.isReblogEnabled = notificationSubscription.reblog
        self.isFavoriteEnabled = notificationSubscription.favourite
        self.isPollEnabled = notificationSubscription.poll
        self.isMentionEnabled = notificationSubscription.mention
        self.mentionPreference = notificationSubscription.mentionPreferenceTransient.preference
        // end init
        
        notificationSubscription.publisher(for: \.isActive)
            .receive(on: DispatchQueue.main)
            .assign(to: &$isActive)
        
        notificationSubscription.publisher(for: \.follow)
            .receive(on: DispatchQueue.main)
            .assign(to: &$isNewFollowEnabled)
        notificationSubscription.publisher(for: \.reblog)
            .receive(on: DispatchQueue.main)
            .assign(to: &$isReblogEnabled)
        notificationSubscription.publisher(for: \.favourite)
            .receive(on: DispatchQueue.main)
            .assign(to: &$isFavoriteEnabled)
        notificationSubscription.publisher(for: \.poll)
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPollEnabled)
        notificationSubscription.publisher(for: \.mention)
            .receive(on: DispatchQueue.main)
            .assign(to: &$isMentionEnabled)
        
        notificationSubscription.publisher(for: \.mentionPreferenceTransient)
            .receive(on: DispatchQueue.main)
            .map { $0.preference }
            .assign(to: &$mentionPreference)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MastodonNotificationSectionViewModel {
    
    func updateNotificationSubscription(action: @escaping (MastodonNotificationSubscription) -> Void) {
        let record = ManagedObjectRecord<MastodonNotificationSubscription>(objectID: notificationSubscription.objectID)
        Task {
            let managedObjectContext = context.coreDataStack.newTaskContext()
            try await managedObjectContext.performChanges {
                guard let object = record.object(in: managedObjectContext) else { return }
                action(object)
            }
            
            await context.notificationService.notifySubscriber(authenticationContext: authContext.authenticationContext)
        }   // end Task
    }
    
}
