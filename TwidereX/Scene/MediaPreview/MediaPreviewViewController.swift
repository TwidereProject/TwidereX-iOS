//
//  MediaPreviewViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import AlamofireImage
import Kingfisher
import Pageboy
import MetaTextArea

protocol MediaPreviewViewControllerDelegate: AnyObject {
    func mediaPreviewViewController(_ viewController: MediaPreviewViewController, longPressGestureRecognizerTriggered longPressGestureRecognizer: UILongPressGestureRecognizer)
}

final class MediaPreviewViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "MediaPreviewViewController", category: "ViewController")

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: MediaPreviewViewModel!
//    weak var delegate: MediaPreviewViewControllerDelegate?

    // TODO: adapt Reduce Transparency preference
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))

    let pageViewController = PageboyViewController()

    let mediaInfoDescriptionView = MediaInfoDescriptionView()

    let closeButtonBackground: UIVisualEffectView = {
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        backgroundView.alpha = 0.9
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = 8
        backgroundView.layer.cornerCurve = .continuous
        return backgroundView
    }()

    let closeButtonBackgroundVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemUltraThinMaterial)))

    let closeButton: UIButton = {
        let button = HitTestExpandedButton(type: .system)
        button.imageView?.tintColor = .label
        button.setImage(Asset.Editing.xmarkRound.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.accessibilityLabel = L10n.Accessibility.Common.close
        return button
    }()

    let pageControlBackgroundVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemMaterial), style: .label))

    let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.isUserInteractionEnabled = false    // avoid tap gesture conflict
        return pageControl
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MediaPreviewViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        overrideUserInterfaceStyle = .dark

        visualEffectView.frame = view.bounds
        view.addSubview(visualEffectView)

        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(pageViewController)
        visualEffectView.contentView.addSubview(pageViewController.view)
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
        ])
        pageViewController.didMove(toParent: self)

        mediaInfoDescriptionView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.contentView.addSubview(mediaInfoDescriptionView)
        NSLayoutConstraint.activate([
            visualEffectView.bottomAnchor.constraint(equalTo: mediaInfoDescriptionView.bottomAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: mediaInfoDescriptionView.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: mediaInfoDescriptionView.trailingAnchor),
        ])

        closeButtonBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButtonBackground)
        NSLayoutConstraint.activate([
            closeButtonBackground.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 12),
            closeButtonBackground.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor)
        ])
        closeButtonBackgroundVisualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        closeButtonBackground.contentView.addSubview(closeButtonBackgroundVisualEffectView)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButtonBackgroundVisualEffectView.contentView.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: closeButtonBackgroundVisualEffectView.topAnchor, constant: 4),
            closeButton.leadingAnchor.constraint(equalTo: closeButtonBackgroundVisualEffectView.leadingAnchor, constant: 4),
            closeButtonBackgroundVisualEffectView.trailingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 4),
            closeButtonBackgroundVisualEffectView.bottomAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 4),
        ])

        pageControlBackgroundVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.contentView.addSubview(pageControlBackgroundVisualEffectView)
        NSLayoutConstraint.activate([
            pageControlBackgroundVisualEffectView.centerXAnchor.constraint(equalTo: mediaInfoDescriptionView.centerXAnchor),
            mediaInfoDescriptionView.topAnchor.constraint(equalTo: pageControlBackgroundVisualEffectView.bottomAnchor, constant: 8),
        ])

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControlBackgroundVisualEffectView.contentView.addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.topAnchor.constraint(equalTo: pageControlBackgroundVisualEffectView.topAnchor),
            pageControl.leadingAnchor.constraint(equalTo: pageControlBackgroundVisualEffectView.leadingAnchor),
            pageControl.trailingAnchor.constraint(equalTo: pageControlBackgroundVisualEffectView.trailingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: pageControlBackgroundVisualEffectView.bottomAnchor),
        ])
        
        mediaInfoDescriptionView.isHidden = true
        
//        if let status = viewModel.status {
//            mediaInfoDescriptionView.configure(
//                statusObject: status,
//                configurationContext: .init(
//                    dateTimeProvider: DateTimeSwiftProvider(),
//                    twitterTextProvider: OfficialTwitterTextProvider(),
//                    viewLayoutFramePublisher: viewModel.$viewLayoutFrame
//                )
//            )
//        } else {
//            mediaInfoDescriptionView.isHidden = true
//        }
        
        pageControl.numberOfPages = viewModel.viewControllers.count
        pageControl.isHidden = viewModel.viewControllers.count == 1
        pageControl.isUserInteractionEnabled = false
        pageControl.addTarget(self, action: #selector(MediaPreviewViewController.pageControlValueDidChanged(_:)), for: .valueChanged)
        
        viewModel.mediaPreviewImageViewControllerDelegate = self
        
        pageViewController.interPageSpacing = 10
        pageViewController.delegate = self
        pageViewController.dataSource = viewModel
        
        mediaInfoDescriptionView.delegate = self
        
        closeButton.addTarget(self, action: #selector(MediaPreviewViewController.closeButtonPressed(_:)), for: .touchUpInside)
        
        // bind view model
//        viewModel.$currentPage
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] index in
//                guard let self = self else { return }
//                // update page control
//                self.pageControl.currentPage = index
//                
//                // update mediaGridContainerView
//                switch self.viewModel.transitionItem.source {
//                case .none:
//                    break
//                case .attachment:
//                    break
//                case .attachments(let mediaGridContainerView):
//                    UIView.animate(withDuration: 0.3) {
//                        mediaGridContainerView.setAlpha(1)
//                        mediaGridContainerView.setAlpha(0, index: index)
//                    }
//                case .profileAvatar, .profileBanner:
//                    break
//                }
//            }
//            .store(in: &disposeBag)
        
        viewModel.$currentPage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let currentViewController = self.pageViewController.currentViewController else { return }
                
                switch currentViewController {
                case is MediaPreviewVideoViewController:
                    self.toggleControlDisplay(isHidden: true)
                default:
                    self.toggleControlDisplay(isHidden: false)
                }
            }
            .store(in: &disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        visualEffectView.frame = view.bounds
    }
    
}

extension MediaPreviewViewController {

    @objc private func closeButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func pageControlValueDidChanged(_ sender: UIPageControl) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        let currentPage = sender.currentPage
        guard let pageCount = pageViewController.pageCount,
              currentPage >= 0,
              currentPage < pageCount
        else { return }
        
        pageViewController.scrollToPage(.at(index: currentPage), animated: true, completion: nil)
    }

}

extension MediaPreviewViewController {
    
    func toggleControlDisplay(isHidden: Bool) {
        closeButtonBackground.alpha = isHidden ? 0 : 1
        mediaInfoDescriptionView.alpha = isHidden ? 0 : 1
    }
    
}

// MARK: - PageboyViewControllerDelegate
extension MediaPreviewViewController: PageboyViewControllerDelegate {
    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        willScrollToPageAt index: PageboyViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        // do nothing
    }

    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollTo position: CGPoint,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        // do nothing
    }

    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollToPageAt index: PageboyViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        viewModel.currentPage = index
    }

    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didReloadWith currentViewController: UIViewController,
        currentPageIndex: PageboyViewController.PageIndex
    ) {
        // do nothing
    }

}

// MARK: - MediaPreviewingViewController
extension MediaPreviewViewController: MediaPreviewingViewController {

    func isInteractiveDismissible() -> Bool {
        if let mediaPreviewImageViewController = pageViewController.currentViewController as? MediaPreviewImageViewController {
            let previewImageView = mediaPreviewImageViewController.previewImageView
            
            // TODO: allow zooming pan dismiss
            guard previewImageView.zoomScale == previewImageView.minimumZoomScale else {
                return false
            }

            let safeAreaInsets = previewImageView.safeAreaInsets
            let statusBarFrameHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            
            let allowInteractiveDismiss = previewImageView.contentOffset.y <= -(safeAreaInsets.top - statusBarFrameHeight)
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): allow interactive dismiss: \(allowInteractiveDismiss)")
            
            return allowInteractiveDismiss
        }
        
        if let mediaPreviewVideoViewController = pageViewController.currentViewController as? MediaPreviewVideoViewController {
            return true
        }

        return false
    }

}

// MARK: - MediaPreviewImageViewControllerDelegate
extension MediaPreviewViewController: MediaPreviewImageViewControllerDelegate {

    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, tapGestureRecognizerDidTrigger tapGestureRecognizer: UITapGestureRecognizer) {
        let location = tapGestureRecognizer.location(in: viewController.previewImageView.imageView)
        let isContainsTap = viewController.previewImageView.imageView.frame.contains(location)
        
        guard !isContainsTap else { return }
        dismiss(animated: true, completion: nil)
    }

    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, longPressGestureRecognizerDidTrigger longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        impactFeedbackGenerator.impactOccurred()
        
        // trigger menu button action
//        mediaInfoDescriptionView.toolbar.delegate?.statusToolbar(
//            mediaInfoDescriptionView.toolbar,
//            actionDidPressed: .menu,
//            button: mediaInfoDescriptionView.toolbar.menuButton
//        )
    }

}

// MARK: - AuthContextProvider
extension MediaPreviewViewController: AuthContextProvider {
    var authContext: AuthContext { viewModel.authContext }
}

// MARK: - MediaInfoDescriptionViewDelegate
extension MediaPreviewViewController: MediaInfoDescriptionViewDelegate { }

// MARK: - ShareActivityProvider
extension MediaPreviewViewController: ShareActivityProvider {
    var activities: [Any] {
        if let provider = pageViewController.currentViewController as? ShareActivityProvider {
            return provider.activities
        }
        
        return []
    }
    
    var applicationActivities: [UIActivity] {
        if let provider = pageViewController.currentViewController as? ShareActivityProvider {
            return provider.applicationActivities
        }
        
        return []
    }
}
