//
//  MentionPickItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-14.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData

enum MentionPickItem: Equatable, Hashable {
    case twitterUser(username: String, attribute: Attribute)
}

extension MentionPickItem {
    class Attribute: Hashable {
        
        let id = UUID()

        var state: State = .loading
        
        var disabled: Bool = false
        var selected: Bool = true
        
        var avatarImageURL: URL?
        var userID: String?
        var name: String?
            
        init(
            disabled: Bool = false,
            selected: Bool = true,
            avatarImageURL: URL? = nil,
            userID: String? = nil,
            name: String? = nil
        ) {
            self.disabled = disabled
            self.selected = selected
            self.avatarImageURL = avatarImageURL
            self.userID = userID
            self.name = name
            
            state = (avatarImageURL == nil || userID == nil || name == nil) ? .loading : .finish
        }
        
        static func == (lhs: MentionPickItem.Attribute, rhs: MentionPickItem.Attribute) -> Bool {
            return lhs.state == rhs.state &&
                lhs.disabled == rhs.disabled &&
                lhs.selected == rhs.selected &&
                lhs.avatarImageURL == rhs.avatarImageURL &&
                lhs.userID == rhs.userID
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

    }
}

extension MentionPickItem.Attribute {
    enum State {
        case loading
        case finish
    }
}
