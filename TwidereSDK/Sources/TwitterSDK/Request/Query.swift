//
//  Query.swift
//  Query
//
//  Created by Cirno MainasuK on 2021-8-19.
//

import Foundation

protocol Query {
    var queryItems: [URLQueryItem]? { get }
    var encodedQueryItems: [URLQueryItem]? { get }
    var formQueryItems: [URLQueryItem]? { get }
    var contentType: String? { get }
    var body: Data? { get }
}

protocol JSONEncodeQuery: Query, Encodable { }

extension Query where Self: JSONEncodeQuery {
    var contentType: String? {
        return "application/json; charset=utf-8"
    }
    
    var body: Data? {
        return try? JSONEncoder().encode(self)
    }
}
