//
//  SavePhotoActivity.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-1.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Photos
import AlamofireImage
import TwidereCore
import SwiftMessages

final class SavePhotoActivity: UIActivity {
    
    weak var context: AppContext?
    let url: URL
    let resourceType: PHAssetResourceType
    
    init(
        context: AppContext,
        url: URL,
        resourceType: PHAssetResourceType
    ) {
        self.context = context
        self.url = url
        self.resourceType = resourceType
    }
    
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType("com.twidere.TwidereX.save-photo-activity")
    }
    
    override var activityTitle: String? {
        return L10n.Common.Controls.Actions.save.localizedCapitalized
    }
    
    override var activityImage: UIImage? {
        return UIImage(systemName: "square.and.arrow.down")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        
    }
    
    override var activityViewController: UIViewController? {
        return nil
    }
    
    override func perform() {
        guard let context = self.context else { return }
        let url = self.url
        
        Task {
            let impactFeedbackGenerator = await UIImpactFeedbackGenerator(style: .light)
            let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

            do {
                await impactFeedbackGenerator.impactOccurred()
                try await context.photoLibraryService.save(
                    source: .remote(url: url),
                    resourceType: self.resourceType
                )
                await context.photoLibraryService.presentSuccessNotification()
                await notificationFeedbackGenerator.notificationOccurred(.success)
                
                self.activityDidFinish(true)
                
            } catch {
                await context.photoLibraryService.presentFailureNotification(error: error)
                await notificationFeedbackGenerator.notificationOccurred(.error)
                
                self.activityDidFinish(false)
            }
        }   // end Task
    }

}

