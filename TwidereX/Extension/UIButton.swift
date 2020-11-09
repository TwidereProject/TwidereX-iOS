//
//  UIBarButton.swift
//  TwidereX
//
//  Created by DTK on 2020-11-9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

extension UIButton {
    
    static let avatarButtonSize = CGSize(width: 30, height: 30)
    
    static var avatarButton: UIButton {
        let button = UIButton(type: .custom)
        let placeholderImage = UIImage
            .placeholder(size: avatarButtonSize, color: .systemFill)
            .af.imageRoundedIntoCircle()
        button.setImage(placeholderImage, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: avatarButtonSize.width).priority(.defaultHigh),
            button.heightAnchor.constraint(equalToConstant: avatarButtonSize.height).priority(.defaultHigh),
        ])
        return button
    }
    
}
