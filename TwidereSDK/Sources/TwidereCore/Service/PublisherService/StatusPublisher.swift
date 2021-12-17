//
//  StatusPublisher.swift
//  
//
//  Created by MainasuK on 2021-11-26.
//

import Foundation
import TwidereCommon

public protocol StatusPublisher: ProgressReporting {
    var state: Published<StatusPublisherState>.Publisher { get }
    func publish(api: APIService, appSecret: AppSecret) async throws -> StatusPublishResult
}
