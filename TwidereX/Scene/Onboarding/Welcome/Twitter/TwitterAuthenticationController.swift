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
import TwitterSDK
import AppShared
import TwidereCommon

// Note:
// use given AuthorizationContext to authorize user
// - OAuth:
//   - PIN-based: for user who use customize consumer key OR custom build with "oob" OAuth endpoint
//   - custom: App Store default build OR custom build with OAuth relay server endpoint
// - OAuth2:
//
final class TwitterAuthenticationController: NeedsDependency {
    
    let logger = Logger(subsystem: "TwitterAuthenticationController", category: "Controller")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    var context: AppContext!
    var coordinator: SceneCoordinator!
    let appSecret: AppSecret
    var authenticationSession: ASWebAuthenticationSession?
    var twitterPinBasedAuthenticationViewController: UIViewController?
    
    // output
    let isAuthenticating = CurrentValueSubject<Bool, Never>(false)
    let error = CurrentValueSubject<Error?, Never>(nil)
    let authenticated = PassthroughSubject<Twitter.Entity.User, Never>()

    init(
        context: AppContext,
        coordinator: SceneCoordinator,
        appSecret: AppSecret,
        authorizationContext: AuthorizationContext
    ) {
        self.context = context
        self.coordinator = coordinator
        self.appSecret = appSecret
        
        setup(authorizationContext)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension TwitterAuthenticationController {
    public enum AuthorizationContext {
        case oauth(Twitter.API.OAuth.RequestTokenResponseContext)
        case oauth2(Twitter.API.V2.OAuth2.RequestTokenResponse)
    }
}

extension TwitterAuthenticationController {

    private func setup(_ authorizationContext: AuthorizationContext) {
        switch authorizationContext {
        case .oauth(let context):
            switch context {
            // use PIN-based OAuth via WKWebView (when set callback as "oob")
            case .standard(let response):
                let authorizeURL = Twitter.API.OAuth.authorizeURL(requestToken: response.oauthToken)
                let twitterPinBasedAuthenticationViewModel = TwitterPinBasedAuthenticationViewModel(authorizeURL: authorizeURL)
                setupPINAuthenticate(
                    requestTokenResponse: response,
                    appSecret: appSecret,
                    pinCodePublisher: twitterPinBasedAuthenticationViewModel.pinCodePublisher
                )
                Task {
                    await twitterPinBasedAuthenticationViewController = coordinator.present(
                        scene: .twitterPinBasedAuthentication(viewModel: twitterPinBasedAuthenticationViewModel),
                        from: nil,
                        transition: .modal(animated: true, completion: nil)
                    )
                }   // end Task
            // 3-legged OAuth via system AuthenticationServices
            case .relay(let response):
                setupAuthenticationSession(requestTokenResponse: response)
            }
        case .oauth2(let response):
            setupAuthenticationSession(requestTokenResponse: response)
        }
    }
    
}

extension TwitterAuthenticationController {
    
    func setupAuthenticationSession(
        requestTokenResponse response: Twitter.API.OAuth.RequestToken.Relay.RequestTokenResponse
    ) {
        let authorizeURL = Twitter.API.OAuth.authorizeURL(requestToken: response.append.requestToken)
        authenticationSession = ASWebAuthenticationSession(
            url: authorizeURL,
            callbackURLScheme: AppCommon.scheme
        ) { [weak self] callback, error in
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
                  let customOAuthCallback = Twitter.API.OAuth.RequestToken.Relay.CustomOAuthCallback(callbackURL: callbackURL),
                  let authentication = try? customOAuthCallback.authentication(privateKey: response.append.clientExchangePrivateKey)
            else {
                let error = AuthenticationError.invalidOAuthCallback(error: nil)
                self.isAuthenticating.value = false
                self.error.value = error
                return
            }
            os_log("%{public}s[%{public}ld], %{public}s: authentication: %s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: authentication))

            Task {
                let property = TwitterAuthentication.Property(
                    userID: authentication.userID,
                    screenName: authentication.screenName,
                    consumerKey: authentication.consumerKey,
                    consumerSecret: authentication.consumerSecret,
                    accessToken: authentication.accessToken,
                    accessTokenSecret: authentication.accessTokenSecret,
                    nonce: "",
                    bearerAccessToken: "",
                    bearerRefreshToken: "",
                    bearerNonce: "",
                    updatedAt: Date()
                )
                do {
                    let response = try await TwitterAuthenticationController.verifyAndSaveAuthentication(
                        context: self.context,
                        property: property,
                        appSecret: .default
                    )
                    let user = response.value
                    os_log("%{public}s[%{public}ld], %{public}s: user @%s verified", ((#file as NSString).lastPathComponent), #line, #function, user.screenName)
                    self.authenticated.send(user)
                } catch {
                    self.isAuthenticating.value = false
                    self.error.value = error
                }
            }
        }
    }
    
    func setupAuthenticationSession(
        requestTokenResponse response: Twitter.API.V2.OAuth2.RequestTokenResponse
    ) {
        authenticationSession = ASWebAuthenticationSession(
            url: response.authorizeURL,
            callbackURLScheme: AppCommon.scheme
        ) { [weak self] callback, error in
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
                  let oauthCallback = Twitter.API.V2.OAuth2.OAuthCallback(callbackURL: callbackURL)
            else {
                let error = AuthenticationError.invalidOAuthCallback(error: nil)
                self.isAuthenticating.value = false
                self.error.value = error
                return
            }
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): code: \(oauthCallback.code)")

            Task {
            
                do {
                    let accessTokenResponse = try await self.context.apiService.twitterOAuth2AccessToken(query: .init(
                        code: oauthCallback.code,
                        clientID: response.clientID,
                        redirectURI: response.callbackURL.absoluteString,
                        codeVerifier: response.verifier
                    ))
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): accessToken: \(accessTokenResponse.accessToken), refreshToken: \(accessTokenResponse.refreshToken)")
                    
//                    let response = try await TwitterAuthenticationController.verifyAndSaveAuthentication(context: self.context, property: property, appSecret: .default)
//                    let user = response.value
//                    os_log("%{public}s[%{public}ld], %{public}s: user @%s verified", ((#file as NSString).lastPathComponent), #line, #function, user.screenName)
//                    self.authenticated.send(user)
                    
                } catch {
                    self.isAuthenticating.value = false
                    self.error.value = error
                }
            }   // end Task
        }
    }
    
}

extension TwitterAuthenticationController {

    // setup pin code based account authentication & verify publisher
    func setupPINAuthenticate(
        requestTokenResponse response: Twitter.API.OAuth.RequestToken.Standard.RequestTokenResponse,
        appSecret: AppSecret,
        pinCodePublisher: PassthroughSubject<String, Never>
    ) {
        guard let context = self.context else { return }
        
        pinCodePublisher
            .sink(receiveValue: { [weak self] pinCode in
                guard let self = self else { return }
                Task {
                    self.isAuthenticating.value = true
                    defer {
                        self.isAuthenticating.value = false
                    }
                    
                    await self.twitterPinBasedAuthenticationViewController?.dismiss(animated: true, completion: nil)
                    self.twitterPinBasedAuthenticationViewController = nil
                    do {
                        let oauthSecret = appSecret.oauthSecret
                        let accessTokenResponse = try await context.apiService.twitterOAuthAccessToken(
                            query: .init(
                                consumerKey: oauthSecret.consumerKey,
                                consumerSecret: oauthSecret.consumerKeySecret,
                                requestToken: response.oauthToken,
                                pinCode: pinCode
                            )
                        )
                        
                        let property = TwitterAuthentication.Property(
                            userID: accessTokenResponse.userID,
                            screenName: accessTokenResponse.screenName,
                            consumerKey: oauthSecret.consumerKey,
                            consumerSecret: oauthSecret.consumerKeySecret,
                            accessToken: accessTokenResponse.oauthToken,
                            accessTokenSecret: accessTokenResponse.oauthTokenSecret,
                            nonce: "",
                            bearerAccessToken: "",
                            bearerRefreshToken: "",
                            bearerNonce: "",
                            updatedAt: Date()
                        )
                        let response = try await TwitterAuthenticationController.verifyAndSaveAuthentication(
                            context: context,
                            property: property,
                            appSecret: appSecret
                        )
                        
                        let user = response.value
                        self.authenticated.send(user)
                        
                    } catch {
                        self.error.value = error
                    }
                }   // end Task
            })
            .store(in: &disposeBag)
    }

}

extension TwitterAuthenticationController {
    
    // shared
    static func verifyAndSaveAuthentication(
        context: AppContext,
        property: TwitterAuthentication.Property,
        appSecret: AppSecret
    ) async throws -> Twitter.Response.Content<Twitter.Entity.User> {
        let twitterAuthenticationProperty: TwitterAuthentication.Property
        do {
            twitterAuthenticationProperty = try property.sealing(appSecret: appSecret)
        } catch {
            throw AuthenticationError.verifyCredentialsFail(error: error)
        }
                                                            
        let response: Twitter.Response.Content<Twitter.Entity.User>
        do {
            let authorization = Twitter.API.OAuth.Authorization(
                consumerKey: property.consumerKey,
                consumerSecret: property.consumerSecret,
                accessToken: property.accessToken,
                accessTokenSecret: property.accessTokenSecret
            )
            response = try await context.apiService.verifyTwitterCredentials(authorization: authorization)
        } catch {
            throw error
        }
        
        assert(twitterAuthenticationProperty.userID == response.value.idStr)
        let userID = response.value.idStr
        
        let managedObjectContext = context.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let now = Date()
            
            // get authenticated user
            let twitterUserRequest = TwitterUser.sortedFetchRequest
            twitterUserRequest.predicate = TwitterUser.predicate(id: userID)
            twitterUserRequest.fetchLimit = 1
            
            // the `verifyTwitterCredentials` method should insert this user
            guard let twitterUser = try? managedObjectContext.fetch(twitterUserRequest).first else {
                assertionFailure()
                return
            }
         
            if let oldTwitterAuthentication = twitterUser.twitterAuthentication {
                // update authentication
                oldTwitterAuthentication.update(screenName: twitterAuthenticationProperty.screenName)
                oldTwitterAuthentication.update(consumerKey: twitterAuthenticationProperty.consumerKey)
                oldTwitterAuthentication.update(consumerSecret: twitterAuthenticationProperty.consumerSecret)
                oldTwitterAuthentication.update(accessToken: twitterAuthenticationProperty.accessToken)
                oldTwitterAuthentication.update(accessTokenSecret: twitterAuthenticationProperty.accessTokenSecret)
                oldTwitterAuthentication.update(nonce: twitterAuthenticationProperty.nonce)
                oldTwitterAuthentication.update(updatedAt: now)
                // update authentication index
                oldTwitterAuthentication.authenticationIndex.update(activeAt: now)
            } else {
                // insert authentication index
                let authenticationIndexProperty = AuthenticationIndex.Property(platform: .twitter)
                let authenticationIndex = AuthenticationIndex.insert(
                    into: managedObjectContext,
                    property: authenticationIndexProperty
                )
                // insert authentication
                _ = TwitterAuthentication.insert(
                    into: managedObjectContext,
                    property: twitterAuthenticationProperty,
                    relationship: .init(
                        authenticationIndex: authenticationIndex,
                        user: twitterUser
                    )
                )
            }
        }   // end managedObjectContext.perform…

        return response
    }
    
//    static func verifyAndAppendAuthenticationV2(
//        context: AppContext,
//        property: TwitterAuthentication.Property,
//        appSecret: AppSecret
//    ) async throws -> Twitter.Response.Content<Twitter.Entity.User> {
//        let twitterAuthenticationProperty: TwitterAuthentication.Property
//        do {
//            twitterAuthenticationProperty = try property.sealingV2(appSecret: appSecret)
//        } catch {
//            throw AuthenticationError.verifyCredentialsFail(error: error)
//        }
//
//        let response: Twitter.Response.Content<Twitter.Entity.V2.User>
//        do {
//            let authorization = Twitter.API.V2.OAuth2.Authorization(
//                accessToken: property.bearerAccessToken,
//                refreshToken: property.bearerRefreshToken
//            )
//            response = try await context.apiService.verifyTwitterCredentials(authorization: authorization)
//        } catch {
//            throw error
//        }
//
//        assert(twitterAuthenticationProperty.userID == response.value.idStr)
//        let userID = response.value.idStr
//
//        let managedObjectContext = context.backgroundManagedObjectContext
//        try await managedObjectContext.performChanges {
//            let now = Date()
//
//            // get authenticated user
//            let twitterUserRequest = TwitterUser.sortedFetchRequest
//            twitterUserRequest.predicate = TwitterUser.predicate(id: userID)
//            twitterUserRequest.fetchLimit = 1
//
//            // the `verifyTwitterCredentials` method should insert this user
//            guard let twitterUser = try? managedObjectContext.fetch(twitterUserRequest).first else {
//                assertionFailure()
//                return
//            }
//
//            if let oldTwitterAuthentication = twitterUser.twitterAuthentication {
//                // update authentication
//                oldTwitterAuthentication.update(bearerAccessToken: twitterAuthenticationProperty.bearerAccessToken)
//                oldTwitterAuthentication.update(bearerRefreshToken: twitterAuthenticationProperty.bearerRefreshToken)
//                oldTwitterAuthentication.update(bearerNonce: twitterAuthenticationProperty.bearerNonce)
//                oldTwitterAuthentication.update(updatedAt: now)
//                // update authentication index
//                oldTwitterAuthentication.authenticationIndex.update(activeAt: now)
//            } else {
//                // insert authentication index
//                let authenticationIndexProperty = AuthenticationIndex.Property(platform: .twitter)
//                let authenticationIndex = AuthenticationIndex.insert(
//                    into: managedObjectContext,
//                    property: authenticationIndexProperty
//                )
//                // insert authentication
////                _ = TwitterAuthentication.insert(
////                    into: managedObjectContext,
////                    property: twitterAuthenticationProperty,
////                    authenticationIndex: authenticationIndex,
////                    twitterUser: twitterUser
////                )
//            }
//        }   // end managedObjectContext.perform…
//
//        return response
//    }
    
}

extension TwitterAuthenticationController {
    enum AuthenticationError: Error {
        case invalidOAuthCallback(error: Error?)
        case verifyCredentialsFail(error: Error?)
    }
}
