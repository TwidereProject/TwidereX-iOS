//
//  DisplayPreferenceViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwitterMeta

final class DisplayPreferenceViewModel: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // MARK: - layout
    @Published var viewSize: CGSize = .zero

    // input
    let authContext: AuthContext
    
    // avatar
    @Published var avatarStyle = UserDefaults.shared.avatarStyle
    
    // Translation
    @Published var translateButtonPreference = UserDefaults.shared.translateButtonPreference
    @Published var translationServicePreference = UserDefaults.shared.translationServicePreference

    // output
    @Published var authenticationContext: AuthenticationContext?

    init(authContext: AuthContext) {
        self.authContext = authContext
        // end init
        
        // avatar style
        UserDefaults.shared.publisher(for: \.avatarStyle)
            .removeDuplicates()
            .assign(to: &$avatarStyle)
        $avatarStyle
            .sink { avatarStyle in
                UserDefaults.shared.avatarStyle = avatarStyle
            }
            .store(in: &disposeBag)
            
        // Translation
        UserDefaults.shared.publisher(for: \.translateButtonPreference)
            .removeDuplicates()
            .assign(to: &$translateButtonPreference)
        $translateButtonPreference
            .sink { preference in
                UserDefaults.shared.translateButtonPreference = preference
            }
            .store(in: &disposeBag)
        
        // Translation service
        UserDefaults.shared.publisher(for: \.translationServicePreference)
            .removeDuplicates()
            .assign(to: &$translationServicePreference)
        $translationServicePreference
            .sink { preference in
                UserDefaults.shared.translationServicePreference = preference
            }
            .store(in: &disposeBag)
    }

}
