//
//  AvatarBarButtonItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-31.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import TwidereUI

public final class AvatarBarButtonItem: UIBarButtonItem {

    public static let avatarButtonSize = CGSize(width: 30, height: 30)
    
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(view: self)
        return viewModel
    }()

    public let avatarButton: AvatarButton = {
        let button = AvatarButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: avatarButtonSize.width).priority(.required - 1),
            button.heightAnchor.constraint(equalToConstant: avatarButtonSize.height).priority(.required - 1),
        ])
        return button
    }()
    
    public override init() {
        super.init()
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension AvatarBarButtonItem {
    
    private func _init() {
        customView = avatarButton
    }
    
}
