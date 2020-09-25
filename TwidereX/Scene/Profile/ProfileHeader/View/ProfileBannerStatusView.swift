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
