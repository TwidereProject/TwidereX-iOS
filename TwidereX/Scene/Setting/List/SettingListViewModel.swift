//
//  SettingListViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-5-18.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import SwiftUI
import Combine
import CoreDataStack
import SwiftyJSON
import TwitterSDK
import TwidereCore
import Meta

final class SettingListViewModel: ObservableObject {

    var disposeBag = Set<AnyCancellable>()

    // input
    let context: AppContext
    let auth: AuthContext?
    
    // output
    let settingListEntryPublisher = PassthroughSubject<SettingListEntry, Never>()
    
    // account
    @Published var user: UserObject?

    init(
        context: AppContext,
        auth: AuthContext?
    ) {
        self.context = context
        self.auth = auth
        // end init
        
        Task {
            await setupAccountSource()
        }
    }

}

extension SettingListViewModel {
    @MainActor
    func setupAccountSource() async {
        user = auth?.authenticationContext.user(in: context.managedObjectContext)
    }
}
