//
//  ComposeToolbarView+Asset.swift
//  
//
//  Created by MainasuK on 2021/11/18.
//

import UIKit
import TwidereAsset

extension ComposeToolbarView {
    public enum Action: Hashable, CaseIterable {
        case media
        case emoji
        case poll
        case mention
        case hashtag
        case location
        case contentWarning
        case mediaSensitive
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
        case .contentWarning:
            return Asset.Indices.exclamationmarkOctagon.image
        case .mediaSensitive:
            return Asset.Human.eyeSlash.image
        }
    }
}

extension ComposeToolbarView {
    public func configure(actions: Set<Action>) {
        for action in Action.allCases {
            let contains = actions.contains(action)
            
            switch action {
            case .media:
                mediaButton.isHidden = !contains
            case .emoji:
                emojiButton.isHidden = !contains
            case .poll:
                pollButton.isHidden = !contains
            case .mention:
                mentionButton.isHidden = !contains
            case .hashtag:
                hashtagButton.isHidden = !contains
            case .location:
                localButton.isHidden = !contains
            case .contentWarning:
                contentWarningButton.isHidden = !contains
            case .mediaSensitive:
                mediaSensitiveButton.isHidden = !contains
            }
        }
    }
}

