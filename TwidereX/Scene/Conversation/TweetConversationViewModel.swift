//
//  TweetConversationViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import os.log
import UIKit
import Combine
import GameplayKit
import CoreData
import CoreDataStack
import AlamofireImage
import TwitterAPI

final class TweetConversationViewModel: NSObject {
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let rootItem: ConversationItem
    let conversationMeta = CurrentValueSubject<ConversationMeta?, Never>(nil)
    weak var contentOffsetAdjustableTimelineViewControllerDelegate: ContentOffsetAdjustableTimelineViewControllerDelegate?
    weak var tableView: UITableView?
    weak var conversationPostTableViewCellDelegate: ConversationPostTableViewCellDelegate?
    weak var timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ConversationSection, ConversationItem>?
    private(set) lazy var loadConversationStateMachine: GKStateMachine = {
        // exclude timeline middle fetcher state
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
    var conversationNodes = CurrentValueSubject<[ConversationNode], Never>([])
    var cellFrameCache = NSCache<NSNumber, NSValue>()
    
    init(context: AppContext, tweetObjectID: NSManagedObjectID) {
        self.context = context
        self.rootItem = .root(tweetObjectID: tweetObjectID)
        super.init()
        
        conversationNodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] nodes in
                guard let self = self else { return }
                guard !nodes.isEmpty else {
                    return
                }
                guard let tableView = self.tableView,
                      let navigationBar = self.contentOffsetAdjustableTimelineViewControllerDelegate?.navigationBar()
                else { return }
                
                guard let diffableDataSource = self.diffableDataSource else { return }
                let oldSnapshot = diffableDataSource.snapshot()
                
                let itemIdentifiers = oldSnapshot.itemIdentifiers
                let currentLeafAttributes: [ConversationItem.LeafAttribute] = {
                    var attributes: [ConversationItem.LeafAttribute] = []
                    for item in itemIdentifiers {
                        guard case let .leaf(_, attribute) = item else { continue }
                        attributes.append(attribute)
                    }
                    return attributes
                }()
                let currentLeafTweetIDs = currentLeafAttributes.map { $0.tweetID }
                
                let leafIDs = nodes.map { [$0.tweet.id, $0.children.first?.tweet.id].compactMap { $0} }.flatMap { $0 }
                let request = Tweet.sortedFetchRequest
                request.predicate = Tweet.predicate(idStrs: leafIDs)
                var tweetDict: [Tweet.ID: Tweet] = [:]
                do {
                    let tweets = try self.context.managedObjectContext.fetch(request)
                    for tweet in tweets {
                        tweetDict[tweet.id] = tweet
                    }
                } catch {
                    os_log("%{public}s[%{public}ld], %{public}s: fetch conversation fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    return
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
                
                var newSnapshot = NSDiffableDataSourceSnapshot<ConversationSection, ConversationItem>()
                newSnapshot.appendSections([.main])
                for item in itemIdentifiers {
                    if case .bottomLoader = item { continue }
                    newSnapshot.appendItems([item], toSection: .main)
                }
                newSnapshot.appendItems(newItems, toSection: .main)
                
                if let currentState = self.loadConversationStateMachine.currentState,
                   currentState is LoadConversationState.Idle || currentState is LoadConversationState.Loading {
                    newSnapshot.appendItems([.bottomLoader], toSection: .main)
                }
                
                guard let difference = self.calculateReloadSnapshotDifference(navigationBar: navigationBar, tableView: tableView, oldSnapshot: oldSnapshot, newSnapshot: newSnapshot) else {
                    diffableDataSource.apply(newSnapshot)
                    return
                }
                
                diffableDataSource.apply(newSnapshot, animatingDifferences: false) {
                    tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
                    tableView.contentOffset.y = tableView.contentOffset.y - difference.offset
                }

            }
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
        let conversationID: Twitter.Entity.V2.Tweet.ConversationID
        let createdAt: Date
    }
}

extension TweetConversationViewModel {
    
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .root(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ConversationPostTableViewCell.self), for: indexPath) as! ConversationPostTableViewCell
                let managedObjectContext = self.context.managedObjectContext
                managedObjectContext.performAndWait {
                    let tweet = managedObjectContext.object(with: objectID) as! Tweet
                    TweetConversationViewModel.configure(cell: cell, tweet: tweet)
                }
                cell.delegate = self.conversationPostTableViewCellDelegate
                return cell
            case .leaf(let objectID, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
                let twitterAuthenticationBox = self.context.authenticationService.activeTwitterAuthenticationBox.value
                let requestUserID = twitterAuthenticationBox?.twitterUserID ?? ""
                let managedObjectContext = self.context.managedObjectContext
                managedObjectContext.performAndWait {
                    let tweet = managedObjectContext.object(with: objectID) as! Tweet
                    TweetConversationViewModel.configure(cell: cell, tweet: tweet, requestUserID: requestUserID)
                }
                cell.conversationLinkUpper.isHidden = attribute.level == 0
                cell.conversationLinkLower.isHidden = !attribute.hasReply || attribute.level != 0
                cell.delegate = self.timelinePostTableViewCellDelegate
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
        snapshot.appendItems([rootItem, .bottomLoader], toSection: .main)
        diffableDataSource?.apply(snapshot)
    }
    
    static func configure(cell: ConversationPostTableViewCell, tweet: Tweet) {
        // set avatar
        if let avatarImageURL = tweet.author.avatarImageURL() {
            let placeholderImage = UIImage
                .placeholder(size: ConversationPostView.avatarImageViewSize, color: .systemFill)
                .af.imageRoundedIntoCircle()
            let filter = ScaledToSizeCircleFilter(size: ConversationPostView.avatarImageViewSize)
            cell.conversationPostView.avatarImageView.af.setImage(
                withURL: avatarImageURL,
                placeholderImage: placeholderImage,
                filter: filter,
                imageTransition: .crossDissolve(0.2)
            )
        } else {
            assertionFailure()
        }
        
        cell.conversationPostView.verifiedBadgeImageView.isHidden = !((tweet.retweet ?? tweet).author.verified)
        cell.conversationPostView.lockImageView.isHidden = !((tweet.retweet ?? tweet).author.protected)
        
        // set name and username
        cell.conversationPostView.nameLabel.text = tweet.author.name
        cell.conversationPostView.usernameLabel.text = "@" + tweet.author.username

        // set text
        cell.conversationPostView.activeTextLabel.text = tweet.text
        
        // set quote
        let quote = tweet.quote
        if let quote = quote {
            // set avatar
            if let avatarImageURL = quote.author.avatarImageURL() {
                let placeholderImage = UIImage
                    .placeholder(size: ConversationPostView.avatarImageViewSize, color: .systemFill)
                    .af.imageRoundedIntoCircle()
                let filter = ScaledToSizeCircleFilter(size: ConversationPostView.avatarImageViewSize)
                cell.conversationPostView.quotePostView.avatarImageView.af.setImage(
                    withURL: avatarImageURL,
                    placeholderImage: placeholderImage,
                    filter: filter,
                    imageTransition: .crossDissolve(0.2)
                )
            } else {
                assertionFailure()
            }
            
            // set name and username
            cell.conversationPostView.quotePostView.nameLabel.text = quote.author.name
            cell.conversationPostView.quotePostView.usernameLabel.text = "@\(quote.author.username)"
            
            // set date
//            let createdAt = quote.createdAt
//            cell.quoteView.dateLabel.text = createdAt.shortTimeAgoSinceNow
//            cell.quoteDateLabelUpdateSubscription = Timer.publish(every: 1, on: .main, in: .default)
//                .autoconnect()
//                .sink { _ in
//                    // do not use core date entity in this run loop
//                    cell.quoteView.dateLabel.text = createdAt.shortTimeAgoSinceNow
//                }
            
            // set text
            cell.conversationPostView.quotePostView.activeTextLabel.text = quote.text
        }
        cell.conversationPostView.quotePostView.isHidden = quote == nil
        
        // set geo
        let placeFullName = tweet.place?.fullname ?? nil
        cell.conversationPostView.geoLabel.text = placeFullName
        cell.conversationPostView.geoMetaContainerStackView.isHidden = placeFullName == nil
        
        // set date
        cell.conversationPostView.dateLabel.text = TweetConversationViewModel.dateFormatter.string(from: tweet.createdAt)
        
        // set status
        if let retweetCount = tweet.metrics?.retweetCount.flatMap({ Int(truncating: $0) }), retweetCount > 0 {
            cell.conversationPostView.retweetPostStatusView.countLabel.text = String(retweetCount)
            cell.conversationPostView.retweetPostStatusView.statusLabel.text = retweetCount > 1 ? "Retweets" : "Retweet"
            cell.conversationPostView.retweetPostStatusView.isHidden = false
        } else {
            cell.conversationPostView.retweetPostStatusView.isHidden = true
        }
        // TODO: quote status
        cell.conversationPostView.quotePostStatusView.isHidden = true
        if let favoriteCount = tweet.metrics?.likeCount.flatMap({ Int(truncating: $0) }), favoriteCount > 0 {
            cell.conversationPostView.likePostStatusView.countLabel.text = String(favoriteCount)
            cell.conversationPostView.likePostStatusView.statusLabel.text = favoriteCount > 1 ? "Likes" : "Like"
            cell.conversationPostView.likePostStatusView.isHidden = false
        } else {
            cell.conversationPostView.likePostStatusView.isHidden = true
        }
        
        // set source
        cell.conversationPostView.sourceLabel.text = tweet.source
    }
    
    static func configure(cell: TimelinePostTableViewCell, tweet: Tweet, requestUserID: String) {
        HomeTimelineViewModel.configure(cell: cell, tweet: tweet, requestUserID: requestUserID)
    }
    
}

extension TweetConversationViewModel {
    public class ConversationNode {
        let tweet: Twitter.Entity.V2.Tweet
        let children: [ConversationNode]
        
        init(tweet: Twitter.Entity.V2.Tweet, children: [ConversationNode]) {
            self.tweet = tweet
            self.children = children
        }
        
        static func leafs(for tweetID: Twitter.Entity.V2.Tweet.ID, from content: Twitter.API.V2.RecentSearch.Content) -> [ConversationNode] {
            let tweets = [content.data, content.includes?.tweets].compactMap { $0 }.flatMap { $0 }
            let dictContent = Twitter.Response.V2.DictContent(
                tweets: tweets,
                users: content.includes?.users ?? [],
                media: content.includes?.media ?? []
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
            
            var leafs: [ConversationNode] = []
            let replies = Array(replyToMappingDict[tweetID] ?? Set())
                .compactMap { dictContent.tweetDict[$0] }
                .sorted(by: { $0.createdAt > $1.createdAt })
            for reply in replies {
                let leaf = node(of: reply, from: dictContent, replyToMappingDict: replyToMappingDict)
                leafs.append(leaf)
            }
            
            return leafs
        }
        
        static func node(of tweet: Twitter.Entity.V2.Tweet, from dictContent: Twitter.Response.V2.DictContent, replyToMappingDict: [Twitter.Entity.V2.Tweet.ID: Set<Twitter.Entity.V2.Tweet.ID>]) -> ConversationNode {
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
    
    private func calculateReloadSnapshotDifference<T: Hashable>(
        navigationBar: UINavigationBar,
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<ConversationSection, T>,
        newSnapshot: NSDiffableDataSourceSnapshot<ConversationSection, T>
    ) -> Difference<T>? {
        guard oldSnapshot.numberOfItems != 0 else { return nil }
        
        // old snapshot not empty. set source index path to first item if not match
        let sourceIndexPath = UIViewController.topVisibleTableViewCellIndexPath(in: tableView, navigationBar: navigationBar) ?? IndexPath(row: 0, section: 0)
        
        guard sourceIndexPath.row < oldSnapshot.itemIdentifiers(inSection: .main).count else { return nil }
        
        let timelineItem = oldSnapshot.itemIdentifiers(inSection: .main)[sourceIndexPath.row]
        guard let itemIndex = newSnapshot.itemIdentifiers(inSection: .main).firstIndex(of: timelineItem) else { return nil }
        let targetIndexPath = IndexPath(row: itemIndex, section: 0)
        
        let offset = UIViewController.tableViewCellOriginOffsetToWindowTop(in: tableView, at: sourceIndexPath, navigationBar: navigationBar)
        return Difference(
            item: timelineItem,
            sourceIndexPath: sourceIndexPath,
            targetIndexPath: targetIndexPath,
            offset: offset
        )
    }
}
