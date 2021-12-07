//
//  DataSourceFacade+Share.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-7.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

extension DataSourceFacade {
    
    @MainActor
    public static func responseToStatusShareAction(
        provider: DataSourceProvider,
        status: StatusRecord,
        button: UIButton
    ) async {
        let activityViewController = await createActivityViewController(
            provider: provider,
            status: status
        )
        provider.coordinator.present(
            scene: .activityViewController(
                activityViewController: activityViewController,
                sourceView: button
            ),
            from: provider,
            transition: .activityViewControllerPresent(animated: true, completion: nil)
        )
    }
    
}

extension DataSourceFacade {
    static func createActivityViewController(
        provider: DataSourceProvider,
        status: StatusRecord
    ) async -> UIActivityViewController {
        var activityItems: [Any] = await provider.context.managedObjectContext.perform {
            guard let object = status.object(in: provider.context.managedObjectContext) else { return [] }
            switch object {
            case .twitter(let status):
                return [status.statusURL]
            case .mastodon(let status):
                let url = status.url ?? status.uri
                return [URL(string: url)].compactMap { $0 } as [Any]
            }
        }
        var applicationActivities: [UIActivity] = [
            SafariActivity(sceneCoordinator: provider.coordinator),     // open URL
        ]
        
        if let provider = provider as? ShareActivityProvider {
            activityItems.append(contentsOf: provider.activities)
            applicationActivities.append(contentsOf: provider.applicationActivities)
        }
        
        let activityViewController = await UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return activityViewController
    }
}
