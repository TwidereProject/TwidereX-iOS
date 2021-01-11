//
//  SearchViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-8.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine

final class SearchViewModel {
    
    var observations = Set<NSKeyValueObservation>()
    
    // input
    let viewDidAppear = PassthroughSubject<Void, Never>()
    
    // output
    let avatarStyle = CurrentValueSubject<UserDefaults.AvatarStyle, Never>(UserDefaults.shared.avatarStyle)

    init() {
        UserDefaults.shared
            .observe(\.avatarStyle) { [weak self] defaults, _ in
                guard let self = self else { return }
                self.avatarStyle.value = defaults.avatarStyle
            }
            .store(in: &observations)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
