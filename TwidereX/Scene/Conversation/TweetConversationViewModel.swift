//
//  TweetConversationViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import os.log
import UIKit
import CoreData
import Combine
import GameplayKit
import CoreData
import CoreDataStack
import AlamofireImage
import Kingfisher
import TwitterSDK

final class TweetConversationViewModel: NSObject {
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    var disposeBag = Set<AnyCancellable>()
    var rootItemObservation: AnyCancellable?
    
    // input
    let context: AppContext
    let rootItem: CurrentValueSubject<ConversationItem, Never>
    let conversationMeta = CurrentValueSubject<ConversationMeta?, Never>(nil)
    let deletedTweetFetchedResultsController: TweetFetchedResultsController
    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
    weak var tableView: UITableView?
    weak var conversationPostTableViewCellDelegate: ConversationPostTableViewCellDelegate?
    weak var timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ConversationSection, ConversationItem>?
    private(set) lazy var loadConversationStateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            LoadConversationState.Initial(viewModel: self),
            LoadConversationState.Prepare(viewModel: self),
            LoadConversationState.PrepareFail(viewModel: self),
            LoadConversationState.Idle(viewModel: self),
            LoadConversationState.Loading(viewModel: self),
            LoadConversationState.Fail(viewModel: self),
            LoadConversationState.NoMore(viewModel: self),
            
        ])
        stateMachine.enter(LoadConversationState.Initial.self)
        return stateMachine
    }()
    private(set) lazy var loadReplyStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
        let stateMachine = GKStateMachine(states: [
            LoadReplyState.Initial(viewModel: self),
            LoadReplyState.Prepare(viewModel: self),
            LoadReplyState.Idle(viewModel: self),
            LoadReplyState.Loading(viewModel: self),
            LoadReplyState.Fail(viewModel: self),
            LoadReplyState.NoMore(viewModel: self),
            
        ])
        stateMachine.enter(LoadReplyState.Initial.self)
        return stateMachine
    }()
    var replyNodes = CurrentValueSubject<[ReplyNode], Never>([])
    var conversationNodes = CurrentValueSubject<[ConversationNode], Never>([])
    var replyItems = CurrentValueSubject<[ConversationItem], Never>([])
    var conversationItems = CurrentValueSubject<[ConversationItem], Never>([])
    var snapshotPublisher = PassthroughSubject<NSDiffableDataSourceSnapshot<ConversationSection, ConversationItem>, Never>()
    var cellFrameCache = NSCache<NSNumber, NSValue>()
    
    // TODO: support loading from ID/URL
    init(context: AppContext, tweetObjectID: NSManagedObjectID) {
        self.context = context
        self.rootItem = CurrentValueSubject(.root(tweetObjectID: tweetObjectID))
        self.deletedTweetFetchedResultsController = TweetFetchedResultsController(managedObjectContext: context.managedObjectContext, additionalTweetPredicate: Tweet.deleted())
        super.init()
        
        Publishers.CombineLatest3(
            rootItem.eraseToAnyPublisher(),
            replyItems.eraseToAnyPublisher(),
            conversationItems.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] rootItem, replyItems, conversationItems in
            guard let self = self else { return }
            let items: [ConversationItem] = [rootItem] + replyItems + conversationItems
            self.updateDeletedTweet(for: items)
        }
        .store(in: &disposeBag)
            
        
        Publishers.CombineLatest4(
            rootItem.eraseToAnyPublisher(),
            replyItems.eraseToAnyPublisher(),
            conversationItems.eraseToAnyPublisher(),
            deletedTweetFetchedResultsController.items.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] rootItem, replyItems, conversationItems, deletedItems in
            guard let self = self else { return }
            guard let tableView = self.tableView,
                  let navigationBar = self.contentOffsetAdjustableTimelineViewControllerDelegate?.navigationBar()
            else { return }
            
            guard let diffableDataSource = self.diffableDataSource else { return }
            let oldSnapshot = diffableDataSource.snapshot()
            let itemIdentifiers = oldSnapshot.itemIdentifiers
            
            var newSnapshot = NSDiffableDataSourceSnapshot<ConversationSection, ConversationItem>()
            newSnapshot.appendSections([.main])
            
            // reply
            if let currentState = self.loadReplyStateMachine.currentState,
               !(currentState is LoadReplyState.NoMore) {
                newSnapshot.appendItems([.topLoader], toSection: .main)
            }
            let replyItems = replyItems.filter { item in
                guard case let .reply(tweetObjectID) = item else { return false }
                return !deletedItems.contains(Item.tweet(objectID: tweetObjectID))
            }
            newSnapshot.appendItems(replyItems, toSection: .main)
            // root
            switch rootItem {
            case .root(let tweetObjectID) where !deletedItems.contains(Item.tweet(objectID: tweetObjectID)):
                newSnapshot.appendItems([rootItem], toSection: .main)
            default:
                break
            }
            // conversation
            let conversationItems = conversationItems.filter { item in
                guard case let .leaf(tweetObjectID, _) = item else { return false }
                return !deletedItems.contains(Item.tweet(objectID: tweetObjectID))
            }
            newSnapshot.appendItems(conversationItems, toSection: .main)

            if let currentState = self.loadConversationStateMachine.currentState,
               currentState is LoadConversationState.Idle || currentState is LoadConversationState.Loading || currentState is LoadConversationState.Prepare {
                newSnapshot.appendItems([.bottomLoader], toSection: .main)
            }
            
            self.snapshotPublisher.send(newSnapshot)

            // difference for first visiable item exclude .topLoader
            guard let difference = self.calculateReloadSnapshotDifference(navigationBar: navigationBar, tableView: tableView, oldSnapshot: oldSnapshot, newSnapshot: newSnapshot) else {
                diffableDataSource.apply(newSnapshot)
                return
            }

            // addtional margin for .topLoader
            let oldTopMargin: CGFloat = {
                guard let index = oldSnapshot.indexOfItem(.topLoader) else { return .zero }
                guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) else { return .zero }
                return cell.frame.height
            }()
            
            diffableDataSource.apply(newSnapshot, animatingDifferences: false) {
                // set bottom inset. Make root item pin to top.
                if let index = newSnapshot.indexOfItem(rootItem),
                   let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
                    // always set bottom inset due to lazy reply loading
                    // otherwise tableView will jump when insert replies
                    let bottomSpacing = tableView.safeAreaLayoutGuide.layoutFrame.height - cell.frame.height - oldTopMargin
                    let additionalInset = round(tableView.contentSize.height - cell.frame.maxY)
                    tableView.contentInset.bottom = max(0, bottomSpacing - additionalInset)
                }
                // set scroll position
                tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
                tableView.contentOffset.y = {
                    var offset: CGFloat = tableView.contentOffset.y - difference.offset
                    if tableView.contentInset.bottom != 0.0 {
                        // needs restore top margin if bottom inset adjusted
                        offset += oldTopMargin
                    }
                    return offset
                }()
            }
        }
        .store(in: &disposeBag)
        
        replyNodes
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] nodes -> [ConversationItem]? in
                guard let self = self else { return nil }
                guard !nodes.isEmpty else { return [] }
                
                var items: [ConversationItem] = []
                for node in nodes {
                    switch node.status {
                    case .success(let objectID):
                        items.append(.reply(tweetObjectID: objectID))
                    case .notDetermined, .fail:
                        break
                    }
                }
                
                return items.reversed()
            }
            .assign(to: \.value, on: replyItems)
            .store(in: &disposeBag)
        
        // map flat conversation nodes to a two-tier tree
        // new conversation nodes append to tail and not break previours tree structure
        conversationNodes
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] nodes -> [ConversationItem]? in
                guard let self = self else { return nil }
                guard !nodes.isEmpty else { return [] }
                
                guard let diffableDataSource = self.diffableDataSource else { return nil }
                let oldSnapshot = diffableDataSource.snapshot()
                
                let itemIdentifiers = oldSnapshot.itemIdentifiers
                
                var oldItems: [ConversationItem] = []
                var currentLeafAttributes: [ConversationItem.LeafAttribute] = []
                for item in itemIdentifiers {
                    guard case let .leaf(_, attribute) = item else { continue }
                    oldItems.append(item)
                    currentLeafAttributes.append(attribute)
                }
                let currentLeafTweetIDs = currentLeafAttributes.map { $0.tweetID }
                
                let childrenIDs = nodes.map { [$0.tweet.id, $0.children.first?.tweet.id].compactMap { $0 } }.flatMap { $0 }
                let request = Tweet.sortedFetchRequest
                request.predicate = Tweet.predicate(idStrs: childrenIDs)
                var tweetDict: [Tweet.ID: Tweet] = [:]
                do {
                    let tweets = try self.context.managedObjectContext.fetch(request)
                    for tweet in tweets {
                        tweetDict[tweet.id] = tweet
                    }
                } catch {
                    os_log("%{public}s[%{public}ld], %{public}s: fetch conversation fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    return nil
                }
                
                var newItems: [ConversationItem] = []
                for node in nodes {
                    // 1st level
                    guard !currentLeafTweetIDs.contains(node.tweet.id) else { continue }
                    guard let tweet = tweetDict[node.tweet.id] else { continue }
                    
                    let firstTierAttribute = ConversationItem.LeafAttribute(tweetID: node.tweet.id, level: 0)
                    let firstTierItem = ConversationItem.leaf(tweetObjectID: tweet.objectID, attribute: firstTierAttribute)
                    newItems.append(firstTierItem)
                    
                    // 2nd level
                    if let child = node.children.first {
                        guard let secondTweet = tweetDict[child.tweet.id] else { continue }
                        let secondTierAttribute = ConversationItem.LeafAttribute(tweetID: child.tweet.id, level: 1)
                        let secondTierItem = ConversationItem.leaf(tweetObjectID: secondTweet.objectID, attribute: secondTierAttribute)
                        newItems.append(secondTierItem)
                    } else {
                        firstTierAttribute.hasReply = false
                    }
                }

                return oldItems + newItems
            }
            .assign(to: \.value, on: conversationItems)
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension TweetConversationViewModel {
    struct ConversationMeta {
        let tweetID: Twitter.Entity.V2.Tweet.ID
        let authorID: Twitter.Entity.User.ID
        let authorUsrename: String
        let conversationID: Twitter.Entity.V2.Tweet.ConversationID
        let createdAt: Date
    }
}

extension TweetConversationViewModel {
    
    // FIXME: refactor into Diffable section
    func setupDiffableDataSource(for tableView: UITableView, dependency: NeedsDependency) {
        assert(Thread.isMainThread)
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self, weak dependency] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let dependency = dependency else { return nil }
            
            switch item {
            case .root(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ConversationPostTableViewCell.self), for: indexPath) as! ConversationPostTableViewCell
                let activeTwitterAuthenticationBox = self.context.authenticationService.activeTwitterAuthenticationBox.value
                let requestTwitterUserID = activeTwitterAuthenticationBox?.twitterUserID ?? ""
                let managedObjectContext = self.context.managedObjectContext
                managedObjectContext.performAndWait {
                    let tweet = managedObjectContext.object(with: objectID) as! Tweet
                    TweetConversationViewModel.configure(cell: cell, readableLayoutFrame: tableView.readableContentGuide.layoutFrame, dependency: dependency, tweet: tweet, requestUserID: requestTwitterUserID)
                    TweetConversationViewModel.configure(cell: cell, overrideTraitCollection: self.context.overrideTraitCollection.value)
                }
                cell.delegate = self.conversationPostTableViewCellDelegate
                return cell
            case .reply(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
                let twitterAuthenticationBox = self.context.authenticationService.activeTwitterAuthenticationBox.value
                let requestUserID = twitterAuthenticationBox?.twitterUserID ?? ""
                let managedObjectContext = self.context.managedObjectContext
                managedObjectContext.performAndWait {
                    let tweet = managedObjectContext.object(with: objectID) as! Tweet
                    TimelineSection.configure(cell: cell, readableLayoutFrame: tableView.readableContentGuide.layoutFrame, dependency: dependency, tweet: tweet, requestUserID: requestUserID)
                    TimelineSection.configure(cell: cell, overrideTraitCollection: self.context.overrideTraitCollection.value)
                    cell.conversationLinkUpper.isHidden = tweet.inReplyToTweetID == nil
                    cell.conversationLinkLower.isHidden = false
                }
                cell.delegate = self.timelinePostTableViewCellDelegate
                return cell
            
            case .leaf(let objectID, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
                let twitterAuthenticationBox = self.context.authenticationService.activeTwitterAuthenticationBox.value
                let requestUserID = twitterAuthenticationBox?.twitterUserID ?? ""
                let managedObjectContext = self.context.managedObjectContext
                managedObjectContext.performAndWait {
                    let tweet = managedObjectContext.object(with: objectID) as! Tweet
                    TimelineSection.configure(cell: cell, readableLayoutFrame: tableView.readableContentGuide.layoutFrame, dependency: dependency, tweet: tweet, requestUserID: requestUserID)
                    TimelineSection.configure(cell: cell, overrideTraitCollection: self.context.overrideTraitCollection.value)
                }
                cell.conversationLinkUpper.isHidden = attribute.level == 0
                cell.conversationLinkLower.isHidden = !attribute.hasReply || attribute.level != 0
                cell.delegate = self.timelinePostTableViewCellDelegate
                return cell
            case .topLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineTopLoaderTableViewCell.self), for: indexPath) as! TimelineTopLoaderTableViewCell
                cell.activityIndicatorView.isHidden = false
                cell.activityIndicatorView.startAnimating()
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.isHidden = false
                cell.activityIndicatorView.startAnimating()
                return cell
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<ConversationSection, ConversationItem>()
        snapshot.appendSections([.main])
        let rootItem = self.rootItem.value
        if case let .root(tweetObjectID) = rootItem,
           let tweet = context.managedObjectContext.object(with: tweetObjectID) as? Tweet,
           let _ = (tweet.retweet ?? tweet).inReplyToTweetID {
            // update reply items later in the `Prepare` state
            snapshot.appendItems([.topLoader], toSection: .main)
        } else {
            // enter NoMore state when not has replyTo
            loadReplyStateMachine.enter(LoadReplyState.NoMore.self)
        }
        snapshot.appendItems([rootItem, .bottomLoader], toSection: .main)
        diffableDataSource?.apply(snapshot)
    }
    
    static func configure(
        cell: ConversationPostTableViewCell,
        readableLayoutFrame: CGRect? = nil,
        dependency: NeedsDependency,
        tweet: Tweet,
        requestUserID: String
    ) {
        // set retweet display
        cell.conversationPostView.retweetContainerStackView.isHidden = tweet.retweet == nil
        cell.conversationPostView.retweetInfoLabel.text = L10n.Common.Controls.Status.userRetweeted(tweet.author.name)
        
        // set avatar
        let avatarImageURL = (tweet.retweet ?? tweet).author.avatarImageURL()
        let verified = (tweet.retweet ?? tweet).author.verified
        UserDefaults.shared
            .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                cell.conversationPostView.configure(withConfigurationInput: AvatarConfigurableViewConfiguration.Input(avatarImageURL: avatarImageURL, verified: verified))
            }
            .store(in: &cell.observations)
        
        cell.conversationPostView.lockImageView.isHidden = !((tweet.retweet ?? tweet).author.protected)
        
        // set name and username
        cell.conversationPostView.nameLabel.text = (tweet.retweet ?? tweet).author.name
        cell.conversationPostView.usernameLabel.text = "@" + (tweet.retweet ?? tweet).author.username

        // set text
        cell.conversationPostView.activeTextLabel.configure(with: (tweet.retweet ?? tweet).displayText)
        
        // set media display
        let media = Array((tweet.retweet ?? tweet).media ?? []).sorted { $0.index.compare($1.index) == .orderedAscending }
        
        // set image
        let mosiacImageViewModel = MosaicImageViewModel(twitterMedia: media)
        let imageViewMaxSize: CGSize = {
            let maxWidth: CGFloat = {
                // use conversationPostView width as container width
                // that width follows readable width and keep constant width after rotate
                let containerFrame = readableLayoutFrame ?? cell.conversationPostView.frame
                let containerWidth = containerFrame.width
                return containerWidth
            }()
            let scale: CGFloat = {
                switch mosiacImageViewModel.metas.count {
                case 1:     return 1.3
                default:    return 0.7
                }
            }()
            return CGSize(width: maxWidth, height: maxWidth * scale)
        }()
        if mosiacImageViewModel.metas.count == 1 {
            let meta = mosiacImageViewModel.metas[0]
            let imageView = cell.conversationPostView.mosaicImageView.setupImageView(aspectRatio: meta.size, maxSize: imageViewMaxSize)
            imageView.af.setImage(
                withURL: meta.url,
                placeholderImage: UIImage.placeholder(color: .systemFill),
                imageTransition: .crossDissolve(0.2)
            )
        } else {
            let imageViews = cell.conversationPostView.mosaicImageView.setupImageViews(count: mosiacImageViewModel.metas.count, maxHeight: imageViewMaxSize.height)
            for (i, imageView) in imageViews.enumerated() {
                let meta = mosiacImageViewModel.metas[i]
                imageView.af.setImage(
                    withURL: meta.url,
                    placeholderImage: UIImage.placeholder(color: .systemFill),
                    imageTransition: .crossDissolve(0.2)
                )
            }
        }
        cell.conversationPostView.mosaicImageView.isHidden = mosiacImageViewModel.metas.isEmpty
        
        // set GIF & video
        let playerViewMaxSize: CGSize = {
            let maxWidth: CGFloat = {
                // use conversationPostView width as container width
                // that width follows readable width and keep constant width after rotate
                let containerFrame = readableLayoutFrame ?? cell.conversationPostView.frame
                var containerWidth = containerFrame.width
                containerWidth -= 10
                containerWidth -= TimelinePostView.avatarImageViewSize.width
                return containerWidth
            }()
            let scale: CGFloat = 1.3
            return CGSize(width: maxWidth, height: maxWidth * scale)
        }()
        if let media = media.first, let videoPlayerViewModel = dependency.context.videoPlaybackService.dequeueVideoPlayerViewModel(for: media) {
            let parent = cell.delegate?.parent()
            let mosaicPlayerView = cell.conversationPostView.mosaicPlayerView
            let playerViewController = mosaicPlayerView.setupPlayer(
                aspectRatio: videoPlayerViewModel.videoSize,
                maxSize: playerViewMaxSize,
                parent: parent
            )
            playerViewController.delegate = cell.delegate?.playerViewControllerDelegate
            playerViewController.showsPlaybackControls = videoPlayerViewModel.videoKind != .gif

            // FIX HUD flick issue
            DispatchQueue.main.async {
                playerViewController.player = videoPlayerViewModel.player
            }

            mosaicPlayerView.gifIndicatorBackgroundVisualEffectView.isHidden = videoPlayerViewModel.videoKind != .gif
            mosaicPlayerView.isHidden = false
        } else {
            cell.conversationPostView.mosaicPlayerView.playerViewController.player?.pause()
            cell.conversationPostView.mosaicPlayerView.playerViewController.player = nil
        }
        
        // set quote
        let quote = (tweet.retweet ?? tweet).quote
        if let quote = quote {
            // set avatar
            let avatarImageURL = quote.author.avatarImageURL()
            let verified = quote.author.verified
            UserDefaults.shared
                .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                    cell.conversationPostView.quotePostView.configure(withConfigurationInput: AvatarConfigurableViewConfiguration.Input(avatarImageURL: avatarImageURL, verified: verified))
                }
                .store(in: &cell.observations)
            
            // set name and username
            cell.conversationPostView.quotePostView.nameLabel.text = quote.author.name
            cell.conversationPostView.quotePostView.usernameLabel.text = "@\(quote.author.username)"
            
            // set text
            cell.conversationPostView.quotePostView.activeTextLabel.configure(with: quote.displayText)
        }
        cell.conversationPostView.quotePostView.isHidden = quote == nil
        
        // set geo
        let placeFullName = tweet.place?.fullname ?? nil
        cell.conversationPostView.geoLabel.text = placeFullName
        cell.conversationPostView.geoMetaContainerStackView.isHidden = placeFullName == nil
        
        // set date
        cell.conversationPostView.dateLabel.text = TweetConversationViewModel.dateFormatter.string(from: tweet.createdAt)
        
        // set status
        if let replyCount = (tweet.retweet ?? tweet).metrics?.replyCount.flatMap({ Int(truncating: $0) }), replyCount > 0 {
            cell.conversationPostView.replyPostStatusView.countLabel.text = String(replyCount)
            cell.conversationPostView.replyPostStatusView.statusLabel.text = replyCount > 1 ? L10n.Common.Countable.Reply.mutiple.localizedCapitalized : L10n.Common.Countable.Reply.single.localizedCapitalized
            cell.conversationPostView.replyPostStatusView.isHidden = false
        } else {
            cell.conversationPostView.replyPostStatusView.isHidden = true
        }
        if let retweetCount = (tweet.retweet ?? tweet).metrics?.retweetCount.flatMap({ Int(truncating: $0) }), retweetCount > 0 {
            cell.conversationPostView.retweetPostStatusView.countLabel.text = String(retweetCount)
            cell.conversationPostView.retweetPostStatusView.statusLabel.text = retweetCount > 1 ? L10n.Common.Countable.Retweet.mutiple.localizedCapitalized : L10n.Common.Countable.Retweet.single.localizedCapitalized
            cell.conversationPostView.retweetPostStatusView.isHidden = false
        } else {
            cell.conversationPostView.retweetPostStatusView.isHidden = true
        }
        if let quoteCount = (tweet.retweet ?? tweet).metrics?.quoteCount.flatMap({ Int(truncating: $0) }), quoteCount > 0 {
            cell.conversationPostView.quotePostStatusView.countLabel.text = String(quoteCount)
            cell.conversationPostView.quotePostStatusView.statusLabel.text = quoteCount > 1 ? L10n.Common.Countable.Quote.mutiple.localizedCapitalized : L10n.Common.Countable.Quote.single.localizedCapitalized
            cell.conversationPostView.quotePostStatusView.isHidden = false
        } else {
            cell.conversationPostView.quotePostStatusView.isHidden = true
        }
        cell.conversationPostView.quotePostStatusView.isHidden = true   // FIXME:
        if let favoriteCount = (tweet.retweet ?? tweet).metrics?.likeCount.flatMap({ Int(truncating: $0) }), favoriteCount > 0 {
            cell.conversationPostView.likePostStatusView.countLabel.text = String(favoriteCount)
            cell.conversationPostView.likePostStatusView.statusLabel.text = favoriteCount > 1 ? L10n.Common.Countable.Like.multiple.localizedCapitalized : L10n.Common.Countable.Like.single.localizedCapitalized
            cell.conversationPostView.likePostStatusView.isHidden = false
        } else {
            cell.conversationPostView.likePostStatusView.isHidden = true
        }
        
        // set source
        cell.conversationPostView.sourceLabel.text = (tweet.retweet ?? tweet).source
        
        // set action toolbar title
        let isRetweeted = (tweet.retweet ?? tweet).retweetBy.flatMap({ $0.contains(where: { $0.id == requestUserID }) }) ?? false
        cell.conversationPostView.actionToolbarContainer.retweetButton.isEnabled = !(tweet.retweet ?? tweet).author.protected
        cell.conversationPostView.actionToolbarContainer.isRetweetButtonHighligh = isRetweeted

        let isLike = (tweet.retweet ?? tweet).likeBy.flatMap({ $0.contains(where: { $0.id == requestUserID }) }) ?? false
        cell.conversationPostView.actionToolbarContainer.isLikeButtonHighlight = isLike
        
        // set upper link
        if let _ = (tweet.retweet ?? tweet).inReplyToTweetID {
            cell.conversationLinkUpper.isHidden = false
        } else {
            cell.conversationLinkUpper.isHidden = true
        }
        
        // set menu button
        if #available(iOS 14.0, *) {
            let menu = StatusProviderFacade.createMenuForStatus(
                tweet: tweet,
                sender: cell.conversationPostView.actionToolbarContainer.menuButton,
                dependency: dependency
            )
            cell.conversationPostView.actionToolbarContainer.menuButton.menu = menu
            cell.conversationPostView.actionToolbarContainer.menuButton.showsMenuAsPrimaryAction = true
        } else {
            // no menu supports. handle by `StatusProvider`
        }
        
        // observe model change
        ManagedObjectObserver.observe(object: tweet.retweet ?? tweet)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // do nothing
            } receiveValue: { change in
                guard case let .update(object) = change.changeType,
                      let newTweet = object as? Tweet else { return }
                let targetTweet = newTweet.retweet ?? newTweet
                
                let isRetweeted = targetTweet.retweetBy.flatMap({ $0.contains(where: { $0.id == requestUserID }) }) ?? false
                cell.conversationPostView.actionToolbarContainer.isRetweetButtonHighligh = isRetweeted

                let isLike = targetTweet.likeBy.flatMap({ $0.contains(where: { $0.id == requestUserID }) }) ?? false
                cell.conversationPostView.actionToolbarContainer.isLikeButtonHighlight = isLike
            }
            .store(in: &cell.disposeBag)
    }

    static func configure(cell: ConversationPostTableViewCell, overrideTraitCollection traitCollection: UITraitCollection?) {
        cell.conversationPostView.nameLabel.font = .preferredFont(forTextStyle: .headline, compatibleWith: traitCollection)
        cell.conversationPostView.usernameLabel.font = .preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection)
        cell.conversationPostView.activeTextLabel.font = .preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
        cell.conversationPostView.geoLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
        cell.conversationPostView.dateLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
        cell.conversationPostView.sourceLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)

        cell.conversationPostView.quotePostView.nameLabel.font = .preferredFont(forTextStyle: .headline, compatibleWith: traitCollection)
        cell.conversationPostView.quotePostView.usernameLabel.font = .preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection)
        cell.conversationPostView.quotePostView.dateLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
        cell.conversationPostView.quotePostView.activeTextLabel.font = .preferredFont(forTextStyle: .body, compatibleWith: traitCollection)

        cell.conversationPostView.retweetPostStatusView.countLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
        cell.conversationPostView.retweetPostStatusView.statusLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
        cell.conversationPostView.quotePostStatusView.countLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
        cell.conversationPostView.quotePostStatusView.statusLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
        cell.conversationPostView.likePostStatusView.countLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
        cell.conversationPostView.likePostStatusView.statusLabel.font = .preferredFont(forTextStyle: .callout, compatibleWith: traitCollection)
    }

}

extension TweetConversationViewModel {
    public class ReplyNode: CustomDebugStringConvertible {
        let tweetID: Tweet.ID
        let inReplyToTweetID: Tweet.ID?
        
        var status: Status
        
        init(tweetID: Tweet.ID, inReplyToTweetID: Tweet.ID?, status: Status) {
            self.tweetID = tweetID
            self.inReplyToTweetID = inReplyToTweetID
            self.status = status
        }
        
        enum Status {
            case notDetermined
            case fail(Error)
            case success(NSManagedObjectID)
        }
        
        public var debugDescription: String {
            return "tweet[\(tweetID)] -> \(inReplyToTweetID ?? "<nil>"), \(status)"
        }
    }
}

protocol ConvsersationTweet {
    var id: Twitter.Entity.V2.Tweet.ID { get }
}

extension Twitter.Entity.Tweet: ConvsersationTweet {
    var id: Twitter.Entity.V2.Tweet.ID { return idStr }
}

extension Twitter.Entity.V2.Tweet: ConvsersationTweet { }

extension TweetConversationViewModel {
    public class ConversationNode {
        let tweet: ConvsersationTweet
        let children: [ConversationNode]
        
        init(tweet: ConvsersationTweet, children: [ConversationNode]) {
            self.tweet = tweet
            self.children = children
        }
         
        /// Construct convsersation children nodes for given tweetID
        /// - Parameters:
        ///   - tweetID: the ID of children's parent tweet
        ///   - content: the material for construct tree (v1)
        /// - Returns: Array of children nodes (node may has children) for given tweet as root
        static func children(
            for tweetID: Twitter.Entity.Tweet.ID,
            from content: Twitter.API.Search.Content
        ) -> [ConversationNode] {
            let tweets = content.statuses ?? []
            var tweetDict: [Twitter.Entity.Tweet.ID: Twitter.Entity.Tweet] = [:]
            var replyToMappingDict: [Twitter.Entity.V2.Tweet.ID: Set<Twitter.Entity.V2.Tweet.ID>] = [:]
            
            for tweet in tweets {
                tweetDict[tweet.idStr] = tweet
                
                guard let replyToID = tweet.inReplyToStatusIDStr else {
                    continue
                }
                if var mapping = replyToMappingDict[replyToID] {
                    mapping.insert(tweet.idStr)
                    replyToMappingDict[replyToID] = mapping
                } else {
                    replyToMappingDict[replyToID] = Set([tweet.idStr])
                }
            }
            
            var children: [ConversationNode] = []
            let replies = Array(replyToMappingDict[tweetID] ?? Set())
                .compactMap { tweetDict[$0] }
                .sorted(by: { $0.createdAt > $1.createdAt })
            for reply in replies {
                let child = node(of: reply, from: tweetDict, replyToMappingDict: replyToMappingDict)
                children.append(child)
            }
            
            return children
        }
        
        /// Construct convsersation children nodes for given tweetID
        /// - Parameters:
        ///   - tweetID: the ID of children's parent tweet
        ///   - content: the material for construct tree (v2)
        /// - Returns: Array of children nodes (node may has children) for given tweet as root
        static func children(
            for tweetID: Twitter.Entity.V2.Tweet.ID,
            from content: Twitter.API.V2.RecentSearch.Content
        ) -> [ConversationNode] {
            let tweets = [content.data, content.includes?.tweets].compactMap { $0 }.flatMap { $0 }
            let dictContent = Twitter.Response.V2.DictContent(
                tweets: tweets,
                users: content.includes?.users ?? [],
                media: content.includes?.media ?? [],
                places: content.includes?.places ?? []
            )
            
            var replyToMappingDict: [Twitter.Entity.V2.Tweet.ID: Set<Twitter.Entity.V2.Tweet.ID>] = [:]
            for tweet in tweets {
                guard let referencedRepliedToTweet = tweet.referencedTweets?.first(where: { $0.type == .repliedTo }),
                      let replyToID = referencedRepliedToTweet.id else {
                    continue
                }
                
                if var mapping = replyToMappingDict[replyToID] {
                    mapping.insert(tweet.id)
                    replyToMappingDict[replyToID] = mapping
                } else {
                    replyToMappingDict[replyToID] = Set([tweet.id])
                }
            }
            
            var children: [ConversationNode] = []
            let replies = Array(replyToMappingDict[tweetID] ?? Set())
                .compactMap { dictContent.tweetDict[$0] }
                .sorted(by: { $0.createdAt > $1.createdAt })
            for reply in replies {
                let child = node(of: reply, from: dictContent, replyToMappingDict: replyToMappingDict)
                children.append(child)
            }
            
            return children
        }
        
        /// Construct a tree node of give tweet
        /// - Parameters:
        ///   - tweet: the tweet which node will be represented
        ///   - dictContent: the material for construct tree node (v1)
        ///   - replyToMappingDict: the relationship material for construct tree node
        /// - Returns: Node represented given tweet (may has children)
        static func node(
            of tweet: Twitter.Entity.Tweet,
            from tweetDict: [Twitter.Entity.Tweet.ID: Twitter.Entity.Tweet],
            replyToMappingDict: [Twitter.Entity.V2.Tweet.ID: Set<Twitter.Entity.V2.Tweet.ID>]
        ) -> ConversationNode {
            let childrenIDs = replyToMappingDict[tweet.idStr] ?? []
            let children = Array(childrenIDs)
                .compactMap { id in tweetDict[id] }
                .sorted(by: { $0.createdAt > $1.createdAt })
                .map { tweet in node(of: tweet, from: tweetDict, replyToMappingDict: replyToMappingDict) }
            return ConversationNode(tweet: tweet, children: children)
        }
        
        /// Construct a tree node of give tweet
        /// - Parameters:
        ///   - tweet: the tweet which node will be represented
        ///   - dictContent: the material for construct tree node (v2)
        ///   - replyToMappingDict: the relationship material for construct tree node
        /// - Returns: Node represented given tweet (may has children)
        static func node(
            of tweet: Twitter.Entity.V2.Tweet,
            from dictContent: Twitter.Response.V2.DictContent,
            replyToMappingDict: [Twitter.Entity.V2.Tweet.ID: Set<Twitter.Entity.V2.Tweet.ID>]
        ) -> ConversationNode {
            let childrenIDs = replyToMappingDict[tweet.id] ?? []
            let children = Array(childrenIDs)
                .compactMap { id in dictContent.tweetDict[id] }
                .sorted(by: { $0.createdAt > $1.createdAt })
                .map { tweet in node(of: tweet, from: dictContent, replyToMappingDict: replyToMappingDict) }
            return ConversationNode(tweet: tweet, children: children)
        }
        
    }
}

extension TweetConversationViewModel {
    private struct Difference<T> {
        let item: T
        let sourceIndexPath: IndexPath
        let targetIndexPath: IndexPath
        let offset: CGFloat
    }
    
    private func calculateReloadSnapshotDifference(
        navigationBar: UINavigationBar,
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<ConversationSection, ConversationItem>,
        newSnapshot: NSDiffableDataSourceSnapshot<ConversationSection, ConversationItem>
    ) -> Difference<ConversationItem>? {
        guard oldSnapshot.numberOfItems != 0 else { return nil }
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows?.sorted() else { return nil }
    
        // find index of the first visible item exclude .topLoader
        var _index: Int?
        let items = oldSnapshot.itemIdentifiers(inSection: .main)
        for (i, item) in items.enumerated() {
            if case .topLoader = item { continue }
            guard visibleIndexPaths.contains(where: { $0.row == i }) else { continue }
            
            _index = i
            break
        }
        
        guard let index = _index else  { return nil }
        let sourceIndexPath = IndexPath(row: index, section: 0)
        guard sourceIndexPath.row < oldSnapshot.itemIdentifiers(inSection: .main).count else { return nil }
        
        let item = oldSnapshot.itemIdentifiers(inSection: .main)[sourceIndexPath.row]
        guard let itemIndex = newSnapshot.itemIdentifiers(inSection: .main).firstIndex(of: item) else { return nil }
        let targetIndexPath = IndexPath(row: itemIndex, section: 0)
        
        let offset = UIViewController.tableViewCellOriginOffsetToWindowTop(in: tableView, at: sourceIndexPath, navigationBar: navigationBar)
        return Difference(
            item: item,
            sourceIndexPath: sourceIndexPath,
            targetIndexPath: targetIndexPath,
            offset: offset
        )
    }
}

extension TweetConversationViewModel {
    private func updateDeletedTweet(for items: [ConversationItem]) {
        let parentManagedObjectContext = context.managedObjectContext
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.parent = parentManagedObjectContext
        managedObjectContext.perform {
            var tweetIDs: [Twitter.Entity.V2.Tweet.ID] = []
            for item in items {
                switch item {
                case .root(let tweetObjectID):
                    guard let tweet = managedObjectContext.object(with: tweetObjectID) as? Tweet else { continue }
                    tweetIDs.append(tweet.id)
                case .reply(let tweetObjectID):
                    guard let tweet = managedObjectContext.object(with: tweetObjectID) as? Tweet else { continue }
                    tweetIDs.append(tweet.id)
                case .leaf(let tweetObjectID, _):
                    guard let tweet = managedObjectContext.object(with: tweetObjectID) as? Tweet else { continue }
                    tweetIDs.append(tweet.id)
                default:
                    continue
                }
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.deletedTweetFetchedResultsController.tweetIDs.value = tweetIDs
            }
        }
    }
}
