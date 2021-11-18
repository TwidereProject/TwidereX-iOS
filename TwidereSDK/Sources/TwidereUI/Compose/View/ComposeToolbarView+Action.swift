//
//  ComposeToolbarView+Asset.swift
//  
//
//  Created by MainasuK on 2021/11/18.
//

import UIKit

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
            return UIImage(named: "photo", in: .module, with: nil)
        case .emoji:
            return state.contains(.selected) ? UIImage(named: "keyboard", in: .module, with: nil) : UIImage(named: "face.smiling", in: .module, with: nil)
        case .poll:
            return UIImage(named: "poll", in: .module, with: nil)
        case .mention:
            return UIImage(named: "at", in: .module, with: nil)
        case .hashtag:
            return UIImage(named: "number", in: .module, with: nil)
        case .location:
            return UIImage(named: "mappin", in: .module, with: nil)
        }
    }
}
