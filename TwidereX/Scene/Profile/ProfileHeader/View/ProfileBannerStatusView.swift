//
//  ProfileBannerStatusView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-25.
//

import UIKit

final class ProfileBannerStatusView: UIView {
    
    let followingStatusItemView = ProfileBannerStatusItemView()
    let followersStatusItemView = ProfileBannerStatusItemView()
    let listedStatusItemView = ProfileBannerStatusItemView()
    
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
