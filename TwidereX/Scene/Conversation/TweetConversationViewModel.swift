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
    let rootItem: ConversationItem
    weak var conversationPostTableViewCellDelegate: ConversationPostTableViewCellDelegate?
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ConversationSection, ConversationItem>?
    
    init(context: AppContext, tweetObjectID: NSManagedObjectID) {
        self.context = context
        self.rootItem = .root(objectID: tweetObjectID)
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
        if let avatarImageURL = tweet.user.avatarImageURL() {
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
        cell.conversationPostView.lockImageView.isHidden = !((tweet.retweet ?? tweet).user.protected)
        
        // set name and username
        cell.conversationPostView.nameLabel.text = tweet.user.name ?? " "
        cell.conversationPostView.usernameLabel.text = tweet.user.screenName.flatMap { "@" + $0 } ?? " "

        // set text
        cell.conversationPostView.activeTextLabel.text = tweet.text
        
        // set quote
        let quote = tweet.quote
        if let quote = quote {
            // set avatar
            if let avatarImageURL = quote.user.avatarImageURL() {
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
            cell.conversationPostView.quotePostView.nameLabel.text = quote.user.name
            cell.conversationPostView.quotePostView.usernameLabel.text = quote.user.screenName.flatMap { "@" + $0 }
            
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
        if let retweetCount = tweet.retweetCount.flatMap({ Int(truncating: $0) }), retweetCount > 0 {
            cell.conversationPostView.retweetPostStatusView.countLabel.text = String(retweetCount)
            cell.conversationPostView.retweetPostStatusView.statusLabel.text = retweetCount > 1 ? "Retweets" : "Retweet"
            cell.conversationPostView.retweetPostStatusView.isHidden = false
        } else {
            cell.conversationPostView.retweetPostStatusView.isHidden = true
        }
        // TODO: quote status
        cell.conversationPostView.quotePostStatusView.isHidden = true
        if let favoriteCount = tweet.favoriteCount.flatMap({ Int(truncating: $0) }), favoriteCount > 0 {
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
