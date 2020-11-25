//
//  ContextMenuImagePreviewViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-25.
//  Copyright © 2020 Twidere. All rights reserved.
//

import func AVFoundation.AVMakeRect
import UIKit

final class ContextMenuImagePreviewViewController: UIViewController {
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    // input
    var image: UIImage!
}

extension ContextMenuImagePreviewViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        imageView.image = image
        let frame = AVMakeRect(aspectRatio: image.size, insideRect: view.bounds)
        preferredContentSize = frame.size
    }
    
}
