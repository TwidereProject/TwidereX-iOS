//
//  UserTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import UIKit
import Combine
import CoreDataStack
import TwitterAPI
import AlamofireImage

class UserTimelineViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    var diffableDataSource: UITableViewDiffableDataSource<TimelineSection, TimelineItem>?
    let context: AppContext
    let userID: CurrentValueSubject<String?, Never>
    let currentTwitterAuthentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
    weak var timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate?
    
    // output
    let userTimelineTweets = CurrentValueSubject<[Twitter.Entity.Tweet], Never>([])
    
    init(context: AppContext, userID: String?) {
        self.context = context
        self.userID = CurrentValueSubject(userID)
        
        context.authenticationService.currentActiveTwitterAutentication
            .assign(to: \.value, on: currentTwitterAuthentication)
            .store(in: &disposeBag)
        
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let userInfo: [AnyHashable : Any] = ["userID": self.userID.value ?? ""]
                NotificationCenter.default.post(name: UserTimelineViewModel.secondStepTimerTriggered, object: nil, userInfo: userInfo)
            }
            .store(in: &disposeBag)
    }
    
}

extension UserTimelineViewModel {
    private static func configure(cell: TimelinePostTableViewCell, tweet: Twitter.Entity.Tweet, userID: String) {
        configure(cell: cell, tweetInterface: tweet)
        internalConfigure(cell: cell, tweetInterface: tweet, userID: userID)
    }
    
    private static func configure(cell: TimelinePostTableViewCell, tweetInterface tweet: Twitter.Entity.Tweet) {
        HomeTimelineViewModel.configure(cell: cell, tweetInterface: tweet)
    }
    
    private static func internalConfigure(cell: TimelinePostTableViewCell, tweetInterface tweet: Twitter.Entity.Tweet, userID: String) {
        // tweet date updater
        let createdAt = (tweet.retweetObject ?? tweet).createdAt
        NotificationCenter.default.publisher(for: UserTimelineViewModel.secondStepTimerTriggered, object: nil)
            .sink { notification in
                guard let incomingUserID = notification.userInfo?["userID"] as? String,
                      incomingUserID == userID else { return }
                cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)
        
        // quote date updater
        let quote = tweet.retweetObject?.quoteObject ?? tweet.quoteObject
        if let quote = quote {
            let createdAt = quote.createdAt
            cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            NotificationCenter.default.publisher(for: UserTimelineViewModel.secondStepTimerTriggered, object: nil)
                .sink { notification in
                    guard let incomingUserID = notification.userInfo?["userID"] as? String,
                          incomingUserID == userID else { return }
                    cell.timelinePostView.quotePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
                }
                .store(in: &cell.disposeBag)
        }
    }
}

extension UserTimelineViewModel {
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource<TimelineSection, TimelineItem>(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            guard let userID = self.userID.value else { return nil }
            
            switch item {
            case .userTimelineItem(let tweet):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
                UserTimelineViewModel.configure(cell: cell, tweet: tweet, userID: userID)
                cell.delegate = self.timelinePostTableViewCellDelegate
                return cell
            default:
                return nil
            }
        }
    }
}

extension UserTimelineViewModel {
    
    enum UserTimelineError: Swift.Error {
        case invalidAuthorization
        case invalidUserID
    }
    
    func fetchLatest() -> AnyPublisher<Twitter.Response<[Twitter.Entity.Tweet]>, Error> {
        guard let authentication = currentTwitterAuthentication.value,
              let authorization = try? authentication.authorization(appSecret: .shared) else {
            return Fail(error: UserTimelineError.invalidAuthorization).eraseToAnyPublisher()
        }
        guard let userID = self.userID.value, !userID.isEmpty else {
            return Fail(error: UserTimelineError.invalidUserID).eraseToAnyPublisher()
        }
        
        return context.apiService.twitterUserTimeline(userID: userID, authorization: authorization)
    }
}

extension UserTimelineViewModel {
    private static let secondStepTimerTriggered = Notification.Name("com.twidere.twiderex.user-timeline.second-step-timer-triggered")
}
