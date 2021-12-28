//
//  TrendService.swift
//  
//
//  Created by MainasuK on 2021-12-28.
//

import os.log
import Foundation
import TwitterSDK

public final class TrendService {
    
    let logger = Logger(subsystem: "TrendService", category: "Service")
    
    public typealias PlaceID = Int
    
    // input
    weak var apiService: APIService?
    
    // output
    @Published public var trendGroupRecords: [PlaceID: TrendGroup] = [:]

    public init(
        apiService: APIService
    ) {
        self.apiService = apiService
        // end init
    }
    
}

extension TrendService {
    public struct TrendGroup {
        public let trends: [TrendObject]
        public let timestamp: Date
    }
    
}

extension TrendService {
    
    @MainActor
    public func fetchTrend(
        placeID: PlaceID = 1,
        authenticationContext: AuthenticationContext
    ) async throws {
        let _object = trendGroupRecords[placeID]
        let now = Date()
        
        if let object = _object {
            guard now.timeIntervalSince(object.timestamp) > 1 * 30 * 60 else {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): skip fetch trend \(placeID) due to fetch in recent 30min.")
                return
            }
        }
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch trend \(placeID)")
        
        do {
            switch authenticationContext {
            case .twitter(let authenticationContext):
                let response = try await self.apiService?.twitterTrend(
                    placeID: placeID,
                    authenticationContext: authenticationContext
                )
                for data in response?.value ?? [] {
                    guard let location = data.locations.first else { continue }
                    trendGroupRecords[location.woeid] = TrendGroup(
                        trends: data.trends.map { TrendObject.twitter(trend: $0) },
                        timestamp: data.asOf
                    )
                }
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch trend success")
            case .mastodon:
                break
            }
        } catch {
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch trend fail: \(error.localizedDescription)")
        }
    }
    
}
