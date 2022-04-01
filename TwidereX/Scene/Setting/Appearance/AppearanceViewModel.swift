//
//  AppearanceViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-4-1.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import CoreDataStack
import TwidereCommon
import TwidereCore
import TwitterSDK
import MastodonSDK

final class AppearanceViewModel: ObservableObject {
    
    // input
    let context: AppContext
    
    // output
    @Published var appIcon: UIImage
    
    // Translation
    @Published var translateButtonPreference = UserDefaults.shared.translateButtonPreference
    @Published var translationServicePreference = UserDefaults.shared.translationServicePreference
    
    init(
        context: AppContext
    ) {
        self.context = context
        // end init
        
        appIcon = UIImage(named: "AppIcon")!
        
        UserDefaults.shared.publisher(for: \.translateButtonPreference)
            .assign(to: &$translateButtonPreference)
        UserDefaults.shared.publisher(for: \.translationServicePreference)
            .assign(to: &$translationServicePreference)
    }
    
}
