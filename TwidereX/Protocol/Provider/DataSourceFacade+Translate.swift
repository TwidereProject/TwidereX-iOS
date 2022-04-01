//
//  DataSourceFacade+Translate.swift
//  TwidereX
//
//  Created by MainasuK on 2022-4-1.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import Foundation
import TwidereCommon
import TwidereCore

extension DataSourceFacade {
    @MainActor
    static func responseToStatusTranslate(
        provider: DataSourceProvider,
        status: StatusRecord
    ) async throws {
        let managedObjectContext = provider.context.managedObjectContext
        let _content: String? = await managedObjectContext.perform {
            guard let object = status.object(in: managedObjectContext) else { return nil }
            switch object {
            case .twitter(let status):
                return status.displayText
            case .mastodon(let status):
                return [
                    status.spoilerText,
                    status.content
                ]
                .compactMap { $0 }
                .joined(separator: "\n")
            }
        }
        
        guard let content = _content else {
            throw AppError.implicit(.badRequest)
        }
        
        let url = TranslateEndpoint.create(
            vendor: {
                switch UserDefaults.shared.translationServicePreference {
                case .bing:     return .bing
                case .deepl:    return .deepl
                case .google:   return .google
                }
            }(),
            content: content,
            locale: Locale.current
        )

        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): link to translator: \(url)")
        provider.coordinator.present(
            scene: .safari(url: url),
            from: provider,
            transition: .safariPresent(animated: true, completion: nil)
        )
    }   // end func
}

