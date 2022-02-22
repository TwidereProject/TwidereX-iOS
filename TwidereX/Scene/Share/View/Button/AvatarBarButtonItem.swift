//
//  AvatarBarButtonItem.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-31.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwidereUI

public protocol AvatarBarButtonItemDelegate: AnyObject {
    func avatarBarButtonItem(_ barButtonItem: AvatarBarButtonItem, didLongPressed sender: UILongPressGestureRecognizer)
}

public final class AvatarBarButtonItem: UIBarButtonItem {
    
    let logger = Logger(subsystem: "AvatarBarButtonItem", category: "View")
    
    var disposeBag = Set<AnyCancellable>()
    weak var delegate: AvatarBarButtonItemDelegate?

    public static let size = CGSize(width: 30, height: 30)
    
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(view: self)
        return viewModel
    }()

    public let avatarButton: AvatarButton = {
        let button = AvatarButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size.width).priority(.required - 1),
            button.heightAnchor.constraint(equalToConstant: size.height).priority(.required - 1),
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
        
        let avatarButtonLongPressGestureRecognizer = UILongPressGestureRecognizer()
        avatarButtonLongPressGestureRecognizer.addTarget(self, action: #selector(AvatarBarButtonItem.avatarButtonDidLongPressed(_:)))
        avatarButton.addGestureRecognizer(avatarButtonLongPressGestureRecognizer)
    }
    
}

extension AvatarBarButtonItem {
    
    @objc func avatarButtonDidLongPressed(_ sender: UILongPressGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")

        switch sender.state {
        case .began:
            delegate?.avatarBarButtonItem(self, didLongPressed: sender)
        default:
            break
        }
    }
    
}
