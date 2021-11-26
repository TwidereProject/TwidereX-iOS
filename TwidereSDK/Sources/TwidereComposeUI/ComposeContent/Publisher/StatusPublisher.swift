//
//  StatusPublisher.swift
//  
//
//  Created by MainasuK on 2021-11-26.
//

import Foundation
import TwidereCore
import TwidereCommon

public protocol StatusPublisher {
    func publish(api: APIService, appSecret: AppSecret) async throws -> StatusPublishResult
}
