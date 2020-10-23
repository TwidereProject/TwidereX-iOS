//
//  ComposeTweetViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-21.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class ComposeTweetViewController: UIViewController, NeedsDependency {
    
    static let avatarImageViewSize = CGSize(width: 44, height: 44)
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ComposeTweetViewModel!
    
    let tableView: UITableView = {
        let tableView = ControlContainableTableView()
        tableView.register(RepliedToTweetContentTableViewCell.self, forCellReuseIdentifier: String(describing: RepliedToTweetContentTableViewCell.self))
        tableView.register(ComposeTweetContentTableViewCell.self, forCellReuseIdentifier: String(describing: ComposeTweetContentTableViewCell.self))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    let cycleCounterView = CycleCounterView()
    let tweetContentOverflowLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    let tweetToolbarView = TweetToolbarView()
    var tweetToolbarViewBottomLayoutConstraint: NSLayoutConstraint!
}

extension ComposeTweetViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Compose"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Asset.Editing.xmark.image.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(ComposeTweetViewController.closeBarButtonItemPressed(_:)))
        navigationItem.leftBarButtonItem?.tintColor = .label
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.ObjectTools.paperplane.image.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(ComposeTweetViewController.sendBarButtonItemPressed(_:)))
        navigationItem.rightBarButtonItem?.tintColor = Asset.Colors.hightLight.color
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        cycleCounterView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cycleCounterView)
        NSLayoutConstraint.activate([
            cycleCounterView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            cycleCounterView.widthAnchor.constraint(equalToConstant: 18).priority(.defaultHigh),
            cycleCounterView.heightAnchor.constraint(equalToConstant: 18).priority(.defaultHigh),
        ])
        
        tweetContentOverflowLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tweetContentOverflowLabel)
        NSLayoutConstraint.activate([
            tweetContentOverflowLabel.centerYAnchor.constraint(equalTo: cycleCounterView.centerYAnchor),
            tweetContentOverflowLabel.leadingAnchor.constraint(equalTo: cycleCounterView.trailingAnchor, constant: 4),
        ])
        
        tweetToolbarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tweetToolbarView)
        tweetToolbarViewBottomLayoutConstraint = view.bottomAnchor.constraint(equalTo: tweetToolbarView.bottomAnchor)
        NSLayoutConstraint.activate([
            tweetToolbarView.topAnchor.constraint(equalTo: cycleCounterView.bottomAnchor, constant: 16),
            tweetToolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tweetToolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tweetToolbarViewBottomLayoutConstraint,
            tweetToolbarView.heightAnchor.constraint(equalToConstant: 48),
        ])
        tweetToolbarView.preservesSuperviewLayoutMargins = true
        
        viewModel.setupDiffableDataSource(for: tableView)
        tableView.delegate = self
        tableView.dataSource = viewModel.diffableDataSource
        
        // respond scrollView overlap change
        view.layoutIfNeeded()
        Publishers.CombineLatest3(
            KeyboardResponderService.shared.isShow.eraseToAnyPublisher(),
            KeyboardResponderService.shared.state.eraseToAnyPublisher(),
            KeyboardResponderService.shared.endFrame.eraseToAnyPublisher()
        )
        .sink(receiveValue: { [weak self] isShow, state, endFrame in
            guard let self = self else { return }
            
            guard isShow, state == .dock else {
                self.tableView.contentInset.bottom = 0.0
                self.tableView.verticalScrollIndicatorInsets.bottom = 0.0
                UIView.animate(withDuration: 0.3) {
                    self.tweetToolbarViewBottomLayoutConstraint.constant = 0.0
                    self.view.layoutIfNeeded()
                }
                return
            }

            // isShow AND dock state
            let contentFrame = self.view.convert(self.tableView.frame, to: nil)
            let padding = contentFrame.maxY - endFrame.minY
            guard padding > 0 else {
                self.tableView.contentInset.bottom = 0.0
                self.tableView.verticalScrollIndicatorInsets.bottom = 0.0
                UIView.animate(withDuration: 0.3) {
                    self.tweetToolbarViewBottomLayoutConstraint.constant = 0.0
                    self.view.layoutIfNeeded()
                }
                return
            }

            self.tableView.contentInset.bottom = padding + 16
            self.tableView.verticalScrollIndicatorInsets.bottom = padding + 16
            UIView.animate(withDuration: 0.3) {
                self.tweetToolbarViewBottomLayoutConstraint.constant = padding
                self.view.layoutIfNeeded()
            }
        })
        .store(in: &disposeBag)
        
        // set cycle counter. update compose button state
        viewModel.twitterTextparseResults
            .receive(on: DispatchQueue.main)
            .sink { [weak self] parseResult in
                guard let self = self else { return }
                let maxWeightedTweetLength = self.viewModel.twitterTextParser.configuration.maxWeightedTweetLength
                let progress = CGFloat(parseResult.weightedLength) / CGFloat(maxWeightedTweetLength)
                let strokeColor: UIColor = {
                    if progress > 1.0 {
                        return .systemRed
                    } else if progress > 0.9 {
                        return .systemOrange
                    } else {
                        return Asset.Colors.hightLight.color
                    }
                }()
                UIView.animate(withDuration: 0.1) {
                    self.cycleCounterView.strokeColor.value = strokeColor
                    self.cycleCounterView.progress.value = progress
                }
                
                let overflow = parseResult.weightedLength - maxWeightedTweetLength
                self.tweetContentOverflowLabel.text = overflow > 0 ? "-\(overflow)" : " "
                
                let isComposeButtonEnabled = parseResult.weightedLength > 0 && parseResult.isValid
                self.navigationItem.rightBarButtonItem?.isEnabled = isComposeButtonEnabled
            }
            .store(in: &disposeBag)
        
        // setup snap behavior
        Publishers.CombineLatest(
            viewModel.repliedToCellFrame.eraseToAnyPublisher(),
            viewModel.tableViewState.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] repliedToCellFrame, tableViewState in
            guard let self = self else { return }
            guard repliedToCellFrame != .zero else { return }
            switch tableViewState {
            case .fold:
                self.tableView.contentInset.top = -repliedToCellFrame.height
            case .expand:
                self.tableView.contentInset.top = 0
            }
        }
        .store(in: &disposeBag)
        
        // bind viewModel
        context.authenticationService.currentActiveTwitterAutentication
            .assign(to: \.value, on: viewModel.currentTwitterAuthentication)
            .store(in: &disposeBag)
        context.authenticationService.currentTwitterUser
            .sink { [weak self] user in
                guard let self = self else { return }
                self.viewModel.avatarImageURL.value = user?.avatarImageURL(size: .reasonablySmall)
                self.viewModel.isAvatarLockHidden.value = user.flatMap { !$0.protected } ?? true
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let cell = self.viewModel.composeTweetContentTableViewCell(of: self.tableView) else { return }
        cell.composeTextView.becomeFirstResponder()
    }
    
}

extension ComposeTweetViewController {
    
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        // prepare authentication
        guard let twitterAuthentication = viewModel.currentTwitterAuthentication.value,
              let authorization = try? twitterAuthentication.authorization(appSecret: AppSecret.shared) else {
            assertionFailure()
            return
        }
        
        context.apiService.tweet(
            content: viewModel.composeContent.value,
            replyToTweetObjectID: viewModel.repliedTweetObjectID,
            authorization: authorization
        )
        .receive(on: DispatchQueue.main)
        .handleEvents(receiveSubscription: { [weak self] _ in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        })
        .sink { completion in
            switch completion {
            case .failure(let error):
                os_log("%{public}s[%{public}ld], %{public}s: tweet fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            case .finished:
                os_log("%{public}s[%{public}ld], %{public}s: tweet success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        } receiveValue: { response in
            // do nothing
        }
        .store(in: &context.disposeBag)
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ComposeTweetViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            return .fullScreen
        default:
            return .formSheet
        }
    }
    
}

// MARK: - UIScrollViewDelegate
extension ComposeTweetViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView === tableView else { return }

        let repliedToCellFrame = viewModel.repliedToCellFrame.value
        guard repliedToCellFrame != .zero else { return }
        let throttle = viewModel.repliedToCellFrame.value.height - scrollView.adjustedContentInset.top
        // print("\(throttle) - \(scrollView.contentOffset.y)")

        switch viewModel.tableViewState.value {
        case .fold:
            if scrollView.contentOffset.y < throttle {
                viewModel.tableViewState.value = .expand
            }
            os_log("%{public}s[%{public}ld], %{public}s: fold", ((#file as NSString).lastPathComponent), #line, #function)

        case .expand:
            if scrollView.contentOffset.y > -44 {
                viewModel.tableViewState.value = .fold
                os_log("%{public}s[%{public}ld], %{public}s: expand", ((#file as NSString).lastPathComponent), #line, #function)
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension ComposeTweetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
