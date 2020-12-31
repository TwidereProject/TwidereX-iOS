//
//  CornerSmoothPreviewViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-31.
//  Copyright © 2020 Twidere. All rights reserved.
//

#if DEBUG
import os.log
import UIKit

final class CornerSmoothPreviewViewController: UIViewController {
    
    let redBackgroundImageView = UIImageView()
    let yellowBackgroundImageView = UIImageView()
    
    func setupCornerSmoothImage(for imageView: UIImageView) {
        guard imageView.bounds.size != .zero else { return }
        let resizedImage = UIImage
            .placeholder(size: imageView.bounds.size, color: .systemYellow)
        let cornerSmoothImage = resizedImage
            .af.imageRounded(withCornerRadius: 27 * resizedImage.scale, divideRadiusByImageScale: true)
        imageView.image = cornerSmoothImage
    }
    
}

extension CornerSmoothPreviewViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Corner Smooth Preview"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(CornerSmoothPreviewViewController.closeBarButtonDidPressed(_:)))
    
        [redBackgroundImageView, yellowBackgroundImageView].forEach { imageView in
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
                imageView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                view.layoutMarginsGuide.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 100),
            ])
        }
        
        redBackgroundImageView.image = UIImage.placeholder(color: .systemRed)
        redBackgroundImageView.layer.masksToBounds = true
        redBackgroundImageView.layer.cornerRadius = 27
        
        setupCornerSmoothImage(for: yellowBackgroundImageView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupCornerSmoothImage(for: yellowBackgroundImageView)
    }
    
}

extension CornerSmoothPreviewViewController {
    @objc private func closeBarButtonDidPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
}

#endif
