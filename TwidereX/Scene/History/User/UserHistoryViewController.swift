//
//  UserHistoryViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-29.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwidereUI

final class UserHistoryViewController: UIViewController, NeedsDependency, MediaPreviewableViewController {

    let logger = Logger(subsystem: "UserHistoryViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: UserHistoryViewModel!
    
    let mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()

}
