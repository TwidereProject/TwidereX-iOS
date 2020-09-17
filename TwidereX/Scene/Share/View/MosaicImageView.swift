//
//  MosaicImageView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-17.
//

import func AVFoundation.AVMakeRect
import UIKit

final class MosaicImageView: UIView {

    var cornerRadius: CGFloat = 8
    let container = UIStackView()
    var imageViews = [UIImageView]()

    private var containerHeightLayoutConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension MosaicImageView {
    
    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        containerHeightLayoutConstraint = container.heightAnchor.constraint(equalToConstant: 162).priority(.defaultHigh)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        container.axis = .horizontal
        container.distribution = .fillEqually
        container.layer.masksToBounds = true
    }
    
}

extension MosaicImageView {
    
    func reset() {
        container.arrangedSubviews.forEach { subview in
            container.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        imageViews = []
        
        layer.masksToBounds = true
        layer.cornerRadius = 0
    }
    
    func setupImageView(aspectRatio: CGSize, maxSize: CGSize) -> UIImageView {
        reset()
                
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        container.addArrangedSubview(contentView)
        
        let rect = AVMakeRect(
            aspectRatio: aspectRatio,
            insideRect: CGRect(origin: .zero, size: maxSize)
        )

        let imageView = UIImageView()
        imageViews.append(imageView)
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = cornerRadius
        imageView.contentMode = .scaleAspectFill
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.widthAnchor.constraint(equalToConstant: floor(rect.width)).priority(.defaultHigh),
        ])
        containerHeightLayoutConstraint.constant = floor(rect.height)
        containerHeightLayoutConstraint.isActive = true

        return imageView
    }
    
    func setupImageViews(count: Int, maxHeight: CGFloat) -> [UIImageView] {
        reset()
        guard count > 1 else {
            return []
        }
        
        containerHeightLayoutConstraint.constant = maxHeight
        container.layer.cornerRadius = cornerRadius
        
        let contentLeftStackView = UIStackView()
        let contentRightStackView = UIStackView()
        [contentLeftStackView, contentRightStackView].forEach { stackView in
            stackView.axis = .vertical
            stackView.distribution = .fillEqually
        }
        container.addArrangedSubview(contentLeftStackView)
        container.addArrangedSubview(contentRightStackView)
        
        var imageViews: [UIImageView] = []
        for _ in 0..<count {
            imageViews.append(UIImageView())
        }
        self.imageViews.append(contentsOf: imageViews)
        imageViews.forEach { imageView in
            imageView.layer.masksToBounds = true
            imageView.contentMode = .scaleAspectFill
        }
        if count == 2 {
            contentLeftStackView.addArrangedSubview(imageViews[0])
            contentRightStackView.addArrangedSubview(imageViews[1])
        } else if count == 3 {
            contentLeftStackView.addArrangedSubview(imageViews[0])
            contentRightStackView.addArrangedSubview(imageViews[1])
            contentRightStackView.addArrangedSubview(imageViews[2])
        } else if count == 4 {
            contentLeftStackView.addArrangedSubview(imageViews[0])
            contentRightStackView.addArrangedSubview(imageViews[1])
            contentLeftStackView.addArrangedSubview(imageViews[2])
            contentRightStackView.addArrangedSubview(imageViews[3])
        }
        return imageViews
    }
}


#if DEBUG
import SwiftUI

struct MosaicImageView_Previews: PreviewProvider {
    
    static var images: [UIImage] {
        return ["jake-davies", "zhang-kaiyv", "watcharlie", "moran"]
            .map { UIImage(named: $0)! }
    }
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                let view = MosaicImageView()
                let image = images[0]
                let imageView = view.setupImageView(
                    aspectRatio: image.size,
                    maxSize: CGSize(width: 375, height: 400)
                )
                imageView.image = image
                return view
            }
            .previewLayout(.fixed(width: 375, height: 400))
            .previewDisplayName("Portrait - one image")
            UIViewPreview(width: 375) {
                let view = MosaicImageView()
                let image = images[1]
                let imageView = view.setupImageView(
                    aspectRatio: image.size,
                    maxSize: CGSize(width: 375, height: 400)
                )
                imageView.layer.masksToBounds = true
                imageView.layer.cornerRadius = 8
                imageView.contentMode = .scaleAspectFill
                imageView.image = image
                return view
            }
            .previewLayout(.fixed(width: 375, height: 400))
            .previewDisplayName("Landscape - one image")
            UIViewPreview(width: 375) {
                let view = MosaicImageView()
                let images = self.images.prefix(2)
                let imageViews = view.setupImageViews(count: images.count, maxHeight: 162)
                for (i, imageView) in imageViews.enumerated() {
                    imageView.image = images[i]
                }
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("two image")
            UIViewPreview(width: 375) {
                let view = MosaicImageView()
                let images = self.images.prefix(3)
                let imageViews = view.setupImageViews(count: images.count, maxHeight: 162)
                for (i, imageView) in imageViews.enumerated() {
                    imageView.image = images[i]
                }
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("three image")
            UIViewPreview(width: 375) {
                let view = MosaicImageView()
                let images = self.images.prefix(4)
                let imageViews = view.setupImageViews(count: images.count, maxHeight: 162)
                for (i, imageView) in imageViews.enumerated() {
                    imageView.image = images[i]
                }
                return view
            }
            .previewLayout(.fixed(width: 375, height: 200))
            .previewDisplayName("four image")
        }
    }
}
#endif
