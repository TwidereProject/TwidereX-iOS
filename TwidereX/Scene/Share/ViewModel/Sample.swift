//
//  Sample.swift
//  TwidereX
//
//  Created by MainasuK Cirno on 2021-7-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import Meta

enum Sample { }

struct SampleUser: User {
    let name: String
    let username: String
    let avatarImageURL: URL?
}

extension Sample {
    static var user: User {
        SampleUser(
            name: "Alice",
            username: "alice",
            avatarImageURL: URL(string: "https://pbs.twimg.com/profile_images/551206220707532800/7XOm99Ps_400x400.jpeg")
        )
    }
}

struct SampleStatus: Status {

    var account: User
    var repost: Status?
    var content: String
    var createdAt: Date

    var metaContent: MetaContent {
        PlaintextMetaContent(string: content)
    }
}

extension Sample {
    static var status: Status {
        SampleStatus(
            account: Sample.user,
            repost: Sample.repost,
            content: "RT \(Sample.repost.content)",
            createdAt: Date()
        )
    }

    static var repost: Status {
        SampleStatus(
            account: Sample.user,
            repost: nil,
            content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            createdAt: Date()
        )
    }
}

final class PlaintextMetaContent: MetaContent {
    var string: String
    let entities: [Meta.Entity] = []

    init(string: String) {
        self.string = string
    }

    func metaAttachment(for entity: Meta.Entity) -> MetaAttachment? {
        return nil
    }
}
