//
//  TrendPlaceViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-21.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import TwidereCore

final class TrendPlaceViewController: UIViewController, NeedsDependency {
 
    let logger = Logger(subsystem: "TrendPlaceViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: TrendViewModel!
    
    private(set) lazy var searchController: UISearchController = {
        let searchController = UISearchController()
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        return searchController
    }()
}

extension TrendPlaceViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Trend Location"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(TrendPlaceViewController.closeBarButtonItemPressed(_:)))
        
        let hostingViewController = UIHostingController(
            rootView: TrendPlaceView(viewModel: viewModel).environmentObject(context)
        )
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        
    }
}

extension TrendPlaceViewController {
 
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        dismiss(animated: true)
    }
    
}

// MARK: - UISearchControllerDelegate
extension TrendPlaceViewController: UISearchControllerDelegate {
    
}

// MARK: - UISearchResultsUpdating
extension TrendPlaceViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchText = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
