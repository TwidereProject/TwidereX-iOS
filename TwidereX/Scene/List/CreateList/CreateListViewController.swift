//
//  CreateListViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-14.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import TwidereLocalization
import TwidereCore

protocol CreateListViewControllerDelegate: AnyObject {
    func createListViewController(_ viewController: CreateListViewController, didCreateList response: APIService.CreateListResponse)
}

final class CreateListViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "CreateListViewController", category: "ViewController")
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: CreateListViewModel!
    
    weak var delegate: CreateListViewControllerDelegate?

    private(set) lazy var closeBarButtonItem = UIBarButtonItem.closeBarButtonItem(target: self, action: #selector(CreateListViewController.closeBarButtonItemPressed(_:)))
    private(set) lazy var doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(CreateListViewController.doneBarButtonItemPressed(_:)))
    private(set) lazy var activityIndicatorBarButtonItem: UIBarButtonItem = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        return UIBarButtonItem(customView: activityIndicator)
    }()
    
    private(set) lazy var createListView = CreateListView(viewModel: viewModel)

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension CreateListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.ListsModify.Create.title
        navigationItem.leftBarButtonItem = closeBarButtonItem
        navigationItem.leftBarButtonItem?.tintColor = .label
        navigationItem.rightBarButtonItem = doneBarButtonItem
                
        let hostingViewController = UIHostingController(rootView: createListView.environmentObject(context))
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    
        Publishers.CombineLatest(
            viewModel.$isValid,
            viewModel.$isBusy
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isValid, isBusy in
            guard let self = self else { return }
            self.doneBarButtonItem.isEnabled = isValid
            self.navigationItem.rightBarButtonItem = isBusy ? self.activityIndicatorBarButtonItem : self.doneBarButtonItem
        }
        .store(in: &disposeBag)
    }
    
}

extension CreateListViewController {

    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        Task { @MainActor in
            do {
                let result = try await viewModel.createList()
                delegate?.createListViewController(self, didCreateList: result)
                self.dismiss(animated: true)

            } catch {
                let alertController = UIAlertController.standardAlert(of: error)
                self.present(alertController, animated: true, completion: nil)
            }
        }   // end Task
    }
    
}
