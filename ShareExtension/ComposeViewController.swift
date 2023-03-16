//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by MainasuK on 2021/11/17.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import UniformTypeIdentifiers

@_exported import TwidereUI

class ComposeViewController: UIViewController {

    let logger = Logger(subsystem: "ComposeViewController", category: "ViewController")
    
    let context = AppContext(appSecret: .default)
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = ComposeViewModel(context: context)

    private(set) lazy var sendBarButtonItem = UIBarButtonItem(image: Asset.Transportation.paperAirplane.image, style: .plain, target: self, action: #selector(ComposeViewController.sendBarButtonItemPressed(_:)))

    
    private var composeContentViewModel: ComposeContentViewModel?
    private var composeContentViewController: ComposeContentViewController?
    
//    lazy var composeContentViewModel: ComposeContentViewModel = {
//        return ComposeContentViewModel(
//            kind: .post,
//            configurationContext: ComposeContentViewModel.ConfigurationContext(
//                apiService: context.apiService,
//                authenticationService: context.authenticationService,
//                mastodonEmojiService: context.mastodonEmojiService,
//                statusViewConfigureContext: .init(
//                    dateTimeProvider: DateTimeSwiftProvider(),
//                    twitterTextProvider: OfficialTwitterTextProvider(),
//                    authenticationContext: context.authenticationService.$activeAuthenticationContext
//                )
//            )
//        )
//    }()
//    private(set) lazy var composeContentViewController: ComposeContentViewController = {
//        let composeContentViewController = ComposeContentViewController()
//        composeContentViewController.viewModel = composeContentViewModel
//        return composeContentViewController
//    }()
    
    let activityIndicatorBarButtonItem: UIBarButtonItem = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        let barButtonItem = UIBarButtonItem(customView: indicatorView)
        indicatorView.startAnimating()
        return barButtonItem
    }()
    
    let publishProgressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.progressViewStyle = .bar
        progressView.tintColor = Asset.Colors.hightLight.color
        return progressView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ComposeViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Compose.Title.compose
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(ComposeViewController.closeBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItem = sendBarButtonItem
        
        viewModel.$isBusy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isBusy in
                guard let self = self else { return }
                self.navigationItem.rightBarButtonItem = isBusy ? self.activityIndicatorBarButtonItem : self.sendBarButtonItem
            }
            .store(in: &disposeBag)
        
        Task { @MainActor in
            let inputItems = self.extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
            await load(inputItems: inputItems)
        }   // end Task

        do {
            guard let authContext = try setupAuthContext() else {
                // setupHintLabel()
                return
            }
            viewModel.authContext = authContext
            
            let composeContentViewModel = ComposeContentViewModel(
                context: context,
                authContext: authContext,
                kind: .post
            )
            let composeContentViewController = ComposeContentViewController()
            composeContentViewController.viewModel = composeContentViewModel
            
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
            
            // layout publish progress
            publishProgressView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(publishProgressView)
            NSLayoutConstraint.activate([
                publishProgressView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
                publishProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                publishProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
            
            // bind compose bar button item
            composeContentViewModel.$isComposeBarButtonEnabled
                .receive(on: DispatchQueue.main)
                .assign(to: \.isEnabled, on: sendBarButtonItem)
                .store(in: &disposeBag)
            
            // bind progress bar
            viewModel.$currentPublishProgress
                .receive(on: DispatchQueue.main)
                .sink { [weak self] progress in
                    guard let self = self else { return }
                    let progress = Float(progress)
                    let withAnimation = progress > self.publishProgressView.progress
                    self.publishProgressView.setProgress(progress, animated: withAnimation)
                    
                    if progress == 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                            guard let self = self else { return }
                            self.publishProgressView.setProgress(0, animated: false)
                        }
                    }
                }
                .store(in: &disposeBag)
            
            // set delegate
            composeContentViewController.delegate = self
            
            self.composeContentViewModel = composeContentViewModel
            self.composeContentViewController = composeContentViewController
            
            Task { @MainActor in
                let inputItems = self.extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
                await load(inputItems: inputItems)
            }   // end Task
            
        } catch {
            
        }
    }

}

extension ComposeViewController {
    private func setupAuthContext() throws -> AuthContext? {
        let request = AuthenticationIndex.sortedFetchRequest
        let _authenticationIndex = try context.managedObjectContext.fetch(request).first
        let _authContext = _authenticationIndex.flatMap { AuthContext(authenticationIndex: $0) }
        return _authContext
    }
}

extension ComposeViewController {
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        extensionContext?.cancelRequest(withError: NSError(domain: "com.twidere.twiderex", code: -1))
    }
    
    @objc private func sendBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
             
        Task { @MainActor in
            do {
                await self.setBusy(true)
                guard let statusPublisher = try self.composeContentViewModel?.statusPublisher() else {
                    await self.setBusy(false)
                    return
                }
                
                // setup progress
                self.viewModel.currentPublishProgressObservation = statusPublisher.progress
                    .observe(\.fractionCompleted, options: [.initial, .new]) { [weak self] progress, _ in
                        guard let self = self else { return }
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): publish progress \(progress.fractionCompleted)")
                        Task { @MainActor in
                            self.viewModel.currentPublishProgress = progress.fractionCompleted                            
                        }
                    }
                
                // publish
                _ = try await statusPublisher.publish(
                    api: self.context.apiService,
                    secret: AppSecret.default.secret
                )
                
                await self.setBusy(false)
            } catch {
                await self.setBusy(false)
                self.viewModel.currentPublishProgress = 0
                
                let alertController = UIAlertController.standardAlert(of: error)
                present(alertController, animated: true)
                return
            }
            
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }   // end Task
    }
    
    @MainActor
    private func setBusy(_ isBusy: Bool) async {
        viewModel.isBusy = isBusy
    }
}

extension ComposeViewController {
    
    private func load(inputItems: [NSExtensionItem]) async {
        guard let composeContentViewModel = self.composeContentViewModel,
              let authContext = viewModel.authContext
        else {
            assertionFailure()
            return
        }
        
        var itemProviders: [NSItemProvider] = []

        for item in inputItems {
            itemProviders.append(contentsOf: item.attachments ?? [])
        }
        
        let _textProvider = itemProviders.first { provider in
            return provider.hasRepresentationConforming(toTypeIdentifier: UTType.plainText.identifier, fileOptions: [])
        }
        
        let _urlProvider = itemProviders.first { provider in
            return provider.hasRepresentationConforming(toTypeIdentifier: UTType.url.identifier, fileOptions: [])
        }

        let _movieProvider = itemProviders.first { provider in
            return provider.hasRepresentationConforming(toTypeIdentifier: UTType.movie.identifier, fileOptions: [])
        }

        let imageProviders = itemProviders.filter { provider in
            return provider.hasRepresentationConforming(toTypeIdentifier: UTType.image.identifier, fileOptions: [])
        }
        
        async let text = ComposeViewController.loadText(textProvider: _textProvider)
        async let url = ComposeViewController.loadURL(textProvider: _urlProvider)
        
        let content = await [text, url]
            .compactMap { $0 }
            .joined(separator: " ")
        // passby the viewModel `content` value
        if !content.isEmpty {
            composeContentViewModel.contentMetaText?.textView.text = content + " "
        }

        if let movieProvider = _movieProvider {
            let attachmentViewModel = AttachmentViewModel(input: .itemProvider(movieProvider))
            composeContentViewModel.attachmentViewModels.append(attachmentViewModel)
        } else if !imageProviders.isEmpty {
            let attachmentViewModels = imageProviders.map { provider in
                AttachmentViewModel(input: .itemProvider(provider))
            }
            composeContentViewModel.attachmentViewModels.append(contentsOf: attachmentViewModels)
        }
    }
    
    private static func loadText(textProvider: NSItemProvider?) async -> String? {
        guard let textProvider = textProvider else { return nil }
        do {
            let item = try await textProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier)
            guard let text = item as? String else { return nil }
            return text
        } catch {
            return nil
        }
    }
    
    private static func loadURL(textProvider: NSItemProvider?) async -> String? {
        guard let textProvider = textProvider else { return nil }
        do {
            let item = try await textProvider.loadItem(forTypeIdentifier: UTType.url.identifier)
            guard let url = item as? URL else { return nil }
            return url.absoluteString
        } catch {
            return nil
        }
    }

}

// MARK: - ComposeContentViewControllerDelegate
extension ComposeViewController: ComposeContentViewControllerDelegate {

    func composeContentViewController(
        _ viewController: ComposeContentViewController,
        previewAttachmentViewModel attachmentViewModel: AttachmentViewModel
    ) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        attachmentViewModel.isPreviewPresented.toggle()
    }

}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ComposeViewController: UIAdaptivePresentationControllerDelegate {

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return composeContentViewModel?.canDismissDirectly ?? true
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        // TODO: showt alert
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
    }

}
