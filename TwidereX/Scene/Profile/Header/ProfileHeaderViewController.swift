//
//  ProfileHeaderViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import Combine
import TabBarPager
import MetaTextKit
import MetaTextArea
import MetaLabel
import Meta

protocol ProfileHeaderViewControllerDelegate: AnyObject {
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, friendshipButtonDidPressed button: UIButton)
    
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta)
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, metaLabel: MetaLabel, didSelectMeta meta: Meta)

    
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, profileDashboardView dashboardView: ProfileDashboardView, followingMeterViewDidPressed meterView: ProfileDashboardMeterView)
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, profileDashboardView dashboardView: ProfileDashboardView, followersMeterViewDidPressed meterView: ProfileDashboardMeterView)
    func headerViewController(_ viewController: ProfileHeaderViewController, profileHeaderView: ProfileHeaderView, profileDashboardView dashboardView: ProfileDashboardView, listedMeterViewDidPressed meterView: ProfileDashboardMeterView)
}

final class ProfileHeaderViewController: UIViewController {
    
    static let headerMinHeight: CGFloat = 50
    
    let logger = Logger(subsystem: "ProfileHeaderViewController", category: "ViewController")
    weak var delegate: ProfileHeaderViewControllerDelegate?
    weak var headerDelegate: TabBarPagerHeaderDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfileHeaderViewModel!
    
    private(set) lazy var headerView = ProfileHeaderView()

    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ProfileHeaderViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ThemeService.shared.$theme
            .map { $0.background }
            .assign(to: \.backgroundColor, on: view)
            .store(in: &disposeBag)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
        ])
        headerView.preservesSuperviewLayoutMargins = true
        
        viewModel.$user
            .sink { [weak self] user in
                guard let self = self else { return }
                self.headerView.configure(user: user)
            }
            .store(in: &disposeBag)
        
        viewModel.$relationshipOptionSet
            .receive(on: DispatchQueue.main)
            .sink { [weak self] relationshipOptionSet in
                guard let self = self else { return }
                self.headerView.configure(relationshipOptionSet: relationshipOptionSet)
            }
            .store(in: &disposeBag)
        
        headerView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        headerDelegate?.viewLayoutDidUpdate(self)
    }
    
}

extension ProfileHeaderViewController {
    @objc private func friendshipButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.headerViewController(self, profileHeaderView: headerView, friendshipButtonDidPressed: sender)
    }
}

// MARK: - TabBarPagerHeader
extension ProfileHeaderViewController: TabBarPagerHeader { }

// MARK: - ProfileHeaderViewDelegate
extension ProfileHeaderViewController: ProfileHeaderViewDelegate {
    
    func profileHeaderView(_ headerView: ProfileHeaderView, friendshipButtonPressed button: UIButton) {
        delegate?.headerViewController(self, profileHeaderView: headerView, friendshipButtonDidPressed: button)
    }
    
    func profileHeaderView(_ headerView: ProfileHeaderView, metaTextAreaView: MetaTextAreaView, didSelectMeta meta: Meta) {
        delegate?.headerViewController(self, profileHeaderView: headerView, metaTextAreaView: metaTextAreaView, didSelectMeta: meta)
    }
    
    func profileHeaderView(_ headerView: ProfileHeaderView, metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        delegate?.headerViewController(self, profileHeaderView: headerView, metaLabel: metaLabel, didSelectMeta: meta)
    }
    
    func profileHeaderView(_ headerView: ProfileHeaderView, profileDashboardView dashboardView: ProfileDashboardView, followingMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        delegate?.headerViewController(self, profileHeaderView: headerView, profileDashboardView: dashboardView, followingMeterViewDidPressed: meterView)
    }
    
    func profileHeaderView(_ headerView: ProfileHeaderView, profileDashboardView dashboardView: ProfileDashboardView, followersMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        delegate?.headerViewController(self, profileHeaderView: headerView, profileDashboardView: dashboardView, followersMeterViewDidPressed: meterView)
    }
    
    func profileHeaderView(_ headerView: ProfileHeaderView, profileDashboardView dashboardView: ProfileDashboardView, listedMeterViewDidPressed meterView: ProfileDashboardMeterView) {
        delegate?.headerViewController(self, profileHeaderView: headerView, profileDashboardView: dashboardView, listedMeterViewDidPressed: meterView)
    }
}
