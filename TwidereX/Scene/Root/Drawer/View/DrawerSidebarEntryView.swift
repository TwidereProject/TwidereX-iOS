//
//  DrawerSidebarEntryView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import SwiftUI

final class DrawerSidebarEntryView: UIView {
    
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        label.textColor = .secondaryLabel
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

extension DrawerSidebarEntryView {
    
    private func _init() {
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor,constant: 16),
            iconImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            bottomAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 16),
        ])
        iconImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        iconImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 18),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
        ])
    }
}

#if DEBUG

struct DrawerSidebarEntryView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 375) {
            let view = DrawerSidebarEntryView()
            view.iconImageView.image = UIImage(systemName: "person")
            view.titleLabel.text = "Person"
            return view
        }
        .previewLayout(.fixed(width: 375, height: 320))
    }
}

#endif
