//
//  ProfileDashboardView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

protocol ProfileDashboardViewDelegate: AnyObject {
    func profileDashboardView(_ dashboardView: ProfileDashboardView, followingMeterViewDidPressed meterView: ProfileDashboardMeterView)
    func profileDashboardView(_ dashboardView: ProfileDashboardView, followersMeterViewDidPressed meterView: ProfileDashboardMeterView)
    func profileDashboardView(_ dashboardView: ProfileDashboardView, listedMeterViewDidPressed meterView: ProfileDashboardMeterView)
}

final class ProfileDashboardView: UIView {
    
    var _disposeBag = Set<AnyCancellable>()
    
    // Twitter
    // following | follower | listed
    
    // Mastodon
    // following | follower
    
    @Published var isAllowAdaptiveLayout = true
    
    let followingMeterView = ProfileDashboardMeterView()
    let separatorLine1 = SeparatorLineView()
    let followerMeterView = ProfileDashboardMeterView()
    let separatorLine2 = SeparatorLineView()
    let listedMeterView = ProfileDashboardMeterView()
    
    weak var delegate: ProfileDashboardViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileDashboardView {
    private func _init() {
        let containerStackView = UIStackView()
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
            containerStackView.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh),
        ])
        
        containerStackView.axis = .horizontal
        containerStackView.distribution = .fillEqually
        containerStackView.addArrangedSubview(followingMeterView)
        containerStackView.addArrangedSubview(followerMeterView)
        containerStackView.addArrangedSubview(listedMeterView)
        
        separatorLine1.translatesAutoresizingMaskIntoConstraints = false
        separatorLine2.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorLine1)
        addSubview(separatorLine2)
        NSLayoutConstraint.activate([
            separatorLine1.leadingAnchor.constraint(equalTo: followingMeterView.trailingAnchor),
            separatorLine1.centerYAnchor.constraint(equalTo: followingMeterView.centerYAnchor),
            separatorLine1.widthAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: self)),
            separatorLine1.heightAnchor.constraint(equalTo: containerStackView.heightAnchor, multiplier: 0.8),
            separatorLine2.leadingAnchor.constraint(equalTo: followerMeterView.trailingAnchor),
            separatorLine2.centerYAnchor.constraint(equalTo: followerMeterView.centerYAnchor),
            separatorLine2.widthAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: self)),
            separatorLine2.heightAnchor.constraint(equalTo: containerStackView.heightAnchor, multiplier: 0.8),
        ])
        
        followingMeterView.indicatorLabel.text = L10n.Common.Controls.ProfileDashboard.following
        followerMeterView.indicatorLabel.text = L10n.Common.Controls.ProfileDashboard.followers
        listedMeterView.indicatorLabel.text = L10n.Common.Controls.ProfileDashboard.listed
        
        let meterViews: [ProfileDashboardMeterView] = [followingMeterView, followerMeterView, listedMeterView]
        meterViews.forEach { statusItemView in
            let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
            tapGestureRecognizer.addTarget(self, action: #selector(ProfileDashboardView.tapGestureRecognizerHandler(_:)))
            statusItemView.addGestureRecognizer(tapGestureRecognizer)
        }
        
        Publishers.CombineLatest(
            UIContentSizeCategory.publisher,
            $isAllowAdaptiveLayout
        )
        .sink { [weak self] category, isAllowAdaptiveLayout in
            guard let self = self else { return }
            
            if isAllowAdaptiveLayout, category >= .accessibilityLarge {
                containerStackView.axis = .vertical
                containerStackView.spacing = 10
                containerStackView.alignment = .leading // set leading
                meterViews.forEach { meterView in
                    meterView.container.axis = .horizontal
                    meterView.container.distribution = .fill
                }
                self.separatorLine1.alpha = 0
                self.separatorLine2.alpha = 0
            } else {
                containerStackView.axis = .horizontal
                containerStackView.spacing = 0
                containerStackView.alignment = .fill    // restore default
                meterViews.forEach { meterView in
                    meterView.container.axis = .vertical
                    meterView.container.distribution = .fillEqually
                }
                self.separatorLine1.alpha = 1
                self.separatorLine2.alpha = 1
            }
        }
        .store(in: &_disposeBag)
        
    }
}

extension ProfileDashboardView {
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let sourceView = sender.view as? ProfileDashboardMeterView else {
            assertionFailure()
            return
        }
        switch sourceView {
        case followingMeterView:
            delegate?.profileDashboardView(self, followingMeterViewDidPressed: sourceView)
        case followerMeterView:
            delegate?.profileDashboardView(self, followersMeterViewDidPressed: sourceView)
        case listedMeterView:
            delegate?.profileDashboardView(self, listedMeterViewDidPressed: sourceView)
        default:
            break
        }
    }
}
