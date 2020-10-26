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

class TwitterMediaService {
    
    var disposeBag = Set<AnyCancellable>()
    let identifier = UUID()
    
    // input
    let context: AppContext
    var isCancelled = false
    let payload: Payload
    
    // output
    var slice: [Data] = []
    var mediaType: String = ""
    var mediaID: String? = nil
    
    private(set) lazy var uploadStatusStateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            TwitterMediaService.UploadStatusState.Init(service: self),
            TwitterMediaService.UploadStatusState.Append(service: self),
            TwitterMediaService.UploadStatusState.Finalize(service: self),
            TwitterMediaService.UploadStatusState.FinalizePending(service: self),
            TwitterMediaService.UploadStatusState.Fail(service: self),
            TwitterMediaService.UploadStatusState.Success(service: self),
        ])
        return stateMachine
    }()
    lazy var uploadStatusStateMachinePublisher = CurrentValueSubject<TwitterMediaService.UploadStatusState?, Never>(nil)
    
    init(context: AppContext, payload: Payload) {
        self.context = context
        self.payload = payload
        
        uploadStatusStateMachine.enter(TwitterMediaService.UploadStatusState.Init.self)
    }
    
    func cancel() {
        isCancelled = true
        disposeBag.removeAll()
        uploadStatusStateMachine.enter(TwitterMediaService.UploadStatusState.Fail.self)
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
                    return [imageData]
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
    class UploadStatusState: GKState {
        weak var service: TwitterMediaService?
        
        init(service: TwitterMediaService) {
            self.service = service
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
            service?.uploadStatusStateMachinePublisher.send(self)
        }
    }
}
extension TwitterMediaService.UploadStatusState {
    class Init: TwitterMediaService.UploadStatusState {
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
                    let mediaType: String
                    switch payload {
                    case .image(let url):
                        slice = payload.slice()
                        mediaType = slice.first.flatMap { data in
                            return data.kf.imageFormat == .PNG ? "image/png" : "image/jpeg"
                        } ?? ""
                    case .gif(let url):
                        slice = []
                        mediaType = "image/gif"
                    case .video(let url):
                        slice = []  // TODO:
                        mediaType = "video/mp4"
                    }
                    
                    guard !slice.isEmpty, !mediaType.isEmpty else {
                        DispatchQueue.main.async {
                            stateMachine.enter(Fail.self)
                        }
                        return
                    }
                    
                    let totalBytes = slice.reduce(0, { result, next in return result + next.count })
                    service.context.apiService.mediaInit(totalBytes: totalBytes, mediaType: mediaType, authorization: authorization)
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
    
    class Append: TwitterMediaService.UploadStatusState {
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

                    case .failure(let error):
                        os_log("%{public}s[%{public}ld], %{public}s: append fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    }
                } receiveValue: { responses in
                    os_log("%{public}s[%{public}ld], %{public}s: append %ld media chunk", ((#file as NSString).lastPathComponent), #line, #function, responses.count)
                    stateMachine.enter(Finalize.self)
                }
                .store(in: &service.disposeBag)
        }
    }
    
    class Finalize: TwitterMediaService.UploadStatusState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == FinalizePending.self || stateClass == Success.self || stateClass == Fail.self
        }
    }
    
    class FinalizePending: TwitterMediaService.UploadStatusState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return stateClass == Success.self || stateClass == Fail.self
        }
    }
    
    class Fail: TwitterMediaService.UploadStatusState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }
    
    class Success: TwitterMediaService.UploadStatusState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }
    
}
