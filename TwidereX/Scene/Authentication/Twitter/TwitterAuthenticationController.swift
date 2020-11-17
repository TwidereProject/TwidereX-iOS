//
//  TwitterAuthenticationController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020/11/12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import CoreDataStack
import AuthenticationServices
import WebKit
import TwitterAPI

final class TwitterAuthenticationController: NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    var context: AppContext!
    var coordinator: SceneCoordinator!
    var authenticationSession: ASWebAuthenticationSession?
    
    // output
    let isAuthenticating = CurrentValueSubject<Bool, Never>(false)
    let error = CurrentValueSubject<Error?, Never>(nil)
    let authenticated = PassthroughSubject<Void, Never>()

    init(context: AppContext, coordinator: SceneCoordinator, authenticateURL: URL, requestTokenExchange: Twitter.API.OAuth.OAuthRequestTokenExchange) {
        self.context = context
        self.coordinator = coordinator
        
        switch requestTokenExchange {
        case .customRequestTokenResponse(_, let append):
            authentication(authenticateURL: authenticateURL, append: append)
        case .requestTokenResponse(let requestTokenResponse):
            let twitterPinBasedAuthenticationViewModel = TwitterPinBasedAuthenticationViewModel(authenticateURL: authenticateURL)
            authentication(requestTokenResponse: requestTokenResponse, pinCodePublisher: twitterPinBasedAuthenticationViewModel.pinCodePublisher)

            coordinator.present(scene: .twitterPinBasedAuthentication(viewModel: twitterPinBasedAuthenticationViewModel), from: nil, transition: .modal(animated: true, completion: nil))
        }
    }
    
}

extension TwitterAuthenticationController {
    
    func authentication(authenticateURL: URL, append: Twitter.API.OAuth.CustomRequestTokenResponseAppend) {
        authenticationSession = ASWebAuthenticationSession(url: authenticateURL, callbackURLScheme: "twidere") { [weak self] callback, error in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: callback: %s, error: %s", ((#file as NSString).lastPathComponent), #line, #function, callback?.debugDescription ?? "<nil>", error.debugDescription)
            
            if let error = error {
                if let error = error as? ASWebAuthenticationSessionError {
                    if error.errorCode == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        self.isAuthenticating.value = false
                        return
                    }
                }
                
                self.isAuthenticating.value = false
                self.error.value = error
                return
            }
            
            let rawProperty: TwitterAuthentication.Property
            let authenticationProperty: TwitterAuthentication.Property
            guard let callbackURL = callback,
                  let oauthCallbackResponse = Twitter.API.OAuth.OAuthCallbackResponse(callbackURL: callbackURL),
                  let authentication = try? oauthCallbackResponse.authentication(privateKey: append.clientExchangePrivateKey)
            else {
                let error = AuthenticationError.invalidOAuthCallback(error: nil)
                self.isAuthenticating.value = false
                self.error.value = error
                return
            }
            os_log("%{public}s[%{public}ld], %{public}s: authentication: %s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: authentication))
            
            rawProperty = TwitterAuthentication.Property(userID: authentication.userID, screenName: authentication.screenName, consumerKey: authentication.consumerKey, consumerSecret: authentication.consumerSecret, accessToken: authentication.accessToken, accessTokenSecret: authentication.accessTokenSecret)
            do {
                authenticationProperty = try rawProperty.seal(appSecret: AppSecret.shared)
            } catch {
                self.isAuthenticating.value = false
                self.error.value = error
                return
            }
            
            let managedObjectContext = self.context.backgroundManagedObjectContext
            let authorization = Twitter.API.OAuth.Authorization(
                consumerKey: rawProperty.consumerKey,
                consumerSecret: rawProperty.consumerSecret,
                accessToken: rawProperty.accessToken,
                accessTokenSecret: rawProperty.accessTokenSecret
            )
            self.context.apiService.verifyCredentials(authorization: authorization)
                .retry(3)
                .tryMap { response -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> in
                    let entity = response.value
                    let userID = entity.idStr
                    assert(userID == authenticationProperty.userID)
                    let twitterUserRequest = TwitterUser.sortedFetchRequest
                    twitterUserRequest.predicate = TwitterUser.predicate(idStr: userID)
                    twitterUserRequest.fetchLimit = 1
                    guard let authenticatedTwitterUser = try? managedObjectContext.fetch(twitterUserRequest).first else {
                        throw AuthenticationError.verifyCredentialsFail(error: error)
                    }
                    
                    return managedObjectContext.performChanges {
                        let twitterAuthenticationRequest = TwitterAuthentication.sortedFetchRequest
                        twitterAuthenticationRequest.predicate = TwitterAuthentication.predicate(userID: authenticationProperty.userID)
                        twitterAuthenticationRequest.fetchLimit = 1
                        if let oldTwitterAuthentication = try! managedObjectContext.fetch(twitterAuthenticationRequest).first {
                            oldTwitterAuthentication.update(screenName: authenticationProperty.screenName)
                            oldTwitterAuthentication.update(consumerKey: authenticationProperty.consumerKey)
                            oldTwitterAuthentication.update(consumerSecret: authenticationProperty.consumerSecret)
                            oldTwitterAuthentication.update(accessToken: authenticationProperty.accessToken)
                            oldTwitterAuthentication.update(accessTokenSecret: authenticationProperty.accessTokenSecret)
                            oldTwitterAuthentication.update(nonce: authenticationProperty.nonce ?? "")
                            oldTwitterAuthentication.update(updatedAt: Date())
                            
                            if oldTwitterAuthentication.authenticationIndex == nil {
                                let authenticationIndexProperty = AuthenticationIndex.Property(platform: .twitter)
                                let authenticationIndex = AuthenticationIndex.insert(into: managedObjectContext, property: authenticationIndexProperty)
                                oldTwitterAuthentication.update(authenticationIndex: authenticationIndex)
                            }
                            if oldTwitterAuthentication.twitterUser == nil {
                                oldTwitterAuthentication.update(twitterUser: authenticatedTwitterUser)
                            }
                            
                        } else {
                            let authenticationIndexProperty = AuthenticationIndex.Property(platform: .twitter)
                            let authenticationIndex = AuthenticationIndex.insert(into: managedObjectContext, property: authenticationIndexProperty)
                            _ = TwitterAuthentication.insert(
                                into: managedObjectContext,
                                property: authenticationProperty,
                                authenticationIndex: authenticationIndex,
                                twitterUser: authenticatedTwitterUser
                            )
                        }
                    }
                    .setFailureType(to: Error.self)
                    .tryMap { result in
                        switch result {
                        case .failure(let error):
                            throw error
                        case .success:
                            return response
                        }
                    }
                    .eraseToAnyPublisher()
                }
                .switchToLatest()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .failure(let error):
                        self.isAuthenticating.value = false
                        self.error.value = error
                    case .finished:
                        self.authenticated.send()
                    }
                } receiveValue: { response in
                    let user = response.value
                    os_log("%{public}s[%{public}ld], %{public}s: user @%s verified", ((#file as NSString).lastPathComponent), #line, #function, user.screenName)
                }
                .store(in: &self.disposeBag)
        }
    }
    
    func authentication(requestTokenResponse: Twitter.API.OAuth.RequestTokenResponse, pinCodePublisher: PassthroughSubject<String, Never>) {
        pinCodePublisher
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                self.isAuthenticating.send(true)
            })
            .setFailureType(to: Error.self)
            .map { pinCode in
                return self.context.apiService.twitterAccessToken(requestToken: requestTokenResponse.oauthToken, pinCode: pinCode)
            }
            .switchToLatest()
            .map { accessTokenResponse in
                accessTokenResponse
                
            }
//            .sink { completion in
//                switch completion {
//                case .failure(let error):
//                    self.isAuthenticating.send(false)
//                    self.error.send(error)
//                case .finished:
//                    break
//                }
//            } receiveValue: { response in
//
//            }
//            .store(in: &disposeBag)
    }
    
}

extension TwitterAuthenticationController {
    enum AuthenticationError: Error {
        case invalidOAuthCallback(error: Error?)
        case verifyCredentialsFail(error: Error?)
    }
}
