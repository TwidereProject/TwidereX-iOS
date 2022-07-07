//
//  NotificationService.swift
//  NotificationService
//
//  Created by MainasuK on 2022-7-7.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UserNotifications
import AppShared
import TwidereCommon
import TwidereCore
import AlamofireImage

class NotificationService: UNNotificationServiceExtension {
    
    static let logger = Logger(subsystem: "NotificationService", category: "Service")
    var logger: Logger { NotificationService.logger }

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
            
            // Payload
            let privateKey = AppSecret.default.mastodonNotificationPrivateKey
            let auth = AppSecret.default.mastodonNotificationAuth
            guard let encodedPayload = bestAttemptContent.userInfo["p"] as? String else {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: invalid payload", ((#file as NSString).lastPathComponent), #line, #function)
                contentHandler(bestAttemptContent)
                return
            }
            let payload = encodedPayload.decode85()
            
            // publicKey
            guard let encodedPublicKey = bestAttemptContent.userInfo["k"] as? String,
                  let publicKey = NotificationService.publicKey(encodedPublicKey: encodedPublicKey) else {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: invalid public key", ((#file as NSString).lastPathComponent), #line, #function)
                contentHandler(bestAttemptContent)
                return
            }
            
            // salt
            guard let encodedSalt = bestAttemptContent.userInfo["s"] as? String else {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: invalid salt", ((#file as NSString).lastPathComponent), #line, #function)
                contentHandler(bestAttemptContent)
                return
            }
            let salt = encodedSalt.decode85()
            
            // notification
            guard let plaintextData = NotificationService.decrypt(payload: payload, salt: salt, auth: auth, privateKey: privateKey, publicKey: publicKey),
                  let notification = try? JSONDecoder().decode(MastodonPushNotification.self, from: plaintextData) else {
                contentHandler(bestAttemptContent)
                return
            }
            
            bestAttemptContent.title = notification.title
            bestAttemptContent.subtitle = ""
            bestAttemptContent.body = notification.body.escape()
            bestAttemptContent.userInfo["plaintext"] = plaintextData
            
//            let accessToken = notification.accessToken
//            UserDefaults.shared.increaseNotificationCount(accessToken: accessToken)
//
//            UserDefaults.shared.notificationBadgeCount += 1
//            bestAttemptContent.badge = NSNumber(integerLiteral: UserDefaults.shared.notificationBadgeCount)
//
            if let urlString = notification.icon, let url = URL(string: urlString) {
                let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("notification-attachments")
                try? FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                let filename = UUID().uuidString + ".png"
                let fileURL = temporaryDirectoryURL.appendingPathComponent(filename)

                ImageDownloader.default.download(URLRequest(url: url), completion: { [weak self] response in
                    guard let _ = self else { return }
                    switch response.result {
                    case .failure(let error):
                        NotificationService.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): download image \(url.debugDescription) fail: \(error.localizedDescription)")
                    case .success(let image):
                        NotificationService.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): download image \(url.debugDescription) success")
                        do {
                            try image.pngData()?.write(to: fileURL)
                        } catch {
                            NotificationService.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): image save fail: \(error.localizedDescription)")
                        }
                        if let attachment = try? UNNotificationAttachment(identifier: filename, url: fileURL, options: nil) {
                            bestAttemptContent.attachments = [attachment]
                            NotificationService.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): add image attachment success: \(attachment.debugDescription)")
                        }
                    }
                    contentHandler(bestAttemptContent)
                })
            } else {
                contentHandler(bestAttemptContent)
            }
            
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
