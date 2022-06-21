//
//  PollComposeItem.swift
//  
//
//  Created by MainasuK on 2021-11-29.
//

import UIKit
import Combine
import TwidereLocalization

public enum PollComposeItem: Hashable {
    case option(Option)
    case expireConfiguration(ExpireConfiguration)
    case multipleConfiguration(MultipleConfiguration)
}

extension PollComposeItem {
    public final class Option: NSObject, Identifiable, ObservableObject {
        public let id = UUID()

        public weak var textField: UITextField?
        
        @Published public var text = ""
        @Published public var shouldBecomeFirstResponder = false
        
        public override init() {
            super.init()
        }
    }
}

extension PollComposeItem {
    public final class ExpireConfiguration: Identifiable, Hashable, ObservableObject {
        public let id = UUID()
        
        @Published public var countdown = DateComponents(day: 1)    // Twitter
        @Published public var option: Option = .oneDay              // Mastodon
    
        public init() {
            // end init
        }
        
        public static func == (lhs: ExpireConfiguration, rhs: ExpireConfiguration) -> Bool {
            return lhs.id == rhs.id
                && (lhs.option == rhs.option && lhs.countdown == rhs.countdown)
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        public enum Option: String, Hashable, CaseIterable {
            case thirtyMinutes
            case oneHour
            case sixHours
            case oneDay
            case threeDays
            case sevenDays

            public var title: String {
                switch self {
                case .thirtyMinutes: return L10n.Scene.Compose.Vote.Expiration._30Min
                case .oneHour: return L10n.Scene.Compose.Vote.Expiration._1Hour
                case .sixHours: return L10n.Scene.Compose.Vote.Expiration._6Hour
                case .oneDay: return L10n.Scene.Compose.Vote.Expiration._1Day
                case .threeDays: return L10n.Scene.Compose.Vote.Expiration._3Day
                case .sevenDays: return L10n.Scene.Compose.Vote.Expiration._7Day
                }
            }

            public var seconds: Int {
                switch self {
                case .thirtyMinutes: return 60 * 30
                case .oneHour: return 60 * 60 * 1
                case .sixHours: return 60 * 60 * 6
                case .oneDay: return 60 * 60 * 24
                case .threeDays: return 60 * 60 * 24 * 3
                case .sevenDays: return 60 * 60 * 24 * 7
                }
            }
        }
    }
}

extension PollComposeItem {
    public final class MultipleConfiguration: Hashable, ObservableObject {
        private let id = UUID()
        
        @Published public var isMultiple = false
        
        public init() {
            // end init
        }
        
        public static func == (lhs: MultipleConfiguration, rhs: MultipleConfiguration) -> Bool {
            return lhs.id == rhs.id
                && lhs.isMultiple == rhs.isMultiple
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
