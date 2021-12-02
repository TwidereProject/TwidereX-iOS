//
//  AttachmentViewModel+Upload.swift
//  
//
//  Created by MainasuK on 2021-11-26.
//

import os.log
import UIKit
import Kingfisher
import UniformTypeIdentifiers
import TwidereCore
import TwitterSDK
import MastodonSDK

extension Data {
    fileprivate func chunks(size: Int) -> [Data] {
        return stride(from: 0, to: count, by: size).map {
            Data(self[$0..<Swift.min(count, $0 + size)])
        }
    }
}

// Twitter Only
extension AttachmentViewModel {
    struct SliceResult {
        let chunks: [Data]
        let type: UTType
        
        let totalBytes: Int
        
        public init(chunks: [Data], type: UTType) {
            self.chunks = chunks
            self.type = type
            self.totalBytes = chunks.reduce(0, { result, next in return result + next.count })
        }
        
    }
    
    static func slice(output: Output, sizeLimit: SizeLimit) -> SliceResult? {
        // needs execute in background
        assert(!Thread.isMainThread)
        
        // try png then use JPEG compress with Q=0.8
        // then slice into 1MiB chunks
        switch output {
        case .image(let data, _):
            let maxPayloadSizeInBytes = sizeLimit.image
            
            // use processed imageData to remove EXIF
            guard let image = UIImage(data: data),
                  var imageData = image.pngData()
            else { return nil }
            
            var didRemoveEXIF = false
            repeat {
                guard let image = KFCrossPlatformImage(data: imageData) else { return nil }
                if imageData.kf.imageFormat == .PNG {
                    // A. png image
                    guard let pngData = image.pngData() else { return nil }
                    didRemoveEXIF = true
                    if pngData.count > maxPayloadSizeInBytes {
                        guard let compressedJpegData = image.jpegData(compressionQuality: 0.8) else { return nil }
                        os_log("%{public}s[%{public}ld], %{public}s: compress png %.2fMiB -> jpeg %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024, Double(compressedJpegData.count) / 1024 / 1024)
                        imageData = compressedJpegData
                    } else {
                        os_log("%{public}s[%{public}ld], %{public}s: png %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(pngData.count) / 1024 / 1024)
                        imageData = pngData
                    }
                } else {
                    // B. other image
                    if !didRemoveEXIF {
                        guard let jpegData = image.jpegData(compressionQuality: 0.8) else { return nil }
                        os_log("%{public}s[%{public}ld], %{public}s: compress jpeg %.2fMiB -> jpeg %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024, Double(jpegData.count) / 1024 / 1024)
                        imageData = jpegData
                        didRemoveEXIF = true
                    } else {
                        let targetSize = CGSize(width: image.size.width * 0.8, height: image.size.height * 0.8)
                        let scaledImage = image.af.imageScaled(to: targetSize)
                        guard let compressedJpegData = scaledImage.jpegData(compressionQuality: 0.8) else { return nil }
                        os_log("%{public}s[%{public}ld], %{public}s: compress jpeg %.2fMiB -> jpeg %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024, Double(compressedJpegData.count) / 1024 / 1024)
                        imageData = compressedJpegData
                    }
                }
            } while (imageData.count > maxPayloadSizeInBytes)
            
            let chunks = imageData.chunks(size: 1 * 1024 * 1024)      // 1 MiB chunks
            os_log("%{public}s[%{public}ld], %{public}s: split to %ld chunks", ((#file as NSString).lastPathComponent), #line, #function, chunks.count)

            return SliceResult(
                chunks: chunks,
                type: imageData.kf.imageFormat == .PNG ? UTType.png : UTType.jpeg
            )
//        case .gif(let url):
//            fatalError()
//        case .video(let url):
//            fatalError()
        }
    }
}

extension AttachmentViewModel {
    struct UploadContext {
        let apiService: APIService
        let authenticationContext: AuthenticationContext
    }
    
    enum UploadResult {
        case twitter(Twitter.Response.Content<Twitter.API.Media.InitResponse>)
        case mastodon(Mastodon.Response.Content<Mastodon.Entity.Attachment>)
    }
}

extension AttachmentViewModel {
    func upload(
        context: UploadContext
    ) async throws -> UploadResult  {
        switch context.authenticationContext {
        case .twitter(let authenticationContext):
            return try await uploadTwitterMedia(
                context: context,
                twitterAuthenticationContext: authenticationContext
            )
        case .mastodon(let authenticationContext):
            return try await uploadMastodonMedia(
                context: context,
                mastodonAuthenticationContext: authenticationContext
            )
        }
    }
    
    private func uploadTwitterMedia(
        context: UploadContext,
        twitterAuthenticationContext: TwitterAuthenticationContext
    ) async throws -> UploadResult {
        guard let output = self.output,
              let sliceResult = AttachmentViewModel.slice(output: output, sizeLimit: sizeLimit) else {
            throw AppError.implicit(.badRequest)
        }
        
        // init + N * append + finalize
        progress.totalUnitCount = 1 + Int64(sliceResult.chunks.count) + 1
        progress.completedUnitCount = 0
        
        // init
        let mediaInitResponse = try await context.apiService.twitterMediaInit(
            totalBytes: sliceResult.totalBytes,
            mediaType: sliceResult.type.preferredMIMEType ?? "",
            twitterAuthenticationContext: twitterAuthenticationContext
        )
        AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): init media success: \(mediaInitResponse.value.mediaIDString)")
        let mediaID = mediaInitResponse.value.mediaIDString
        progress.completedUnitCount += 1
        
        // append
        let chunkCount = sliceResult.chunks.count
        for (i, chunk) in sliceResult.chunks.enumerated() {
            _ = try await context.apiService.twitterMediaAppend(
                mediaID: mediaID,
                chunk: chunk,
                index: i,
                twitterAuthenticationContext: twitterAuthenticationContext
            )
            AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): append chunk \(i)/\(chunkCount) success")
            progress.completedUnitCount += 1
        }
        
        var isFinalized = false
        repeat {
            let mediaFinalizedResponse = try await context.apiService.TwitterMediaFinalize(
                mediaID: mediaID,
                twitterAuthenticationContext: twitterAuthenticationContext
            )
            if let info = mediaFinalizedResponse.value.processingInfo {
                assert(!Thread.isMainThread)
                let checkAfterSeconds = UInt64(info.checkAfterSecs)
                AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): finalize status pending. check after \(info.checkAfterSecs)s")
                await Task.sleep(1_000_000_000 * checkAfterSeconds)     // 1s * checkAfterSeconds
                continue
            
            } else {
                AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): finalize success")
                isFinalized = true
            }
        } while !isFinalized
        progress.completedUnitCount += 1
        
        return .twitter(mediaInitResponse)
    }
    
    private func uploadMastodonMedia(
        context: UploadContext,
        mastodonAuthenticationContext: MastodonAuthenticationContext
    ) async throws -> UploadResult {
        guard let output = self.output else {
            throw AppError.implicit(.badRequest)
        }
        
        let attachment = output.asAttachment
        
        let query = Mastodon.API.Media.UploadMediaQuery(
            file: attachment,
            thumbnail: nil,
            description: nil,       // TODO:
            focus: nil              // TODO:
        )
        
        let attachmentUploadResponse: Mastodon.Response.Content<Mastodon.Entity.Attachment> = try await {
            do {
                AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [V2] upload attachment...")
                return try await context.apiService.mastodonMediaUpload(
                    query: query,
                    mastodonAuthenticationContext: mastodonAuthenticationContext,
                    needsFallback: false
                )
            } catch {
                // check needs fallback
                guard let apiError = error as? Mastodon.API.Error,
                      apiError.httpResponseStatus == .notFound
                else { throw error }
                
                AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [V1] upload attachment...")

                return try await context.apiService.mastodonMediaUpload(
                    query: query,
                    mastodonAuthenticationContext: mastodonAuthenticationContext,
                    needsFallback: true
                )
            }
        }()
        
        
        // check needs wait processing (until get the `url`)
        if attachmentUploadResponse.statusCode == 202 {
            // note:
            // the Mastodon server append the attachments in order by upload time
            // can not upload concurrency
            let waitProcessRetryLimit = 10
            var waitProcessRetryCount = 0
            
            repeat {
                defer {
                    // make sure always count + 1
                    waitProcessRetryCount += 1
                }
                
                AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): check attachment process status")

                let attachmentStatusResponse = try await context.apiService.mastodonMediaAttachment(
                    attachmentID: attachmentUploadResponse.value.id,
                    mastodonAuthenticationContext: mastodonAuthenticationContext
                )
                
                if let url = attachmentStatusResponse.value.url {
                    AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): attachment process finish: \(url)")
                    
                    // escape here
                    return .mastodon(attachmentStatusResponse)
                    
                } else {
                    AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): attachment processing. Retry \(waitProcessRetryCount)/\(waitProcessRetryLimit)")
                    await Task.sleep(1_000_000_000 * 3)     // 3s
                }
            } while waitProcessRetryCount < waitProcessRetryLimit
         
            AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): attachment processing result discard due to exceed retry limit")
            throw AppError.implicit(.badRequest)
        } else {
            AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): upload attachment success: \(attachmentUploadResponse.value.url ?? "<nil>")")

            return .mastodon(attachmentUploadResponse)
        }
    }
}

extension AttachmentViewModel.Output {
    var asAttachment: Mastodon.API.MediaAttachment {
        switch self {
        case .image(let data, let kind):
            switch kind {
            case .png:      return .png(data)
            case .jpg:      return .jpeg(data)
            }
        }
    }
}
