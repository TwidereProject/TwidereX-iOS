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
import TwidereCommon
import SwiftMessages

public final class PhotoLibraryService: NSObject {
    
    let logger = Logger(subsystem: "PhotoLibraryService", category: "Serivce")
    
    public override init() {
        super.init()
    }
}

extension PhotoLibraryService {
    
    public enum PhotoLibraryError: Error {
        case noPermission
        case badPayload
    }
    
    public enum Source {
        case image(UIImage)      // local image
        case remote(url: URL)    // remote resources
    }
    
}

extension PhotoLibraryService {
    
    public func save(source: Source, resourceType: PHAssetResourceType) async throws {
        guard PHPhotoLibrary.authorizationStatus(for: .addOnly) != .denied else {
            throw PhotoLibraryError.noPermission
        }
                
        do {
            guard let data = try await data(from: source) else {
                throw PhotoLibraryError.badPayload
            }
            
            try await save(data: data, from: source, resourceType: resourceType)
            
            // update store review count trigger
            UserDefaults.shared.storeReviewInteractTriggerCount += 1
            
        } catch {
            throw error
        }
    }
    
    public func copy(source: Source, resourceType: PHAssetResourceType) async throws {
        do {
            guard let data = try await data(from: source) else {
                throw PhotoLibraryError.badPayload
            }
            
            try await copy(data: data, from: source, resourceType: resourceType)
            
            // update store review count trigger
            UserDefaults.shared.storeReviewInteractTriggerCount += 1
            
        } catch {
            throw error
        }
    }
    
    public func data(from source: Source) async throws -> Data? {
        switch source {
        case .remote(let url):
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): download media: \(url.absoluteString)")
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
    
    public func file(from source: Source) async throws -> URL? {
        guard let data = try await data(from: source) else { return nil }
        
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let downloadDirectory = temporaryDirectory.appendingPathComponent("Download", isDirectory: true)
        try? FileManager.default.createDirectory(at: downloadDirectory, withIntermediateDirectories: true, attributes: nil)
        let pathExtension: String = {
            switch source {
            case .remote(let url):  return url.pathExtension
            case .image:            return "png"
            }
        }()
        let assetURL = downloadDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false).appendingPathExtension(pathExtension)
        
        try data.write(to: assetURL)
        return assetURL
    }
    
}
    
extension PhotoLibraryService {
    
    func save(data: Data, from source: Source, resourceType: PHAssetResourceType) async throws {
        assert(PHAssetCreationRequest.supportsAssetResourceTypes([resourceType.rawValue as NSNumber]))
        do {
            switch resourceType {
            case .video:
                let temporaryDirectory = FileManager.default.temporaryDirectory
                let downloadDirectory = temporaryDirectory.appendingPathComponent("Download", isDirectory: true)
                try? FileManager.default.createDirectory(at: downloadDirectory, withIntermediateDirectories: true, attributes: nil)
                let pathExtension: String = {
                    switch source {
                    case .remote(let url):  return url.pathExtension
                    case .image:            return "png"
                    }
                }()
                let assetURL = downloadDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false).appendingPathExtension(pathExtension)
                try data.write(to: assetURL)
                
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.forAsset().addResource(
                        with: resourceType,
                        fileURL: assetURL,
                        options: nil
                    )
                }
            default:
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.forAsset().addResource(
                        with: resourceType,
                        data: data,
                        options: nil
                    )
                }
            }   // end switch
            
        } catch {
            debugPrint(error)
            throw error
        }
    }
    
    func copy(data: Data, from source: Source, resourceType: PHAssetResourceType) async throws {
        switch resourceType {
        case .video:
            UIPasteboard.general.setData(data, forPasteboardType: UTType.mpeg4Movie.identifier)     // public.mpeg-4
        default:
            UIPasteboard.general.image = await UIImage(data: data, scale: UIScreen.main.scale)
        }   // end switch
    }
    
}
