//
//  AccountPreferenceViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-12.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import CoreDataStack
import TwidereCore

final class AccountPreferenceViewModel: ObservableObject {

    // input
    let context: AppContext
    let auth: AuthContext
    let user: UserObject
    
    // notification
    @Published var mastodonNotificationSectionViewModel: MastodonNotificationSectionViewModel?
    @Published var isNewFollowEnabled = true
    @Published var isReblogEnabled = true
    @Published var isFavoriteEnabled = true
    @Published var isPollEnabled = true
    @Published var isMentionEnabled = true

    // output
    let listEntryPublisher = PassthroughSubject<AccountPreferenceListEntry, Never>()
    
    init(
        context: AppContext,
        auth: AuthContext,
        user: UserObject
    ) {
        self.context = context
        self.auth = auth
        self.user = user
        // end init
        
        setupNotificationSource()
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension AccountPreferenceViewModel {
    func setupNotificationSource() {
        switch user {
        case .twitter:
            // do nothing
            break
        case .mastodon(let user):
            mastodonNotificationSectionViewModel = user.mastodonAuthentication?.notificationSubscription.flatMap {
                return .init(
                    context: context,
                    auth: auth,
                    notificationSubscription: $0
                )
            }
        }
    }
}
  
