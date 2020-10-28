//
//  TwitterMediaService.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-26.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import GameplayKit
import TwitterAPI
import Kingfisher

protocol TwitterMediaServiceDelegate: class {
    func twitterMediaService(_ service: TwitterMediaService, uploadStateDidChange state: TwitterMediaService.UploadState?)
}

class TwitterMediaService {
    
    var disposeBag = Set<AnyCancellable>()
    let identifier = UUID()
    
    // input
    let context: AppContext
    let payload: Payload
    var isCancelled = false
    weak var delegate: TwitterMediaServiceDelegate?
    
    // output
    var slice: [Data] = []
    var mediaType: MediaType = .jpeg
    var mediaID: String? = nil
    
    private(set) lazy var uploadStateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            TwitterMediaService.UploadState.Init(service: self),
            TwitterMediaService.UploadState.Append(service: self),
            TwitterMediaService.UploadState.Finalize(service: self),
            TwitterMediaService.UploadState.FinalizePending(service: self),
            TwitterMediaService.UploadState.Fail(service: self),
            TwitterMediaService.UploadState.Success(service: self),
        ])
        return stateMachine
    }()
    lazy var uploadStateMachineSubject = CurrentValueSubject<TwitterMediaService.UploadState?, Never>(nil)
    
    init(context: AppContext, payload: Payload) {
        self.context = context
        self.payload = payload
        
        uploadStateMachine.enter(TwitterMediaService.UploadState.Init.self)
        uploadStateMachineSubject
            .sink { [weak self] state in
                guard let self = self else { return }
                self.delegate?.twitterMediaService(self, uploadStateDidChange: state)
            }
            .store(in: &disposeBag)
    }
    
    func cancel() {
        uploadStateMachine.enter(TwitterMediaService.UploadState.Fail.self)
        isCancelled = true
        disposeBag.removeAll()
    }

}

extension TwitterMediaService {
    enum MediaType: String {
        case jpeg = "image/jpeg"
        case png = "image/png"
        case gif = "image/gif"
        case mp4 = "video/mp4"
    }
}

extension TwitterMediaService: Equatable, Hashable {
    
    static func == (lhs: TwitterMediaService, rhs: TwitterMediaService) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
}

extension TwitterMediaService {
    enum Payload {
        case image(URL)
        case gif(URL) // TODO:
        case video(URL)
        
        var maxPayloadSizeInBytes: Int {
            switch self {
            case .image:        return 5 * 1024 * 1024      // 5 MiB
            case .gif:          return 15 * 1024 * 1024     // 15 MiB
            case .video:        return 15 * 1024 * 1024     // 15 MiB
            }
        }
        
        func slice() -> [Data] {
            switch self {
            case .image(let url):
                do {
                    var imageData = try Data(contentsOf: url)
                    var didRemoveEXIF = false
                    repeat {
                        guard let image = KFCrossPlatformImage(data: imageData) else { return [] }
                        if imageData.kf.imageFormat == .PNG {
                            // A. png image
                            guard let pngData = image.pngData() else { return [] }
                            didRemoveEXIF = true
                            if pngData.count > maxPayloadSizeInBytes {
                                guard let compressedJpegData = image.jpegData(compressionQuality: 0.8) else { return [] }
                                os_log("%{public}s[%{public}ld], %{public}s: compress png %.2fMiB -> jpeg %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024, Double(compressedJpegData.count) / 1024 / 1024)
                                imageData = compressedJpegData
                            } else {
                                os_log("%{public}s[%{public}ld], %{public}s: png %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(pngData.count) / 1024 / 1024)
                                imageData = pngData
                            }
                        } else {
                            // B. other image
                            if !didRemoveEXIF {
                                guard let jpegData = image.jpegData(compressionQuality: 0.8) else { return [] }
                                os_log("%{public}s[%{public}ld], %{public}s: compress jpeg %.2fMiB -> jpeg %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024, Double(jpegData.count) / 1024 / 1024)
                                imageData = jpegData
                                didRemoveEXIF = true
                            } else {
                                let targetSize = CGSize(width: image.size.width * 0.8, height: image.size.height * 0.8)
                                let scaledImage = image.af.imageScaled(to: targetSize)
                                guard let compressedJpegData = scaledImage.jpegData(compressionQuality: 0.8) else { return [] }
                                os_log("%{public}s[%{public}ld], %{public}s: compress jpeg %.2fMiB -> jpeg %.2fMiB", ((#file as NSString).lastPathComponent), #line, #function, Double(imageData.count) / 1024 / 1024, Double(compressedJpegData.count) / 1024 / 1024)
                                imageData = compressedJpegData
                            }
                        }
                    } while (imageData.count > maxPayloadSizeInBytes)
                    let chunks = imageData.chunks(size: 1 * 1024 * 1024)      // 1 MiB chunks
                    os_log("%{public}s[%{public}ld], %{public}s: split to %ld chunks", ((#file as NSString).lastPathComponent), #line, #function, chunks.count)
                    return chunks
                } catch {
                    os_log("%{public}s[%{public}ld], %{public}s: slice get error: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    return []
                }
            case .gif(let url):
                fatalError()
            case .video(let url):
                fatalError()
            }
        }
    }
}

extension TwitterMediaService {
    class UploadState: GKState {
        weak var service: TwitterMediaService?
        
        init(service: TwitterMediaService) {
            self.service = service
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            service?.uploadStateMachineSubject.send(self)
        }
    }
}
extension TwitterMediaService.UploadState {
    class Init: TwitterMediaService.UploadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Append.self || stateClass == Fail.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            guard let service = service, let stateMachine = stateMachine else { return }
            guard !service.isCancelled,
                  let autentication = service.context.authenticationService.currentActiveTwitterAutentication.value,
                  let authorization = try? autentication.authorization(appSecret: AppSecret.shared)
            else { return }
            

            let payload = service.payload
            DispatchQueue.global(qos: .userInitiated)
                .async {
                    let slice: [Data]
                    let mediaType: TwitterMediaService.MediaType
                    switch payload {
                    case .image(let url):
                        slice = payload.slice()
                        mediaType = slice.first.flatMap { data in
                            return data.kf.imageFormat == .PNG ? .png : .jpeg
                        } ?? .jpeg
                    case .gif(let url):
                        slice = []  // TODO:
                        mediaType = .gif
                    case .video(let url):
                        slice = []  // TODO:
                        mediaType = .mp4
                    }
                    
                    guard !slice.isEmpty else {
                        DispatchQueue.main.async {
                            stateMachine.enter(Fail.self)
                        }
                        return
                    }
                    
                    let totalBytes = slice.reduce(0, { result, next in return result + next.count })
                    service.context.apiService.mediaInit(totalBytes: totalBytes, mediaType: mediaType.rawValue, authorization: authorization)
                        .retry(3)
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            switch completion {
                            case .finished:
                                os_log("%{public}s[%{public}ld], %{public}s: media init success", ((#file as NSString).lastPathComponent), #line, #function)

                            case .failure(let error):
                                os_log("%{public}s[%{public}ld], %{public}s: media init fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                                stateMachine.enter(Fail.self)
                            }
                        } receiveValue: { response in
                            let response = response.value
                            service.mediaID = response.mediaIDString
                            service.slice = slice
                            service.mediaType = mediaType
                            os_log("%{public}s[%{public}ld], %{public}s: media init success. mediaID: %s", ((#file as NSString).lastPathComponent), #line, #function, response.mediaIDString)
                            stateMachine.enter(Append.self)
                        }
                        .store(in: &service.disposeBag)
                }
        }
    }
    
    class Append: TwitterMediaService.UploadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Finalize.self || stateClass == Fail.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let service = service, let stateMachine = stateMachine else { return }
            guard !service.isCancelled,
                  let autentication = service.context.authenticationService.currentActiveTwitterAutentication.value,
                  let authorization = try? autentication.authorization(appSecret: AppSecret.shared)
            else { return }
            
            guard let mediaID = service.mediaID, !service.slice.isEmpty else {
                stateMachine.enter(Fail.self)
                return
            }
            
            service.slice.enumerated()
                .publisher
                .setFailureType(to: Error.self)
                .flatMap { i, chunk in
                    service.context.apiService.mediaAppend(mediaID: mediaID, chunk: chunk, index: i, authorization: authorization)
                        .retry(3)
                        .eraseToAnyPublisher()
                }
                .collect()
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        os_log("%{public}s[%{public}ld], %{public}s: append success", ((#file as NSString).lastPathComponent), #line, #function)
                        stateMachine.enter(Finalize.self)
                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: append fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    }
                } receiveValue: { responses in
                    os_log("%{public}s[%{public}ld], %{public}s: append %ld media chunks", ((#file as NSString).lastPathComponent), #line, #function, responses.count)
                }
                .store(in: &service.disposeBag)
        }
    }
    
    class Finalize: TwitterMediaService.UploadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == FinalizePending.self || stateClass == Success.self || stateClass == Fail.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let service = service, let stateMachine = stateMachine else { return }
            guard !service.isCancelled,
                  let autentication = service.context.authenticationService.currentActiveTwitterAutentication.value,
                  let authorization = try? autentication.authorization(appSecret: AppSecret.shared)
            else { return }
            
            guard let mediaID = service.mediaID else {
                stateMachine.enter(Fail.self)
                return
            }
            
            service.context.apiService.mediaFinalize(mediaID: mediaID, authorization: authorization)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: finalize fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        stateMachine.enter(Fail.self)
                    }
                } receiveValue: { response in
                    let response = response.value
                    if let info = response.processingInfo {
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: finalize status pending. check after %lds", ((#file as NSString).lastPathComponent), #line, #function, info.checkAfterSecs)
                        stateMachine.enter(FinalizePending.self)
                    } else {
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: finalize success", ((#file as NSString).lastPathComponent), #line, #function)
                        stateMachine.enter(Success.self)
                    }
                    
                }
                .store(in: &service.disposeBag)

        }
    }
    
    class FinalizePending: TwitterMediaService.UploadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Success.self || stateClass == Fail.self
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let service = service, let stateMachine = stateMachine else { return }
            guard !service.isCancelled,
                  let autentication = service.context.authenticationService.currentActiveTwitterAutentication.value,
                  let authorization = try? autentication.authorization(appSecret: AppSecret.shared)
            else { return }
            
            guard let mediaID = service.mediaID else {
                stateMachine.enter(Fail.self)
                return
            }
            
            service.context.apiService.mediaStatus(mediaID: mediaID, authorization: authorization)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: check media status fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }
                } receiveValue: { response in
                    let response = response.value
                    switch response.processingInfo.state {
                    case "succeeded":
                        stateMachine.enter(Success.self)
                    case "pending", "in_progress":
                        let delay = TimeInterval(response.processingInfo.checkAfterSecs ?? 10)
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak stateMachine] in
                            stateMachine?.enter(FinalizePending.self)
                        }
                    case "failed":
                        stateMachine.enter(Fail.self)
                    default:
                        assertionFailure()
                        stateMachine.enter(Fail.self)
                    }
                }
                .store(in: &service.disposeBag)
        }
    }
    
    class Fail: TwitterMediaService.UploadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }
    
    class Success: TwitterMediaService.UploadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }
    
}

extension Data {
    func chunks(size: Int) -> [Data] {
        return stride(from: 0, to: count, by: size).map {
            Data(self[$0..<Swift.min(count, $0 + size)])
        }
    }
}
