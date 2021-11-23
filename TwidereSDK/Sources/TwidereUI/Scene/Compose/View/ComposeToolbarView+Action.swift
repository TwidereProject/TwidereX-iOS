//
//  ComposeToolbarView+Asset.swift
//  
//
//  Created by MainasuK on 2021/11/18.
//

import UIKit
import TwidereAsset

extension ComposeToolbarView {
    public enum Action: Hashable {
        case media
        case emoji
        case poll
        case mention
        case hashtag
        case location
    }
}

extension ComposeToolbarView.Action {
    public func image(of state: UIControl.State) -> UIImage? {
        switch self {
        case .media:
            return Asset.ObjectTools.photo.image
        case .emoji:
            return state.contains(.selected) ? Asset.Keyboard.keyboard.image : Asset.Human.faceSmiling.image
        case .poll:
            return Asset.ObjectTools.poll.image
        case .mention:
            return Asset.Symbol.at.image
        case .hashtag:
            return Asset.Symbol.number.image
        case .location:
            return Asset.ObjectTools.mappin.image
        }
    }
}
