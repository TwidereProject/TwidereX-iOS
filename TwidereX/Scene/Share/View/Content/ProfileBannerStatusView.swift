//
//  ProfileBannerStatusView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-25.
//

import os.log
import UIKit

protocol ProfileBannerStatusViewDelegate: class {
    func profileBannerStatusView(_ view: ProfileBannerStatusView, followingStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView)
    func profileBannerStatusView(_ view: ProfileBannerStatusView, followersStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView)
    func profileBannerStatusView(_ view: ProfileBannerStatusView, listedStatusItemViewDidPressed statusItemView: ProfileBannerStatusItemView)
}

final class ProfileBannerStatusView: UIView {
    
    let followingStatusItemView = ProfileBannerStatusItemView()
    let followersStatusItemView = ProfileBannerStatusItemView()
    let listedStatusItemView = ProfileBannerStatusItemView()
        
    weak var delegate: ProfileBannerStatusViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileBannerStatusView {
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
        containerStackView.addArrangedSubview(followingStatusItemView)
        containerStackView.addArrangedSubview(followersStatusItemView)
        containerStackView.addArrangedSubview(listedStatusItemView)
        
        let sepratorLine1 = UIView.separatorLine
        let sepratorLine2 = UIView.separatorLine
        sepratorLine1.translatesAutoresizingMaskIntoConstraints = false
        sepratorLine2.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sepratorLine1)
        addSubview(sepratorLine2)
        NSLayoutConstraint.activate([
            sepratorLine1.leadingAnchor.constraint(equalTo: followingStatusItemView.trailingAnchor),
            sepratorLine1.centerYAnchor.constraint(equalTo: followingStatusItemView.centerYAnchor),
            sepratorLine1.widthAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: self)),
            sepratorLine1.heightAnchor.constraint(equalToConstant: 24),
            sepratorLine2.leadingAnchor.constraint(equalTo: followersStatusItemView.trailingAnchor),
            sepratorLine2.centerYAnchor.constraint(equalTo: followersStatusItemView.centerYAnchor),
            sepratorLine2.widthAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: self)),
            sepratorLine2.heightAnchor.constraint(equalToConstant: 24),
        ])
        
        followingStatusItemView.statusLabel.text = L10n.Common.Controls.ProfileDashboard.following
        followersStatusItemView.statusLabel.text = L10n.Common.Controls.ProfileDashboard.followers
        listedStatusItemView.statusLabel.text = L10n.Common.Controls.ProfileDashboard.listed
        
        [followingStatusItemView, followersStatusItemView, listedStatusItemView].forEach { statusItemView in
            let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
            tapGestureRecognizer.addTarget(self, action: #selector(ProfileBannerStatusView.tapGestureRecognizerHandler(_:)))
            statusItemView.addGestureRecognizer(tapGestureRecognizer)
        }
    }
}

extension ProfileBannerStatusView {
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let sourceView = sender.view as? ProfileBannerStatusItemView else {
            assertionFailure()
            return
        }
        if sourceView === followingStatusItemView {
            delegate?.profileBannerStatusView(self, followingStatusItemViewDidPressed: sourceView)
        } else if sourceView === followersStatusItemView {
            delegate?.profileBannerStatusView(self, followersStatusItemViewDidPressed: sourceView)
        } else if sourceView === listedStatusItemView {
            delegate?.profileBannerStatusView(self, listedStatusItemViewDidPressed: sourceView)
        }
    }
}


#if DEBUG
import SwiftUI

struct ProfileBannerStatusView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 375) {
            ProfileBannerStatusView()
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
}
#endif
