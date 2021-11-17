//
//  MastodonUser.swift
//  MastodonUser
//
//  Created by Cirno MainasuK on 2021-8-26.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import MastodonMeta

extension MastodonUser {
    var name: String {
        if displayName.isEmpty {
            return username
        } else {
            return displayName
        }
    }
    
    var acctWithDomain: String {
        if !acct.contains("@") {
            // Safe concat due to username cannot contains "@"
            return username + "@" + domain
        } else {
            return acct
        }
    }
}

extension MastodonUser {
    var nameMetaContent: MastodonMetaContent? {
        do {
            let content = MastodonContent(content: name, emojis: emojis.asDictionary)
            let metaContent = try MastodonMetaContent.convert(document: content)
            return metaContent
        } catch {
            assertionFailure()
            return nil
        }
    }
    
    var bioMetaContent: MastodonMetaContent? {
        guard let note = note else { return nil }
        do {
            let content = MastodonContent(content: note, emojis: emojis.asDictionary)
            let metaContent = try MastodonMetaContent.convert(document: content)
            return metaContent
        } catch {
            assertionFailure()
            return nil
        }
    }
}
