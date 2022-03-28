//
//  Mastodon+API+List.swift
//  
//
//  Created by MainasuK on 2022-3-8.
//

import Foundation

extension Mastodon.API.List {
    
    static func listsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("lists")
    }
    
    /// Fetch all lists that the user owns.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.2
    /// # Last Update
    ///   2022/3/8
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/timelines/lists/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token
    /// - Returns: `[Mastodon.Entity.List]` nested in the response
    public static func ownedLists(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.List]> {
        let request = Mastodon.API.request(
            url: listsEndpointURL(domain: domain),
            method: .GET,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.List].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
}

extension Mastodon.API.List {
    
    /// Create a new list.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.6
    /// # Last Update
    ///   2022/3/15
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/timelines/lists/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token
    /// - Returns: `Mastodon.Entity.List` nested in the response
    public static func create(
        session: URLSession,
        domain: String,
        query: CreateQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.List> {
        let request = Mastodon.API.request(
            url: listsEndpointURL(domain: domain),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.List.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct CreateQuery: JSONEncodeQuery {
        public let title: String
        public let repliesPolicy: Mastodon.Entity.ReplyPolicy?
        
        enum CodingKeys: String, CodingKey {
            case title
            case repliesPolicy = "replies_policy"
        }
        
        public init(
            title: String,
            repliesPolicy: Mastodon.Entity.ReplyPolicy?
        ) {
            self.title = title
            self.repliesPolicy = repliesPolicy
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
    
}

extension Mastodon.API.List {
    
    private static func listEndpointURL(
        domain: String,
        listID: Mastodon.Entity.List.ID
    ) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("lists")
            .appendingPathComponent(listID)
    }
    
    /// Fetch all lists that the user owns.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.6
    /// # Last Update
    ///   2022/3/25
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/timelines/lists/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - listID: the ID for list
    ///   - query: UpdateQuery
    ///   - authorization: User token
    /// - Returns: `Mastodon.Entity.List` nested in the response
    public static func update(
        session: URLSession,
        domain: String,
        listID: Mastodon.Entity.List.ID,
        query: UpdateQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.List> {
        let request = Mastodon.API.request(
            url: listEndpointURL(domain: domain, listID: listID),
            method: .PUT,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.List.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct UpdateQuery: JSONEncodeQuery {
        public let title: String?
        public let repliesPolicy: Mastodon.Entity.ReplyPolicy?
        
        enum CodingKeys: String, CodingKey {
            case title
            case repliesPolicy = "replies_policy"
        }
        
        public init(
            title: String?,
            repliesPolicy: Mastodon.Entity.ReplyPolicy?
        ) {
            self.title = title
            self.repliesPolicy = repliesPolicy
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
    
}

extension Mastodon.API.List {
    
    private static func deleteListEndpointURL(
        domain: String,
        listID: Mastodon.Entity.List.ID
    ) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("lists")
            .appendingPathComponent(listID)
    }
    
    /// Delete a list.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.6
    /// # Last Update
    ///   2022/3/21
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/timelines/lists/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - listID: the ID for list
    ///   - authorization: User token
    /// - Returns: `Mastodon.Entity.List` nested in the response
    public static func delete(
        session: URLSession,
        domain: String,
        listID: Mastodon.Entity.List.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Void> {
        let request = Mastodon.API.request(
            url: deleteListEndpointURL(domain: domain, listID: listID),
            method: .DELETE,
            query: nil,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        if let error = try? Mastodon.API.decode(type: Mastodon.Entity.Error.self, from: data, response: response) {
            throw Mastodon.API.Error(httpResponseStatus: .ok, error: error)
        }
        return Mastodon.Response.Content(value: Void(), response: response)
    }
    
    public struct DeleteContent: Codable {
        public let error: String?
    }
    
}

extension Mastodon.API.List {
    
    private static func accountsEndpointURL(
        domain: String,
        listID: Mastodon.Entity.List.ID
    ) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("lists")
            .appendingPathComponent(listID)
            .appendingPathComponent("accounts")
    }
    
    /// View accounts in list.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.6
    /// # Last Update
    ///   2022/3/21
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/timelines/lists/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - listID: the ID for list
    ///   - authorization: User token
    /// - Returns: `Mastodon.Entity.Account` nested in the response
    public static func accounts(
        session: URLSession,
        domain: String,
        listID: Mastodon.Entity.List.ID,
        query: AccountsQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let request = Mastodon.API.request(
            url: accountsEndpointURL(domain: domain, listID: listID),
            method: .GET,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Account].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public struct AccountsQuery: Query {
        public let maxID: Mastodon.Entity.Status.ID?
        public let sinceID: Mastodon.Entity.Status.ID?
        public let limit: Int?
        
        public init(
            maxID: Mastodon.Entity.Status.ID? = nil,
            sinceID: Mastodon.Entity.Status.ID? = nil,
            limit: Int? = nil
        ) {
            self.maxID = maxID
            self.sinceID = sinceID
            self.limit = limit
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            guard !items.isEmpty else { return nil }
            return items
        }
        
        var body: Data? {
            return nil
        }
    }
    
    /// Add accounts to list.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.6
    /// # Last Update
    ///   2022/3/23
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/timelines/lists/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - listID: the ID for list
    ///   - query: AddAccountsQuery
    ///   - authorization: User token
    /// - Returns: `Mastodon.Entity.Account` nested in the response
    public static func addAccounts(
        session: URLSession,
        domain: String,
        listID: Mastodon.Entity.List.ID,
        query: AddAccountsQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Void> {
        let request = Mastodon.API.request(
            url: accountsEndpointURL(domain: domain, listID: listID),
            method: .POST,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        if let error = try? Mastodon.API.decode(type: Mastodon.Entity.Error.self, from: data, response: response) {
            // 422: Account is already in list
            if let response = response as? HTTPURLResponse, response.statusCode == 422 {
                return Mastodon.Response.Content(value: Void(), response: response)
            }
            throw Mastodon.API.Error(httpResponseStatus: .ok, error: error)
        }
        return Mastodon.Response.Content(value: Void(), response: response)
    }
    
    public struct AddAccountsQuery: JSONEncodeQuery {
        
        public let accountIDs: [Mastodon.Entity.Account.ID]
        
        public init(
            accountIDs: [Mastodon.Entity.Account.ID]
        ) {
            self.accountIDs = accountIDs
        }
        
        enum CodingKeys: String, CodingKey {
            case accountIDs = "account_ids"
        }
        
        var queryItems: [URLQueryItem]? { nil }
        
    }
    
    /// Remove accounts from list.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.6
    /// # Last Update
    ///   2022/3/23
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/timelines/lists/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - listID: the ID for list
    ///   - query: DeleteAccountsQuery
    ///   - authorization: User token
    /// - Returns: `Mastodon.Entity.Account` nested in the response
    public static func deleteAccounts(
        session: URLSession,
        domain: String,
        listID: Mastodon.Entity.List.ID,
        query: DeleteAccountsQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Void> {
        let request = Mastodon.API.request(
            url: accountsEndpointURL(domain: domain, listID: listID),
            method: .DELETE,
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request, delegate: nil)
        if let error = try? Mastodon.API.decode(type: Mastodon.Entity.Error.self, from: data, response: response) {
            throw Mastodon.API.Error(httpResponseStatus: .ok, error: error)
        }
        return Mastodon.Response.Content(value: Void(), response: response)
    }
    
    public typealias DeleteAccountsQuery = AddAccountsQuery
    
}
