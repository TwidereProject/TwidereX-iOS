//
//  Twitter+Request+PlaceFields.swift
//  TwitterAPI
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import Foundation

extension Twitter.Request {
    public enum PlaceFields: String, CaseIterable {
        case containedWithin = "contained_within"
        case country = "country"
        case countryCode = "country_code"
        case fullName = "full_name"
        case geo = "geo"
        case id = "id"
        case name = "name"
        case placeType = "place_type"
        
        public static var allCasesQueryItem: URLQueryItem {
            let value = TwitterFields.allCases.map { $0.rawValue }.joined(separator: ",")
            return URLQueryItem(name: "place.fields", value: value)
        }
    }
}
