//
//  ComposeContentViewModel+MetaTextDelegate.swift
//  
//
//  Created by MainasuK on 2022-5-19.
//

import os.log
import UIKit
import MetaTextKit
import TwitterMeta
import MastodonMeta

// MARK: - MetaTextDelegate
extension ComposeContentViewModel: MetaTextDelegate {
    
    public enum MetaTextViewKind: Int {
        case none
        case content
        case contentWarning
    }
    
    public func metaText(
        _ metaText: MetaText,
        processEditing textStorage: MetaTextStorage
    ) -> MetaContent? {
        guard let author = self.author else {
            return nil
        }
        
        let kind = MetaTextViewKind(rawValue: metaText.textView.tag) ?? .none
        
        switch kind {
        case .none:
            assertionFailure()
            return nil
            
        case .content:
            let textInput = textStorage.string
            self.content = textInput
            
            switch author {
            case .twitter:
                let content = TwitterContent(content: textInput)
                let metaContent = TwitterMetaContent.convert(
                    content: content,
                    urlMaximumLength: .max,
                    twitterTextProvider: configurationContext.statusViewConfigureContext.twitterTextProvider
                )
                return metaContent
                
            case .mastodon:
                let content = MastodonContent(
                    content: textInput,
                    emojis: [:] // TODO: emojiViewModel?.emojis.asDictionary ?? [:]
                )
                let metaContent = MastodonMetaContent.convert(text: content)
                return metaContent
            }
            
        case .contentWarning:
            let textInput = textStorage.string.replacingOccurrences(of: "\n", with: " ")
            self.contentWarning = textInput
            
            let content = MastodonContent(
                content: textInput,
                emojis: [:] // emojiViewModel?.emojis.asDictionary ?? [:]
            )
            let metaContent = MastodonMetaContent.convert(text: content)
            return metaContent
        }
    }
}
