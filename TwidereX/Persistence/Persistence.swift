//
//  Persistence.swift
//  Persistence
//
//  Created by Cirno MainasuK on 2021-8-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

enum Persistence {
    enum MastodonUser { }
}

extension Persistence {
    class PersistCache<T> {
        var dictionary: [String : T] = [:]
    }
}
