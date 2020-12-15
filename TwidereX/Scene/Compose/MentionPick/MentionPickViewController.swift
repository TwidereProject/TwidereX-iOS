//
//  MentionPickViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-14.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

protocol MentionPickViewControllerDelegate: class {
    func mentionPickViewController(_ controller: MentionPickViewController, didUpdateMentionPickItems items: [MentionPickItem])
}

final class MentionPickViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: MentionPickViewModel!
    weak var delegate: MentionPickViewControllerDelegate?
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(MentionPickTableViewCell.self, forCellReuseIdentifier: String(describing: MentionPickTableViewCell.self))
        return tableView
    }()
    
}

extension MentionPickViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Compose.replyingTo
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Asset.Editing.xmark.image.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(MentionPickViewController.closeBarButtonItemPressed(_:)))
        navigationItem.leftBarButtonItem?.tintColor = .label
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        viewModel.setupDiffableTableViewDataSource(for: tableView)
        tableView.delegate = self
        
        viewModel.diffableDataSource.defaultRowAnimation = .none
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        resolveLoadingItems()
    }
    
}

extension MentionPickViewController {

    func resolveLoadingItems() {
        guard let twitterAuthenticationBox = context.authenticationService.activeTwitterAuthenticationBox.value else { return }
        viewModel.resolveLoadingItems(twitterAuthenticationBox: twitterAuthenticationBox)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    // TODO: handle error
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch users fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                case .finished:
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch users success", ((#file as NSString).lastPathComponent), #line, #function)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                let users = response.value.data ?? []
                
                var items: [MentionPickItem] = []
                for item in self.viewModel.secondaryItems {
                    switch item {
                    case .twitterUser(let username, let attribute):
                        guard let user = users.first(where: { $0.username == username }) else { continue }
                        attribute.avatarImageURL = user.avatarImageURL()
                        attribute.userID = user.id
                        attribute.name = user.name
                        attribute.state = .finish
                         
                        items.append(item)
                    }
                }
                
                guard let diffableDataSource = self.viewModel.diffableDataSource else { return }
                if !items.isEmpty {
                    var snapshot = diffableDataSource.snapshot()
                    snapshot.reloadItems(items)
                    diffableDataSource.apply(snapshot)
                }
            }
            .store(in: &viewModel.disposeBag)
    }
    
}

extension MentionPickViewController {
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate
extension MentionPickViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let diffableDataSource = viewModel.diffableDataSource else { return }
        guard let item = diffableDataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .twitterUser(_, let attribute):
            guard !attribute.disabled else { return }
            attribute.selected.toggle()
            var snapshot = diffableDataSource.snapshot()
            snapshot.reloadItems([item])
            diffableDataSource.apply(snapshot)
        }
        
        delegate?.mentionPickViewController(self, didUpdateMentionPickItems: viewModel.secondaryItems)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else { return nil }
        let header = TableViewSectionTextHeaderView()
        header.headerLabel.text = L10n.Scene.Compose.othersInThisConversation
        return header
    }
    
}
