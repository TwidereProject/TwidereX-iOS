//
//  NewColumnViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2023/5/23.
//  Copyright © 2023 Twidere. All rights reserved.
//

import UIKit
import Combine

final class NewColumnViewModel: ObservableObject {
    
    weak var delegate: NewColumnViewDelegate?
    
    // input
    let context: AppContext
    let auth: AuthContext
    
    @Published var preferredEnableHistory: Bool = false
    
    // output
    var tabs: [TabBarItem] {
        switch auth.authenticationContext {
        case .twitter:
            var results: [TabBarItem] = [
                .home,
                .notification,
                .search,
                .me,
                .likes,
            ]
            if preferredEnableHistory {
                results.append(.history)
            }
            results.append(.lists)
            results.append(.trends)
            return results
        case .mastodon:
            var results: [TabBarItem] = [
                .home,
                .notification,
                .search,
                .me,
                .local,
                .federated,
                .likes,
            ]
            if preferredEnableHistory {
                results.append(.history)
            }
            results.append(.lists)
            results.append(.trends)
            return results
        }
    }
        
    // output
    
    init(
        context: AppContext,
        auth: AuthContext
    ) {
        self.context = context
        self.auth = auth
        // end init
        
        UserDefaults.shared.publisher(for: \.preferredEnableHistory).removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$preferredEnableHistory)
    }

}
