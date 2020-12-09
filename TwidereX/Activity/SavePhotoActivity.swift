//
//  SavePhotoActivity.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-1.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import AlamofireImage

final class SavePhotoActivity: UIActivity {
    
    weak var context: AppContext?
    let url: URL
    
    init(context: AppContext, url: URL) {
        self.context = context
        self.url = url
    }
    
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType("com.twidere.TwidereX.save-photo-activity")
    }
    
    override var activityTitle: String? {
        return L10n.Common.Controls.Actions.savePhoto
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
        ImageDownloader.default.download(URLRequest(url: url), completion: { [weak self] response in
            guard let self = self else { return }
            switch response.result {
            case .failure(let error):
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: download image %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, url.debugDescription, error.localizedDescription)
                self.activityDidFinish(false)
            case .success(let image):
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: download image %s success", ((#file as NSString).lastPathComponent), #line, #function, url.debugDescription)
                context.photoLibraryService.save(image: image)
                self.activityDidFinish(true)
            }
        })
    }
    
}

