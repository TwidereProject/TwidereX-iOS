//
//  CustomEmojiPickerInputView+ViewModel+Diffable.swift
//  
//
//  Created by MainasuK on 2021-11-28.
//

import UIKit
import MastodonSDK

extension CustomEmojiPickerInputView.ViewModel {
    
    public enum Section: Hashable {
        case section(category: String)
    }
    
    public enum Item: Hashable {
        case emoji(emoji: Mastodon.Entity.Emoji)
    }
    
}
