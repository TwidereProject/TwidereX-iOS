//
//  SearchDetailViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

final class SearchDetailViewModel {
    
    // input
    var needsBecomeFirstResponder = false
    
    // output
    let searchText = CurrentValueSubject<String, Never>("")
    let searchActionPublisher = PassthroughSubject<Void, Never>()
    
}
