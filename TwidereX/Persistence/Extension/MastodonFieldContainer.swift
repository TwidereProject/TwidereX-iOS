//
//  MastodonFieldContainer.swift
//  MastodonFieldContainer
//
//  Created by Cirno MainasuK on 2021-8-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import MastodonSDK

protocol MastodonFieldContainer {
    var fieldsData: Data? { get }
}

extension MastodonFieldContainer {
    
    static func encode(fields: [Mastodon.Entity.Field]) -> Data? {
        return try? JSONEncoder().encode(fields)
    }
    
    var fields: [Mastodon.Entity.Field]? {
        guard let data = fieldsData else { return nil }
        return try? JSONDecoder().decode([Mastodon.Entity.Field].self, from: data)
    }
    
}
