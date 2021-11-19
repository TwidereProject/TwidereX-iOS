//
//  NSItemProvider.swift
//  
//
//  Created by MainasuK on 2021/11/19.
//

import os.log
import Foundation
import UniformTypeIdentifiers
import MobileCoreServices
import PhotosUI

// load image with low memory usage
// Refs: https://christianselig.com/2020/09/phpickerviewcontroller-efficiently/

extension NSItemProvider {
    
    static let logger = Logger(subsystem: "NSItemProvider", category: "Logic")

    public func loadImageData() async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                if let error = error {
                    continuation.resume(with: .failure(error))
                    return
                }
                
                guard let url = url else {
                    continuation.resume(with: .success(nil))
                    assertionFailure()
                    return
                }
                
                let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
                guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
                    return
                }

                #if APP_EXTENSION
                let maxPixelSize: Int = 4096        // not limit but may upload fail
                #else
                let maxPixelSize: Int = 1536        // fit 120MB RAM limit
                #endif
                
                let downsampleOptions = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                ] as CFDictionary
                
                guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
                    continuation.resume(with: .success(nil))
                    return
                }
                
                let data = NSMutableData()
                guard let imageDestination = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, nil) else {
                    continuation.resume(with: .success(nil))
                    assertionFailure()
                    return
                }
                
                let isPNG: Bool = {
                    guard let utType = cgImage.utType else { return false }
                    return (utType as String) == UTType.png.identifier
                }()
                
                let destinationProperties = [
                    kCGImageDestinationLossyCompressionQuality: isPNG ? 1.0 : 0.75
                ] as CFDictionary
                
                CGImageDestinationAddImage(imageDestination, cgImage, destinationProperties)
                CGImageDestinationFinalize(imageDestination)
                
                let dataSize = ByteCountFormatter.string(fromByteCount: Int64(data.length), countStyle: .memory)
                NSItemProvider.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): load image \(dataSize)")

                continuation.resume(with: .success(data as Data))
            }
        }
    }
}
