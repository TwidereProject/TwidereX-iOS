//
//  MastodonNotificationType.swift
//  CoreDataStack
//
//  Created by MainasuK on 2021/11/11.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

public enum MastodonNotificationType: RawRepresentable {
    case follow
    case followRequest
    case mention
    case reblog
    case favourite      // same to API
    case poll
    case status
    
    case _other(String)
    
    public init?(rawValue: String) {
        switch rawValue {
        case "follow":              self = .follow
        case "followRequest":       self = .followRequest
        case "mention":             self = .mention
        case "reblog":              self = .reblog
        case "favourite":           self = .favourite
        case "poll":                self = .poll
        case "status":              self = .status
        default:                    self = ._other(rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .follow:               return "follow"
        case .followRequest:        return "followRequest"
        case .mention:              return "mention"
        case .reblog:               return "reblog"
        case .favourite:            return "favourite"
        case .poll:                 return "poll"
        case .status:               return "status"
        case ._other(let value):    return value
        }
    }
}
