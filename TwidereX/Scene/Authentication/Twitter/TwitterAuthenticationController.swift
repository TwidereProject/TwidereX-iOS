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
    var twitterPinBasedAuthenticationViewController: UIViewController?
    
    // output
    let isAuthenticating = CurrentValueSubject<Bool, Never>(false)
    let error = CurrentValueSubject<Error?, Never>(nil)
    let authenticated = PassthroughSubject<Void, Never>()

    init(context: AppContext, coordinator: SceneCoordinator, authenticateURL: URL, requestTokenExchange: Twitter.API.OAuth.OAuthRequestTokenExchange) {
        self.context = context
        self.coordinator = coordinator
        
        switch requestTokenExchange {
        // default use system AuthenticationServices
        case .customRequestTokenResponse(_, let append):
            authentication(authenticateURL: authenticateURL, append: append)
        // use custom pin-based OAuth when set callback as "oob"
        case .requestTokenResponse(let requestTokenResponse):
            let twitterPinBasedAuthenticationViewModel = TwitterPinBasedAuthenticationViewModel(authenticateURL: authenticateURL)
            authentication(requestTokenResponse: requestTokenResponse, pinCodePublisher: twitterPinBasedAuthenticationViewModel.pinCodePublisher)
            twitterPinBasedAuthenticationViewController = coordinator.present(scene: .twitterPinBasedAuthentication(viewModel: twitterPinBasedAuthenticationViewModel), from: nil, transition: .modal(animated: true, completion: nil))
        }
    }
    
}

extension TwitterAuthenticationController {
    
    // create authenticationSession and setup callback account authentication & verify publisher
    func authentication(authenticateURL: URL, append: Twitter.API.OAuth.CustomRequestTokenResponseAppend) {
        authenticationSession = ASWebAuthenticationSession(url: authenticateURL, callbackURLScheme: "twidere") { [weak self] callback, error in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: callback: %s, error: %s", ((#file as NSString).lastPathComponent), #line, #function, callback?.debugDescription ?? "<nil>", error.debugDescription)
            
            if let error = error {
                if let error = error as? ASWebAuthenticationSessionError {
                    if error.errorCode == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: user cancel authentication", ((#file as NSString).lastPathComponent), #line, #function)
                        self.isAuthenticating.value = false
                        return
                    }
                }
                
                self.isAuthenticating.value = false
                self.error.value = error
                return
            }
            
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

            let property = TwitterAuthentication.Property(
                userID: authentication.userID,
                screenName: authentication.screenName,
                consumerKey: authentication.consumerKey,
                consumerSecret: authentication.consumerSecret,
                accessToken: authentication.accessToken,
                accessTokenSecret: authentication.accessTokenSecret
            )
            TwitterAuthenticationController.verifyAndSaveAuthentication(context: self.context, property: property, appSecret: .shared)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .failure(let error):
                        self.isAuthenticating.value = false
                        self.error.value = error
                    case .finished:
                        break
                    }
                } receiveValue: { response in
                    let user = response.value
                    os_log("%{public}s[%{public}ld], %{public}s: user @%s verified", ((#file as NSString).lastPathComponent), #line, #function, user.screenName)
                    self.authenticated.send()
                }
                .store(in: &self.disposeBag)
        }
    }
    
    // setup pin code based account authentication & verify publisher
    func authentication(requestTokenResponse: Twitter.API.OAuth.RequestTokenResponse, pinCodePublisher: PassthroughSubject<String, Never>) {
        pinCodePublisher
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                self.isAuthenticating.send(true)
                self.twitterPinBasedAuthenticationViewController?.dismiss(animated: true, completion: nil)
                self.twitterPinBasedAuthenticationViewController = nil
            })
            .setFailureType(to: Error.self)
            .flatMap { pinCode in
                self.context.apiService.twitterAccessToken(requestToken: requestTokenResponse.oauthToken, pinCode: pinCode)
                    .retry(3)
            }
            .flatMap { accessTokenResponse -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> in
                let oauthSecret = AppSecret.shared.oauthSecret
                let property = TwitterAuthentication.Property(
                    userID: accessTokenResponse.userID,
                    screenName: accessTokenResponse.screenName,
                    consumerKey: oauthSecret.consumerKey,
                    consumerSecret: oauthSecret.consumerKeySecret,
                    accessToken: accessTokenResponse.oauthToken,
                    accessTokenSecret: accessTokenResponse.oauthTokenSecret
                )
                return TwitterAuthenticationController.verifyAndSaveAuthentication(context: self.context, property: property, appSecret: .shared)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    self.isAuthenticating.value = false
                    self.error.value = error
                case .finished:
                    break
                }
            } receiveValue: { response in
                let user = response.value
                os_log("%{public}s[%{public}ld], %{public}s: user @%s verified", ((#file as NSString).lastPathComponent), #line, #function, user.screenName)
                self.authenticated.send()
            }
            .store(in: &self.disposeBag)
    }
    
}

extension TwitterAuthenticationController {
    
    // shared
    static func verifyAndSaveAuthentication(context: AppContext, property: TwitterAuthentication.Property, appSecret: AppSecret) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        Just(property)
            .setFailureType(to: Error.self)
            .flatMap { property -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> in
                let persistProperty: TwitterAuthentication.Property
                do {
                    persistProperty = try property.seal(appSecret: appSecret)
                } catch {
                    return Fail(error: AuthenticationError.verifyCredentialsFail(error: error)).eraseToAnyPublisher()
                }
                
                let authorization = Twitter.API.OAuth.Authorization(
                    consumerKey: property.consumerKey,
                    consumerSecret: property.consumerSecret,
                    accessToken: property.accessToken,
                    accessTokenSecret: property.accessTokenSecret
                )
                let managedObjectContext = context.backgroundManagedObjectContext
                return context.apiService.verifyCredentials(authorization: authorization)
                    .retry(3)
                    .flatMap { response -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> in
                        let entity = response.value
                        let userID = entity.idStr
                        assert(userID == persistProperty.userID)
                        let twitterUserRequest = TwitterUser.sortedFetchRequest
                        twitterUserRequest.predicate = TwitterUser.predicate(idStr: userID)
                        twitterUserRequest.fetchLimit = 1
                        guard let authenticatedTwitterUser = try? managedObjectContext.fetch(twitterUserRequest).first else {
                            return Fail(error: AuthenticationError.verifyCredentialsFail(error: nil)).eraseToAnyPublisher()
                        }
                        
                        return managedObjectContext.performChanges {
                            let twitterAuthenticationRequest = TwitterAuthentication.sortedFetchRequest
                            twitterAuthenticationRequest.predicate = TwitterAuthentication.predicate(userID: persistProperty.userID)
                            twitterAuthenticationRequest.fetchLimit = 1
                            if let oldTwitterAuthentication = try! managedObjectContext.fetch(twitterAuthenticationRequest).first {
                                oldTwitterAuthentication.update(screenName: persistProperty.screenName)
                                oldTwitterAuthentication.update(consumerKey: persistProperty.consumerKey)
                                oldTwitterAuthentication.update(consumerSecret: persistProperty.consumerSecret)
                                oldTwitterAuthentication.update(accessToken: persistProperty.accessToken)
                                oldTwitterAuthentication.update(accessTokenSecret: persistProperty.accessTokenSecret)
                                oldTwitterAuthentication.update(nonce: persistProperty.nonce ?? "")
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
                                    property: persistProperty,
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
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
}

extension TwitterAuthenticationController {
    enum AuthenticationError: Error {
        case invalidOAuthCallback(error: Error?)
        case verifyCredentialsFail(error: Error?)
    }
}
