//
//  ProfileDashboardMeterView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

final class ProfileDashboardMeterView: UIView {
    
    let container = UIStackView()
    
    let countLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.text = "999"
        label.textAlignment = .center
        return label
    }()
    
    let indicatorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.text = L10n.Common.Controls.ProfileDashboard.following
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

extension ProfileDashboardMeterView {
    private func _init() {
        container.axis = .vertical
        container.distribution = .fillEqually
        
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        container.addArrangedSubview(countLabel)
        container.addArrangedSubview(indicatorLabel)
    }
}

#if DEBUG
import SwiftUI

struct ProfileDashboardMeterView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 100) {
            ProfileDashboardMeterView()
        }
        .previewLayout(.fixed(width: 100, height: 44))
    }
}
#endif
