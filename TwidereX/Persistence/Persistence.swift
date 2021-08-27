//
//  Persistence.swift
//  Persistence
//
//  Created by Cirno MainasuK on 2021-8-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

enum Persistence { }

extension Persistence {
    enum TwitterUser { }
    enum TwitterStatus { }
}

extension Persistence {
    enum MastodonUser { }
    enum MastodonStatus { }
}

extension Persistence {
    class PersistCache<T> {
        var dictionary: [String : T] = [:]
    }
}
