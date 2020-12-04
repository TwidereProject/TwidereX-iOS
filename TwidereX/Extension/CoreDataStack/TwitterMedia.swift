//
//  TwitterMedia.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/10/21.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import CoreDataStack

extension TwitterMedia {
    
    public enum SizeKind: String {
        case thumbnail = "thumb"
        case small
        case medium
        case large
        case original = "orig"
    }
    
    public func photoURL(sizeKind: SizeKind) -> (URL, CGSize)? {
        guard type == "photo" else { return nil }
        guard let urlString = self.url, var url = URL(string: urlString) else { return nil }
        guard let width = self.width?.intValue, let height = self.height?.intValue else { return nil }
        
        let format = url.pathExtension
        url.deletePathExtension()
        
        guard var component = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        component.queryItems = [
            URLQueryItem(name: "format", value: format),
            URLQueryItem(name: "name", value: sizeKind.rawValue)
        ]
        guard let targetURL = component.url else { return nil }
        let targetSize = CGSize(width: width, height: height)
        
        return (targetURL, targetSize)
    }
}
