//
//  MastodonVisibility.swift
//  
//
//  Created by MainasuK on 2021-12-6.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension MastodonVisibility {
    public var asStatusVisibility: StatusVisibility {
        let visibility: Mastodon.Entity.Status.Visibility = .init(rawValue: rawValue) ?? ._other(rawValue)
        return .mastodon(visibility)
    }
}
