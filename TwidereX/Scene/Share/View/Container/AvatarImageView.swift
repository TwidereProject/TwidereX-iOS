//
//  AvatarImageView.swift
//  AvatarImageView
//
//  Created by Cirno MainasuK on 2021-8-20.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import FLAnimatedImage
import AlamofireImage

class AvatarImageView: FLAnimatedImageView {
    var imageViewSize: CGSize?
    var configuration = Configuration(url: nil)
}

extension AvatarImageView {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        setup(corner: configuration.corner)
    }
    
    private func setup(corner: Configuration.Corner) {
        layer.masksToBounds = true
        switch configuration.corner {
        case .circle:
            layer.cornerCurve = .circular
            layer.cornerRadius = frame.width / 2
        case .roundRect(let radius):
            layer.cornerCurve = .continuous
            layer.cornerRadius = radius
        }
    }
    
}

extension AvatarImageView {
    
    static let placeholder = UIImage.placeholder(color: .systemFill)
    
    struct Configuration {
        let url: URL?
        let placeholder: UIImage?
        let corner: Corner
        
        init(
            url: URL?,
            placeholder: UIImage = AvatarImageView.placeholder,
            corner: Corner = .circle
        ) {
            self.url = url
            self.placeholder = placeholder
            self.corner = corner
        }
        
        enum Corner {
            case circle
            case roundRect(radius: CGFloat)
        }
    }
    
    func configure(configuration: Configuration) {
        // reset
        cancelTask()
        af.cancelImageRequest()
        
        self.configuration = configuration
        setup(corner: configuration.corner)
        
        guard let url = configuration.url else {
            image = configuration.placeholder
            return
        }
        
        switch url.pathExtension.lowercased() {
        case "gif":
            setImage(
                url: configuration.url,
                placeholder: configuration.placeholder,
                scaleToSize: imageViewSize
            )
        default:
            let filter: ImageFilter? = {
                if let imageViewSize = self.imageViewSize {
                    return ScaledToSizeFilter(size: imageViewSize)
                }
                guard self.frame.size.width != 0,
                      self.frame.size.height != 0
                else { return nil }
                return ScaledToSizeFilter(size: self.frame.size)
            }()
            
            af.setImage(withURL: url, filter: filter)
        }
    }
    
}
