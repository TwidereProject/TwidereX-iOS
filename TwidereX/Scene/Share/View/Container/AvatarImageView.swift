//
//  AvatarImageView.swift
//  AvatarImageView
//
//  Created by Cirno MainasuK on 2021-8-20.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import FLAnimatedImage

class AvatarImageView: FLAnimatedImageView {
    var imageViewSize: CGSize?
}

extension AvatarImageView {
    
    static let placeholder = UIImage.placeholder(color: .systemFill)
    
    struct Configuration {
        let url: URL?
        let placeholder: UIImage?
        let imageViewSize: CGSize?
        
        init(
            url: URL?,
            placeholder: UIImage = AvatarImageView.placeholder,
            imageViewSize: CGSize? = nil
        ) {
            self.url = url
            self.placeholder = placeholder
            self.imageViewSize = imageViewSize
        }
    }
    
    func configure(configuration: Configuration) {
        // reset
        cancelTask()
        af.cancelImageRequest()
        
        guard let url = configuration.url else {
            image = configuration.placeholder
            return
        }
        
        switch url.pathExtension.lowercased() {
        case "gif":
            setImage(
                url: configuration.url,
                placeholder: configuration.placeholder,
                scaleToSize: configuration.imageViewSize ?? self.imageViewSize
            )
        default:
            af.setImage(withURL: url)            
        }

    }
    
}
