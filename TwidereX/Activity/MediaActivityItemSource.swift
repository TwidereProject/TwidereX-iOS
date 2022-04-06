//
//  MediaActivityItemSource.swift
//  TwidereX
//
//  Created by MainasuK on 2022-4-6.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import LinkPresentation
import UniformTypeIdentifiers

final class MediaActivityItemSource: NSObject {
    
    let logger = Logger(subsystem: "MediaActivityItemSource", category: "Activity")
        
    let metadata = LPLinkMetadata()
    
    // input
    let assetURL: URL
    var assetData: Data
    
    init(assetURL: URL, assetData: Data) {
        self.assetURL = assetURL
        self.assetData = assetData
        super.init()
        
        do {
            let temporaryDirectory = FileManager.default.temporaryDirectory
            let downloadDirectory = temporaryDirectory.appendingPathComponent("Download", isDirectory: true)
            try? FileManager.default.createDirectory(at: downloadDirectory, withIntermediateDirectories: true, attributes: nil)
            let pathExtension = assetURL.pathExtension
            let url = downloadDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false).appendingPathExtension(pathExtension)
            try assetData.write(to: url)
            
            metadata.originalURL = assetURL
            metadata.title = {
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                return formatter.string(fromByteCount: Int64(assetData.count))
            }()
            switch pathExtension.lowercased() {
            case "mp4":
                metadata.videoProvider = NSItemProvider(contentsOf: url)
            default:
                metadata.imageProvider = NSItemProvider(contentsOf: url)
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
        
        // end init
    }
    
}

// MARK: - UIActivityItemSource
extension MediaActivityItemSource: UIActivityItemSource {
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return UIImage()
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): item data: \(self.assetData.debugDescription)")
        return assetData
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return metadata
    }
    
}


