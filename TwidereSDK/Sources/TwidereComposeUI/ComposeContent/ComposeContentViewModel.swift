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
import MastodonSDK
import TwidereCore
import TwidereAsset
import MetaTextKit
import TwitterMeta
import MastodonMeta

// FIXME: make binding logic more generic
public final class ComposeContentViewModel: NSObject {
    
    let logger = Logger(subsystem: "ComposeContentViewModel", category: "ViewModel")
    var disposeBag = Set<AnyCancellable>()
    
    public let composeReplyTableViewCell = ComposeReplyTableViewCell()
    public let composeInputTableViewCell = ComposeInputTableViewCell()
    public let composeAttachmentTableViewCell = ComposeAttachmentTableViewCell()
    public let composePollTableViewCell = ComposePollTableViewCell()
    
    let locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        return locationManager
    }()
    
    // Input
    public let configurationContext: ConfigurationContext
    public let customEmojiPickerInputViewModel = CustomEmojiPickerInputView.ViewModel()
        
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
    
    // visibility (Mastodon)
    @Published public internal(set) var mastodonVisibility: Mastodon.Entity.Status.Visibility = .public
    @Published public private(set) var visibility: StatusVisibility? = nil
    
    // attachment
    @Published public internal(set) var attachmentViewModels: [AttachmentViewModel] = []
    @Published public var maxMediaAttachmentLimit = 4
    @Published public internal(set) var isMediaSensitive = false        // Mastodon only
    
    // Output
    public var diffableDataSource: UITableViewDiffableDataSource<Section, Item>?
    public var customEmojiDiffableDataSource: UICollectionViewDiffableDataSource<CustomEmojiPickerInputView.ViewModel.Section, CustomEmojiPickerInputView.ViewModel.Item>?
    @Published public private(set) var items: Set<Item> = [.input]
    
    // text
    @Published public var currentTextInput = ""
    @Published public var currentTextInputWeightedLength = 0
    @Published public var isContentWarningComposing = false {           // Mastodon only
        didSet {
            if isContentWarningComposing {
                isMediaSensitive = true
            }
        }
    }
    @Published public var currentContentWarningInput = ""               // Mastodon only
    @Published public var currentContentWarningInputWeightedLength = 0  // Mastodon only, set 0 when not composing
    @Published public var maxTextInputLimit = 500
    @Published public var textInputLimitProgress: CGFloat = 0.0
    @Published public var isTextInputEmpty = true
    @Published public var isTextInputValid = true
    
    // emoji (Mastodon only)
    @Published public internal(set) var isCustomEmojiComposing = false
    @Published public private(set) var emojiToolBarButtonImage = Asset.Human.faceSmiling.image
    @Published public private(set) var emojiViewModel: MastodonEmojiService.EmojiViewModel? = nil
    var emojiViewModelSubscription: AnyCancellable?
    
    // poll
    @Published public var isPollComposing = false
    @Published public var pollOptions: [PollComposeItem.Option] = {
        // initial with 2 options
        var options: [PollComposeItem.Option] = []
        options.append(PollComposeItem.Option())
        options.append(PollComposeItem.Option())
        return options
    }()
    public let pollExpireConfiguration = PollComposeItem.ExpireConfiguration()
    public let pollMultipleConfiguration = PollComposeItem.MultipleConfiguration()
    @Published public var maxPollOptionLimit = 4
    public let pollCollectionViewDiffableDataSourceDidUpdate = PassthroughSubject<Void, Never>()
    
    // location (Twitter only)
    public private(set) var didRequestLocationAuthorization = false
    @Published public var isRequestLocation = false
    @Published public private(set) var currentLocation: CLLocation?
    @Published public internal(set) var currentPlace: Twitter.Entity.Place?
    
    // toolbar
    @Published public private(set) var availableActions: Set<ComposeToolbarView.Action> = Set()
    @Published public private(set) var isMediaToolBarButtonEnabled = true
    @Published public private(set) var isPollToolBarButtonEnabled = true
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
            // set content text
            switch user {
            case .twitter(let user):
                currentTextInput = "@" + user.username + " "
            case .mastodon(let user):
                currentTextInput = "@" + user.acct + " "
            }
        case .reply(let status):
            replyTo = status
            items.insert(.replyTo)
            
            switch status {
            case .twitter(let status):
                // set mention
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
            case .mastodon(let status):
                // set content warning
                if let spoilerText = status.spoilerText, !spoilerText.isEmpty {
                    isContentWarningComposing = true
                    currentContentWarningInput = spoilerText
                }
            }
        }
        
        // bind text
        $currentTextInput
            .map { $0.isEmpty }
            .assign(to: &$isTextInputEmpty)
        
        Publishers.CombineLatest(
            $currentTextInput,
            $author
        )
        .sink { [weak self] currentTextInput, author in
            guard let self = self else { return }
            guard let author = author else { return }
            switch author {
            case .twitter:
                let parseResult = configurationContext.twitterTextProvider.parse(text: currentTextInput)
                self.textInputLimitProgress = {
                    guard parseResult.maxWeightedLength > 0 else { return .zero }
                    return CGFloat(parseResult.weightedLength) / CGFloat(parseResult.maxWeightedLength)
                }()
                self.currentTextInputWeightedLength = parseResult.weightedLength
                self.maxTextInputLimit = parseResult.maxWeightedLength
                self.isTextInputValid = parseResult.isValid
            case .mastodon:
                self.currentTextInputWeightedLength = currentTextInput.count
            }
        }
        .store(in: &disposeBag)
        
        Publishers.CombineLatest3(
            $isContentWarningComposing,
            $currentContentWarningInput,
            $author
        )
        .sink { [weak self] isContentWarningComposing, currentContentWarningInput, author in
            guard let self = self else { return }
            guard let author = author else { return }
            switch author {
            case .twitter:
                self.currentContentWarningInputWeightedLength = 0
            case .mastodon:
                self.currentContentWarningInputWeightedLength = isContentWarningComposing ? currentContentWarningInput.count : 0
            }
        }
        .store(in: &disposeBag)
        
        Publishers.CombineLatest4(
            $currentTextInputWeightedLength,
            $currentContentWarningInputWeightedLength,
            $maxTextInputLimit,
            $author
        )
        .sink { [weak self] currentTextInputWeightedLength, currentContentWarningInputWeightedLength, maxTextInputLimit, author in
            guard let self = self else { return }
            guard let author = author else { return }
            switch author {
            case .twitter:
                break
            case .mastodon:
                let count = currentTextInputWeightedLength + currentContentWarningInputWeightedLength
                self.isTextInputValid = count <= maxTextInputLimit
                self.textInputLimitProgress = {
                    guard maxTextInputLimit > 0 else { return .zero }
                    return CGFloat(count) / CGFloat(maxTextInputLimit)
                }()
            }
        }
        .store(in: &disposeBag)
        
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
        
        // bind visibility
        $author
            .compactMap { $0 }
            .first()
            .sink { [weak self] author in
                guard let self = self else { return }
                
                switch author {
                case .twitter:
                    break
                case .mastodon(let author):
                    self.mastodonVisibility = {
                        var defaultVisibility: Mastodon.Entity.Status.Visibility  = author.locked ? .private : .public
                        if case let .reply(object) = inputContext,
                           case let .mastodon(status) = object {
                            switch status.visibility {
                            case .direct:
                                defaultVisibility = .direct
                            case .unlisted:
                                defaultVisibility = author.locked ? .private : .unlisted
                            case .private:
                                defaultVisibility = .private
                            case .public, ._other:
                                break
                            }
                        }
                        return defaultVisibility
                    }()
                }
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            $author,
            $mastodonVisibility
        )
        .receive(on: DispatchQueue.main)
        .map { [weak self] author, mastodonVisibility -> StatusVisibility? in
            guard let self = self else { return nil }
            
            switch author {
            case .twitter:
                return nil
            case .mastodon(let author):
                return .mastodon(mastodonVisibility)
            case .none:
                return nil
            }
        }
        .assign(to: &$visibility)
    
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
        
        // bind emojis
        $isCustomEmojiComposing
            .assign(to: \.value, on: customEmojiPickerInputViewModel.isCustomEmojiComposing)
            .store(in: &disposeBag)
        
        $isCustomEmojiComposing
            .map { isComposing in
                isComposing ? Asset.Keyboard.keyboard.image : Asset.Human.faceSmiling.image
            }
            .assign(to: &$emojiToolBarButtonImage)
        
        $author
            .map { [weak self] author -> MastodonEmojiService.EmojiViewModel? in
                guard let self = self else { return nil }
                guard case let .mastodon(user) = author else { return nil }
                let domain = user.domain
                guard let emojiViewModel = self.configurationContext.mastodonEmojiService.dequeueEmojiViewModel(for: domain) else { return nil }
                return emojiViewModel
            }
            .assign(to: &$emojiViewModel)
        
        // bind poll
        $isPollComposing
            .sink { [weak self] isPollComposing in
                guard let self = self else { return }
                if isPollComposing {
                    self.items.insert(.poll)
                } else {
                    self.items.remove(.poll)
                }
            }
            .store(in: &disposeBag)
        
        $pollOptions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pollOptions in
                guard let self = self else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<PollComposeSection, PollComposeItem>()
                snapshot.appendSections([.main])
                
                var items: [PollComposeItem] = []
                items.append(contentsOf: pollOptions.map { PollComposeItem.option($0) })
                items.append(PollComposeItem.expireConfiguration(self.pollExpireConfiguration))
                items.append(PollComposeItem.multipleConfiguration(self.pollMultipleConfiguration))
                snapshot.appendItems(items, toSection: .main)
                
                self.composePollTableViewCell.diffableDataSource?.apply(snapshot, animatingDifferences: false) { [weak self] in
                    guard let self = self else { return }
                    self.pollCollectionViewDiffableDataSourceDidUpdate.send()
                }
                
                var height = CGFloat(pollOptions.count) * ComposePollOptionCollectionViewCell.height
                height += ComposePollExpireConfigurationCollectionViewCell.height
                height += ComposePollMultipleConfigurationCollectionViewCell.height
                self.composePollTableViewCell.collectionViewHeightLayoutConstraint.constant = height
                self.composePollTableViewCell.collectionViewHeightDidUpdate.send()
            }
            .store(in: &disposeBag)
        
        // bind location
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
        Publishers.CombineLatest(
            $author,
            $attachmentViewModels
        )
            .map { author, attachmentViewModels -> Set<ComposeToolbarView.Action> in
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
                    if !attachmentViewModels.isEmpty {
                        set.insert(.mediaSensitive)
                    }
                case .none:
                    break
                }
                return set
            }
            .assign(to: &$availableActions)
        
        Publishers.CombineLatest3(
            $attachmentViewModels,
            $maxMediaAttachmentLimit,
            $isPollComposing
        )
        .map { attachmentViewModels, maxMediaAttachmentLimit, isPollComposing in
            return !isPollComposing && attachmentViewModels.count < maxMediaAttachmentLimit
                
        }
        .assign(to: &$isMediaToolBarButtonEnabled)
        
        $attachmentViewModels
            .map { $0.isEmpty }
            .assign(to: &$isPollToolBarButtonEnabled)

        
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
        
        // set delegate
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
        public let mastodonEmojiService: MastodonEmojiService
        public let dateTimeProvider: DateTimeProvider
        public let twitterTextProvider: TwitterTextProvider
        
        public init(
            apiService: APIService,
            authenticationService: AuthenticationService,
            mastodonEmojiService: MastodonEmojiService,
            dateTimeProvider: DateTimeProvider,
            twitterTextProvider: TwitterTextProvider
        ) {
            self.apiService = apiService
            self.authenticationService = authenticationService
            self.mastodonEmojiService = mastodonEmojiService
            self.dateTimeProvider = dateTimeProvider
            self.twitterTextProvider = twitterTextProvider
        }
    }
}

extension ComposeContentViewModel {
    func metaText(_ metaText: MetaText, processEditing textStorage: MetaTextStorage) -> MetaContent? {
        guard let author = self.author else {
            return nil
        }
        
        switch metaText.textView {
        case composeInputTableViewCell.contentWarningMetaText.textView:
            let textInput = textStorage.string.replacingOccurrences(of: "\n", with: " ")
            self.currentContentWarningInput = textInput
            
            let content = MastodonContent(
                content: textInput,
                emojis: [:] // emojiViewModel?.emojis.asDictionary ?? [:]
            )
            let metaContent = MastodonMetaContent.convert(text: content)
            return metaContent
            
        case composeInputTableViewCell.contentMetaText.textView:
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
                return metaContent
                
            case .mastodon:
                let content = MastodonContent(
                    content: textInput,
                    emojis: [:] // emojiViewModel?.emojis.asDictionary ?? [:]
                )
                let metaContent = MastodonMetaContent.convert(text: content)
                return metaContent
            }
            
        default:
            assertionFailure()
            return nil
        }
    }

}

extension ComposeContentViewModel {
    func createNewPollOptionIfNeeds() {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard pollOptions.count < maxPollOptionLimit else { return }
        pollOptions.append(PollComposeItem.Option())
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
            return MastodonStatusPublisher(
                author: author,
                replyTo: {
                    guard case let .mastodon(status) = replyTo else { return nil }
                    return .init(objectID: status.objectID)
                }(),
                isContentWarningComposing: isContentWarningComposing,
                contentWarning: currentContentWarningInput,
                content: currentTextInput,
                isMediaSensitive: isMediaSensitive,
                attachmentViewModels: attachmentViewModels,
                isPollComposing: isPollComposing,
                pollOptions: pollOptions,
                pollExpireConfiguration: pollExpireConfiguration,
                pollMultipleConfiguration: pollMultipleConfiguration,
                visibility: mastodonVisibility
            )
        }   // end switch
    }   // end func publisher()
}
