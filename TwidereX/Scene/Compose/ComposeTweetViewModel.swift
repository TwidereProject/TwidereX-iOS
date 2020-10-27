//
//  ComposeTweetViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import AlamofireImage
import twitter_text


final class ComposeTweetViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    var mediaServicesUploadStatusStatesDisposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let twitterTextParser = TwitterTextParser.defaultParser()
    let currentTwitterAuthentication = CurrentValueSubject<TwitterAuthentication?, Never>(nil)
    let repliedTweetObjectID: NSManagedObjectID?
    let composeContent = CurrentValueSubject<String, Never>("")
    let repliedToCellFrame = CurrentValueSubject<CGRect, Never>(.zero)

    // output
    var diffableDataSource: UITableViewDiffableDataSource<ComposeTweetSection, ComposeTweetItem>?
    let tableViewState = CurrentValueSubject<TableViewState, Never>(.fold)
    let avatarImageURL = CurrentValueSubject<URL?, Never>(nil)
    let isAvatarLockHidden = CurrentValueSubject<Bool, Never>(true)
    let twitterTextParseResults = CurrentValueSubject<TwitterTextParseResults, Never>(.init())
    let mediaServices = CurrentValueSubject<[TwitterMediaService], Never>([])
    let isComposeBarButtonEnabled = CurrentValueSubject<Bool, Never>(false)
    
    init(context: AppContext, repliedTweetObjectID: NSManagedObjectID?) {
        self.context = context
        self.repliedTweetObjectID = repliedTweetObjectID
        
        composeContent
            .map { text in self.twitterTextParser.parseTweet(text) }
            .assign(to: \.value, on: twitterTextParseResults)
            .store(in: &disposeBag)
        
        let isTweetContentValid = twitterTextParseResults
            .map { parseResult in parseResult.weightedLength > 0 && parseResult.isValid }
            
        let isMediaUploadAllSuccess = mediaServices
            .map { services in services.allSatisfy { $0.uploadStateMachineSubject.value is TwitterMediaService.UploadState.Success } }
        Publishers.CombineLatest(
            isTweetContentValid.eraseToAnyPublisher(),
            isMediaUploadAllSuccess.eraseToAnyPublisher()
        )
        .map { isTweetContentValid, isMediaUploadAllSuccess in
            isTweetContentValid && isMediaUploadAllSuccess
        }
        .assign(to: \.value, on: isComposeBarButtonEnabled)
        .store(in: &disposeBag)

        #if DEBUG
        twitterTextParseResults.print().sink { _ in }.store(in: &disposeBag)
        #endif
    }
    
}

extension ComposeTweetViewModel {
    // reply/input snap behavior
    enum TableViewState {
        case fold       // snap to input
        case expand     // snap to reply
    }
}

extension ComposeTweetViewModel {
    
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource<ComposeTweetSection, ComposeTweetItem>(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .reply(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RepliedToTweetContentTableViewCell.self), for: indexPath) as! RepliedToTweetContentTableViewCell
                self.context.managedObjectContext.performAndWait {
                    let tweet = self.context.managedObjectContext.object(with: objectID) as! Tweet
                    ComposeTweetViewModel.configure(cell: cell, tweet: tweet)
                }
                cell.framePublisher.assign(to: \.value, on: self.repliedToCellFrame).store(in: &cell.disposeBag)
                cell.conversationLinkUpper.isHidden = true
                cell.conversationLinkLower.isHidden = false
                return cell
            case .input(let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ComposeTweetContentTableViewCell.self), for: indexPath) as! ComposeTweetContentTableViewCell
                
                // set avatar
                self.avatarImageURL
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] url in
                        guard let self = self else { return }
                        let placeholderImage = UIImage
                            .placeholder(size: TimelinePostView.avatarImageViewSize, color: .systemFill)
                            .af.imageRoundedIntoCircle()
                        guard let url = url else {
                            cell.avatarImageView.image = UIImage.placeholder(color: .systemFill)
                            return
                        }
                        let filter = ScaledToSizeCircleFilter(size: ComposeTweetViewController.avatarImageViewSize)
                        cell.avatarImageView.af.setImage(
                            withURL: url,
                            placeholderImage: placeholderImage,
                            filter: filter,
                            imageTransition: .crossDissolve(0.2)
                        )
                    }
                    .store(in: &cell.disposeBag)
                self.isAvatarLockHidden.receive(on: DispatchQueue.main).assign(to: \.isHidden, on: cell.lockImageView).store(in: &cell.disposeBag)
                
                cell.conversationLinkUpper.isHidden = !attribute.hasReplyTo
                
                // self size input cell
                cell.composeText
                    .receive(on: DispatchQueue.main)
                    .sink { text in
                        tableView.beginUpdates()
                        tableView.endUpdates()
                    }
                    .store(in: &cell.disposeBag)
                cell.composeText.assign(to: \.value, on: self.composeContent).store(in: &cell.disposeBag)
                
                return cell
            case .quote(let objectID):
                fatalError("TODO:")
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<ComposeTweetSection, ComposeTweetItem>()
        snapshot.appendSections([.repliedTo, .input, .quoted])
        if let repliedTweetObjectID = self.repliedTweetObjectID {
            snapshot.appendItems([.reply(objectID: repliedTweetObjectID)], toSection: .repliedTo)
        }
        let inputAttribute = ComposeTweetItem.InputAttribute(hasReplyTo: self.repliedTweetObjectID != nil)
        snapshot.appendItems([.input(attribute: inputAttribute)], toSection: .input)
        diffableDataSource?.apply(snapshot, animatingDifferences: false)
    }
     
    func composeTweetContentTableViewCell(of tableView: UITableView) -> ComposeTweetContentTableViewCell? {
        guard let diffableDataSource = diffableDataSource else { return nil }
        let _inputItem = diffableDataSource.snapshot().itemIdentifiers.first { item in
            guard case .input = item else { return false }
            return true
        }
        guard let inputItem = _inputItem,
              let indexPath = diffableDataSource.indexPath(for: inputItem) else  { return nil }
        let cell = tableView.cellForRow(at: indexPath) as? ComposeTweetContentTableViewCell
        return cell
    }
    
}

extension ComposeTweetViewModel {
    static func configure(cell: RepliedToTweetContentTableViewCell, tweet: Tweet) {
        // set avatar
        let placeholderImage = UIImage
            .placeholder(size: TimelinePostView.avatarImageViewSize, color: .systemFill)
            .af.imageRoundedIntoCircle()
        if let avatarImageURL = tweet.author.avatarImageURL() {
            let filter = ScaledToSizeCircleFilter(size: ComposeTweetViewController.avatarImageViewSize)
            cell.timelinePostView.avatarImageView.af.setImage(
                withURL: avatarImageURL,
                placeholderImage: placeholderImage,
                filter: filter,
                imageTransition: .crossDissolve(0.2)
            )
        } else {
            cell.timelinePostView.avatarImageView.image = placeholderImage
        }
        
        // set name and username
        cell.timelinePostView.nameLabel.text = tweet.author.name
        cell.timelinePostView.usernameLabel.text = "@" + tweet.author.username
        
        // set tweet content text
        cell.timelinePostView.activeTextLabel.text = tweet.text
    }
}

// MARK: - TwitterMediaServiceDelegate
extension ComposeTweetViewModel: TwitterMediaServiceDelegate {
    func twitterMediaService(_ service: TwitterMediaService, uploadStateDidChange state: TwitterMediaService.UploadState?) {
        // trigger new output event
        mediaServices.value = mediaServices.value
    }
}
