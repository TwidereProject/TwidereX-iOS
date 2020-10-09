//
//  TweetConversationViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import UIKit
import CoreData
import CoreDataStack
import AlamofireImage
import Kanna

final class TweetConversationViewModel: NSObject {
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    // input
    let context: AppContext
    let rootItem: ConversationItem.RootItem
    weak var conversationPostTableViewCellDelegate: ConversationPostTableViewCellDelegate?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ConversationSection, ConversationItem>?
    
    init(context: AppContext, rootItem: ConversationItem.RootItem) {
        self.context = context
        self.rootItem = rootItem
    }
    
}

extension TweetConversationViewModel {
    
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .root(let item):
                switch item {
                case .objectID(let objectID):
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ConversationPostTableViewCell.self), for: indexPath) as! ConversationPostTableViewCell
                    let managedObjectContext = self.context.managedObjectContext
                    managedObjectContext.performAndWait {
                        let tweet = managedObjectContext.object(with: objectID) as! Tweet
                        TweetConversationViewModel.configure(cell: cell, tweetObject: tweet)
                    }
                    cell.delegate = self.conversationPostTableViewCellDelegate
                    return cell
                case .entity(let tweet):
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ConversationPostTableViewCell.self), for: indexPath) as! ConversationPostTableViewCell
                    TweetConversationViewModel.configure(cell: cell, tweetObject: tweet)
                    cell.delegate = self.conversationPostTableViewCellDelegate
                    return cell
                }
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<ConversationSection, ConversationItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems([.root(rootItem)], toSection: .main)
        diffableDataSource?.apply(snapshot)
    }
    
    static func configure(cell: ConversationPostTableViewCell, tweetObject tweet: TweetInterface) {
        // set avatar
        if let avatarImageURL = tweet.userObject.avatarImageURL() {
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
        
        // set name and username
        cell.conversationPostView.nameLabel.text = tweet.userObject.name ?? " "
        cell.conversationPostView.usernameLabel.text = tweet.userObject.screenName.flatMap { "@" + $0 } ?? " "

        // set text
        cell.conversationPostView.activeTextLabel.text = tweet.text
        
        // set quote
        let quote = tweet.quoteObject
        if let quote = quote {
            // set avatar
            if let avatarImageURL = quote.userObject.avatarImageURL() {
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
            cell.conversationPostView.quotePostView.nameLabel.text = quote.userObject.name
            cell.conversationPostView.quotePostView.usernameLabel.text = quote.userObject.screenName.flatMap { "@" + $0 }
            
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
        let placeFullName = tweet.place.flatMap { $0.fullName } ?? nil
        cell.conversationPostView.geoLabel.text = placeFullName
        cell.conversationPostView.geoMetaContainerStackView.isHidden = placeFullName == nil
        
        // set date
        cell.conversationPostView.dateLabel.text = TweetConversationViewModel.dateFormatter.string(from: tweet.createdAt)
        
        // set status
        if let retweetCount = tweet.retweetCountInt, retweetCount > 0 {
            cell.conversationPostView.retweetPostStatusView.countLabel.text = String(retweetCount)
            cell.conversationPostView.retweetPostStatusView.statusLabel.text = retweetCount > 1 ? "Retweets" : "Retweet"
            cell.conversationPostView.retweetPostStatusView.isHidden = false
        } else {
            cell.conversationPostView.retweetPostStatusView.isHidden = true
        }
        // TODO: quote status
        cell.conversationPostView.quotePostStatusView.isHidden = true
        if let favoriteCount = tweet.favoriteCountInt, favoriteCount > 0 {
            cell.conversationPostView.likePostStatusView.countLabel.text = String(favoriteCount)
            cell.conversationPostView.likePostStatusView.statusLabel.text = favoriteCount > 1 ? "Likes" : "Like"
            cell.conversationPostView.likePostStatusView.isHidden = false
        } else {
            cell.conversationPostView.likePostStatusView.isHidden = true
        }
        
        // set source
        cell.conversationPostView.sourceLabel.text = {
            guard let sourceHTML = tweet.source, let html = try? HTML(html: sourceHTML, encoding: .utf8) else { return nil }
            return html.text
        }()
    }
    
}