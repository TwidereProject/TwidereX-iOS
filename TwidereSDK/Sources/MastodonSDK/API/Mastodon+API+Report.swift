//
//  Mastodon+API+Report.swift
//  
//
//  Created by MainasuK on 2021-12-6.
//

import Foundation
import enum NIOHTTP1.HTTPResponseStatus

extension Mastodon.API.Report {
    static func reportsEndpointURL(domain: String) -> URL {
        Mastodon.API.endpointURL(domain: domain).appendingPathComponent("reports")
    }

    /// File a report
    ///
    /// Version history:
    /// 1.1 - added
    /// 2.3.0 - add forward parameter
    /// # Last Update
    ///   2021/12/6
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/reports/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: fileReportQuery query
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains status indicate if report successfully.
    public static func fileReport(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Report.FileReportQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Bool> {
        let request = Mastodon.API.request(
            url: reportsEndpointURL(domain: domain),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (_, response) = try await session.data(for: request, delegate: nil)
        guard let response = response as? HTTPURLResponse else {
            assertionFailure()
            throw NSError()
        }
        if response.statusCode == 200 {
            return Mastodon.Response.Content(
                value: true,
                response: response
            )
        } else {
            let httpResponseStatus = HTTPResponseStatus(statusCode: response.statusCode)
            throw Mastodon.API.Error(
                httpResponseStatus: httpResponseStatus,
                mastodonError: nil
            )
        }
    }

    public class FileReportQuery: JSONEncodeQuery {
        
        public let accountID: Mastodon.Entity.Account.ID
        public var statusIDs: [Mastodon.Entity.Status.ID]?
        public var comment: String?
        public let forward: Bool?
        
        enum CodingKeys: String, CodingKey {
            case accountID = "account_id"
            case statusIDs = "status_ids"
            case comment
            case forward
        }
        
        public init(
            accountID: Mastodon.Entity.Account.ID,
            statusIDs: [Mastodon.Entity.Status.ID]?,
            comment: String?,
            forward: Bool?) {
            self.accountID = accountID
            self.statusIDs = statusIDs
            self.comment = comment
            self.forward = forward
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
}
