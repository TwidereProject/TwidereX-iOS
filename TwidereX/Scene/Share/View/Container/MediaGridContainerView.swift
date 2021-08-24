//
//  MediaGridContainerView.swift
//  MediaGridContainerView
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import func AVFoundation.AVMakeRect

final class MediaGridContainerView: UIView {
    
    static let maxCount = 9
    
    private(set) var mediaViews: [MediaView] = {
        var mediaViews: [MediaView] = []
        for i in 0..<MediaGridContainerView.maxCount {
            let mediaView = MediaView()
            mediaView.tag = i
            mediaViews.append(mediaView)
        }
        return mediaViews
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

extension MediaGridContainerView {
    private func _init() {
        
    }
}

extension MediaGridContainerView {

    func dequeueMediaView(adaptiveLayout layout: AdaptiveLayout) -> MediaView {
        prepareForReuse()
        let mediaView = mediaViews[0]
        layout.layout(in: self, mediaView: mediaView)
        return mediaView
    }
    
    func dequeueMediaView(gridLayout layout: GridLayout) -> [MediaView] {
        prepareForReuse()
        let mediaViews = Array(mediaViews[0..<layout.count])
        layout.layout(in: self, mediaViews: mediaViews)
        return mediaViews
    }
    
    func prepareForReuse() {
        mediaViews.forEach { view in
            view.removeFromSuperview()
            view.removeConstraints(view.constraints)
            view.prepareForReuse()
        }
        
        subviews.forEach { view in
            view.removeFromSuperview()
        }
        
        removeConstraints(constraints)
    }

}

extension MediaGridContainerView {
    struct AdaptiveLayout {
        let aspectRatio: CGSize
        let maxSize: CGSize
        
        func layout(in view: UIView, mediaView: MediaView) {
            let imageViewSize = AVMakeRect(aspectRatio: aspectRatio, insideRect: CGRect(origin: .zero, size: maxSize)).size
            mediaView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(mediaView)
            NSLayoutConstraint.activate([
                mediaView.topAnchor.constraint(equalTo: view.topAnchor),
                mediaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                mediaView.trailingAnchor.constraint(equalTo: view.trailingAnchor).priority(.defaultLow),
                mediaView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                mediaView.widthAnchor.constraint(equalToConstant: imageViewSize.width).priority(.required - 1),
                mediaView.heightAnchor.constraint(equalToConstant: imageViewSize.height).priority(.required - 1),
            ])
        }
    }
    
    struct GridLayout {
        static let spacing: CGFloat = 8
        
        let count: Int
        let maxSize: CGSize
        
        init(count: Int, maxSize: CGSize) {
            self.count = min(count, 9)
            self.maxSize = maxSize
        
        }
        
        private func createStackView(axis: NSLayoutConstraint.Axis) -> UIStackView {
            let stackView = UIStackView()
            stackView.axis = axis
            stackView.semanticContentAttribute = .forceLeftToRight
            stackView.spacing = GridLayout.spacing
            stackView.distribution = .fillEqually
            return stackView
        }
        
        func layout(in view: UIView, mediaViews: [MediaView]) {
            let containerVerticalStackView = createStackView(axis: .vertical)
            containerVerticalStackView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(containerVerticalStackView)
            NSLayoutConstraint.activate([
                containerVerticalStackView.topAnchor.constraint(equalTo: view.topAnchor),
                containerVerticalStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerVerticalStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                containerVerticalStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            
            let count = mediaViews.count
            switch count {
            case 1:
                assertionFailure("should use Adaptive Layout")
                containerVerticalStackView.addArrangedSubview(mediaViews[0])
            case 2:
                let horizontalStackView = createStackView(axis: .horizontal)
                containerVerticalStackView.addArrangedSubview(horizontalStackView)
                horizontalStackView.addArrangedSubview(mediaViews[0])
                horizontalStackView.addArrangedSubview(mediaViews[1])
            case 3:
                let horizontalStackView = createStackView(axis: .horizontal)
                containerVerticalStackView.addArrangedSubview(horizontalStackView)
                horizontalStackView.addArrangedSubview(mediaViews[0])
                
                let verticalStackView = createStackView(axis: .vertical)
                horizontalStackView.addArrangedSubview(verticalStackView)
                verticalStackView.addArrangedSubview(mediaViews[1])
                verticalStackView.addArrangedSubview(mediaViews[2])
            case 4:
                let topHorizontalStackView = createStackView(axis: .horizontal)
                containerVerticalStackView.addArrangedSubview(topHorizontalStackView)
                topHorizontalStackView.addArrangedSubview(mediaViews[0])
                topHorizontalStackView.addArrangedSubview(mediaViews[1])
                
                let bottomHorizontalStackView = createStackView(axis: .horizontal)
                containerVerticalStackView.addArrangedSubview(bottomHorizontalStackView)
                bottomHorizontalStackView.addArrangedSubview(mediaViews[2])
                bottomHorizontalStackView.addArrangedSubview(mediaViews[3])
            case 5...9:
                let topHorizontalStackView = createStackView(axis: .horizontal)
                containerVerticalStackView.addArrangedSubview(topHorizontalStackView)
                topHorizontalStackView.addArrangedSubview(mediaViews[0])
                topHorizontalStackView.addArrangedSubview(mediaViews[1])
                topHorizontalStackView.addArrangedSubview(mediaViews[2])
                
                func mediaViewOrPlaceholderView(at index: Int) -> UIView {
                    return index < mediaViews.count ? mediaViews[index] : UIView()
                }
                let middleHorizontalStackView = createStackView(axis: .horizontal)
                containerVerticalStackView.addArrangedSubview(middleHorizontalStackView)
                middleHorizontalStackView.addArrangedSubview(mediaViews[3])
                middleHorizontalStackView.addArrangedSubview(mediaViews[4])
                middleHorizontalStackView.addArrangedSubview(mediaViewOrPlaceholderView(at: 5))
                
                if count > 6 {
                    let bottomHorizontalStackView = createStackView(axis: .horizontal)
                    containerVerticalStackView.addArrangedSubview(bottomHorizontalStackView)
                    bottomHorizontalStackView.addArrangedSubview(mediaViewOrPlaceholderView(at: 6))
                    bottomHorizontalStackView.addArrangedSubview(mediaViewOrPlaceholderView(at: 7))
                    bottomHorizontalStackView.addArrangedSubview(mediaViewOrPlaceholderView(at: 8))
                }
            default:
                assertionFailure()
                return
            }
            
            let containerWidth = maxSize.width
            let containerHeight = count > 6 ? containerWidth : containerWidth * 2 / 3
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: containerWidth).priority(.required - 1),
                view.heightAnchor.constraint(equalToConstant: containerHeight).priority(.required - 1),
            ])
        }
    }
}
