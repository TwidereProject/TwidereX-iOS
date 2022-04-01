//
//  EditListViewController.swift
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

protocol EditListViewControllerDelegate: AnyObject {
    func editListViewController(_ viewController: EditListViewController, didCreateList response: APIService.CreateListResponse)
    func editListViewController(_ viewController: EditListViewController, didUpdateList response: APIService.UpdateListResponse)
}

final class EditListViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "CreateListViewController", category: "ViewController")
        
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    var viewModel: EditListViewModel!
    
    weak var delegate: EditListViewControllerDelegate?

    private(set) lazy var closeBarButtonItem = UIBarButtonItem.closeBarButtonItem(target: self, action: #selector(EditListViewController.closeBarButtonItemPressed(_:)))
    private(set) lazy var doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(EditListViewController.doneBarButtonItemPressed(_:)))
    private(set) lazy var activityIndicatorBarButtonItem: UIBarButtonItem = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        return UIBarButtonItem(customView: activityIndicator)
    }()
    
    private(set) lazy var createListView = EditListView(viewModel: viewModel)

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension EditListViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = {
            switch viewModel.kind {
            case .create:       return L10n.Scene.ListsModify.Create.title
            case .edit:         return L10n.Scene.ListsModify.Edit.title
            }
        }()
        navigationItem.leftBarButtonItem = closeBarButtonItem
        navigationItem.leftBarButtonItem?.tintColor = .label
        navigationItem.rightBarButtonItem = doneBarButtonItem
                
        let hostingViewController = UIHostingController(rootView: createListView)
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

extension EditListViewController {

    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func doneBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        Task { @MainActor in
            do {
                switch viewModel.kind {
                case .create:
                    let result = try await viewModel.createList()
                    delegate?.editListViewController(self, didCreateList: result)
                case .edit:
                    let result = try await viewModel.updateList()
                    delegate?.editListViewController(self, didUpdateList: result)
                }
                self.dismiss(animated: true)

            } catch {
                let alertController = UIAlertController.standardAlert(of: error)
                self.present(alertController, animated: true, completion: nil)
            }
        }   // end Task
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension EditListViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return !viewModel.isBusy
    }

}
