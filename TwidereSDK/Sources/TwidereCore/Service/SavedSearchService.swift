//
//  SavedSearchService.swift
//  
//
//  Created by MainasuK on 2021-12-22.
//

import os.log
import Foundation

public final class SavedSearchService {
    
    let logger = Logger(subsystem: "SavedSearchService", category: "Service")
    
    // input
    weak var apiService: APIService?
    
    // output
    var fetchListTimestampRecords: [AuthenticationContext: Date] = [:]

    public init(
        apiService: APIService
    ) {
        self.apiService = apiService
        // end init
    }
    
}

extension SavedSearchService {
    
    @MainActor
    public func fetchList(authenticationContext: AuthenticationContext) async throws {
        let timestamp = fetchListTimestampRecords[authenticationContext]
        let now = Date()
        
        if let timestamp = timestamp {
            guard now.timeIntervalSince(timestamp) > 5 else {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): skip fetch list due to fetch in recent 5s.")
                return
            }
        }
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch list")
        fetchListTimestampRecords[authenticationContext] = now
        
        do {
            switch authenticationContext {
            case .twitter(let authenticationContext):
                _ = try await self.apiService?.twitterSavedSearches(authenticationContext: authenticationContext)
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch list success")
            case .mastodon:
                break
            }
        } catch {
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch list fail: \(error.localizedDescription)")
        }
    }
}
