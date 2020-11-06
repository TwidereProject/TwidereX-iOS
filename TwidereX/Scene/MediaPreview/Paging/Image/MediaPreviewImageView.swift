//
//  MediaPreviewImageView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-6.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit

final class MediaPreviewImageView: UIScrollView {
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    let doubleTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.numberOfTapsRequired = 2
        return tapGestureRecognizer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension MediaPreviewImageView {
    
    private func _init() {
        isUserInteractionEnabled = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false

        bouncesZoom = true
        minimumZoomScale = 1.0
        maximumZoomScale = 4.0
        
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageView)
        
        doubleTapGestureRecognizer.addTarget(self, action: #selector(MediaPreviewImageView.doubleTapGestureRecognizerHandler(_:)))
        imageView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        delegate = self
    }

}

extension MediaPreviewImageView {
 
    @objc private func doubleTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let middleZoomScale = 0.5 * maximumZoomScale
        if zoomScale >= middleZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            let center = sender.location(in: imageView)
            let zoomRect: CGRect = {
                let width = bounds.width / middleZoomScale
                let height = bounds.height / middleZoomScale
                return CGRect(
                    x: center.x - 0.5 * width,
                    y: center.y - 0.5 * height,
                    width: width,
                    height: height
                )
            }()
            zoom(to: zoomRect, animated: true)
        }
    }
    
}

extension MediaPreviewImageView {

    func setup(image: UIImage, container: UIView) {
        contentSize = image.size
        imageView.frame = container.bounds
        imageView.image = image
        
        // reset to normal
        zoomScale = minimumZoomScale
        contentOffset = .zero
    }
    
}

// MARK: - UIScrollViewDelegate
extension MediaPreviewImageView: UIScrollViewDelegate {
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}
