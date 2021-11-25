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
import AppShared
import TwidereUI
import TwidereComposeUI

class ComposeViewController: UIViewController {

    let logger = Logger(subsystem: "ComposeViewController", category: "ViewController")
    
//    var disposeBag = Set<AnyCancellable>()
//    let viewModel = ComposeViewModel()
//
//    private(set) lazy var sendBarButtonItem = UIBarButtonItem(image: Asset.Transportation.paperAirplane.image, style: .plain, target: self, action: #selector(ComposeViewController.sendBarButtonItemPressed(_:)))
//
//    let composeContentViewModel = ComposeContentViewModel(
//        inputContext: .post,
//        configurationContext: ComposeContentViewModel.ConfigurationContext(
//            apiService: APIS,
//            dateTimeProvider: DateTimeSwiftProvider(),
//            twitterTextProvider: OfficialTwitterTextProvider()
//        )
//    )
//    private(set) lazy var composeContentViewController: ComposeContentViewController = {
//        let composeContentViewController = ComposeContentViewController()
//        composeContentViewController.viewModel = composeContentViewModel
//        return composeContentViewController
//    }()
    
//    override func isContentValid() -> Bool {
//        // Do validation of contentText and/or NSExtensionContext attachments here
//        return true
//    }
//
//    override func didSelectPost() {
//        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
//
//        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
//        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
//    }
//
//    override func configurationItems() -> [Any]! {
//        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
//        return []
//    }

}

extension ComposeViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.backgroundColor = .systemBackground
//        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(ComposeViewController.closeBarButtonItemPressed(_:)))
//        navigationItem.rightBarButtonItem = sendBarButtonItem
//        navigationController?.presentationController?.delegate = self
//
//
//        viewModel.$title
//            .map { $0 as String? }
//            .assign(to: \.title, on: self)
//            .store(in: &disposeBag)
//
//        addChild(composeContentViewController)
//        composeContentViewController.view.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(composeContentViewController.view)
//        NSLayoutConstraint.activate([
//            composeContentViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
//            composeContentViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            composeContentViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            composeContentViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ])
//        composeContentViewController.didMove(toParent: self)
    }
}

//extension ComposeViewController {
//    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        self.dismiss(animated: true, completion: nil)
//    }
//    
//    @objc private func sendBarButtonItemPressed(_ sender: UIBarButtonItem) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        self.dismiss(animated: true, completion: nil)
//    }
//}
//
//// MARK: - UIAdaptivePresentationControllerDelegate
//extension ComposeViewController: UIAdaptivePresentationControllerDelegate {
//
//    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
//        return composeContentViewModel.canDismissDirectly
//    }
//
//    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        // TODO:
//    }
//
//    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//    }
//
//}
