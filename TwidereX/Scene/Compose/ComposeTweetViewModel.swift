//
//  ComposeTweetViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-22.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import CoreLocation
import CoreData
import CoreDataStack
import AlamofireImage
import TwitterAPI
import twitter_text

final class ComposeTweetViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    var mediaServicesUploadStatusStatesDisposeBag = Set<AnyCancellable>()
    let locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        if #available(iOS 14.0, *) {
            locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        } else {
            // Fallback on earlier versions
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        }
        return locationManager
    }()
    
    // input
    let context: AppContext
    let twitterTextParser = TwitterTextParser.defaultParser()
    let repliedTweetObjectID: NSManagedObjectID?
    let composeContent = CurrentValueSubject<String, Never>("")
    let repliedToCellFrame = CurrentValueSubject<CGRect, Never>(.zero)

    // output
    var diffableDataSource: UITableViewDiffableDataSource<ComposeTweetSection, ComposeTweetItem>!
    var mediaDiffableDataSource: UICollectionViewDiffableDataSource<ComposeTweetMediaSection, ComposeTweetMediaItem>!
    let tableViewState = CurrentValueSubject<TableViewState, Never>(.fold)
    let avatarImageURL = CurrentValueSubject<URL?, Never>(nil)
    // let isAvatarLockHidden = CurrentValueSubject<Bool, Never>(true)
    let isVerifiedBadgekHidden = CurrentValueSubject<Bool, Never>(true)
    let twitterTextParseResults = CurrentValueSubject<TwitterTextParseResults, Never>(.init())
    let mediaServices = CurrentValueSubject<[TwitterMediaService], Never>([])
    let isComposeBarButtonEnabled = CurrentValueSubject<Bool, Never>(false)
    let isCameraToolbarButtonEnabled = CurrentValueSubject<Bool, Never>(true)
    let isRequestLocationMarking = CurrentValueSubject<Bool, Never>(false)
    let isLocationServicesEnabled = CurrentValueSubject<Bool, Never>(false)
    let currentLocation = CurrentValueSubject<CLLocation?, Never>(nil)
    let latestPlace = CurrentValueSubject<Twitter.Entity.Place?, Never>(nil)
    let currentPlace = CurrentValueSubject<Twitter.Entity.Place?, Never>(nil)
    
    init(context: AppContext, repliedTweetObjectID: NSManagedObjectID?) {
        self.context = context
        self.repliedTweetObjectID = repliedTweetObjectID
        super.init()
        
        composeContent
            .map { text in self.twitterTextParser.parseTweet(text) }
            .assign(to: \.value, on: twitterTextParseResults)
            .store(in: &disposeBag)
        
        let isTweetContentEmpty = twitterTextParseResults
            .map { parseResult in parseResult.weightedLength == 0 }
        let isTweetContentValid = twitterTextParseResults
            .map { parseResult in parseResult.isValid }
        let isMediaEmpty = mediaServices
            .map { $0.isEmpty }
        let isMediaUploadAllSuccess = mediaServices
            .map { services in services.allSatisfy { $0.uploadStateMachineSubject.value is TwitterMediaService.UploadState.Success } }
        Publishers.CombineLatest4(
            isTweetContentValid.eraseToAnyPublisher(),
            isTweetContentEmpty.eraseToAnyPublisher(),
            isMediaEmpty.eraseToAnyPublisher(),
            isMediaUploadAllSuccess.eraseToAnyPublisher()
        )
        .map { isTweetContentValid, isTweetContentEmpty, isMediaEmpty, isMediaUploadAllSuccess in
            if isMediaEmpty {
                return isTweetContentValid && !isTweetContentEmpty
            } else {
                return isTweetContentValid && isMediaUploadAllSuccess
            }
        }
        .assign(to: \.value, on: isComposeBarButtonEnabled)
        .store(in: &disposeBag)
        
        mediaServices
            .map { services -> Bool in
                return services.count < 4
            }
            .assign(to: \.value, on: isCameraToolbarButtonEnabled)
            .store(in: &disposeBag)
        
        locationManager.delegate = self
        isLocationServicesEnabled.value = CLLocationManager.locationServicesEnabled()
        isRequestLocationMarking
            .sink { [weak self] isRequestLocationMarking in
                guard let self = self else { return }
                if isRequestLocationMarking {
                    self.requestLocationMarking()
                } else {
                    self.cancelLocationMarking()
                }
            }
            .store(in: &disposeBag)

        #if DEBUG
        twitterTextParseResults.print().sink { _ in }.store(in: &disposeBag)
        #endif
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        locationManager.stopUpdatingLocation()
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
                    .sink { url in
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
                self.isVerifiedBadgekHidden.receive(on: DispatchQueue.main).assign(to: \.isHidden, on: cell.verifiedBadgeImageView).store(in: &cell.disposeBag)
                
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
    
        // set protect locker
        cell.timelinePostView.lockImageView.isHidden = !tweet.author.protected
        
        // set name and username
        cell.timelinePostView.nameLabel.text = tweet.author.name
        cell.timelinePostView.usernameLabel.text = "@" + tweet.author.username
        
        // set tweet content text
        cell.timelinePostView.activeTextLabel.text = tweet.text
    }
}

extension ComposeTweetViewModel {
    
    func setupDiffableDataSource(for mediaCollectionView: UICollectionView) {
        mediaDiffableDataSource = UICollectionViewDiffableDataSource(collectionView: mediaCollectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ComposeTweetMediaCollectionViewCell.self), for: indexPath) as! ComposeTweetMediaCollectionViewCell
            let imageViewSize = CGSize(width: 56, height: 56)
            let scale = collectionView.window?.screen.scale ?? UIScreen.main.scale
            let placehoderImage = UIImage.placeholder(size: imageViewSize, color: .systemFill)
            if case let .media(service) = item {
                switch service.payload {
                case .image(let url):
                    let imageData = try? Data(contentsOf: url)
                    let image = imageData.flatMap { UIImage(data: $0, scale: scale) } ?? placehoderImage
                    image.af.inflate()
                    let imageFilter = AspectScaledToFillSizeWithRoundedCornersFilter(
                        size: imageViewSize,
                        radius: 8.0,
                        divideRadiusByImageScale: false
                    )
                    let filteredImage = imageFilter.filter(image)
                    cell.imageView.image = filteredImage
                    
                default:
                    // TODO:
                    break
                }
                
                cell.overlayBlurVisualEffectView.layer.masksToBounds = true
                cell.overlayBlurVisualEffectView.layer.cornerRadius = 8.0
                
                service.uploadStateMachineSubject
                    .receive(on: DispatchQueue.main)
                    .sink { state in
                        guard let state = state else { return }
                        switch state {
                        case is TwitterMediaService.UploadState.Init,
                             is TwitterMediaService.UploadState.Append,
                             is TwitterMediaService.UploadState.Finalize,
                             is TwitterMediaService.UploadState.FinalizePending:
                            UIView.animate(withDuration: 0.3) {
                                cell.overlayBlurVisualEffectView.alpha = 0.5
                            }
                            cell.uploadActivityIndicatorView.startAnimating()
                        case is TwitterMediaService.UploadState.Success:
                            UIView.animate(withDuration: 0.3) {
                                cell.overlayBlurVisualEffectView.alpha = 0.0
                            }
                        case is TwitterMediaService.UploadState.Fail:
                            // TODO:
                            UIView.animate(withDuration: 0.3) {
                                cell.overlayBlurVisualEffectView.alpha  = 0.5
                            }
                        default:
                            break
                        }
                    }
                    .store(in: &cell.disposeBag)
            } else {
                assertionFailure()
            }
            return cell
        }
    }
    
}

extension ComposeTweetViewModel {

    var authorizationStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            // Fallback on earlier versions
            return CLLocationManager.authorizationStatus()
        }
    }
    
    func requestLocationAuthorizationIfNeeds(presentingViewController: UIViewController) -> Bool {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        switch authorizationStatus {
        case .notDetermined:
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

// MARK: - TwitterMediaServiceDelegate
extension ComposeTweetViewModel: TwitterMediaServiceDelegate {
    func twitterMediaService(_ service: TwitterMediaService, uploadStateDidChange state: TwitterMediaService.UploadState?) {
        // trigger new output event
        mediaServices.value = mediaServices.value
    }
}

// MARK: - CLLocationManagerDelegate
extension ComposeTweetViewModel: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        os_log("%{public}s[%{public}ld], %{public}s: status: %s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: status))

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        os_log("%{public}s[%{public}ld], %{public}s: status", ((#file as NSString).lastPathComponent), #line, #function, String(describing: manager.authorizationStatus))
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        currentLocation.value = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    
}
