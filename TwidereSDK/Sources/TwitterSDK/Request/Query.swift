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
}
