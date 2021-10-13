//
//  StatusRecord.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack

enum StatusRecord: Hashable {
    case twitter(record: ManagedObjectRecord<TwitterStatus>)
    case mastodon(record: ManagedObjectRecord<MastodonStatus>)
}
