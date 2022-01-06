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
    @Published public var trendGroupRecords: [TrendGroupIndex: TrendGroup] = [:]

    public init(
        apiService: APIService
    ) {
        self.apiService = apiService
        // end init
    }
    
}

extension TrendService {
    public enum TrendGroupIndex: Hashable, CustomStringConvertible {
        case none
        case twitter(placeID: Int)
        case mastodon(domain: String)
        
        public var description: String {
            switch self {
            case .none:
                return "none"
            case .twitter(let placeID):
                return "twitter placeID: \(placeID)"
            case .mastodon(let domain):
                return "mastodon domain: \(domain)"
            }
        }
    }
    
    public struct TrendGroup {
        public let trends: [TrendObject]
        public let timestamp: Date
    }
}

extension TrendService {
    
    @MainActor
    public func fetchTrend(
        index: TrendGroupIndex,
        authenticationContext: AuthenticationContext
    ) async throws {
        let _object = trendGroupRecords[index]
        let now = Date()
        
        if let object = _object {
            guard now.timeIntervalSince(object.timestamp) > 5 * 60 else {  // 5min CD
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): skip fetch trend \(index) due to fetch in recent 5min.")
                return
            }
        }
        
        guard let apiService = self.apiService else {
            return
        }
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch trend \(index)")
        
        do {
            switch (index, authenticationContext) {
            case (.twitter(let placeID), .twitter(let authenticationContext)):
                let response = try await apiService.twitterTrend(
                    placeID: placeID,
                    authenticationContext: authenticationContext
                )
                for data in response.value {
                    guard let location = data.locations.first else { continue }
                    trendGroupRecords[.twitter(placeID: location.woeid)] = TrendGroup(
                        trends: data.trends.map { TrendObject.twitter(trend: $0) },
                        timestamp: data.asOf
                    )
                }
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch trends \(response.value.count)")
            case (.mastodon(let domain), .mastodon(let authenticationContext)):
                let response = try await apiService.mastodonTrend(
                    authenticationContext: authenticationContext
                )
                trendGroupRecords[.mastodon(domain: domain)] = TrendGroup(
                    trends: response.value.map { TrendObject.mastodon(tag: $0) },
                    timestamp: response.networkDate
                )
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch trends \(response.value.count) ")
            case (.none, _):
                break
            default:
                assertionFailure()
                return
            }
        } catch {
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch trend fail: \(error.localizedDescription)")
        }
    }
    
}
