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
import SwiftyJSON
import TwitterSDK

final class SettingListViewModel: ObservableObject {

    var disposeBag = Set<AnyCancellable>()

    // input
    
    // output
    let settingListEntryPublisher = PassthroughSubject<SettingListEntry, Never>()
    
    init() {
        
    }

}
