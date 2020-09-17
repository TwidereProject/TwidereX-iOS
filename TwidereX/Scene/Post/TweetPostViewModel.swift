//
//  TweetPostViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-16.
//

import UIKit
import CoreData
import CoreDataStack
import AlamofireImage
import Kanna

final class TweetPostViewModel: NSObject {
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    // input
    let context: AppContext
    let tweet: Tweet
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<TweetPostDetailSection, TweetPostDetailItem>?
    
    init(context: AppContext, tweet: Tweet) {
        self.context = context
        self.tweet = tweet
    }
    
}

extension TweetPostViewModel {
    
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .tweet(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TweetPostDetailTableViewCell.self), for: indexPath) as! TweetPostDetailTableViewCell
                let managedObjectContext = self.context.managedObjectContext
                managedObjectContext.performAndWait {
                    let tweet = managedObjectContext.object(with: objectID) as! Tweet
                    TweetPostViewModel.configure(cell: cell, tweet: tweet)
                }
                return cell
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<TweetPostDetailSection, TweetPostDetailItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems([.tweet(objectID: tweet.objectID)], toSection: .main)
        diffableDataSource?.apply(snapshot)
    }
    
    static func configure(cell: TweetPostDetailTableViewCell, tweet: Tweet) {
        // set avatar
//        if let avatarImageURL = tweet.user.avatarImageURL() {
//            let placeholderImage = UIImage
//                .placeholder(size: TweetPostDetailTableViewCell.avatarImageViewSize, color: .systemFill)
//                .af.imageRoundedIntoCircle()
//            let filter = ScaledToSizeCircleFilter(size: TweetPostDetailTableViewCell.avatarImageViewSize)
//            cell.avatarImageView.af.setImage(
//                withURL: avatarImageURL,
//                placeholderImage: placeholderImage,
//                filter: filter,
//                imageTransition: .crossDissolve(0.2)
//            )
//        } else {
//            assertionFailure()
//        }
//        
//        // set name and username
//        cell.nameLabel.text = tweet.user.name ?? " "
//        cell.usernameLabel.text = tweet.user.screenName.flatMap { "@" + $0 } ?? " "
//        
//        // set text
//        cell.activeTextLabel.text = tweet.text
//        
//        // set quote
//        let quote = tweet.quote
//        if let quote = quote {
//            // set avatar
//            if let avatarImageURL = quote.user.avatarImageURL() {
//                let placeholderImage = UIImage
//                    .placeholder(size: TweetPostDetailTableViewCell.avatarImageViewSize, color: .systemFill)
//                    .af.imageRoundedIntoCircle()
//                let filter = ScaledToSizeCircleFilter(size: TweetPostDetailTableViewCell.avatarImageViewSize)
//                cell.quoteView.avatarImageView.af.setImage(
//                    withURL: avatarImageURL,
//                    placeholderImage: placeholderImage,
//                    filter: filter,
//                    imageTransition: .crossDissolve(0.2)
//                )
//            } else {
//                assertionFailure()
//            }
//            
//            // set name and username
//            cell.quoteView.nameLabel.text = quote.user.name
//            cell.quoteView.usernameLabel.text = quote.user.screenName.flatMap { "@" + $0 }
//            
//            // set date
//            let createdAt = quote.createdAt
//            cell.quoteView.dateLabel.text = createdAt.shortTimeAgoSinceNow
//            cell.quoteDateLabelUpdateSubscription = Timer.publish(every: 1, on: .main, in: .default)
//                .autoconnect()
//                .sink { _ in
//                    // do not use core date entity in this run loop
//                    cell.quoteView.dateLabel.text = createdAt.shortTimeAgoSinceNow
//                }
//            
//            // set text
//            cell.quoteView.activeTextLabel.text = quote.text
//        }
//        cell.tweetQuoteContainerStackView.isHidden = quote == nil
//        
//        // set geo
//        let placeFullName = tweet.place.flatMap { $0.fullName } ?? nil
//        cell.geoLabel.text = placeFullName
//        cell.tweetGeoMetaContainerStackView.isHidden = placeFullName == nil
//        
//        // set date
//        cell.dateLabel.text = TweetPostViewModel.dateFormatter.string(from: tweet.createdAt)
//        
//        // set source
//        cell.sourceLabel.text = {
//            guard let sourceHTML = tweet.source,
//                  let html = try? HTML(html: sourceHTML, encoding: .utf8) else {
//                return nil
//            }
//            
//            return html.text
//        }()
    }
    
}
