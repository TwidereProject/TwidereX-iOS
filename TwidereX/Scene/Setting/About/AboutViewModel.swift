//
//  AboutViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-5-18.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import SwiftUI
import Combine
import SwiftyJSON
import TwitterSDK

final class AboutViewModel: ObservableObject {

    var disposeBag = Set<AnyCancellable>()

    // input
    let authContext: AuthContext
    
    // output
    let entryPublisher = PassthroughSubject<Entry, Never>()
    
    init(authContext: AuthContext) {
        self.authContext = authContext
    }

}

extension AboutViewModel {
    enum Entry: Identifiable, Hashable, CaseIterable {
        case github
        case twitter
        case telegram
        case discord
        case license
        case privacyPolicy
        
        var id: Entry { return self }
        
        public var text: String {
            switch self {
            case .github:           return "GitHub"
            case .twitter:          return "Twitter"
            case .telegram:         return "Telegram"
            case .discord:          return "Discord"
            case .license:          return "License"
            case .privacyPolicy:    return "Privacy Policy"
            }
        }
    }
}
