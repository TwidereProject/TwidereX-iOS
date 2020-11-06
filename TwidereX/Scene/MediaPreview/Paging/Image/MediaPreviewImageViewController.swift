//
//  MediaPreviewImageViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-6.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class MediaPreviewImageViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: MediaPreviewImageViewModel!
    
    let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var previewImageView = MediaPreviewImageView(frame: view.bounds)

    let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
}

extension MediaPreviewImageViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(thumbnailImageView)
        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: view.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewImageView)
        NSLayoutConstraint.activate([
            previewImageView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            previewImageView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewImageView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewImageView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tapGestureRecognizer.addTarget(self, action: #selector(MediaPreviewImageViewController.tapGestureRecognizerHandler(_:)))
        tapGestureRecognizer.shouldRequireFailure(of: previewImageView.doubleTapGestureRecognizer)
        view.addGestureRecognizer(tapGestureRecognizer)

        
        viewModel.preview
            .receive(on: DispatchQueue.main)
            .sink { [weak self] preview in
                guard let self = self else { return }
                guard let image = preview else {
                    self.previewImageView.imageView.image = nil
                    return
                }
                
                self.previewImageView.setup(image: image, container: self.previewImageView)
            }
            .store(in: &disposeBag)
        
        //        thumbnailImageView.image = viewModel.thumbnail
        viewModel.preview.send(viewModel.thumbnail)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { _ in
            guard let image = self.previewImageView.imageView.image else { return }
            self.previewImageView.setup(image: image, container: self.previewImageView)
        } completion: { _ in
            // do nothing
        }

        super.viewWillTransition(to: size, with: coordinator)
    }
    
}

extension MediaPreviewImageViewController {
    
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
