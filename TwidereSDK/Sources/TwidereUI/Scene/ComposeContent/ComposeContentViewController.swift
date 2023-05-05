//
//  ComposeContentViewController.swift
//  
//
//  Created by MainasuK on 2021/11/17.
//

import os.log
import UIKit
import SwiftUI
import Combine
import MetaTextKit
import PhotosUI
import TwitterSDK
import MastodonSDK
import MastodonMeta
import TwidereCore
import TwidereAsset
import CropViewController
import KeyboardLayoutGuide

public protocol ComposeContentViewControllerDelegate: AnyObject {
    func composeContentViewController(_ viewController: ComposeContentViewController, previewAttachmentViewModel attachmentViewModel: AttachmentViewModel)
}

public final class ComposeContentViewController: UIViewController {
    
    let logger = Logger(subsystem: "ComposeContentViewController", category: "ViewController")
    
    public weak var delegate: ComposeContentViewControllerDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    public var viewModel: ComposeContentViewModel!
    
    let customEmojiPickerInputView: CustomEmojiPickerInputView = {
        let inputView = CustomEmojiPickerInputView(
            frame: CGRect(x: 0, y: 0, width: 0, height: 300),
            inputViewStyle: .keyboard
        )
        return inputView
    }()
    
    private(set) lazy var documentPickerController: UIDocumentPickerViewController = {
        let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: [.image, .movie])
        documentPickerController.delegate = self
        return documentPickerController
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension ComposeContentViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        viewModel.viewLayoutFrame.update(view: view)
        
        customEmojiPickerInputView.delegate = self
        viewModel.setupDiffableDataSource(
            customEmojiPickerInputView: customEmojiPickerInputView
        )
        
        let hostingViewController = UIHostingController(
            rootView: ComposeContentView(viewModel: viewModel)
        )
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingViewController.view.frame = view.bounds
        view.addSubview(hostingViewController.view)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingViewController.didMove(toParent: self)
        
        // mention - pick action
        // FIXME: TODO
//        viewModel.mentionPickPublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//                guard let authContext = self.viewModel.authContext else { return }
//                guard let primaryItem = self.viewModel.primaryMentionPickItem else { return }
//
//                let mentionPickViewModel = MentionPickViewModel(
//                    context: self.viewModel.context,
//                    authContext: authContext,
//                    primaryItem: primaryItem,
//                    secondaryItems: self.viewModel.secondaryMentionPickItems
//                )
//                let mentionPickViewController = MentionPickViewController()
//                mentionPickViewController.viewModel = mentionPickViewModel
//                mentionPickViewController.delegate = self
//
//                let navigationController = AdaptiveStatusBarStyleNavigationController(rootViewController: mentionPickViewController)
//                navigationController.modalPresentationStyle = .pageSheet
//                if let sheetPresentationController = navigationController.sheetPresentationController {
//                    sheetPresentationController.detents = [.medium(), .large()]
//                    sheetPresentationController.selectedDetentIdentifier = .medium
//                    sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false
//                    sheetPresentationController.prefersGrabberVisible = true
//                }
//                self.present(navigationController, animated: true, completion: nil)
//            }
//            .store(in: &disposeBag)
        
        // attachment - preview action
        viewModel.mediaPreviewPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] attachmentViewModel in
                guard let self = self else { return }
                assert(self.delegate != nil)
                self.delegate?.composeContentViewController(self, previewAttachmentViewModel: attachmentViewModel)
            }
            .store(in: &disposeBag)
        
        // toolbar - media item
        viewModel.mediaActionPublisher
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] mediaAction in
                guard let self = self else { return }
                switch mediaAction {
                case .photoLibrary:
                    let picker = self.createPhotoLibraryPicker()
                    self.present(picker, animated: true, completion: nil)
                case .camera:
                    let picker = UIImagePickerController()
                    picker.sourceType = .camera
                    picker.delegate = self
                    self.present(picker, animated: true)
                case .browse:
                    self.present(self.documentPickerController, animated: true, completion: nil)
                }
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
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)        
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()
    }
    
    public override func viewLayoutMarginsDidChange() {
        super.viewLayoutMarginsDidChange()
        
        viewModel.viewLayoutMarginDidUpdate.send()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        viewModel.viewLayoutFrame.update(view: view)
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        viewModel.viewLayoutFrame.update(view: view)
    }

}

extension ComposeContentViewController {
    private func createPhotoLibraryPicker() -> PHPickerViewController {
        let configuration: PHPickerConfiguration = {
            var configuration = PHPickerConfiguration()
            // Twitter not supports HDR (HEVC, Dolby Vision)
            // configuration.preferredAssetRepresentationMode = .current
            configuration.filter = .any(of: [.images, .videos])
            configuration.selectionLimit = viewModel.maxMediaAttachmentLimit - viewModel.attachmentViewModels.count
            return configuration
        }()
        let imagePicker = PHPickerViewController(configuration: configuration)
        imagePicker.delegate = self
        return imagePicker
    }
}

// MARK: - UIDocumentPickerDelegate
extension ComposeContentViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        let attachmentViewModel = AttachmentViewModel(input: .url(url))
        viewModel.attachmentViewModels.append(attachmentViewModel)
    }
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
