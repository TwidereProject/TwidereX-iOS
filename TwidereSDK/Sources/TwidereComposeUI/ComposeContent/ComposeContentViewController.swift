//
//  ComposeContentViewController.swift
//  
//
//  Created by MainasuK on 2021/11/17.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import PhotosUI
import TwitterSDK
import TwidereCore
import TwidereAsset
import CropViewController
import KeyboardLayoutGuide

public final class ComposeContentViewController: UIViewController {
    
    let logger = Logger(subsystem: "ComposeContentViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    public var viewModel: ComposeContentViewModel!
        
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    let composeToolbarBackgroundView = UIView()
    let composeToolbarView = ComposeToolbarView()
}

extension ComposeContentViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        composeToolbarBackgroundView.backgroundColor = .systemBackground
        composeToolbarView.backgroundColor = .systemBackground
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView
        )
        
        composeToolbarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composeToolbarBackgroundView)
        NSLayoutConstraint.activate([
            composeToolbarBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composeToolbarBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composeToolbarBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        composeToolbarView.translatesAutoresizingMaskIntoConstraints = false
        composeToolbarView.preservesSuperviewLayoutMargins = true
        view.addSubview(composeToolbarView)
        NSLayoutConstraint.activate([
            composeToolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composeToolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Apple `keyboardLayoutGuide` has issue (FB9733654). Use KeyboardLayoutGuide package instead
            view.keyboardLayoutGuide.topAnchor.constraint(equalTo: composeToolbarView.bottomAnchor),
            composeToolbarBackgroundView.topAnchor.constraint(equalTo: composeToolbarView.topAnchor).priority(.defaultHigh),
        ])

        // bind keyboard
        composeToolbarView
            .observe(\.bounds, options: [.initial, .new]) { [weak self] toolbar, _ in
                guard let self = self else { return }
                self.viewModel.additionalSafeAreaInsets.bottom = toolbar.frame.height
                self.viewModel.viewLayoutMarginDidUpdate.send()
            }
            .store(in: &observations)
        
        // set tableView inset for keyboard
        KeyboardResponderService.configure(
            scrollView: tableView,
            layoutNeedsUpdate: {
                Publishers.CombineLatest(
                    viewModel.viewDidAppear.eraseToAnyPublisher(),
                    viewModel.viewLayoutMarginDidUpdate.eraseToAnyPublisher()
                )
                .map { _ in Void() }
                .eraseToAnyPublisher()
            }(),
            additionalSafeAreaInsets: viewModel.$additionalSafeAreaInsets.eraseToAnyPublisher()
        )
        .store(in: &disposeBag)
        
//        view.keyboardLayoutGuide.setConstraints([
//
//        ], activeWhenAwayFrom: .top)
//        view.keyboardLayoutGuide.setConstraints([
//
//        ], activeWhenNearEdge: .top)
        
        // bind toolbar
        viewModel.$textInputLimitProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self else { return }
                let strokeColor: UIColor = {
                    if progress > 1.0 {
                        return .systemRed
                    } else if progress > 0.9 {
                        return .systemOrange
                    } else {
                        return Asset.Colors.hightLight.color
                    }
                }()
                
                UIView.animate(withDuration: 0.1) { [weak self] in
                    guard let self = self else { return }
                    // set progress
                    self.composeToolbarView.circleCounterView.progress = progress
                    // set appearance
                    self.composeToolbarView.circleCounterView.strokeColor = strokeColor
                }
            }
            .store(in: &disposeBag)
        
        viewModel.$availableActions
            .assign(to: &composeToolbarView.$availableActions)
        
        // attachment
        viewModel.$attachmentViewModels
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateTableViewLayout()
            }
            .store(in: &disposeBag)
        
        // media
        viewModel.$isMediaToolBarButtonEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMediaToolBarButtonEnabled in
                guard let self = self else { return }
                self.composeToolbarView.mediaButton.isEnabled = isMediaToolBarButtonEnabled
            }
            .store(in: &disposeBag)
        
        // location
        viewModel.$isLocationToolBarButtonEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLocationToolBarButtonEnabled in
                guard let self = self else { return }
                self.composeToolbarView.localButton.isEnabled = isLocationToolBarButtonEnabled
                
            }
            .store(in: &disposeBag)
        
        viewModel.$isRequestLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRequestLocation in
                guard let self = self else { return }
                let tintColor = isRequestLocation ? Asset.Colors.hightLight.color : UIColor.secondaryLabel
                UIView.animate(withDuration: 0.3) {
                    self.composeToolbarView.localButton.tintColor = tintColor
                }
                
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            viewModel.$isRequestLocation,
            viewModel.$currentLocation
        )
        .asyncMap { [weak self] isRequestLocation, currentLocation -> Twitter.Entity.Place? in
            guard let self = self else { return nil }
            guard isRequestLocation, let currentLocation = currentLocation else { return nil }
            
            guard let authenticationContext = self.viewModel.configurationContext.authenticationService.activeAuthenticationContext.value,
                  case let .twitter(twitterAuthenticationContext) = authenticationContext
            else { return nil }
            
            do {
                let response = try await self.viewModel.configurationContext.apiService.geoSearch(
                    latitude: currentLocation.coordinate.latitude,
                    longitude: currentLocation.coordinate.longitude,
                    granularity: "city",
                    twitterAuthenticationContext: twitterAuthenticationContext
                )
                let place = response.value.first
                return place
            } catch {
                return nil
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] place in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: current place: %s", ((#file as NSString).lastPathComponent), #line, #function, place?.fullName ?? "<nil>")
            if let place = place {
                self.viewModel.currentPlace = place
            }
            self.composeToolbarView.locationLabel.text = place?.fullName
            self.composeToolbarView.locationLabel.isHidden = place == nil
        }
        .store(in: &disposeBag)
        
        composeToolbarView.delegate = self
        viewModel.composeInputTableViewCell.delegate = self
        viewModel.composeInputTableViewCell.metaText.delegate = self
        viewModel.composeAttachmentTableViewCell.delegate = self
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()
    }
    
    public override func viewLayoutMarginsDidChange() {
        super.viewLayoutMarginsDidChange()
        
        viewModel.viewLayoutMarginDidUpdate.send()
    }
    
}

extension ComposeContentViewController {
    private func createPhotoLibraryPicker() -> PHPickerViewController {
        let configuration: PHPickerConfiguration = {
            var configuration = PHPickerConfiguration()
            configuration.filter = .any(of: [.images, .videos])
            configuration.selectionLimit = viewModel.maxMediaAttachmentLimit - viewModel.attachmentViewModels.count
            return configuration
        }()
        let imagePicker = PHPickerViewController(configuration: configuration)
        imagePicker.delegate = self
        return imagePicker
    }
    
    private func updateTableViewLayout() {
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }
}


// MARK: - UITableViewDelegate
extension ComposeContentViewController: UITableViewDelegate {

}

// MARK: - PHPickerViewControllerDelegate
extension ComposeContentViewController: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        let newAttachmentViewModels = results.map { result in
            AttachmentViewModel(input: .pickerResult(result))
        }
        viewModel.attachmentViewModels.append(contentsOf: newAttachmentViewModels)
    }
}


// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension ComposeContentViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - CropViewControllerDelegate
extension ComposeContentViewController: CropViewControllerDelegate {
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        let attachmentViewModel = AttachmentViewModel(input: .image(image))
        viewModel.attachmentViewModels.append(attachmentViewModel)
        
        cropViewController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - ComposeToolbarViewDelegate
extension ComposeContentViewController: ComposeToolbarViewDelegate {
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, mediaButtonPressed button: UIButton, mediaSelectionType type: ComposeToolbarView.MediaSelectionType) {
        switch type {
        case .camera:
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.present(picker, animated: true)
            }
        case .photoLibrary:
            present(createPhotoLibraryPicker(), animated: true, completion: nil)
        case .browse:
            break
        }
    }

    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, emojiButtonPressed button: UIButton) {
        
    }
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, pollButtonPressed button: UIButton) {
        
    }
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, mentionButtonPressed button: UIButton) {
        // TODO: mention scene
        insertTextWithPrefixSpace(text: "@")
    }
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, hashtagButtonPressed button: UIButton) {
        // TODO: hashtag scene
        insertTextWithPrefixSpace(text: "#")
    }
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, localButtonPressed button: UIButton) {
        guard viewModel.requestLocationAuthorizationIfNeeds(presentingViewController: self) else { return }
        viewModel.isRequestLocation.toggle()
    }
    
    private func insertTextWithPrefixSpace(text: String) {
        let string = viewModel.composeInputTableViewCell.metaText.textStorage.string
        let isEmpty = string.isEmpty
        let hasPrefix = string.hasPrefix(" ")
        if hasPrefix || isEmpty {
            viewModel.composeInputTableViewCell.metaText.textView.insertText(text)
        } else {
            viewModel.composeInputTableViewCell.metaText.textView.insertText(" " + text)
        }
    }
}

// MARK: - ComposeInputTableViewCellDelegate
extension ComposeContentViewController: ComposeInputTableViewCellDelegate {
    public func composeInputTableViewCell(_ cell: ComposeInputTableViewCell, mentionPickButtonDidPressed button: UIButton) {
        guard let primaryItem = viewModel.primaryMentionPickItem else { return }
        
        let mentionPickViewModel = MentionPickViewModel(
            apiService: viewModel.configurationContext.apiService,
            authenticationService: viewModel.configurationContext.authenticationService,
            primaryItem: primaryItem,
            secondaryItems: viewModel.secondaryMentionPickItems
        )
        let mentionPickViewController = MentionPickViewController()
        mentionPickViewController.viewModel = mentionPickViewModel
        mentionPickViewController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: mentionPickViewController)
        navigationController.modalPresentationStyle = .pageSheet
        if let sheetPresentationController = navigationController.sheetPresentationController {
            sheetPresentationController.detents = [.medium(), .large()]
            sheetPresentationController.selectedDetentIdentifier = .medium
            sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false
            sheetPresentationController.prefersGrabberVisible = true
        }
        present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - MentionPickViewControllerDelegate
extension ComposeContentViewController: MentionPickViewControllerDelegate {
    func mentionPickViewController(
        _ controller: MentionPickViewController,
        itemPickDidChange items: [MentionPickViewModel.Item]
    ) {
        let excludeReplyTwitterUserIDs = items.compactMap { item -> Twitter.Entity.V2.Tweet.ID? in
            switch item {
            case .twitterUser(_, let attribute):
                guard !attribute.selected else { return nil }
                return attribute.userID
            }
        }
        
        viewModel.excludeReplyTwitterUserIDs = Set(excludeReplyTwitterUserIDs)
    }
}

// MARK: - MetaTextDelegate
extension ComposeContentViewController: MetaTextDelegate {
    public func metaText(_ metaText: MetaText, processEditing textStorage: MetaTextStorage) -> MetaContent? {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        defer {
            DispatchQueue.main.async {
                self.updateTableViewLayout()
            }
        }
        
        return viewModel.processEditing(textStorage: textStorage)
    }
}

// MARK: - ComposeAttachmentTableViewCellDelegate
extension ComposeContentViewController: ComposeAttachmentTableViewCellDelegate {
    public func composeAttachmentTableViewCell(_ cell: ComposeAttachmentTableViewCell, contextMenuAction: ComposeAttachmentTableViewCell.ContextMenuAction, for item: ComposeAttachmentTableViewCell.Item) {
        switch contextMenuAction {
        case .remove:
            switch item {
            case .attachment(let attachmentViewModel):
                viewModel.attachmentViewModels.removeAll(where: { $0 === attachmentViewModel })
            }
        }   // end switch contextMenuAction { … }
    }
}
