//
//  StubTimelineViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-9.
//

import os.log
import UIKit
import Combine

#if DEBUG
final class StubTimelineViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel = StubTimelineViewModel(context: context)
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TimelinePostTableViewCell.self, forCellReuseIdentifier: String(describing: TimelinePostTableViewCell.self))
        //        tableView.register(TimelineMiddleLoaderCollectionViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderCollectionViewCell.self))
        //        tableView.register(TimelineBottomLoaderCollectionViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderCollectionViewCell.self))
        return tableView
    }()
}

extension StubTimelineViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Stub Timeline"
        view.backgroundColor = .systemBackground
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(StubTimelineViewController.refreshControlValueChanged(_:)), for: .valueChanged)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Fetch", style: .plain, target: self, action: #selector(StubTimelineViewController.fetchBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Top", style: .plain, target: self, action: #selector(StubTimelineViewController.topBarButtonItemPressed(_:))),
            UIBarButtonItem(title: "Drop", style: .plain, target: self, action: #selector(StubTimelineViewController.dropBarButtonItemPressed(_:)))
        ]
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.backgroundColor = .systemBackground
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        tableView.dataSource = viewModel
    }
}

extension StubTimelineViewController {
    
    @objc private func refreshControlValueChanged(_ sender: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.insertNewStub()
            
            DispatchQueue.main.async {
                sender.endRefreshing()
            }
        }
    }
    
    @objc private func fetchBarButtonItemPressed(_ sender: UIBarButtonItem) {
        self.insertNewStub()
    }
    
    @objc private func dropBarButtonItemPressed(_ sender: UIBarButtonItem) {

    }
    
    @objc private func topBarButtonItemPressed(_ sender: UIBarButtonItem) {

    }
    
}

extension StubTimelineViewController {
    
    func insertNewStub() {
        UIView.performWithoutAnimation {
            let topWillBeAt = getTopVisibleRow() + 20
            let oldHeightDifferenceBetweenTopRowAndNavBar = heightDifferenceBetweenTopRowAndNavBar()
            
            viewModel.stubItems.insert(contentsOf: StubTimelineViewModel.createStubs(count: 20), at: 0)
            tableView.reloadData()
            
            tableView.scrollToRow(at: IndexPath(row: topWillBeAt, section: 0), at: .top, animated: false)
            tableView.contentOffset.y = tableView.contentOffset.y - oldHeightDifferenceBetweenTopRowAndNavBar
        }
    }
    
    func getTopVisibleRow() -> Int {
        //We need this to accounts for the translucency below the nav bar
        let navBar = navigationController?.navigationBar
        let whereIsNavBarInTableView = tableView.convert(navBar!.bounds, from: navBar)
        let pointWhereNavBarEnds = CGPoint(x: 0, y: whereIsNavBarInTableView.origin.y + whereIsNavBarInTableView.size.height + 1)
        let accurateIndexPath = tableView.indexPathForRow(at: pointWhereNavBarEnds)
        return accurateIndexPath?.row ?? 0
    }
    
    func heightDifferenceBetweenTopRowAndNavBar()-> CGFloat{
        let rectForTopRow = tableView.rectForRow(at:IndexPath(row:  getTopVisibleRow(), section: 0))
        let navBar = navigationController?.navigationBar
        let whereIsNavBarInTableView = tableView.convert(navBar!.bounds, from: navBar)
        let pointWhereNavBarEnds = CGPoint(x: 0, y: whereIsNavBarInTableView.origin.y + whereIsNavBarInTableView.size.height)
        let differenceBetweenTopRowAndNavBar = rectForTopRow.origin.y - pointWhereNavBarEnds.y
        return differenceBetweenTopRowAndNavBar
    }
}

#endif
