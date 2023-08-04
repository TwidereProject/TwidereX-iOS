//
//  HashtagData.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import MastodonSDK

// Note:
// Maybe configure an in-memory CoreData persist coordinator better here
// But a simple solution should also works

public enum HashtagData: Hashable {
    // case twitter(record: ManagedObjectRecord<TwitterStatus>)
    case mastodon(data: Mastodon.Entity.Tag)
}
