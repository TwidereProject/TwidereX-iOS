//
//  ComposeTweetViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-21.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import Photos
import TwitterAPI
import SwiftMessages
import CropViewController

final class ComposeTweetViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ComposeTweetViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    lazy var composeBarButtonItem = UIBarButtonItem(image: Asset.ObjectTools.paperplane.image.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(ComposeTweetViewController.composeBarButtonItemPressed(_:)))
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(RepliedToTweetContentTableViewCell.self, forCellReuseIdentifier: String(describing: RepliedToTweetContentTableViewCell.self))
        tableView.register(ComposeTweetContentTableViewCell.self, forCellReuseIdentifier: String(describing: ComposeTweetContentTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private(set) lazy var mediaCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCollectionViewLayout())
        collectionView.register(ComposeTweetMediaCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ComposeTweetMediaCollectionViewCell.self))
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    let cycleCounterView = CycleCounterView()
    let tweetContentOverflowLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    let locationButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setInsets(forContentPadding: .zero, imageTitlePadding: 4)
        button.imageView?.tintColor = .secondaryLabel
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setImage(Asset.ObjectTools.mappinMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        return button
    }()
    
    let tweetToolbarView = TweetToolbarView()
    var tweetToolbarViewBottomLayoutConstraint: NSLayoutConstraint!
    let tweetToolbarBackgroundView = UIView()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ComposeTweetViewController {
    func createCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalHeight(1.0)))
        item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(60),
                                               heightDimension: .absolute(60)),
            subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        if #available(iOS 14.0, *) {
            section.contentInsetsReference = .layoutMargins
        } else {
            // Fallback on earlier versions
            // iOS 13 workaround
            section.contentInsets.leading = 16
            section.contentInsets.trailing = 16
        }
        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension ComposeTweetViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Compose.Title.compose
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Asset.Editing.xmark.image.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(ComposeTweetViewController.closeBarButtonItemPressed(_:)))
        navigationItem.leftBarButtonItem?.tintColor = .label
        navigationItem.rightBarButtonItem = composeBarButtonItem
        navigationItem.rightBarButtonItem?.tintColor = Asset.Colors.hightLight.color
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        mediaCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mediaCollectionView)
        NSLayoutConstraint.activate([
            mediaCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mediaCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mediaCollectionView.heightAnchor.constraint(equalToConstant: 60).priority(.defaultHigh),
        ])
        
        cycleCounterView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cycleCounterView)
        NSLayoutConstraint.activate([
            cycleCounterView.topAnchor.constraint(equalTo: mediaCollectionView.bottomAnchor, constant: 16),
            cycleCounterView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            cycleCounterView.widthAnchor.constraint(equalToConstant: 18).priority(.defaultHigh),
            cycleCounterView.heightAnchor.constraint(equalToConstant: 18).priority(.defaultHigh),
        ])
        
        tweetContentOverflowLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tweetContentOverflowLabel)
        NSLayoutConstraint.activate([
            tweetContentOverflowLabel.centerYAnchor.constraint(equalTo: cycleCounterView.centerYAnchor),
            tweetContentOverflowLabel.leadingAnchor.constraint(equalTo: cycleCounterView.trailingAnchor, constant: 4),
        ])
        
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locationButton)
        NSLayoutConstraint.activate([
            locationButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            locationButton.centerYAnchor.constraint(equalTo: cycleCounterView.centerYAnchor),
        ])
        
        tweetToolbarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tweetToolbarView)
        tweetToolbarViewBottomLayoutConstraint = view.bottomAnchor.constraint(equalTo: tweetToolbarView.bottomAnchor)
        NSLayoutConstraint.activate([
            tweetToolbarView.topAnchor.constraint(equalTo: cycleCounterView.bottomAnchor, constant: 16),
            tweetToolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tweetToolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tweetToolbarViewBottomLayoutConstraint,
            tweetToolbarView.heightAnchor.constraint(equalToConstant: 48),
        ])
        tweetToolbarView.preservesSuperviewLayoutMargins = true
        tweetToolbarView.delegate = self
        
        tweetToolbarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(tweetToolbarBackgroundView, belowSubview: tweetToolbarView)
        NSLayoutConstraint.activate([
            tweetToolbarBackgroundView.topAnchor.constraint(equalTo: tweetToolbarView.topAnchor),
            tweetToolbarBackgroundView.leadingAnchor.constraint(equalTo: tweetToolbarView.leadingAnchor),
            tweetToolbarBackgroundView.trailingAnchor.constraint(equalTo: tweetToolbarView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tweetToolbarBackgroundView.bottomAnchor),
        ])
        tweetToolbarBackgroundView.backgroundColor = tweetToolbarView.backgroundColor
        
        viewModel.composeTweetContentTableViewCellDelegate = self
        
        viewModel.setupDiffableDataSource(for: tableView)
        tableView.delegate = self
        tableView.dataSource = viewModel.diffableDataSource
        
        viewModel.setupDiffableDataSource(for: mediaCollectionView)
        mediaCollectionView.delegate = self
        mediaCollectionView.dataSource = viewModel.mediaDiffableDataSource
        
        viewModel.mediaServices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] services in
                guard let self = self else { return }
                var snapshot = NSDiffableDataSourceSnapshot<ComposeTweetMediaSection, ComposeTweetMediaItem>()
                snapshot.appendSections([.main])
                let items = services.map { service -> ComposeTweetMediaItem in
                    return ComposeTweetMediaItem.media(mediaService: service)
                }
                snapshot.appendItems(items, toSection: .main)
                self.viewModel.mediaDiffableDataSource.apply(snapshot, animatingDifferences: true, completion: nil)
            }
            .store(in: &disposeBag)
        
        // respond scrollView overlap change
        view.layoutIfNeeded()
        Publishers.CombineLatest3(
            KeyboardResponderService.shared.isShow.eraseToAnyPublisher(),
            KeyboardResponderService.shared.state.eraseToAnyPublisher(),
            KeyboardResponderService.shared.endFrame.eraseToAnyPublisher()
        )
        .sink(receiveValue: { [weak self] isShow, state, endFrame in
            guard let self = self else { return }
            
            guard isShow, state == .dock else {
                self.tableView.contentInset.bottom = 0.0
                self.tableView.verticalScrollIndicatorInsets.bottom = 0.0
                UIView.animate(withDuration: 0.3) {
                    self.tweetToolbarViewBottomLayoutConstraint.constant = 0.0
                    self.view.layoutIfNeeded()
                }
                return
            }

            // isShow AND dock state
            let contentFrame = self.view.convert(self.tableView.frame, to: nil)
            let padding = contentFrame.maxY - endFrame.minY
            guard padding > 0 else {
                self.tableView.contentInset.bottom = 0.0
                self.tableView.verticalScrollIndicatorInsets.bottom = 0.0
                UIView.animate(withDuration: 0.3) {
                    self.tweetToolbarViewBottomLayoutConstraint.constant = 0.0
                    self.view.layoutIfNeeded()
                }
                return
            }

            self.tableView.contentInset.bottom = padding + 16
            self.tableView.verticalScrollIndicatorInsets.bottom = padding + 16
            UIView.animate(withDuration: 0.3) {
                self.tweetToolbarViewBottomLayoutConstraint.constant = padding
                self.view.layoutIfNeeded()
            }
        })
        .store(in: &disposeBag)
        
        // set cycle counter. update compose button state
        viewModel.twitterTextParseResults
            .receive(on: DispatchQueue.main)
            .sink { [weak self] parseResult in
                guard let self = self else { return }
                let maxWeightedTweetLength = self.viewModel.twitterTextParser.configuration.maxWeightedTweetLength
                let progress = CGFloat(parseResult.weightedLength) / CGFloat(maxWeightedTweetLength)
                let strokeColor: UIColor = {
                    if progress > 1.0 {
                        return .systemRed
                    } else if progress > 0.9 {
                        return .systemOrange
                    } else {
                        return Asset.Colors.hightLight.color
                    }
                }()
                
                // update counter appearance
                UIView.animate(withDuration: 0.1) {
                    self.cycleCounterView.strokeColor.value = strokeColor
                    self.cycleCounterView.progress.value = progress
                }
                
                // update overflow label text
                let overflow = parseResult.weightedLength - maxWeightedTweetLength
                self.tweetContentOverflowLabel.text = overflow > 0 ? "-\(overflow)" : " "
            }
            .store(in: &disposeBag)
        
        // update composeBarButtonItem state
        viewModel.isComposeBarButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: composeBarButtonItem)
            .store(in: &disposeBag)
        
        // update toolbar
        viewModel.isCameraToolbarButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: tweetToolbarView.cameraButton)
            .store(in: &disposeBag)
        
        viewModel.isLocationServicesEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: tweetToolbarView.locationButton)
            .store(in: &disposeBag)
        
        viewModel.isRequestLocationMarking
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRequestLocationMarking in
                guard let self = self else { return }
                let tintColor = isRequestLocationMarking ? Asset.Colors.hightLight.color : UIColor.secondaryLabel
                UIView.animate(withDuration: 0.3) {
                    self.tweetToolbarView.locationButton.imageView?.tintColor = tintColor
                    self.locationButton.alpha = isRequestLocationMarking ? 1.0 : 0.0
                }
            }
            .store(in: &disposeBag)
            
        Publishers.CombineLatest(
            viewModel.isRequestLocationMarking.eraseToAnyPublisher(),
            viewModel.currentLocation.eraseToAnyPublisher()
        )
        .map { [weak self] isRequestLocationMarking, currentLocation -> AnyPublisher<Twitter.Entity.Place?, Never> in
            guard let self = self else {
                return Just(nil).eraseToAnyPublisher()
            }
            guard let activeTwitterAuthenticationBox = self.viewModel.context.authenticationService.activeTwitterAuthenticationBox.value else {
                return Just(nil).eraseToAnyPublisher()
            }
            guard isRequestLocationMarking, let currentLocation = currentLocation else {
                return Just(nil).eraseToAnyPublisher()
            }
            
            if let place = self.viewModel.latestPlace.value {
                return Just(place).eraseToAnyPublisher()
            }
            
            return self.context.apiService.geoSearch(
                latitude: currentLocation.coordinate.latitude,
                longitude: currentLocation.coordinate.longitude,
                granularity: "city",
                twitterAuthenticationBox: activeTwitterAuthenticationBox
            )
            .map { $0.value.first }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
        }
        .switchToLatest()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] place in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: current place: %s", ((#file as NSString).lastPathComponent), #line, #function, place?.fullName ?? "<nil>")
            if let place = place {
                self.viewModel.latestPlace.value = place
            }
            self.viewModel.currentPlace.value = place
            self.locationButton.setTitle(place?.fullName ?? "", for: .normal)
        }
        .store(in: &disposeBag)
        
        // setup tableView snap behavior
        Publishers.CombineLatest(
            viewModel.repliedToCellFrame.eraseToAnyPublisher(),
            viewModel.tableViewState.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] repliedToCellFrame, tableViewState in
            guard let self = self else { return }
            guard repliedToCellFrame != .zero else { return }
            switch tableViewState {
            case .fold:
                self.tableView.contentInset.top = -repliedToCellFrame.height
            case .expand:
                self.tableView.contentInset.top = 0
            }
        }
        .store(in: &disposeBag)
        
        context.authenticationService.activeAuthenticationIndex
            .assign(to: \.value, on: viewModel.activeAuthenticationIndex)
            .store(in: &disposeBag)
        
        // TODO:
        tweetToolbarView.gifButton.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let cell = self.viewModel.composeTweetContentTableViewCell(of: self.tableView) else { return }
        cell.composeTextView.becomeFirstResponder()
    }
    
}

extension ComposeTweetViewController {
    
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func composeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        // prepare authentication
        guard let activeTwitterAuthenticationBox = self.viewModel.context.authenticationService.activeTwitterAuthenticationBox.value else {
            assertionFailure()
            return
        }
        
        let mediaIDs: [String]? = {
            let mediaIDs = viewModel.mediaServices.value.compactMap { $0.mediaID }
            guard !mediaIDs.isEmpty else { return nil }
            return mediaIDs
        }()
        let feedbackGenerator = UINotificationFeedbackGenerator()
        let excludeReplyUserIDs: [TwitterUser.ID]? = {
            let ids = viewModel.excludeReplyUserInfos.value.map { $0.0 }
            return ids.isEmpty ? nil : ids
        }()
        context.apiService.tweet(
            content: viewModel.composeContent.value,
            mediaIDs: mediaIDs,
            placeID: viewModel.currentPlace.value?.id,
            replyToTweetObjectID: viewModel.repliedTweetObjectID,
            excludeReplyUserIDs: excludeReplyUserIDs,
            twitterAuthenticationBox: activeTwitterAuthenticationBox
        )
        .receive(on: DispatchQueue.main)
        .handleEvents(receiveSubscription: { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }, receiveOutput: { _ in
            feedbackGenerator.prepare()
        })
        .sink { completion in
            switch completion {
            case .failure(let error):
                os_log("%{public}s[%{public}ld], %{public}s: tweet fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                var config = SwiftMessages.defaultConfig
                config.duration = .seconds(seconds: 3)
                config.interactiveHide = true
                let bannerView = NotifyBannerView()
                bannerView.configure(for: .error)
                bannerView.titleLabel.text = L10n.Common.Alerts.TweetFail.title
                bannerView.messageLabel.text = L10n.Common.Alerts.TweetFail.message
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    SwiftMessages.show(config: config, view: bannerView)
                    feedbackGenerator.notificationOccurred(.error)
                }
            case .finished:
                os_log("%{public}s[%{public}ld], %{public}s: tweet success", ((#file as NSString).lastPathComponent), #line, #function)
                var config = SwiftMessages.defaultConfig
                config.duration = .seconds(seconds: 3)
                config.interactiveHide = true
                let bannerView = NotifyBannerView()
                bannerView.configure(for: .normal)
                bannerView.titleLabel.text = L10n.Common.Alerts.TweetSent.title
                bannerView.messageLabel.isHidden = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    SwiftMessages.show(config: config, view: bannerView)
                    feedbackGenerator.notificationOccurred(.success)
                }
            }
        } receiveValue: { response in
            // do nothing
        }
        .store(in: &context.disposeBag)
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ComposeTweetViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            return .fullScreen
        default:
            return .pageSheet
        }
    }
    
}

// MARK: - UIScrollViewDelegate
extension ComposeTweetViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView === tableView else { return }

        let repliedToCellFrame = viewModel.repliedToCellFrame.value
        guard repliedToCellFrame != .zero else { return }
        let throttle = viewModel.repliedToCellFrame.value.height - scrollView.adjustedContentInset.top
        // print("\(throttle) - \(scrollView.contentOffset.y)")

        switch viewModel.tableViewState.value {
        case .fold:
            if scrollView.contentOffset.y < throttle {
                viewModel.tableViewState.value = .expand
            }
            os_log("%{public}s[%{public}ld], %{public}s: fold", ((#file as NSString).lastPathComponent), #line, #function)

        case .expand:
            if scrollView.contentOffset.y > -44 {
                viewModel.tableViewState.value = .fold
                os_log("%{public}s[%{public}ld], %{public}s: expand", ((#file as NSString).lastPathComponent), #line, #function)
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension ComposeTweetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - TweetToolbarViewDelegate
extension ComposeTweetViewController: TweetToolbarViewDelegate {
    
    func tweetToolbarView(_ tweetToolbarView: TweetToolbarView, cameraButtonDidPressed sender: UIButton) {
        let photoSourcePickAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            photoSourcePickAlertController.addAction(UIAlertAction(title: L10n.Common.Controls.Actions.takePhoto.localizedCapitalized, style: .default, handler: { [weak self] _ in
                self?.showImagePicker(sourceType: .camera)
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            photoSourcePickAlertController.addAction(UIAlertAction(title: L10n.Common.Controls.Ios.photoLibrary, style: .default, handler: { [weak self] _ in
                self?.showImagePicker(sourceType: .photoLibrary)
            }))
        }
        photoSourcePickAlertController.addAction(UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil))
        photoSourcePickAlertController.popoverPresentationController?.sourceView = sender
        
        UIView.animate(withDuration: 0.3) {
            self.tweetToolbarViewBottomLayoutConstraint.constant = 0.0
            self.view.layoutIfNeeded()
        }
        present(photoSourcePickAlertController, animated: true, completion: nil)
    }
    
    func tweetToolbarView(_ tweetToolbarView: TweetToolbarView, gifButtonDidPressed sender: UIButton) {
        // TODO:
    }
    
    func tweetToolbarView(_ tweetToolbarView: TweetToolbarView, atButtonDidPressed sender: UIButton) {
        let items = viewModel.diffableDataSource.snapshot().itemIdentifiers
        for item in items {
            guard case let .input(attribute) = item else { continue }
            guard let indexPath = viewModel.diffableDataSource.indexPath(for: item) else { continue }
            guard let cell = tableView.cellForRow(at: indexPath) as? ComposeTweetContentTableViewCell else { continue }
            
            cell.composeTextView.insertText("@")
        }
    }
    
    func tweetToolbarView(_ tweetToolbarView: TweetToolbarView, topicButtonDidPressed sender: UIButton) {
        let items = viewModel.diffableDataSource.snapshot().itemIdentifiers
        for item in items {
            guard case let .input(attribute) = item else { continue }
            guard let indexPath = viewModel.diffableDataSource.indexPath(for: item) else { continue }
            guard let cell = tableView.cellForRow(at: indexPath) as? ComposeTweetContentTableViewCell else { continue }
            
            cell.composeTextView.insertText("#")
        }
    }
    
    func tweetToolbarView(_ tweetToolbarView: TweetToolbarView, locationButtonDidPressed sender: UIButton) {
        guard viewModel.requestLocationAuthorizationIfNeeds(presentingViewController: self) else { return }
        viewModel.isRequestLocationMarking.value.toggle()
    }
    
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension ComposeTweetViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    private func showImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        guard let mediaType = info[.mediaType] as? String else { return }
        
        // TODO: check media type
        guard mediaType == "public.image" else { return }
        
        let cropViewController = CropViewController(croppingStyle: .default, image: image)
        cropViewController.delegate = self
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.modalTransitionStyle = .crossDissolve
        cropViewController.transitioningDelegate = nil
        picker.dismiss(animated: true) {
            self.present(cropViewController, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        picker.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - CropViewControllerDelegate
extension ComposeTweetViewController: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        let imagePayload = TwitterMediaService.Payload.image(image)
        let mediaService = TwitterMediaService(context: context, payload: imagePayload)
        mediaService.delegate = viewModel
        
        let value = viewModel.mediaServices.value
        viewModel.mediaServices.value = value + [mediaService]
        
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDelegate
extension ComposeTweetViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: select item at: %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
        let mediaServices = viewModel.mediaServices.value
        guard indexPath.row < mediaServices.count else { return }
        let mediaService = mediaServices[indexPath.row]
        
        let payload = mediaService.payload
        switch payload {
        case .image(let image):
            let meta = MediaPreviewViewModel.LocalImagePreviewMeta(image: image)
            let mediaPreviewViewModel = MediaPreviewViewModel(context: context, meta: meta)
            coordinator.present(scene: .mediaPreview(viewModel: mediaPreviewViewModel), from: self, transition: .custom(transitioningDelegate: mediaPreviewTransitionController))
        default:
            return
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: select item at: %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
        let mediaServices = viewModel.mediaServices.value
        guard indexPath.row < mediaServices.count else { return nil }
        let mediaService = mediaServices[indexPath.row]
        
        let payload = mediaService.payload
        switch payload {
        case .image(let image):
            return UIContextMenuConfiguration(identifier: nil) { () -> UIViewController? in
                let previewProvider = ContextMenuImagePreviewViewController()
                let contextMenuImagePreviewViewModel = ContextMenuImagePreviewViewModel(aspectRatio: image.size, thumbnail: image)
                previewProvider.viewModel = contextMenuImagePreviewViewModel
                return previewProvider
            } actionProvider: { _ -> UIMenu? in
                return UIMenu(
                    title: "",
                    image: nil,
                    children: [
                        UIAction(title: L10n.Common.Controls.Actions.preview, image: UIImage(systemName: "eye"), identifier: nil, attributes: [], state: .off, handler: { [weak self] _ in
                            guard let self = self else { return }
                            let meta = MediaPreviewViewModel.LocalImagePreviewMeta(image: image)
                            let mediaPreviewViewModel = MediaPreviewViewModel(context: self.context, meta: meta)
                            self.coordinator.present(scene: .mediaPreview(viewModel: mediaPreviewViewModel), from: self, transition: .custom(transitioningDelegate: self.mediaPreviewTransitionController))
                        }),
                        UIAction(title: L10n.Common.Controls.Actions.remove, image: UIImage(systemName: "minus.circle"), identifier: nil, attributes: .destructive, state: .off, handler: { [weak self] _ in
                            guard let self = self else { return }
                            var mediaServices = mediaServices
                            mediaServices.remove(at: indexPath.row)
                            self.viewModel.mediaServices.value = mediaServices
                        })
                    ]
                )
            }
            
        default:
            return nil
        }
    }
    
}

// MARK: - ComposeTweetContentTableViewCellDelegate
extension ComposeTweetViewController: ComposeTweetContentTableViewCellDelegate {
    func composeTweetContentTableViewCell(_ cell: ComposeTweetContentTableViewCell, mentionPickButtonDidPressed button: UIButton) {
        guard let primaryItem = viewModel.primaryMentionPickItem else { return }

        guard let authenticationBox = context.authenticationService.activeAuthenticationIndex.value else { return }
        guard let userID = authenticationBox.twitterAuthentication?.userID,
              let screenName = authenticationBox.twitterAuthentication?.screenName else { return }

        let secondaryItems = viewModel.secondaryMentionPickItems.filter { item in
            switch item {
            case .twitterUser(let username, let attribute):
                return attribute.userID != userID && username != screenName
            }
        }
        let mentionPickViewModel = MentionPickViewModel(context: context, primaryItem: primaryItem, secondaryItems: secondaryItems)
        coordinator.present(scene: .mentionPick(viewModel: mentionPickViewModel, delegate: self), from: self, transition: .modal(animated: true, completion: nil))
    }
}

// MARK: - MentionPickViewControllerDelegate
extension ComposeTweetViewController: MentionPickViewControllerDelegate {
    func mentionPickViewController(_ controller: MentionPickViewController, didUpdateMentionPickItems items: [MentionPickItem]) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let excludeReplyUserInfos = items.compactMap { item -> (TwitterUser.ID, String)? in
            switch item {
            case .twitterUser(let username, let attribute):
                guard attribute.state == .finish, !attribute.selected else { return nil }
                guard let userID = attribute.userID else { return nil }
                return (userID, username)
            }
        }
        viewModel.excludeReplyUserInfos.value = excludeReplyUserInfos
    }
}
