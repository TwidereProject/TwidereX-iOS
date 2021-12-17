//
//  TwitterLocation.swift
//  TwitterLocation
//
//  Created by Cirno MainasuK on 2021-9-2.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

final public class TwitterLocation: NSObject, Codable {
    public typealias ID = String
    
    public let id: ID
    public let fullName: String

    public let name: String?
    public let country: String?
    public let countryCode: String?
    
    public init(
        id: TwitterLocation.ID,
        fullName: String,
        name: String?,
        country: String?,
        countryCode: String?
    ) {
        self.id = id
        self.fullName = fullName
        self.name = name
        self.country = country
        self.countryCode = countryCode
    }
}
