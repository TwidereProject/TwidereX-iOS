//
//  DataSourceFacade+Meta.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-10.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import TwidereCore
import CoreDataStack
import MetaTextArea
import Meta

extension DataSourceFacade {
    static func responseToMetaTextAreaView(
        provider: DataSourceProvider,
        target: StatusTarget,
        status: StatusRecord,
        metaTextAreaView: MetaTextAreaView,
        didSelectMeta meta: Meta
    ) async {
        let _redirectRecord = await DataSourceFacade.status(
            managedObjectContext: provider.context.managedObjectContext,
            status: status,
            target: target
        )
        guard let redirectRecord = _redirectRecord else { return }
        
        await responseToMetaTextAreaView(
            provider: provider,
            status: redirectRecord,
            metaTextAreaView: metaTextAreaView,
            didSelectMeta: meta
        )
    }
    
    static func responseToMetaTextAreaView(
        provider: DataSourceProvider,
        status: StatusRecord,
        metaTextAreaView: MetaTextAreaView,
        didSelectMeta meta: Meta
    ) async {
        switch meta {
        case .url(_, _, let url, _):
            guard let url = URL(string: url) else { return }
            await provider.coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        case .hashtag(_, let hashtag, _):
            let hashtagViewModel = HashtagTimelineViewModel(context: provider.context, hashtag: hashtag)
            await provider.coordinator.present(scene: .hashtagTimeline(viewModel: hashtagViewModel), from: provider, transition: .show)
        case .mention(_, let mention, let userInfo):
            await DataSourceFacade.coordinateToProfileScene(
                provider: provider,
                status: status,
                mention: mention,
                userInfo: userInfo
            )
        case .email: break
        case .emoji: break
        }
    }
}
