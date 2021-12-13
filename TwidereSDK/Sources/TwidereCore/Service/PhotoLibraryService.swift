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
import SwiftMessages

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
            
        } catch {
            throw error
        }
    }
    
    func data(from source: Source) async throws -> Data? {
        switch source {
        case .remote(let url):
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
    
}
