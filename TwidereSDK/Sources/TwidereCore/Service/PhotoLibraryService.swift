//
//  PhotoLibraryService.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-30.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Photos
import Alamofire
import AlamofireImage

public final class PhotoLibraryService: NSObject {
    public override init() {
        super.init()
    }
}

extension PhotoLibraryService {
    
    public enum PhotoLibraryError: Error {
        case noPermission
        case badPayload
    }
    
    public enum ImageSource {
        case url(URL)               // remote
        case image(UIImage)
    }
    
}

extension PhotoLibraryService {
    
    public func save(source: ImageSource) async throws {
        guard PHPhotoLibrary.authorizationStatus(for: .addOnly) != .denied else {
            throw PhotoLibraryError.noPermission
        }
                
        do {
            guard let imageData = try await imageData(from: source) else {
                throw PhotoLibraryError.badPayload
            }
            
            try await save(data: imageData)
            
        } catch {
            throw error
        }
    }
    
    func imageData(from source: ImageSource) async throws -> Data? {
        switch source {
        case .url(let url):
            let data: Data = try await withCheckedThrowingContinuation { continuation in
                AF.request(url).responseData { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(with: .success(data))
                    case .failure(let error):
                        continuation.resume(with: .failure(error))
                    }
                }
            }
            return data
        case .image(let image):
            return image.pngData()
        }
    }
    
    func save(data: Data) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(
                with: .photo,
                data: data,
                options: nil
            )
        }
    }
    
//    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
//        let feedbackGenerator = UINotificationFeedbackGenerator()
//        feedbackGenerator.prepare()
//
//        if let error = error {
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: save image fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//            var config = SwiftMessages.defaultConfig
//            config.duration = .seconds(seconds: 3)
//            config.interactiveHide = true
//            let bannerView = NotificationBannerView()
//            bannerView.configure(for: .warning)
//            bannerView.titleLabel.text = L10n.Common.Alerts.PhotoSaveFail.title
//            bannerView.messageLabel.text = L10n.Common.Alerts.PhotoSaveFail.message
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                SwiftMessages.show(config: config, view: bannerView)
//                feedbackGenerator.notificationOccurred(.error)
//            }
//        } else {
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: save image success", ((#file as NSString).lastPathComponent), #line, #function)
//            var config = SwiftMessages.defaultConfig
//            config.duration = .seconds(seconds: 3)
//            config.interactiveHide = true
//            let bannerView = NotificationBannerView()
//            bannerView.configure(for: .normal)
//            bannerView.titleLabel.text = L10n.Common.Alerts.PhotoSaved.title
//            bannerView.messageLabel.isHidden = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                SwiftMessages.show(config: config, view: bannerView)
//                feedbackGenerator.notificationOccurred(.success)
//            }
//        }
//    }
    
}
