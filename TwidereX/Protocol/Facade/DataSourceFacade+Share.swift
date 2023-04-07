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
        sourceView: UIView
    ) async {
        let activityViewController = await createActivityViewController(
            provider: provider,
            status: status
        )
        provider.coordinator.present(
            scene: .activityViewController(
                activityViewController: activityViewController,
                sourceView: sourceView
            ),
            from: provider,
            transition: .activityViewControllerPresent(animated: true, completion: nil)
        )
    }
    
}

extension DataSourceFacade {
    @MainActor
    static func createActivityViewController(
        provider: DataSourceProvider,
        status: StatusRecord
    ) async -> UIActivityViewController {
        var activityItems: [Any] = await provider.context.managedObjectContext.perform {
            guard let object = status.object(in: provider.context.managedObjectContext) else { return [] }
            guard let url = object.statusURL else { return [] }
            return [url] as [Any]
        }
        var applicationActivities: [UIActivity] = [
            SafariActivity(sceneCoordinator: provider.coordinator),     // open URL
        ]
        
        if let provider = provider as? ShareActivityProvider {
            activityItems.append(contentsOf: provider.activities)
            applicationActivities.append(contentsOf: provider.applicationActivities)
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return activityViewController
    }
}
