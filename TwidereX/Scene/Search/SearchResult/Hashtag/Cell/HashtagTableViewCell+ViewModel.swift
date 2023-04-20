//
//  HashtagTableViewCell+ViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import Meta
import MastodonSDK

extension HashtagTableViewCell {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        
        @Published var primaryContent: MetaContent?
        @Published var secondaryContent: MetaContent?
    }
}

extension HashtagTableViewCell.ViewModel {
    func bind(cell: HashtagTableViewCell) {
        $primaryContent
            .sink { metaContent in
                let metaContent = metaContent ?? PlaintextMetaContent(string: " ")
                cell.primaryLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
        $secondaryContent
            .sink { metaContent in
                let metaContent = metaContent ?? PlaintextMetaContent(string: " ")
                cell.secondaryLabel.configure(content: metaContent)
            }
            .store(in: &disposeBag)
    }
}

extension HashtagTableViewCell {
    func configure(hashtagData: HashtagData) {
        switch hashtagData {
        case .mastodon(let tag):
            configure(tag: tag)
        }
    }
    
    func configure(tag: Mastodon.Entity.Tag) {
        // primary
        let primaryContent = Meta.convert(document: .plaintext(string: "#" + tag.name))
        viewModel.primaryContent = primaryContent
        // secondary
        let count = tag.history?.sorted(by: { $0.day < $1.day })
            .suffix(2)
            .compactMap { Int($0.accounts) }
            .reduce(0, +)
        let secondaryContent = count.flatMap {
            let text = L10n.Count.People.talking($0)
            return PlaintextMetaContent(string: text)
        } ?? PlaintextMetaContent(string: " ")
        viewModel.secondaryContent = secondaryContent
    }

}
