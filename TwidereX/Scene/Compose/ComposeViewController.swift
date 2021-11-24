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
import TwidereUI

final class ComposeViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "ComposeViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ComposeViewModel!
    var composeContentViewModel: ComposeContentViewModel!
    
    private(set) lazy var sendBarButtonItem = UIBarButtonItem(image: Asset.Transportation.paperAirplane.image, style: .plain, target: self, action: #selector(ComposeViewController.sendBarButtonItemPressed(_:)))
    
    
    private(set) lazy var composeContentViewController: ComposeContentViewController = {
        let composeContentViewController = ComposeContentViewController()
        composeContentViewController.viewModel = composeContentViewModel
        return composeContentViewController
    }()
}

extension ComposeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(ComposeViewController.closeBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItem = sendBarButtonItem
        
        viewModel.$title
            .map { $0 as String? }
            .assign(to: \.title, on: self)
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
        composeContentViewModel.$isTextInputValid
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: sendBarButtonItem)
            .store(in: &disposeBag)
        
        // bind author
        viewModel.$author.assign(to: &composeContentViewModel.$author)
    }
    
}

extension ComposeViewController {
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ComposeViewController: UIAdaptivePresentationControllerDelegate {

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
