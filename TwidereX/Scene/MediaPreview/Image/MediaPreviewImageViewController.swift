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

protocol MediaPreviewImageViewControllerDelegate: AnyObject {
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, tapGestureRecognizerDidTrigger tapGestureRecognizer: UITapGestureRecognizer)
    func mediaPreviewImageViewController(_ viewController: MediaPreviewImageViewController, longPressGestureRecognizerDidTrigger longPressGestureRecognizer: UILongPressGestureRecognizer)
}

final class MediaPreviewImageViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: MediaPreviewImageViewModel!
    weak var delegate: MediaPreviewImageViewControllerDelegate?

    let progressBarView = ProgressBarView()
    let previewImageView = MediaPreviewImageView()

    let tapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    let longPressGestureRecognizer = UILongPressGestureRecognizer()
    
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
        
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewImageView)
        NSLayoutConstraint.activate([
            previewImageView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            previewImageView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewImageView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewImageView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tapGestureRecognizer.addTarget(self, action: #selector(MediaPreviewImageViewController.tapGestureRecognizerHandler(_:)))
        longPressGestureRecognizer.addTarget(self, action: #selector(MediaPreviewImageViewController.longPressGestureRecognizerHandler(_:)))
        tapGestureRecognizer.require(toFail: previewImageView.doubleTapGestureRecognizer)
        tapGestureRecognizer.require(toFail: longPressGestureRecognizer)
        previewImageView.addGestureRecognizer(tapGestureRecognizer)
        previewImageView.addGestureRecognizer(longPressGestureRecognizer)
        
        switch viewModel.item {
        case .remote(let imageContext):
            progressBarView.isHidden = imageContext.thumbnail != nil
            guard let assetURL = imageContext.assetURL else {
                assertionFailure()
                return
            }
            previewImageView.imageView.af.setImage(
                withURL: assetURL,
                placeholderImage: imageContext.thumbnail,
                filter: nil,
                progress: { [weak self] progress in
                    guard let self = self else { return }
                    self.progressBarView.progress.value = CGFloat(progress.fractionCompleted)
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: load %s progress: %.2f", ((#file as NSString).lastPathComponent), #line, #function, assetURL.debugDescription, progress.fractionCompleted)
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
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: setImage url: %s", ((#file as NSString).lastPathComponent), #line, #function, assetURL.debugDescription)
        case .local(let imageContext):
            progressBarView.isHidden = true
            previewImageView.imageView.image = imageContext.image
            self.previewImageView.setup(image: imageContext.image, container: self.previewImageView, forceUpdate: true)
        }
    }
    
}

extension MediaPreviewImageViewController {
    
    @objc private func tapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.mediaPreviewImageViewController(self, tapGestureRecognizerDidTrigger: sender)
    }
    
    @objc private func longPressGestureRecognizerHandler(_ sender: UILongPressGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        switch sender.state {
        case .began:
            delegate?.mediaPreviewImageViewController(self, longPressGestureRecognizerDidTrigger: sender)
        default:
            break
        }
    }
    
}

// MARK: - ShareActivityProvider
extension MediaPreviewImageViewController: ShareActivityProvider {
    var activities: [Any] {
        return []
    }
    
    var applicationActivities: [UIActivity] {
        switch viewModel.item {
        case .remote(let previewContext):
            guard let url = previewContext.assetURL else { return [] }
            return [
                SavePhotoActivity(context: viewModel.context, url: url, resourceType: .photo)
            ]
        case .local:
            return []
        }
    }
}

// MARK: - MediaPreviewTransitionViewController
extension MediaPreviewImageViewController: MediaPreviewTransitionViewController {
    var mediaPreviewTransitionContext: MediaPreviewTransitionContext? {
        let imageView = previewImageView.imageView
        let _snapshot: UIView? = {
            if imageView.image == nil {
                return progressBarView.snapshotView(afterScreenUpdates: false)
            } else {
                return imageView.snapshotView(afterScreenUpdates: false)
            }
        }()
        
        guard let snapshot = _snapshot else {
            return nil
        }

        return MediaPreviewTransitionContext(
            transitionView: imageView,
            snapshot: snapshot,
            snapshotTransitioning: snapshot
        )
    }
}
