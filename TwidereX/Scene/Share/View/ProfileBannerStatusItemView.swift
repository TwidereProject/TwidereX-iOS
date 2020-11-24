//
//  ProfileBannerStatusItemView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-25.
//

import UIKit

final class ProfileBannerStatusItemView: UIView {
    
    let countLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.text = "999"
        label.textAlignment = .center
        return label
    }()
    
    let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.text = "Following"
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ProfileBannerStatusItemView {
    private func _init() {
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: topAnchor),
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: countLabel.trailingAnchor),
        ])
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            bottomAnchor.constraint(equalTo: statusLabel.bottomAnchor),
            countLabel.heightAnchor.constraint(equalTo: statusLabel.heightAnchor),
        ])
    }
}

#if DEBUG
import SwiftUI

struct ProfileBannerStatusItemView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 100) {
            ProfileBannerStatusItemView()
        }
        .previewLayout(.fixed(width: 100, height: 44))
    }
}
#endif
