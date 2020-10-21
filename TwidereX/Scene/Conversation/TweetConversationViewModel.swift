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
    let currentTwitterAuthentication: CurrentValueSubject<TwitterAuthentication?, Never>
    weak var conversationPostTableViewCellDelegate: ConversationPostTableViewCellDelegate?
    
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
    
    init(context: AppContext, tweetObjectID: NSManagedObjectID) {
        self.context = context
        self.rootItem = .root(tweetObjectID: tweetObjectID)
        self.currentTwitterAuthentication = CurrentValueSubject(context.authenticationService.currentActiveTwitterAutentication.value)
        super.init()
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
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<ConversationSection, ConversationItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems([rootItem], toSection: .main)
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
        cell.conversationPostView.lockImageView.isHidden = !((tweet.retweet ?? tweet).author.protected)
        
        // set name and username
        cell.conversationPostView.nameLabel.text = tweet.author.name
        cell.conversationPostView.usernameLabel.text = tweet.author.username

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
    
}

extension TweetConversationViewModel {
    public class ConversationNode {
        let tweet: Twitter.Entity.V2.Tweet
        let children: [ConversationNode]
        
        init(tweet: Twitter.Entity.V2.Tweet, children: [ConversationNode]) {
            self.tweet = tweet
            self.children = children
        }
        
        static func leafs(for tweetID: Twitter.Entity.V2.Tweet.ID, from content: Twitter.API.RecentSearch.Content) -> [ConversationNode] {
            let tweets = [content.data, content.includes?.tweets].compactMap { $0 }.flatMap { $0 }
            let dictContent = Twitter.Response.V2.DictContent(
                tweets: tweets,
                users: content.includes?.users ?? [],
                media: content.includes?.media ?? []
            )
            
            var roots: [ConversationNode] = []
            for tweet in tweets {
                guard let referencedRepliedToTweet = tweet.referencedTweets?.first(where: { $0.type == .repliedTo }),
                      let replyToID = referencedRepliedToTweet.id else {
                    continue
                }
                guard replyToID == tweetID else { continue }
                print(tweet.text)
            }
            return roots
        }
        
        static func node(of tweet: Twitter.Entity.V2.Tweet, from dictContent: Twitter.Response.V2.DictContent) -> ConversationNode {
            fatalError()
        }
    }
}
