//
//  ComposeViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2021/11/17.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import AVKit
import TwidereUI

final class ComposeViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {
    
    let logger = Logger(subsystem: "ComposeViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    // MARK: MediaPreviewTransitionHostViewController
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ComposeViewModel!
    var composeContentViewModel: ComposeContentViewModel!
    
    private(set) lazy var sendBarButtonItem = UIBarButtonItem(image: Asset.Transportation.paperAirplane.image, style: .plain, target: self, action: #selector(ComposeViewController.sendBarButtonItemPressed(_:)))
    
    private(set) lazy var composeContentViewController: ComposeContentViewController = {
        let composeContentViewController = ComposeContentViewController()
        composeContentViewController.viewModel = composeContentViewModel
        return composeContentViewController
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension ComposeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(ComposeViewController.closeBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItem = sendBarButtonItem
        
        viewModel.$title
            .map { $0 as String? }
            .sink { [weak self] title in
                guard let self = self else { return }
                self.title = title
            }
            .store(in: &disposeBag)
        
        addChild(composeContentViewController)
        composeContentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composeContentViewController.view)
        NSLayoutConstraint.activate([
            composeContentViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            composeContentViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composeContentViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composeContentViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        composeContentViewController.didMove(toParent: self)
        
        // bind compose bar button item
        composeContentViewModel.$isComposeBarButtonEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: sendBarButtonItem)
            .store(in: &disposeBag)
        
        // bind author
        viewModel.$author.assign(to: &composeContentViewModel.$author)
        
        composeContentViewController.delegate = self
    }
    
}

extension ComposeViewController {
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        do {
            let statusPublisher = try composeContentViewModel.statusPublisher()
            context.publisherService.enqueue(statusPublisher: statusPublisher)
        } catch {
            assertionFailure()
            // TODO: handle error
            return
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - ComposeContentViewControllerDelegate
extension ComposeViewController: ComposeContentViewControllerDelegate {

    func composeContentViewController(
        _ viewController: ComposeContentViewController,
        previewAttachmentViewModel attachmentViewModel: AttachmentViewModel
    ) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        let _item: MediaPreviewViewModel.Item?
        switch attachmentViewModel.output {
        case .image(let data, _):
            _item = UIImage(data: data).flatMap { .image(.init(image: $0)) }
        case .video(let url, _):
            let playerViewController = AVPlayerViewController()
            playerViewController.player = AVPlayer(url: url)
            playerViewController.player?.play()
            playerViewController.delegate = context.playerService
            present(playerViewController, animated: true, completion: nil)
            return
        case .none:
            _item = nil
        }
        
        guard let item = _item else {
            assertionFailure()
            return
        }
        
        let mediaPreviewViewModel = MediaPreviewViewModel(
            context: context,
            item: item,
            transitionItem: {
                let item = MediaPreviewTransitionItem(
                    source: .none,
                    previewableViewController: self
                )
                
                item.image = attachmentViewModel.thumbnail
                item.aspectRatio = attachmentViewModel.thumbnail?.size
                
                return item
            }()
        )
        coordinator.present(
            scene: .mediaPreview(viewModel: mediaPreviewViewModel),
            from: self,
            transition: .custom(transitioningDelegate: mediaPreviewTransitionController)
        )
    }

}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ComposeViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            return .fullScreen
        default:
            return .automatic
        }
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return composeContentViewModel.canDismissDirectly
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        // TODO: show alert
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }

}
