//
//  PollItem.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import MastodonSDK
import CoreDataStack

public enum PollItem: Hashable {
    case option(record: ManagedObjectRecord<MastodonPollOption>)
}
