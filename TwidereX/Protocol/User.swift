//
//  User.swift
//  TwidereX
//
//  Created by MainasuK Cirno on 2021-7-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack

protocol User {
    var name: String { get }
    var username: String { get }
    var avatarImageURL: URL? { get }
}

extension TwitterUser: User {
    var avatarImageURL: URL? {
        return avatarImageURL()
    }
}
