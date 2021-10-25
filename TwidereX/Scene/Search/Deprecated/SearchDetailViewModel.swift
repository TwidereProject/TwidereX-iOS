//
//  SearchDetailViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class SearchDetailViewModel {
    
    // input
    var needsBecomeFirstResponder = false
    let viewDidAppear = PassthroughSubject<Void, Never>()

    // output
    let searchText: CurrentValueSubject<String, Never>
    let searchActionPublisher = PassthroughSubject<Void, Never>()
    
    init(initialSearchText: String = "") {
        self.searchText = CurrentValueSubject(initialSearchText)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
