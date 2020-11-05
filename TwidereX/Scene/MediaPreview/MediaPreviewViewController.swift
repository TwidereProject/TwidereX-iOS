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

final class MediaPreviewViewController: UIViewController, NeedsDependency {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var viewModel: MediaPreviewViewModel!
    
    let mediaInfoDescriptionView = MediaInfoDescriptionView()
}


extension MediaPreviewViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .red
        
        mediaInfoDescriptionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mediaInfoDescriptionView)
        NSLayoutConstraint.activate([
            view.bottomAnchor.constraint(equalTo: mediaInfoDescriptionView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: mediaInfoDescriptionView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: mediaInfoDescriptionView.trailingAnchor),
        ])
    }
    
}
