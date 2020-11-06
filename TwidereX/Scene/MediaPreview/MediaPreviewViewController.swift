//
//  MediaPreviewViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-5.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import Pageboy

final class MediaPreviewViewController: UIViewController, NeedsDependency {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var viewModel: MediaPreviewViewModel!
    
    // TODO: adapt Reduce Transparency preference
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    
    let pagingViewConttroller = MediaPreviewPagingViewController()
        
    let mediaInfoDescriptionView = MediaInfoDescriptionView()
    
    let closeButtonBackground: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .systemBackground
        backgroundView.alpha = 0.5
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = 8
        return backgroundView
    }()
    
    let closeButtonBackgroundVisualEffectView = UIVisualEffectView(effect:
        UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemMaterial))
    )
    
    let closeButton: UIButton = {
        let button = HitTestExpandedButton(type: .custom)
        button.imageView?.tintColor = .label
        button.setImage(Asset.Editing.xmarkRound.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
}

extension MediaPreviewViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .dark
                
        visualEffectView.frame = view.bounds
        view.addSubview(visualEffectView)
        
        pagingViewConttroller.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(pagingViewConttroller)
        view.addSubview(pagingViewConttroller.view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: pagingViewConttroller.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: pagingViewConttroller.view.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: pagingViewConttroller.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: pagingViewConttroller.view.trailingAnchor),
        ])
        pagingViewConttroller.didMove(toParent: self)
        
        mediaInfoDescriptionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mediaInfoDescriptionView)
        NSLayoutConstraint.activate([
            view.bottomAnchor.constraint(equalTo: mediaInfoDescriptionView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: mediaInfoDescriptionView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: mediaInfoDescriptionView.trailingAnchor),
        ])

        closeButtonBackground.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButtonBackground)
        NSLayoutConstraint.activate([
            closeButtonBackground.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 12),
            closeButtonBackground.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor)
        ])
        closeButtonBackgroundVisualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        closeButtonBackground.addSubview(closeButtonBackgroundVisualEffectView)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButtonBackgroundVisualEffectView.contentView.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: closeButtonBackgroundVisualEffectView.topAnchor, constant: 4),
            closeButton.leadingAnchor.constraint(equalTo: closeButtonBackgroundVisualEffectView.leadingAnchor, constant: 4),
            closeButtonBackgroundVisualEffectView.trailingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 4),
            closeButtonBackgroundVisualEffectView.bottomAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 4),
        ])
        
        closeButton.addTarget(self, action: #selector(MediaPreviewViewController.closeButtonPressed(_:)), for: .touchUpInside)
        
        pagingViewConttroller.interPageSpacing = 10
        pagingViewConttroller.dataSource = viewModel
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        visualEffectView.frame = view.bounds
    }
    
}

extension MediaPreviewViewController {
    
    @objc private func closeButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
    
}
