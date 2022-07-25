//
//  MastodonNotificationSubscriptionMentionPreference.swift
//  
//
//  Created by MainasuK on 2022-7-14.
//

import Foundation

extension MastodonNotificationSubscription {
    public final class MentionPreference: NSObject, Codable {
        
        public let preference: Preference
        
        public init(preference: Preference = .everyone) {
            self.preference = preference
        }
        
        public enum Preference: String, Codable, CaseIterable, Identifiable, Hashable {
            case everyone
            case follows
            
            public var id: Self { self }
        }
        
    }
}
