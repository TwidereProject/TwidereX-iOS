//
//  MastodonEmojiService+EmojiViewModel.swift
//  
//
//  Created by MainasuK on 2021-11-24.
//

import Foundation
import Combine
import GameplayKit
import TwidereCommon
import MastodonSDK

extension MastodonEmojiService {
    public final class EmojiViewModel {
        
        var disposeBag = Set<AnyCancellable>()
        
        private var learnedEmoji: Set<String> = Set()
        
        // input
        public let domain: String
        weak var service: MastodonEmojiService?
        
        // output
        private(set) lazy var stateMachine: GKStateMachine = {
            // exclude timeline middle fetcher state
            let stateMachine = GKStateMachine(states: [
                State.Initial(viewModel: self),
                State.Loading(viewModel: self),
                State.Fail(viewModel: self),
                State.Finish(viewModel: self),
            ])
            stateMachine.enter(State.Initial.self)
            return stateMachine
        }()
        @Published public var emojis: [Mastodon.Entity.Emoji] = []
        @Published public var emojiDict: [Mastodon.Entity.Emoji.Shortcode: [Mastodon.Entity.Emoji]] = [:]
        @Published public var emojiTrie: Trie<Character>? = nil
        
        init(domain: String, service: MastodonEmojiService) {
            self.domain = domain
            self.service = service
            // end init
            
            $emojis
                .map { Dictionary(grouping: $0, by: { $0.shortcode }) }
                .assign(to: &$emojiDict)
            
            $emojis
                .map { emojis -> Trie<Character>? in
                    guard !emojis.isEmpty else { return nil }
                    var trie: Trie<Character> = Trie()
                    for emoji in emojis {
                        let key = emoji.shortcode.lowercased()
                        trie.inserted(Array(key).slice, value: emoji)
                    }
                    return trie
                }
                .assign(to: &$emojiTrie)
        }
        
        func emoji(shortcode: Mastodon.Entity.Emoji.Shortcode) -> Mastodon.Entity.Emoji? {
            // learn emoji shortcode
            if !learnedEmoji.contains(shortcode) {
                learnedEmoji.insert(shortcode)
                
                DispatchQueue.global().async {
                    UITextChecker.learnWord(shortcode)
                    UITextChecker.learnWord(":" + shortcode + ":")
                }
            }

            return emojiDict[shortcode]?.first
        }
    }
}
