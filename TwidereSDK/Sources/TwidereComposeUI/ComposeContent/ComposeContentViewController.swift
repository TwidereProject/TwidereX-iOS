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
import MastodonSDK
import TwidereCore
import TwidereAsset
import MastodonMeta
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
    
    let customEmojiPickerInputView: CustomEmojiPickerInputView = {
        let inputView = CustomEmojiPickerInputView(
            frame: CGRect(x: 0, y: 0, width: 0, height: 300),
            inputViewStyle: .keyboard
        )
        return inputView
    }()
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
        customEmojiPickerInputView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView,
            customEmojiPickerInputView: customEmojiPickerInputView,
            composeInputTableViewCellDelegate: self,
            composeAttachmentTableViewCellDelegate: self,
            composePollTableViewCellDelegate: self
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
        
        // bind content warning
        viewModel.$isContentWarningComposing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isContentWarningComposing in
                guard let self = self else { return }
                self.viewModel.composeInputTableViewCell.contentWarningContainer.isHidden = !isContentWarningComposing
                self.updateTableViewLayout()
            }
            .store(in: &disposeBag)
        
        // bind counter
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
        
        Publishers.CombineLatest3(
            viewModel.$currentTextInputWeightedLength,
            viewModel.$currentContentWarningInputWeightedLength,
            viewModel.$maxTextInputLimit
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] currentTextInputWeightedLength, currentContentWarningInputWeightedLength, maxTextInputLimit in
            guard let self = self else { return }
            let count = currentTextInputWeightedLength + currentContentWarningInputWeightedLength
            let overflow = maxTextInputLimit - count
            self.composeToolbarView.counterLabel.isHidden = overflow > 0
            self.composeToolbarView.counterLabel.text = "-\(abs(overflow))"
        }
        .store(in: &disposeBag)
        
        
        // bind toolbar
        viewModel.$availableActions
            .assign(to: &composeToolbarView.$availableActions)
        
        // visibility
        viewModel.$visibility
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visibility in
                guard let self = self else { return }
                
                self.composeToolbarView.setVisibilityButtonDisplay(visibility != nil)
                
                switch visibility {
                case .mastodon(let visibility):
                    self.composeToolbarView.visibilityButton.setImage(visibility.image, for: .normal)
                    self.composeToolbarView.visibilityButton.setTitle(visibility.title, for: .normal)
                case .none:
                    break
                }
            }
            .store(in: &disposeBag)
        
        // media sensitive
        viewModel.$isMediaSensitive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMediaSensitive in
                guard let self = self else { return }
                self.composeToolbarView.mediaSensitiveButton.tintColor = isMediaSensitive ? Asset.Colors.hightLight.color : .secondaryLabel
            }
            .store(in: &disposeBag)
        
        // content warning
        viewModel.$isContentWarningComposing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isContentWarningComposing in
                guard let self = self else { return }
                self.composeToolbarView.contentWarningButton.tintColor = isContentWarningComposing ? Asset.Colors.hightLight.color : .secondaryLabel
            }
            .store(in: &disposeBag)
        
        // attachment
        viewModel.$attachmentViewModels
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateTableViewLayout()
            }
            .store(in: &disposeBag)
        
        viewModel.$isMediaToolBarButtonEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMediaToolBarButtonEnabled in
                guard let self = self else { return }
                self.composeToolbarView.mediaButton.isEnabled = isMediaToolBarButtonEnabled
            }
            .store(in: &disposeBag)
        
        // poll
        viewModel.composePollTableViewCell.collectionViewHeightDidUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateTableViewLayout()
            }
            .store(in: &disposeBag)
        
        viewModel.$isPollToolBarButtonEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPollToolBarButtonEnabled in
                guard let self = self else { return }
                self.composeToolbarView.pollButton.isEnabled = isPollToolBarButtonEnabled
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
        
        // emoji
        viewModel.$emojiViewModel
            .map { viewModel -> AnyPublisher<[Mastodon.Entity.Emoji], Never> in
                guard let viewModel = viewModel else {
                    return Just([]).eraseToAnyPublisher()
                }
                return viewModel.$emojis.eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] emojis in
                guard let self = self else { return }
                if emojis.isEmpty {
                    self.customEmojiPickerInputView.activityIndicatorView.startAnimating()
                } else {
                    self.customEmojiPickerInputView.activityIndicatorView.stopAnimating()
                }
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            viewModel.$isCustomEmojiComposing,
            viewModel.$emojiToolBarButtonImage
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isCustomEmojiComposing, emojiToolBarButtonImage in
            guard let self = self else { return }
            self.composeToolbarView.emojiButton.setImage(emojiToolBarButtonImage, for: .normal)
            self.composeToolbarView.emojiButton.tintColor = isCustomEmojiComposing ? Asset.Colors.hightLight.color : .secondaryLabel
        }
        .store(in: &disposeBag)
        
        
        composeToolbarView.delegate = self
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.composeInputTableViewCell.contentMetaText.textView.becomeFirstResponder()
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
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, visibilityButtonPressed button: UIButton, selectedVisibility visibility: Mastodon.Entity.Status.Visibility) {
        viewModel.mastodonVisibility = visibility
    }
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, mediaSensitiveButtonPressed button: UIButton) {
        viewModel.isMediaSensitive.toggle()
    }
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, contentWarningButtonPressed button: UIButton) {
        viewModel.isContentWarningComposing.toggle()
        
        if viewModel.isContentWarningComposing {
            viewModel.composeInputTableViewCell.contentWarningMetaText.textView.becomeFirstResponder()
        } else {
            if viewModel.composeInputTableViewCell.contentWarningMetaText.textView.isFirstResponder {
                viewModel.composeInputTableViewCell.contentMetaText.textView.becomeFirstResponder()
            }
        }
    }
    
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
        viewModel.isCustomEmojiComposing.toggle()
    }
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, pollButtonPressed button: UIButton) {
        viewModel.isPollComposing.toggle()
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
        let string = viewModel.composeInputTableViewCell.contentMetaText.textStorage.string
        let isEmpty = string.isEmpty
        let hasPrefix = string.hasPrefix(" ")
        if hasPrefix || isEmpty {
            viewModel.composeInputTableViewCell.contentMetaText.textView.insertText(text)
        } else {
            viewModel.composeInputTableViewCell.contentMetaText.textView.insertText(" " + text)
        }
    }
}

// MARK: - ComposeInputTableViewCellDelegate & MetaTextDelegate & UITextViewDelegate
extension ComposeContentViewController: ComposeInputTableViewCellDelegate & MetaTextDelegate & UITextViewDelegate {
    
    // MARK: - ComposeInputTableViewCellDelegate
    public func composeInputTableViewCell(
        _ cell: ComposeInputTableViewCell,
        mentionPickButtonDidPressed button: UIButton
    ) {
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

    // MARK: - MetaTextDelegate
    public func metaText(
        _ metaText: MetaText,
        processEditing textStorage: MetaTextStorage
    ) -> MetaContent? {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        defer {
            DispatchQueue.main.async {
                self.updateTableViewLayout()
            }
        }
        
        // Two input sources
        // 1. content warning
        // 2. status text
        return viewModel.metaText(metaText, processEditing: textStorage)
    }
 
    // MARK: - UITextViewDelegate
    public func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        switch textView {
        case viewModel.composeInputTableViewCell.contentWarningMetaText.textView:
            let isReturn = text == "\n"
            if isReturn {
                viewModel.composeInputTableViewCell.contentMetaText.textView.becomeFirstResponder()
            }
            return !isReturn
        case viewModel.composeInputTableViewCell.contentMetaText.textView:
            return true
        default:
            assertionFailure()
            return true
        }
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        switch textView {
        case viewModel.composeInputTableViewCell.contentWarningMetaText.textView:
            let _text = textView.textStorage.string
            let text = _text.replacingOccurrences(of: "\n", with: " ")
            
            guard text != _text else { break }
            
            let content = MastodonContent(content: text, emojis: [:]) // viewModel.emojiViewModel?.emojis.asDictionary ?? [:]
            let metaContent = MastodonMetaContent.convert(text: content)
            viewModel.currentContentWarningInput = text
            viewModel.composeInputTableViewCell.contentWarningMetaText.configure(content: metaContent)
            
        case viewModel.composeInputTableViewCell.contentMetaText.textView:
            break
        default:
            assertionFailure()
        }
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

// MARK: - ComposePollTableViewCellDelegate
extension ComposeContentViewController: ComposePollTableViewCellDelegate {
    
    public func composePollTableViewCell(_ cell: ComposePollTableViewCell, pollOptionCollectionViewCell collectionViewCell: ComposePollOptionCollectionViewCell, textFieldDidBeginEditing textField: UITextField) {

    }
    
    public func composePollTableViewCell(_ cell: ComposePollTableViewCell, pollOptionCollectionViewCell collectionViewCell: ComposePollOptionCollectionViewCell, textFieldDidReturn: UITextField) {
        guard let diffableDataSource = cell.diffableDataSource else { return }
        guard let indexPath = cell.collectionView.indexPath(for: collectionViewCell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        
        let optionItems = diffableDataSource.snapshot().itemIdentifiers.filter { item in
            switch item {
            case .option:   return true
            default:        return false
            }
        }
        guard let index = optionItems.firstIndex(of: item) else { return }
        let isLast = index == optionItems.count - 1
        
        if isLast {
            // set action trigger
            var cancellable: AnyCancellable?
            cancellable = viewModel.pollCollectionViewDiffableDataSourceDidUpdate
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.markLastPollOptionBecomeFirstResponser()
                    
                    if let cancellable = cancellable {
                        self.disposeBag.remove(cancellable)
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): cleanup poll data source trigger")
                    }
                }
            if let cancellable = cancellable {
                self.disposeBag.insert(cancellable)
            }
            // do action
            viewModel.createNewPollOptionIfNeeds()
        } else {
            // the `isLast` guard the `nextIndex` is always valid
            let nextIndex = optionItems.index(after: index)
            let nextItem = optionItems[nextIndex]
            let cell = pollOptionCollectionViewCell(of: nextItem)
            cell?.pollOptionView.textField.becomeFirstResponder()
        }
    }
    
    public func composePollTableViewCell(_ cell: ComposePollTableViewCell, pollOptionCollectionViewCell collectionViewCell: ComposePollOptionCollectionViewCell, textBeforeDeleteBackward text: String?) {
        guard (text ?? "").isEmpty else { return }
        guard let diffableDataSource = viewModel.composePollTableViewCell.diffableDataSource else { return }
        guard let indexPath = viewModel.composePollTableViewCell.collectionView.indexPath(for: collectionViewCell) else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        guard case .option = item else { return }
        
        let items = diffableDataSource.snapshot().itemIdentifiers.filter { item in
            switch item {
            case .option:       return true
            default:            return false
            }
        }
        guard let index = items.firstIndex(of: item) else { return }
        guard index > 0 else {
            // do nothing when at the first
            return
        }
        
        func cellBeforeRemoved() -> ComposePollOptionCollectionViewCell? {
            guard index > 0 else { return nil }
            let indexBeforeRemoved = items.index(before: index)
            let itemBeforeRemoved = items[indexBeforeRemoved]
            return pollOptionCollectionViewCell(of: itemBeforeRemoved)
        }
        func cellAfterRemoved() -> ComposePollOptionCollectionViewCell? {
            guard index < items.count - 1 else { return nil }
            let indexAfterRemoved = items.index(after: index)
            let itemAfterRemoved = items[indexAfterRemoved]
            return pollOptionCollectionViewCell(of: itemAfterRemoved)
        }
        
        // move first responder
        let cell = cellBeforeRemoved() ?? cellAfterRemoved()
        cell?.pollOptionView.textField.becomeFirstResponder()
        
        guard items.count > 2 else {
            // remove item when more then 2 options
            return
        }
        viewModel.pollOptions.remove(at: index)
    }
    
    public func composePollTableViewCell(_ cell: ComposePollTableViewCell, pollExpireConfigurationCollectionViewCell collectionViewCell: ComposePollExpireConfigurationCollectionViewCell, didSelectExpireConfigurationOption option: PollComposeItem.ExpireConfiguration.Option) {
        viewModel.pollExpireConfiguration.option = option
    }
    
    public func composePollTableViewCell(_ cell: ComposePollTableViewCell, composePollMultipleConfigurationCollectionViewCell collectionViewCell: ComposePollMultipleConfigurationCollectionViewCell, multipleSelectionDidChange isMultiple: Bool) {
        viewModel.pollMultipleConfiguration.isMultiple = isMultiple
    }
    
}

extension ComposeContentViewController {
    
    private func pollOptionCollectionViewCell(of item: PollComposeItem) -> ComposePollOptionCollectionViewCell? {
        guard case .option = item else { return nil }
        guard let diffableDataSource = viewModel.composePollTableViewCell.diffableDataSource else { return nil }
        guard let indexPath = diffableDataSource.indexPath(for: item),
              let cell = viewModel.composePollTableViewCell.collectionView.cellForItem(at: indexPath) as? ComposePollOptionCollectionViewCell
        else {
            return nil
        }

        return cell
    }
    
    private func firstPollOptionCollectionViewCell() -> ComposePollOptionCollectionViewCell? {
        guard let diffableDataSource = viewModel.composePollTableViewCell.diffableDataSource else { return nil }
        let items = diffableDataSource.snapshot().itemIdentifiers(inSection: .main)
        let _firstItem = items.first { item -> Bool in
            guard case .option = item else { return false }
            return true
        }

        guard let firstItem = _firstItem else {
            return nil
        }

        return pollOptionCollectionViewCell(of: firstItem)
    }
    
    private func lastPollOptionCollectionViewCell() -> ComposePollOptionCollectionViewCell? {
        guard let diffableDataSource = viewModel.composePollTableViewCell.diffableDataSource else { return nil }
        let items = diffableDataSource.snapshot().itemIdentifiers(inSection: .main)
        let _lastItem = items.last { item -> Bool in
            guard case .option = item else { return false }
            return true
        }

        guard let lastItem = _lastItem else { return nil }

        return pollOptionCollectionViewCell(of: lastItem)
    }
    
    private func markLastPollOptionBecomeFirstResponser() {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        guard let cell = lastPollOptionCollectionViewCell() else { return }
        cell.pollOptionView.textField.becomeFirstResponder()
    }
}

// MARK: - CustomEmojiPickerInputViewDelegate
extension ComposeContentViewController: CustomEmojiPickerInputViewDelegate {
    public func customEmojiPickerInputView(_ inputView: CustomEmojiPickerInputView, didSelectItemAt indexPath: IndexPath) {
        guard let diffableDataSource = viewModel.customEmojiDiffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .emoji(let emoji):
            _ = viewModel.customEmojiPickerInputViewModel.insertText(":\(emoji.shortcode): ")       // suffix with a space
        }
    }
}
