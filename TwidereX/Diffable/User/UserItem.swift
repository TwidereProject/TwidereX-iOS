//
//  UserItem.swift
//  UserItem
//
//  Created by Cirno MainasuK on 2021-8-25.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import TwidereCore

enum UserItem: Hashable {
    case authenticationIndex(record: ManagedObjectRecord<AuthenticationIndex>)
    case user(record: UserRecord, style: UserView.Style)
    case bottomLoader
}
