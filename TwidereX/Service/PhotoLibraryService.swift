//
//  PhotoLibraryService.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftMessages

final class PhotoLibraryService: NSObject {

}

extension PhotoLibraryService {
    
    func save(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(PhotoLibraryService.image(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()

        if let error = error {
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: save image fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
            var config = SwiftMessages.defaultConfig
            config.duration = .seconds(seconds: 3)
            config.interactiveHide = true
            let bannerView = NotifyBannerView()
            bannerView.configure(for: .warning)
            bannerView.titleLabel.text = "Save Photo Fail"
            bannerView.messageLabel.text = "Please try again"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                SwiftMessages.show(config: config, view: bannerView)
                feedbackGenerator.notificationOccurred(.error)
            }
        } else {
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: save image success", ((#file as NSString).lastPathComponent), #line, #function)
            var config = SwiftMessages.defaultConfig
            config.duration = .seconds(seconds: 3)
            config.interactiveHide = true
            let bannerView = NotifyBannerView()
            bannerView.configure(for: .normal)
            bannerView.titleLabel.text = "Photo Saved"
            bannerView.messageLabel.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                SwiftMessages.show(config: config, view: bannerView)
                feedbackGenerator.notificationOccurred(.success)
            }
        }
    }
    
}
