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
    let authContext: AuthContext
    
    // output
    let settingListEntryPublisher = PassthroughSubject<SettingListEntry, Never>()
    
    // account
    @Published var userViewModel: UserView.ViewModel?
    
    // App Icon
    @Published var alternateIconNamePreference = UserDefaults.shared.alternateIconNamePreference
    
    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context = context
        self.authContext = authContext
        // end init
        
        Task {
            await setupAccountSource()
        }
        
        // App Icon
        UserDefaults.shared.publisher(for: \.alternateIconNamePreference)
            .assign(to: &$alternateIconNamePreference)
    }

}

extension SettingListViewModel {
    @MainActor
    func setupAccountSource() async {
        guard let user = authContext.authenticationContext.user(in: context.managedObjectContext) else { return }
        userViewModel = UserView.ViewModel(
            user: user,
            authContext: authContext,
            kind: .settingAccountSection,
            delegate: nil
        )
    }
}
