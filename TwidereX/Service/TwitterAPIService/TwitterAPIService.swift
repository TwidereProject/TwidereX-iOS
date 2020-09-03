//
//  TwitterAPIService.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import Foundation
import Combine
import TwitterAPI

final class TwitterAPIService {
        
    let session: URLSession
    
    init() {
        session = URLSession(configuration: .default)
    }
    
}
