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

//extension PollItem {
//    public class OptionInfo: Hashable {
//        public let pollID: Mastodon.Entity.Poll.ID
//        public let index: Int
//        
//        public let isMultiple: Bool
//        public let isReveal: Bool
//        public let isExpire: Bool
//        public let isSelect: Bool
//        public let percentage: Double
//        
//        public init(
//            pollID: Mastodon.Entity.Poll.ID,
//            index: Int,
//            isMultiple: Bool,
//            isReveal: Bool,
//            isExpire: Bool,
//            isSelect: Bool,
//            percentage: Double
//        ) {
//            self.pollID = pollID
//            self.index = index
//            self.isMultiple = isMultiple
//            self.isReveal = isReveal
//            self.isExpire = isExpire
//            self.isSelect = isSelect
//            self.percentage = percentage
//        }
//
//        public func hash(into hasher: inout Hasher) {
//            hasher.combine(pollID)
//            hasher.combine(index)
//        }
//        
//        public static func == (lhs: PollItem.OptionInfo, rhs: PollItem.OptionInfo) -> Bool {
//            return lhs.pollID == rhs.pollID
//                && lhs.index == rhs.index
//                && lhs.isMultiple == rhs.isMultiple
//                && lhs.isReveal == rhs.isReveal
//                && lhs.isExpire == rhs.isExpire
//                && lhs.isSelect == rhs.isSelect
//                && lhs.percentage == rhs.percentage
//        }
//    }
//}
