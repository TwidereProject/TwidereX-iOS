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
public final class ComposeContentViewModel: NSObject, ObservableObject {
    
    let logger = Logger(subsystem: "ComposeContentViewModel", category: "ViewModel")
    var disposeBag = Set<AnyCancellable>()
    
    let locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        return locationManager
    }()
    
    // MARK: - layout
    @Published var viewSize: CGSize = .zero

    // input
    let context: AppContext
    public let kind: Kind
    public let configurationContext: ConfigurationContext
    public let customEmojiPickerInputViewModel = CustomEmojiPickerInputView.ViewModel()
    public let platform: Platform
    
    // Author (Me)
    @Published public private(set) var authContext: AuthContext?
    @Published public private(set) var author: UserObject?
    
    // reply-to
    public private(set) var replyTo: StatusObject?

    // limit
    @Published public var maxTextInputLimit = 500

    // text
    public weak var contentMetaText: MetaText? {
        didSet {
            guard let textView = contentMetaText?.textView else { return }
            customEmojiPickerInputViewModel.configure(textInput: textView)
        }
    }
    @Published public var initialContent = ""
    @Published public var content = ""
    @Published public var contentWeightedLength = 0
    @Published public var isContentEmpty = true
    @Published public var isContentValid = true
    @Published public var isContentEditing = false
    
    // content warning (Mastodon)
    weak var contentWarningMetaText: MetaText? {
        didSet {
            guard let textView = contentWarningMetaText?.textView else { return }
            customEmojiPickerInputViewModel.configure(textInput: textView)
        }
    }
    @Published public var contentWarning = ""
    @Published public var contentWarningWeightedLength = 0  // set 0 when not composing
    @Published public var isContentWarningComposing = false {
        didSet {
            if isContentWarningComposing {
                isMediaSensitive = true
            }
        }
    }
    @Published public var isContentWarningEditing = false
        
    // mention (Twitter)
    @Published public private(set) var isMentionPickDisplay = false
    @Published public private(set) var mentionPickButtonTitle = ""
    public private(set) var primaryMentionPickItem: MentionPickViewModel.Item?
    public private(set) var secondaryMentionPickItems: [MentionPickViewModel.Item] = []
    @Published public internal(set) var excludeReplyTwitterUserIDs: Set<TwitterUser.ID> = Set()
    public let mentionPickPublisher = PassthroughSubject<Void, Never>()
    
    // replySettingss (Twitter)
    @Published public internal(set) var twitterReplySettings: Twitter.Entity.V2.Tweet.ReplySettings = .everyone
    
    // visibility (Mastodon)
    @Published public internal(set) var mastodonVisibility: Mastodon.Entity.Status.Visibility = .public
    
    // attachment
    public let mediaActionPublisher = PassthroughSubject<ComposeContentToolbarView.MediaAction, Never>()
    public let mediaPreviewPublisher = PassthroughSubject<AttachmentViewModel, Never>()
    @Published public var attachmentViewModels: [AttachmentViewModel] = []
    @Published public var maxMediaAttachmentLimit = 4
    @Published public internal(set) var isMediaSensitive = false        // Mastodon only
    @Published public internal(set) var isMediaValid = true
    
    // MARK: - output
    public var customEmojiDiffableDataSource: UICollectionViewDiffableDataSource<CustomEmojiPickerInputView.ViewModel.Section, CustomEmojiPickerInputView.ViewModel.Item>?
    
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
    @Published public var pollExpireConfiguration = PollComposeItem.ExpireConfiguration()
    @Published public var pollMultipleConfiguration = PollComposeItem.MultipleConfiguration()
    @Published public var maxPollOptionLimit = 4
    public let pollExpireConfigurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.formattingContext = .standalone
        formatter.unitsStyle = .short
        return formatter
    }()
    
    // location (Twitter only)
    public private(set) var didRequestLocationAuthorization = false
    @Published public var isRequestLocation = false
    @Published public private(set) var currentLocation: CLLocation?
    @Published public internal(set) var currentPlace: Twitter.Entity.Place?
    
    // toolbar
    @Published public private(set) var availableActions: Set<ComposeContentToolbarView.Action> = Set()
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
        context: AppContext,
        authContext: AuthContext,
        kind: Kind,
        settings: Settings = Settings(),
        configurationContext: ConfigurationContext
    ) {
        self.context = context
        self.authContext = authContext
        self.kind = kind
        self.configurationContext = configurationContext
        self.platform = configurationContext.authenticationService.activeAuthenticationContext?.platform ?? .none
        super.init()
        // end init

        switch kind {
        case .post:
            break
        case .hashtag(let hashtag):
            content = "#" + hashtag + " "
        case .mention(let user):
            // set content text
            switch user {
            case .twitter(let user):
                content = "@" + user.username + " "
            case .mastodon(let user):
                content = "@" + user.acct + " "
            }
        case .reply(let status):
            replyTo = status
            
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
                    contentWarning = spoilerText
                }
                
                // set content text
                var mentionAccts: [String] = []
                let _authorUserIdentifier: MastodonUserIdentifier? = {
                    switch configurationContext.authenticationService.activeAuthenticationContext?.userIdentifier {
                    case .mastodon(let userIdentifier):     return userIdentifier
                    default:                                return nil
                    }
                }()
                if _authorUserIdentifier?.id != status.author.id {
                    mentionAccts.append("@" + status.author.acct)
                }
                for mention in status.mentions {
                    let acct = "@" + mention.acct
                    guard !mentionAccts.contains(acct) else { continue }
                    guard mention.id != _authorUserIdentifier?.id else { continue }
                    mentionAccts.append(acct)
                }
                for acct in mentionAccts {
                    UITextChecker.learnWord(acct)
                }
                content = mentionAccts.joined(separator: " ") + " "
            }
        }
        
        initialContent = content
        
        // bind author
//        $authContext
//            .receive(on: DispatchQueue.main)
//            .map { authContext in
//                authContext?.authenticationContext.user(in: configurationContext.apiService.)
//            }
        
        // bind text
        $content
            .map { $0.isEmpty }
            .assign(to: &$isContentEmpty)
        
        Publishers.CombineLatest(
            $content,
            $author
        )
        .sink { [weak self] content, author in
            guard let self = self else { return }
            guard let author = author else { return }
            switch author {
            case .twitter:
                let twitterTextProvider = configurationContext.statusViewConfigureContext.twitterTextProvider
                let parseResult = twitterTextProvider.parse(text: content)
                self.contentWeightedLength = parseResult.weightedLength
                self.maxTextInputLimit = parseResult.maxWeightedLength
                self.isContentValid = parseResult.isValid
            case .mastodon:
                self.contentWeightedLength = content.count
            }
        }
        .store(in: &disposeBag)
        
        Publishers.CombineLatest3(
            $isContentWarningComposing,
            $contentWarning,
            $author
        )
        .sink { [weak self] isContentWarningComposing, contentWarning, author in
            guard let self = self else { return }
            guard let author = author else { return }
            switch author {
            case .twitter:
                self.contentWarningWeightedLength = 0
            case .mastodon:
                self.contentWarningWeightedLength = isContentWarningComposing ? contentWarning.count : 0
            }
        }
        .store(in: &disposeBag)
        
        Publishers.CombineLatest4(
            $contentWeightedLength,
            $contentWarningWeightedLength,
            $maxTextInputLimit,
            $author
        )
        .sink { [weak self] contentWeightedLength, contentWarningWeightedLength, maxTextInputLimit, author in
            guard let self = self else { return }
            guard let author = author else { return }
            switch author {
            case .twitter:
                break
            case .mastodon:
                let count =  contentWeightedLength + contentWarningWeightedLength
                self.isContentValid = count <= maxTextInputLimit
            }
        }
        .store(in: &disposeBag)
        
        // bind mention
        $author
            .map { author in
                switch author {
                case .twitter:
                    guard case .reply = kind else { return false }
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
        .compactMap { [weak self] author, excludeReplyTwitterUserIDs -> String? in
            guard let self = self else { return nil }
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
            
            let names = usernames.map { "@" + $0 }
            return ListFormatter.localizedString(byJoining: names)
        }
        .assign(to: &$mentionPickButtonTitle)
        
        // bind visibility
        if let mastodonVisibility = settings.mastodonVisibility {
            self.mastodonVisibility = mastodonVisibility
        } else {
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
                            if case let .reply(object) = kind,
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
        }
    
        // bind attachments
        $attachmentViewModels
            .map { viewModels in
                Publishers.MergeMany(viewModels.map { $0.$output })     // build publisher when underlying outputs emits
                    .delay(for: 0.5, scheduler: DispatchQueue.main)
                    .map { _ in viewModels.map { $0.output } }          // convert to outputs with delay. Due to @Published emit before changes
            }
            .switchToLatest()                                           // always apply stream on latest viewModels
            .map { outputs in
                // condition 1: all outputs ready
                guard outputs.allSatisfy({ $0 != nil }) else { return false }
                // condition 2: video exclusive (empty or only one)
                var videoCount = 0
                for output in outputs {
                    switch output {
                    case .video:        videoCount += 1
                    default:            continue
                    }
                }
                guard videoCount == 0 || (videoCount == 1 && outputs.count == 1) else {
                    return false
                }
                return true
            }
            .assign(to: &$isMediaValid)
        
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
        
        Publishers.CombineLatest(
            $isRequestLocation,
            $currentLocation
        )
        .asyncMap { [weak self] isRequestLocation, currentLocation -> Twitter.Entity.Place? in
            guard let self = self else { return nil }
            guard isRequestLocation, let currentLocation = currentLocation else { return nil }
            
            guard let authenticationContext = self.configurationContext.authenticationService.activeAuthenticationContext,
                  case let .twitter(twitterAuthenticationContext) = authenticationContext
            else { return nil }
            
            do {
                let response = try await self.configurationContext.apiService.geoSearch(
                    latitude: currentLocation.coordinate.latitude,
                    longitude: currentLocation.coordinate.longitude,
                    granularity: "city",
                    twitterAuthenticationContext: twitterAuthenticationContext
                )
                let place = response.value.first
                return place
            } catch {
                return nil
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] place in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: current place: %s", ((#file as NSString).lastPathComponent), #line, #function, place?.fullName ?? "<nil>")
            self.currentPlace = place
        }
        .store(in: &disposeBag)
        
        // bind toolbar
        Publishers.CombineLatest(
            $author,
            $attachmentViewModels
        )
        .map { author, attachmentViewModels -> Set<ComposeContentToolbarView.Action> in
            var set = Set<ComposeContentToolbarView.Action>()
            set.insert(.media)
            set.insert(.mention)
            set.insert(.hashtag)
            set.insert(.media)
            
            switch author {
            case .twitter:
                set.insert(.poll)
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
        Publishers.CombineLatest4(
            $isContentEmpty,
            $isContentValid,
            $attachmentViewModels,
            $isMediaValid
        )
        .map { isContentEmpty, isContentValid, attachmentViewModels, isMediaValid in
            guard isContentValid else {
                return false
            }
            if isContentEmpty {
                return !attachmentViewModels.isEmpty && isMediaValid
            } else {
                return attachmentViewModels.isEmpty || isMediaValid
            }
        }
        .assign(to: &$isComposeBarButtonEnabled)
        
        Publishers.CombineLatest(
            $initialContent,
            $content
        )
        .map { initialContent, content in
            return initialContent.trimmingCharacters(in: .whitespacesAndNewlines) == content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .assign(to: &$canDismissDirectly)
        
        // set delegate
        locationManager.delegate = self
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        locationManager.stopUpdatingLocation()
    }
    
}

extension ComposeContentViewModel {
    public enum Kind {
        case post
        case hashtag(hashtag: String)
        case mention(user: UserObject)
        case reply(status: StatusObject)
    }
    
    public struct Settings {
        public var twitterReplySettings: Twitter.Entity.V2.Tweet.ReplySettings?
        public var mastodonVisibility: Mastodon.Entity.Status.Visibility?
        
        public init(
            twitterReplySettings: Twitter.Entity.V2.Tweet.ReplySettings? = nil,
            mastodonVisibility: Mastodon.Entity.Status.Visibility? = nil
        ) {
            self.twitterReplySettings = twitterReplySettings
            self.mastodonVisibility = mastodonVisibility
        }
    }
    
    public struct ConfigurationContext {
        public let apiService: APIService
        public let authenticationService: AuthenticationService
        public let mastodonEmojiService: MastodonEmojiService
        public let statusViewConfigureContext: StatusView.ConfigurationContext

        public init(
            apiService: APIService,
            authenticationService: AuthenticationService,
            mastodonEmojiService: MastodonEmojiService,
            statusViewConfigureContext: StatusView.ConfigurationContext
        ) {
            self.apiService = apiService
            self.authenticationService = authenticationService
            self.mastodonEmojiService = mastodonEmojiService
            self.statusViewConfigureContext = statusViewConfigureContext
        }
    }
}

extension ComposeContentViewModel {
    func createNewPollOptionIfCould() {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard pollOptions.count < maxPollOptionLimit else { return }
        let option = PollComposeItem.Option()
        option.shouldBecomeFirstResponder = true
        pollOptions.append(option)
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
            let alertController = UIAlertController(title: "Location Access Disabled", message: "Please enable location access to compose geo marked tweet", preferredStyle: .alert)    // FIXME: i18n
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
    public enum ComposeError: LocalizedError {
        case pollInvalid
        
        public var errorDescription: String? {
            switch self {
            case .pollInvalid:
                return L10n.Common.Alerts.PostFailInvalidPoll.title
            }
        }
        
        public var failureReason: String? {
            switch self {
            case .pollInvalid:
                return L10n.Common.Alerts.PostFailInvalidPoll.message
            }
        }
    }
    
    public func statusPublisher() throws -> StatusPublisher {
        guard let authContext = self.authContext,
              let author = self.author
        else {
            throw AppError.implicit(.authenticationMissing)
        }
        
        let isPollValid: Bool = {
            guard isPollComposing else { return true }
            let isAllNonEmpty = pollOptions
                .map { $0.text }
                .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            return isAllNonEmpty
        }()
        guard isPollValid else {
            throw ComposeError.pollInvalid
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
                content: content,
                place: isRequestLocation ? currentPlace : nil,
                poll: {
                    guard isPollComposing else { return nil }
                    let durationMinutes: Int = {
                        let countdown = pollExpireConfiguration.countdown
                        return (countdown.day ?? 0) * 24 * 60
                            + (countdown.hour ?? 0) * 60
                            + (countdown.minute ?? 0)
                    }()
                    return .init(
                        options: pollOptions.map { $0.text },
                        durationMinutes: durationMinutes
                    )
                }(),
                replySettings: twitterReplySettings,
                attachmentViewModels: attachmentViewModels
            )
        case .mastodon(let author):
            return MastodonStatusPublisher(
                authContext: authContext,
                author: author,
                replyTo: {
                    guard case let .mastodon(status) = replyTo else { return nil }
                    return .init(objectID: status.objectID)
                }(),
                isContentWarningComposing: isContentWarningComposing,
                contentWarning: contentWarning,
                content: content,
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

// MARK: - UITextViewDelegate
extension ComposeContentViewModel: UITextViewDelegate {
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        switch textView {
        case contentMetaText?.textView:
            isContentEditing = true
        case contentWarningMetaText?.textView:
            isContentWarningEditing = true
        default:
            break
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        switch textView {
        case contentMetaText?.textView:
            isContentEditing = false
        case contentWarningMetaText?.textView:
            isContentWarningEditing = false
        default:
            break
        }
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        switch textView {
        case contentMetaText?.textView:
            return true
        case contentWarningMetaText?.textView:
            let isReturn = text == "\n"
            if isReturn {
                setContentTextViewFirstResponderIfNeeds()
            }
            return !isReturn
        default:
            assertionFailure()
            return true
        }
    }

    func insertContentText(text: String) {
        guard let contentMetaText = self.contentMetaText else { return }
        // FIXME: smart prefix and suffix
        let string = contentMetaText.textStorage.string
        let isEmpty = string.isEmpty
        let hasPrefix = string.hasPrefix(" ")
        if hasPrefix || isEmpty {
            contentMetaText.textView.insertText(text)
        } else {
            contentMetaText.textView.insertText(" " + text)
        }
    }
    
    func setContentTextViewFirstResponderIfNeeds() {
        guard let contentMetaText = self.contentMetaText else { return }
        guard !contentMetaText.textView.isFirstResponder else { return }
        contentMetaText.textView.becomeFirstResponder()
    }
    
    func setContentWarningTextViewFirstResponderIfNeeds() {
        guard let contentWarningMetaText = self.contentWarningMetaText else { return }
        guard !contentWarningMetaText.textView.isFirstResponder else { return }
        contentWarningMetaText.textView.becomeFirstResponder()
    }
    
}

// MARK: - DeleteBackwardResponseTextFieldRelayDelegate
extension ComposeContentViewModel: DeleteBackwardResponseTextFieldRelayDelegate {

    func deleteBackwardResponseTextFieldDidReturn(_ textField: DeleteBackwardResponseTextField) {
        let index = textField.tag
        if index + 1 == pollOptions.count {
            createNewPollOptionIfCould()
        } else if index < pollOptions.count {
            pollOptions[index + 1].textField?.becomeFirstResponder()
        }
    }
    
    func deleteBackwardResponseTextField(_ textField: DeleteBackwardResponseTextField, textBeforeDelete: String?) {
        guard (textBeforeDelete ?? "").isEmpty else {
            // do nothing when not empty
            return
        }
        
        let index = textField.tag
        guard index > 0 else {
            // do nothing at first row
            return
        }
        
        func optionBeforeRemoved() -> PollComposeItem.Option? {
            guard index > 0 else { return nil }
            let indexBeforeRemoved = pollOptions.index(before: index)
            let itemBeforeRemoved = pollOptions[indexBeforeRemoved]
            return itemBeforeRemoved
            
        }
        
        func optionAfterRemoved() -> PollComposeItem.Option? {
            guard index < pollOptions.count - 1 else { return nil }
            let indexAfterRemoved = pollOptions.index(after: index)
            let itemAfterRemoved = pollOptions[indexAfterRemoved]
            return itemAfterRemoved
        }
        
        // move first responder
        let _option = optionBeforeRemoved() ?? optionAfterRemoved()
        _option?.textField?.becomeFirstResponder()
        
        guard pollOptions.count > 2 else {
            // remove item when more then 2 options
            return
        }
        pollOptions.remove(at: index)
    }
    
}
