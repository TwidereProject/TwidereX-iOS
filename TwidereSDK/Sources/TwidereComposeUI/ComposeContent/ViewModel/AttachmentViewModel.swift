//
//  AttachmentViewModel.swift
//  
//
//  Created by MainasuK on 2021/11/19.
//

import os.log
import UIKit
import Combine
import PhotosUI
import TwidereCommon

final public class AttachmentViewModel {

    static let logger = Logger(subsystem: "AttachmentViewModel", category: "ViewModel")
    
    let id = UUID()
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    public let input: Input
    @Published var altDescription = ""
    
    // output
    @Published var output: Output?
    @Published var thumbnail: UIImage?      // original size image thumbnail
    @Published var error: Error?
    let progress = Progress()
    
    public init(input: Input) {
        self.input = input
        // end init
        
        defer {
            load(input: input)
        }
        
        $output
            .map { output -> UIImage? in
                switch output {
                case .image(let data):
                    return UIImage(data: data)
//                case .file(let url, _):
//                    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
//                    let asset = AVURLAsset(url: url)
//                    let assetImageGenerator = AVAssetImageGenerator(asset: asset)
//                    assetImageGenerator.appliesPreferredTrackTransform = true   // fix orientation
//                    do {
//                        let cgImage = try assetImageGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
//                        let image = UIImage(cgImage: cgImage)
//                        return image
//                    } catch {
//                        AttachmentViewModel.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): thumbnail generate fail: \(error.localizedDescription)")
//                        return nil
//                    }
                case .none:
                    return nil
                }
            }
            .assign(to: &$thumbnail)
    }
}

extension AttachmentViewModel: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(input)
    }
    
    public static func == (lhs: AttachmentViewModel, rhs: AttachmentViewModel) -> Bool {
        return lhs.input == rhs.input
    }
}

extension AttachmentViewModel {
    public enum Input: Hashable {
        case image(UIImage)
        case pickerResult(PHPickerResult)
    }
    
    public enum Output {
        case image(Data)
        // case gif(Data)
        // case file(URL, mimeType: String)    // assert use file for video only
    }
    
    public enum AttachmentError: Error {
        case invalidAttachmentType
        case attachmentTooLarge
    }
}

extension AttachmentViewModel {
    
    private func load(input: Input) {
        switch input {
        case .image(let image):
            guard let data = image.pngData() else {
                error = AttachmentError.invalidAttachmentType
                return
            }
            output = .image(data)
        case .pickerResult(let pickerResult):
            Task {
                do {
                    let output = try await AttachmentViewModel.load(pickerResult: pickerResult)
                    self.output = output
                } catch {
                    self.error = error
                }
            }
        }
    }
    
    private static func load(pickerResult asset: PHPickerResult) async throws -> Output {
        if asset.isImage() {
            guard let data = try await asset.itemProvider.loadImageData() else {
                throw AttachmentError.invalidAttachmentType
            }
            return .image(data)
        } else if asset.isMovie() {
            // TODO:
            assertionFailure()
            throw AttachmentError.invalidAttachmentType
        } else {
            throw AttachmentError.invalidAttachmentType
        }
    }

}

extension PHPickerResult {
    fileprivate func isImage() -> Bool {
        return itemProvider.hasRepresentationConforming(
            toTypeIdentifier: UTType.image.identifier,
            fileOptions: []
        )
    }
    
    fileprivate func isMovie() -> Bool {
        return itemProvider.hasRepresentationConforming(
            toTypeIdentifier: UTType.movie.identifier,
            fileOptions: []
        )
    }
}
