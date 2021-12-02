//
//  PublisherService.swift
//  
//
//  Created by MainasuK on 2021-12-2.
//

import os.log
import Foundation
import Combine
import TwidereCommon

public final class PublisherService {
    
    let logger = Logger(subsystem: "PublisherService", category: "Service")
    
    // input
    let apiService: APIService
    let appSecret: AppSecret
    public private(set) var statusPublishers: [StatusPublisher] = []
    
    // output
    public let statusPublishResult = PassthroughSubject<Result<StatusPublishResult, Error>, Never>()
    
    public init(
        apiService: APIService,
        appSecret: AppSecret
    ) {
        self.apiService = apiService
        self.appSecret = appSecret
    }
    
}

extension PublisherService {
    
    @MainActor
    public func enqueue(statusPublisher publisher: StatusPublisher) {
        guard !statusPublishers.contains(where: { $0 === publisher }) else {
            assertionFailure()
            return
        }
        statusPublishers.append(publisher)
        
        Task {
            do {
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): publish status…")
                let result = try await publisher.publish(api: apiService, appSecret: appSecret)
                
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): publish status success")
                self.statusPublishResult.send(.success(result))
                self.statusPublishers.removeAll(where: { $0 === publisher })
                
            } catch is CancellationError {
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): publish cancelled")
                self.statusPublishers.removeAll(where: { $0 === publisher })
                
            } catch {
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): publish failure: \(error.localizedDescription)")
                self.statusPublishResult.send(.failure(error))
            }
        }
    }
}
