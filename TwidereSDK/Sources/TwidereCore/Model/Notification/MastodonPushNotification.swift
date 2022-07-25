//
//  MastodonPushNotification.swift
//  
//
//  Created by MainasuK on 2022-7-7.
//

import Foundation

public struct MastodonPushNotification: Codable {
    
    public let accessToken: String

    public let notificationID: Int              //<<< the server use `Int` type here!
    public let notificationType: String
    
    public let preferredLocale: String?
    public let icon: String?
    public let title: String
    public let body: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case notificationID = "notification_id"
        case notificationType = "notification_type"
        case preferredLocale = "preferred_locale"
        case icon
        case title
        case body
    }
    
    public init(
        accessToken: String,
        notificationID: Int,
        notificationType: String,
        preferredLocale: String?,
        icon: String?,
        title: String,
        body: String
    ) {
        self.accessToken = accessToken
        self.notificationID = notificationID
        self.notificationType = notificationType
        self.preferredLocale = preferredLocale
        self.icon = icon
        self.title = title
        self.body = body
    }
    
}
