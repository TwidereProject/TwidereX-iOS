//
//  SafariActivity.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import SafariServices

final class SafariActivity: UIActivity {
    
    weak var sceneCoordinator: SceneCoordinator?
    var url: NSURL?
    
    init(sceneCoordinator: SceneCoordinator) {
        self.sceneCoordinator = sceneCoordinator
    }
    
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType("com.twidere.TwidereX.safari-activity")
    }
    
    override var activityTitle: String? {
        return L10n.Common.Controls.Actions.openInSafari
    }
    
    override var activityImage: UIImage? {
        return UIImage(systemName: "safari")
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            guard let _ = item as? NSURL, sceneCoordinator != nil else { continue }
            return true
        }
        
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            guard let url = item as? NSURL else { continue }
            self.url = url
        }
    }
    
    override var activityViewController: UIViewController? {
        return nil
    }
    
    override func perform() {
        guard let url = url else {
            activityDidFinish(false)
            return
        }
        
        sceneCoordinator?.present(scene: .safari(url: url as URL), from: nil, transition: .safariPresent(animated: true, completion: nil))
        activityDidFinish(true)
    }
    
}
