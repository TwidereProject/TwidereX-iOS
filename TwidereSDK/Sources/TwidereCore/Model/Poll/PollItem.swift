//
//  PollItem.swift
//  
//
//  Created by MainasuK on 2021-11-29.
//

import Foundation
import Combine
import TwidereLocalization

public enum PollItem: Hashable {
    case option(Option)
    case expireConfiguration(ExpireConfiguration)
    case multipleConfiguration(MultipleConfiguration)
}

public protocol PollItemOptionDelegate: AnyObject {
    func option(_ option: PollItem.Option, optionDidChanges option: String)
}

extension PollItem {
    public final class Option: Hashable {
        private let id = UUID()
        
        var disposeBag = Set<AnyCancellable>()
        public weak var delegate: PollItemOptionDelegate?
        
        @Published public var option = ""
        
        public init() {
            $option
                .sink { [weak self] option in
                    guard let self = self else { return }
                    self.delegate?.option(self, optionDidChanges: option)
                }
                .store(in: &disposeBag)
        }
        
        public static func == (lhs: Option, rhs: Option) -> Bool {
            return lhs.id == rhs.id
                && lhs.option == rhs.option
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

public protocol PollItemExpireConfigurationDelegate: AnyObject {
    func expireConfiguration(_ configuration: PollItem.ExpireConfiguration,  expiresOptionDidChanges expiresOption: PollItem.ExpireConfiguration.Option)
}

extension PollItem {
    public final class ExpireConfiguration: Hashable, ObservableObject {
        private let id = UUID()
        
        var disposeBag = Set<AnyCancellable>()
        public weak var delegate: PollItemExpireConfigurationDelegate?

        @Published public var option: Option = .oneDay
        
        public init() {
            $option
                .sink { [weak self] expiresOption in
                    guard let self = self else { return }
                    self.delegate?.expireConfiguration(self, expiresOptionDidChanges: expiresOption)
                }
                .store(in: &disposeBag)
        }

        public static func == (lhs: ExpireConfiguration, rhs: ExpireConfiguration) -> Bool {
            return lhs.id == rhs.id
                && lhs.option == rhs.option
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

public protocol PollItemMultipleConfigurationDelegate: AnyObject {
    func multipleConfiguration(_ configuration: PollItem.MultipleConfiguration, isMultipleDidChanges isMultiple: Bool)
}

extension PollItem {
    public final class MultipleConfiguration: Hashable, ObservableObject {
        private let id = UUID()
        
        var disposeBag = Set<AnyCancellable>()
        public weak var delegate: PollItemMultipleConfigurationDelegate?
        
        @Published public var isMultiple = false
        
        public init() {
            $isMultiple
                .sink { [weak self] isMultiple in
                    guard let self = self else { return }
                    self.delegate?.multipleConfiguration(self, isMultipleDidChanges: isMultiple)
                }
                .store(in: &disposeBag)
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
