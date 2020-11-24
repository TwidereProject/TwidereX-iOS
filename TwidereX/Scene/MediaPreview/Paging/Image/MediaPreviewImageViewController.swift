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

protocol MediaPreviewImageViewControllerDelegate: class {
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, tapGestureRecognizerDidTrigger tapGestureRecognizer: UITapGestureRecognizer)
}

final class MediaPreviewImageViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: MediaPreviewImageViewModel!
    weak var delegate: MediaPreviewImageViewControllerDelegate?

    let progressBarView = ProgressBarView()
    lazy var previewImageView = MediaPreviewImageView(frame: view.bounds)

    let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        previewImageView.imageView.af.cancelImageRequest()
    }
}

extension MediaPreviewImageViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressBarView.tintColor = .white
        progressBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressBarView)
        NSLayoutConstraint.activate([
            progressBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressBarView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressBarView.widthAnchor.constraint(equalToConstant: 120),
            progressBarView.heightAnchor.constraint(equalToConstant: 44),
        ])
        
        progressBarView.isHidden = viewModel.thumbnail != nil
        
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
        
        previewImageView.imageView.af.setImage(
            withURL: viewModel.url,
            placeholderImage: viewModel.thumbnail,
            filter: nil,
            progress: { [weak self] progress in
                guard let self = self else { return }
                self.progressBarView.progress.value = CGFloat(progress.fractionCompleted)
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: load %s progress: %.2f", ((#file as NSString).lastPathComponent), #line, #function, self.viewModel.url.debugDescription, progress.fractionCompleted)
            },
            imageTransition: .crossDissolve(0.3),
            runImageTransitionIfCached: false,
            completion: { [weak self] response in
                guard let self = self else { return }
                switch response.result {
                case .success(let image):
                    self.progressBarView.isHidden = true
                    self.previewImageView.imageView.image = image
                    self.previewImageView.setup(image: image, container: self.previewImageView, forceUpdate: true)
                case .failure(let error):
                    // TODO:
                    break
                }
            }
        )
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: setImage url: %s", ((#file as NSString).lastPathComponent), #line, #function, viewModel.url.debugDescription)
    }
    
}

extension MediaPreviewImageViewController {
    
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.mediaPreviewImageViewController(self, tapGestureRecognizerDidTrigger: sender)
    }
    
}
