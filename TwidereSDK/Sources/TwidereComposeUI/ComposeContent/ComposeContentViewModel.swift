//
//  ComposeContentViewModel.swift
//  
//
//  Created by MainasuK on 2021/11/17.
//

import os.log
import UIKit
import SwiftUI
import Combine
import CoreLocation
import CoreDataStack
import TwitterSDK
import TwidereCore
import TwitterMeta
import MetaTextKit
import MastodonMeta

public final class ComposeContentViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    public let composeReplyTableViewCell = ComposeReplyTableViewCell()
    public let composeInputTableViewCell = ComposeInputTableViewCell()
    public let composeAttachmentTableViewCell = ComposeAttachmentTableViewCell()
    
    let locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        return locationManager
    }()
    
    // Input
    public let configurationContext: ConfigurationContext
    
    // text
    @Published public private(set) var initialTextInput = ""
    
    // avatar
    @Published public var author: UserObject?
    
    // reply-to
    public private(set) var replyTo: StatusObject?
    
    // mention (Twitter only)
    @Published public private(set) var isMentionPickDisplay = false
    @Published public private(set) var mentionPickButtonTitle = ""
    public private(set) var primaryMentionPickItem: MentionPickViewModel.Item?
    public private(set) var secondaryMentionPickItems: [MentionPickViewModel.Item] = []
    @Published public internal(set) var excludeReplyTwitterUserIDs: Set<TwitterUser.ID> = Set()
    
    // attachment
    @Published public internal(set) var attachmentViewModels: [AttachmentViewModel] = []
    @Published public var maxMediaAttachmentLimit = 4
    
    // Output
    public var diffableDataSource: UITableViewDiffableDataSource<Section, Item>?
    @Published public private(set) var items: Set<Item> = [.input]
    
    // text
    @Published public var currentTextInput = ""
    @Published public var maxTextInputLimit = 500
    @Published public var textInputLimitProgress: CGFloat = 0.0
    @Published public var isTextInputEmpty = true
    @Published public var isTextInputValid = true
    
    // emoji
    @Published public private(set) var emojiViewModel: MastodonEmojiService.EmojiViewModel? = nil
    
    // location
    public private(set) var didRequestLocationAuthorization = false
    @Published public var isRequestLocation = false
    @Published public private(set) var currentLocation: CLLocation?
    @Published public internal(set) var currentPlace: Twitter.Entity.Place?
    
    // toolbar
    @Published public private(set) var availableActions: Set<ComposeToolbarView.Action> = Set()
    @Published public private(set) var isMediaToolBarButtonEnabled = true
    @Published public private(set) var isLocationToolBarButtonEnabled = CLLocationManager.locationServicesEnabled()
    
    // UI state
    @Published public private(set) var isComposeBarButtonEnabled = true
    @Published public private(set) var canDismissDirectly = true
    @Published public var additionalSafeAreaInsets: UIEdgeInsets = .zero
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
    let viewLayoutMarginDidUpdate = CurrentValueSubject<Void, Never>(Void())
    
    public init(
        inputContext: InputContext,
        configurationContext: ConfigurationContext
    ) {
        self.configurationContext = configurationContext
        super.init()
        // end init

        switch inputContext {
        case .post:
            break
        case .hashtag(let hashtag):
            break
        case .mention(let user):
            break
        case .reply(let status):
            replyTo = status
            items.insert(.replyTo)
            
            // set mention
            switch status {
            case .twitter(let status):
                self.primaryMentionPickItem = .twitterUser(
                    username: status.author.username,
                    attribute: MentionPickViewModel.Item.Attribute(
                        disabled: true,
                        selected: true,
                        avatarImageURL: status.author.avatarImageURL(),
                        userID: status.author.id,
                        name: status.author.name,
                        state: .finish
                    )
                )
                self.secondaryMentionPickItems = {
                    var items: [MentionPickViewModel.Item] = []
                    for mention in status.entities?.mentions ?? [] {
                        let username = mention.username
                        let item = MentionPickViewModel.Item.twitterUser(
                            username: username,
                            attribute: .init(
                                disabled: false,
                                selected: true,
                                avatarImageURL: nil,
                                userID: mention.id,
                                name: nil,
                                state: .loading
                            )
                        )
                        items.append(item)
                    }
                    return items
                }()
            case .mastodon:
                break
            }
        }
        
        // bind text
        $currentTextInput
            .map { $0.isEmpty }
            .assign(to: &$isTextInputEmpty)
        
        // bind author
        $author
            .receive(on: DispatchQueue.main)
            .sink { [weak self] author in
                guard let self = self else { return }
                self.composeInputTableViewCell.configure(user: author)
            }
            .store(in: &disposeBag)
        
        // bind mention
        $author
            .map { author in
                switch author {
                case .twitter:
                    guard case .reply = inputContext else { return false }
                    return true
                default:
                    return false
                }
            }
            .assign(to: &$isMentionPickDisplay)
        
        Publishers.CombineLatest(
            $author,
            $excludeReplyTwitterUserIDs
        )
        .map { author, excludeReplyTwitterUserIDs -> String in
            var usernames: [String] = []
            
            switch (self.replyTo, author) {
            case (.twitter(let status), .twitter(let author)):
                usernames.append(status.author.username)
                
                var excludeUsernames: Set<String> = Set()
                let excludeSecondaryMentionPickItemUsernames = self.secondaryMentionPickItems
                    .compactMap { item -> String? in
                        switch item {
                        case .twitterUser(let username, let attribute):
                            guard !attribute.selected else { return nil }   // exclude when not selected
                            return username
                        }
                    }
                for username in excludeSecondaryMentionPickItemUsernames {
                    excludeUsernames.insert(username)
                }
                excludeUsernames.insert(author.username)
                
                for mention in status.entities?.mentions ?? [] {
                    guard !excludeUsernames.contains(mention.username) else { continue }
                    usernames.append(mention.username)
                }
                
            default:
                break
            }
            
            return usernames
                .map { "@" + $0 }
                .joined(separator: ", ")
        }
        .assign(to: &$mentionPickButtonTitle)
        
        $mentionPickButtonTitle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                guard let self = self else { return }
                self.composeInputTableViewCell.mentionPickButton.setTitle(title, for: .normal)
            }
            .store(in: &disposeBag)
        
        $isMentionPickDisplay
            .sink { [weak self] isMentionPickDisplay in
                guard let self = self else { return }
                self.composeInputTableViewCell.mentionPickButton.isHidden = !isMentionPickDisplay
            }
            .store(in: &disposeBag)
        
        // bind attachments
        $attachmentViewModels
            .sink { [weak self] attachmentViewModels in
                guard let self = self else { return }
                // update items
                if attachmentViewModels.isEmpty {
                    self.items.remove(.attachment)
                } else {
                    self.items.insert(.attachment)
                }
                // update data source
                var snapshot = NSDiffableDataSourceSnapshot<ComposeAttachmentTableViewCell.Section, ComposeAttachmentTableViewCell.Item>()
                snapshot.appendSections([.main])
                let items: [ComposeAttachmentTableViewCell.Item] = attachmentViewModels.map {
                    ComposeAttachmentTableViewCell.Item.attachment(viewModel: $0)
                }
                snapshot.appendItems(items, toSection: .main)
                self.composeAttachmentTableViewCell.diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
        
        // location
        $isRequestLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRequestLocation in
                guard let self = self else { return }
                if isRequestLocation {
                    self.requestLocationMarking()
                } else {
                    self.cancelLocationMarking()
                }
            }
            .store(in: &disposeBag)
        
        // bind toolbar
        $author
            .map { author -> Set<ComposeToolbarView.Action> in
                var set = Set<ComposeToolbarView.Action>()
                set.insert(.media)
                set.insert(.mention)
                set.insert(.hashtag)
                set.insert(.media)
                
                switch author {
                case .twitter:
                    set.insert(.location)
                case .mastodon:
                    set.insert(.emoji)
                    set.insert(.poll)
                    set.insert(.contentWarning)
                    set.insert(.mediaSensitive)
                case .none:
                    break
                }
                return set
            }
            .assign(to: &$availableActions)
        
        Publishers.CombineLatest(
            $attachmentViewModels,
            $maxMediaAttachmentLimit
        )
        .map { attachmentViewModels, maxMediaAttachmentLimit in
            return attachmentViewModels.count < maxMediaAttachmentLimit
        }
        .assign(to: &$isMediaToolBarButtonEnabled)

        
        // bind UI state
        Publishers.CombineLatest3(
            $isTextInputEmpty,
            $isTextInputValid,
            $attachmentViewModels
        )
        .map { isTextInputEmpty, isTextInputValid, attachmentViewModels in
            guard isTextInputValid else { return false }
            guard !isTextInputEmpty || !attachmentViewModels.isEmpty else { return false }
            return true
        }
        .assign(to: &$isComposeBarButtonEnabled)
        
        Publishers.CombineLatest(
            $initialTextInput,
            $currentTextInput
        )
        .map { initialTextInput, currentTextInput in
            return initialTextInput.trimmingCharacters(in: .whitespacesAndNewlines) == currentTextInput.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .assign(to: &$canDismissDirectly)
        
        // bind location
        locationManager.delegate = self
        
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        locationManager.stopUpdatingLocation()
    }
    
}

extension ComposeContentViewModel {
    public enum InputContext {
        case post
        case hashtag(hashtag: String)
        case mention(user: UserObject)
        case reply(status: StatusObject)
    }
    
    public struct ConfigurationContext {
        public let apiService: APIService
        public let authenticationService: AuthenticationService
        public let dateTimeProvider: DateTimeProvider
        public let twitterTextProvider: TwitterTextProvider
        
        public init(
            apiService: APIService,
            authenticationService: AuthenticationService,
            dateTimeProvider: DateTimeProvider,
            twitterTextProvider: TwitterTextProvider
        ) {
            self.apiService = apiService
            self.authenticationService = authenticationService
            self.dateTimeProvider = dateTimeProvider
            self.twitterTextProvider = twitterTextProvider
        }
    }
}

extension ComposeContentViewModel {
    func processEditing(textStorage: MetaTextStorage) -> MetaContent? {
        guard let author = self.author else {
            return nil
        }
        
        let textInput = textStorage.string
        self.currentTextInput = textInput

        switch author {
        case .twitter:
            let content = TwitterContent(content: textInput)
            let metaContent = TwitterMetaContent.convert(
                content: content,
                urlMaximumLength: .max,
                twitterTextProvider: configurationContext.twitterTextProvider
            )
            
            // set text limit
            let parseResult = configurationContext.twitterTextProvider.parse(text: textInput)
            textInputLimitProgress = {
                guard parseResult.maxWeightedLength > 0 else { return .zero }
                return CGFloat(parseResult.weightedLength) / CGFloat(parseResult.maxWeightedLength)
            }()
            maxTextInputLimit = parseResult.maxWeightedLength
            isTextInputValid = parseResult.isValid
            
            return metaContent
            
        case .mastodon:
            let content = MastodonContent(
                content: textInput,
                emojis: emojiViewModel?.emojis.asDictionary ?? [:]
            )
            let metaContent = MastodonMetaContent.convert(text: content)
            return metaContent
        }
    }
}

extension ComposeContentViewModel {

    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }

    func requestLocationAuthorizationIfNeeds(presentingViewController: UIViewController) -> Bool {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        switch authorizationStatus {
        case .notDetermined:
            didRequestLocationAuthorization = true
            locationManager.requestWhenInUseAuthorization()
            return false
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        case .restricted, .denied:
            let alertController = UIAlertController(title: "Location Access Disabled", message: "Please enable location access to compose geo marked tweet", preferredStyle: .alert)
            let openSettingsAction = UIAlertAction(title: "Open Settings", style: .default) { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(openSettingsAction)
            alertController.addAction(cancelAction)
            presentingViewController.present(alertController, animated: true, completion: nil)
            return false
        @unknown default:
            return false
        }
    }

    func requestLocationMarking() {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        switch authorizationStatus {
        case .notDetermined:
            break
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            break
        @unknown default:
            break
        }
    }

    func cancelLocationMarking() {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        locationManager.stopUpdatingLocation()
    }
    
}

// MARK: - CLLocationManagerDelegate
extension ComposeContentViewModel: CLLocationManagerDelegate {
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        os_log("%{public}s[%{public}ld], %{public}s: status", ((#file as NSString).lastPathComponent), #line, #function, String(describing: manager.authorizationStatus))
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if didRequestLocationAuthorization {
                isRequestLocation = true
            }
        default:
            break
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        currentLocation = location
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // do nothing
    }
    
}

extension ComposeContentViewModel {
    public func statusPublisher() throws -> StatusPublisher {
        guard let author = self.author else {
            throw AppError.implicit(.authenticationMissing)
        }
        
        switch author {
        case .twitter(let author):
            return TwitterStatusPublisher(
                apiService: configurationContext.apiService,
                author: author,
                replyTo: {
                    guard case let .twitter(status) = replyTo else { return nil }
                    return .init(objectID: status.objectID)
                }(),
                excludeReplyUserIDs: Array(excludeReplyTwitterUserIDs),
                content: currentTextInput,
                attachmentViewModels: attachmentViewModels,
                place: currentPlace
            )
        case .mastodon(let author):
            // TODO:
            throw AppError.implicit(.authenticationMissing)
        }   // end switch
    }   // end func publisher()
}
//extension ComposeContentViewModel {
//    public struct State: OptionSet {
//
//        public let rawValue: Int
//
//        public init(rawValue: Int) {
//            self.rawValue = rawValue
//        }
//
//        // FIXME: use stencil template generate
//        public static let media = ComposeToolbarView.Action.media.option
//        public static let emoji = ComposeToolbarView.Action.emoji.option
//        public static let poll = ComposeToolbarView.Action.poll.option
//        public static let mention = ComposeToolbarView.Action.mention.option
//        public static let hashtag = ComposeToolbarView.Action.hashtag.option
//        public static let location = ComposeToolbarView.Action.location.option
//    }
//}
//
//extension ComposeToolbarView.Action {
//    public var option: ComposeContentViewModel.State {
//        return ComposeContentViewModel.State(rawValue: 1 << rawValue)
//    }
//}
