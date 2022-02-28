//
//  StatusMetricsDashboardView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-2-23.
//

import UIKit
import Combine
import CoreDataStack

extension StatusMetricsDashboardView {
    public final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        
        @Published public var platform: Platform = .none

        @Published public var replyCount: Int = 0
        @Published public var repostCount: Int = 0
        @Published public var quoteCount: Int = 0
        @Published public var likeCount: Int = 0
        
        func bind(view: StatusMetricsDashboardView) {
            // reply
            $replyCount
                .sink { count in
                    let text = ViewModel.metricText(count: count)
                    view.replyButton.setTitle(text, for: .normal)
                    view.replyButton.accessibilityLabel = L10n.Count.reply(count)
                }
                .store(in: &disposeBag)
            // repost
            Publishers.CombineLatest(
                $repostCount,
                $platform
            )
            .sink { count, platform in
                let text = ViewModel.metricText(count: count)
                view.repostButton.setTitle(text, for: .normal)
                
                switch platform {
                case .none:
                    view.repostButton.accessibilityLabel = nil
                case .twitter:
                    view.repostButton.accessibilityLabel = L10n.Count.retweet(count)
                case .mastodon:
                    view.repostButton.accessibilityLabel = L10n.Count.reblog(count)
                }
            }
            .store(in: &disposeBag)
            // quote
            Publishers.CombineLatest(
                $quoteCount,
                $platform
            )
            .sink { count, platform in
                let text = ViewModel.metricText(count: count)
                view.quoteButton.setTitle(text, for: .normal)
                view.quoteButton.accessibilityLabel = L10n.Count.quote(count)
                
                view.quoteButton.isHidden = {
                    switch platform {
                    case .none:         return true
                    case .twitter:      return false
                    case .mastodon:     return true
                    }
                }()
            }
            .store(in: &disposeBag)
            // like
            $likeCount
                .sink { count in
                    let text = ViewModel.metricText(count: count)
                    view.likeButton.setTitle(text, for: .normal)
                    view.likeButton.accessibilityLabel = L10n.Count.like(count)
                }
                .store(in: &disposeBag)
        }
        
        private static func metricText(count: Int) -> String {
            guard count >= 0 else { return "0" }
            return StatusMetricsDashboardView.numberMetricFormatter.string(from: count) ?? "0"
        }
    }
}
