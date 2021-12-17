//
//  StatusVisibility.swift
//  
//
//  Created by MainasuK on 2021-12-6.
//

import UIKit
import MastodonSDK
import TwidereAsset

public enum StatusVisibility {
    case mastodon(Mastodon.Entity.Status.Visibility)
}

extension StatusVisibility {
    public var inlineImage: UIImage? {
        switch self {
        case .mastodon(let visibility):
            switch visibility {
            case .public:
                return Asset.ObjectTools.globeMiniInline.image.withRenderingMode(.alwaysTemplate)
            case .unlisted:
                return Asset.ObjectTools.lockOpenMiniInline.image.withRenderingMode(.alwaysTemplate)
            case .private:
                return Asset.ObjectTools.lockMiniInline.image.withRenderingMode(.alwaysTemplate)
            case .direct:
                return Asset.Communication.mailMiniInline.image.withRenderingMode(.alwaysTemplate)
            case ._other:
                return nil
            }
        }
    }
}
