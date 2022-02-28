//
//  MediaPreviewImageView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-6.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import func AVFoundation.AVMakeRect
import UIKit

final class MediaPreviewImageView: UIScrollView {
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.accessibilityIgnoresInvertColors = true
        imageView.isAccessibilityElement = true
        return imageView
    }()
    
    let doubleTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.numberOfTapsRequired = 2
        return tapGestureRecognizer
    }()
    
    private var containerFrame: CGRect?
    
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
        
        addSubview(imageView)
        
        doubleTapGestureRecognizer.addTarget(self, action: #selector(MediaPreviewImageView.doubleTapGestureRecognizerHandler(_:)))
        imageView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let image = imageView.image else { return }
        setup(image: image, container: self)
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

    func setup(image: UIImage, container: UIView, forceUpdate: Bool = false) {
        guard image.size.width > 0, image.size.height > 0 else  { return }
        guard container.bounds.width > 0, container.bounds.height > 0 else  { return }
        
        // do not setup when frame not change except force update
        if containerFrame == container.frame && !forceUpdate {
            return
        }
        containerFrame = container.frame
        
        // reset to normal
        zoomScale = minimumZoomScale
        
        let imageViewSize = AVMakeRect(aspectRatio: image.size, insideRect: container.bounds).size
        let imageContentInset: UIEdgeInsets = {
            if imageViewSize.width == container.bounds.width {
                return UIEdgeInsets(top: 0.5 * (container.bounds.height - imageViewSize.height), left: 0, bottom: 0, right: 0)
            } else {
                return UIEdgeInsets(top: 0, left: 0.5 * (container.bounds.width - imageViewSize.width), bottom: 0, right: 0)
            }
        }()
        imageView.frame = CGRect(origin: .zero, size: imageViewSize)
        imageView.image = image
        contentSize = imageViewSize
        contentInset = imageContentInset
        
        centerScrollViewContents()
        contentOffset = CGPoint(x: -contentInset.left, y: -contentInset.top)
        
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: setup image for container %s", ((#file as NSString).lastPathComponent), #line, #function, container.frame.debugDescription)
    }
    
}

// MARK: - UIScrollViewDelegate
extension MediaPreviewImageView: UIScrollViewDelegate {
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        centerScrollViewContents()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}

// Ref: https://stackoverflow.com/questions/14069571/keep-zoomable-image-in-center-of-uiscrollview
extension MediaPreviewImageView {
    
    private var scrollViewVisibleSize: CGSize {
        let contentInset = self.contentInset
        let scrollViewSize = bounds.standardized.size
        let width = scrollViewSize.width - contentInset.left - contentInset.right
        let height = scrollViewSize.height - contentInset.top - contentInset.bottom
        return CGSize(width: width, height: height)
    }

    private var scrollViewCenter: CGPoint {
        let scrollViewSize = self.scrollViewVisibleSize
        return CGPoint(x: scrollViewSize.width / 2.0,
                       y: scrollViewSize.height / 2.0)
    }

    private func centerScrollViewContents() {
        guard let image = imageView.image else { return }

        let imageViewSize = imageView.frame.size
        let imageSize = image.size

        var realImageSize: CGSize
        if imageSize.width / imageSize.height > imageViewSize.width / imageViewSize.height {
            realImageSize = CGSize(width: imageViewSize.width,
                                   height: imageViewSize.width / imageSize.width * imageSize.height)
        } else {
            realImageSize = CGSize(width: imageViewSize.height / imageSize.height * imageSize.width,
                                   height: imageViewSize.height)
        }

        var frame = CGRect.zero
        frame.size = realImageSize
        imageView.frame = frame

        let screenSize = self.frame.size
        let offsetX = screenSize.width > realImageSize.width ? (screenSize.width - realImageSize.width) / 2 : 0
        let offsetY = screenSize.height > realImageSize.height ? (screenSize.height - realImageSize.height) / 2 : 0
        contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)

        // The scroll view has zoomed, so you need to re-center the contents
        let scrollViewSize = scrollViewVisibleSize

        // First assume that image center coincides with the contents box center.
        // This is correct when the image is bigger than scrollView due to zoom
        var imageCenter = CGPoint(x: contentSize.width / 2.0,
                                  y: contentSize.height / 2.0)

        let center = scrollViewCenter

        // if image is smaller than the scrollView visible size - fix the image center accordingly
        if contentSize.width < scrollViewSize.width {
            imageCenter.x = center.x
        }

        if contentSize.height < scrollViewSize.height {
            imageCenter.y = center.y
        }

        imageView.center = imageCenter
    }
    
}
