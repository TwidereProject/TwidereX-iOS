//
//  ListFetchViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-2.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import CoreDataStack
import TwitterSDK
import MastodonSDK

public enum ListFetchViewModel {
    public enum Result {
        case twitter([Twitter.Entity.V2.List])
        case mastodon([Mastodon.Entity.List])
    }
}

extension ListFetchViewModel {
    public enum List { }
}
