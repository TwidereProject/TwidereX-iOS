//
//  EmptyStateView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-29.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class EmptyStateView: UIView {
    
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor.secondaryLabel.withAlphaComponent(0.5)
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.text = " "
        return label
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.text = " "
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

extension EmptyStateView {
    private func _init() {
        preservesSuperviewLayoutMargins = true
        
        let topPaddingView = UIView()
        let centerPaddingView = UIView()
        let bottomPaddingView = UIView()
        
        topPaddingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topPaddingView)
        NSLayoutConstraint.activate([
            topPaddingView.topAnchor.constraint(equalTo: topAnchor),
            topPaddingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topPaddingView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topPaddingView.bottomAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 120).priority(.defaultHigh),
            iconImageView.heightAnchor.constraint(equalToConstant: 120).priority(.defaultHigh),
        ])
        
        centerPaddingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(centerPaddingView)
        NSLayoutConstraint.activate([
            centerPaddingView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor),
            centerPaddingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            centerPaddingView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
        ])
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
        ])
        
        bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomPaddingView)
        NSLayoutConstraint.activate([
            bottomPaddingView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor),
            bottomPaddingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomPaddingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: bottomPaddingView.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            centerPaddingView.heightAnchor.constraint(equalTo: topPaddingView.heightAnchor, multiplier: 0.5),
            bottomPaddingView.heightAnchor.constraint(equalTo: topPaddingView.heightAnchor, multiplier: 1.0),
        ])
    }
}


#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct EmptyStateView_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview {
            let emptyStateView = EmptyStateView()
            emptyStateView.iconImageView.image = Asset.Human.eyeSlashLarge.image.withRenderingMode(.alwaysTemplate)
            emptyStateView.titleLabel.text = "Permission Denied"
            
            return emptyStateView
        }
    }
    
}

#endif

