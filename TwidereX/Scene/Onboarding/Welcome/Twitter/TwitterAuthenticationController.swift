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

// Note:
// use given AuthorizationContext to authorize user
// - OAuth:
//   - PIN-based: for user who use customize consumer key OR custom build with "oob" OAuth endpoint
//   - custom: App Store default build OR custom build with OAuth relay server endpoint
// - OAuth2:
//   - TODO:
final class TwitterAuthenticationController: NeedsDependency {
    
    let logger = Logger(subsystem: "TwitterAuthenticationController", category: "Controller")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    var context: AppContext!
    var coordinator: SceneCoordinator!
    
    // output
    @Published var authenticationSession: ASWebAuthenticationSession?
    @Published var twitterPinBasedAuthenticationViewController: UIViewController?
    @Published var isAuthenticating = false
    @Published var error: Error? = nil
    @Published var authenticatedTwitterUser: Twitter.Entity.User? = nil

    init(
        context: AppContext,
        coordinator: SceneCoordinator
    ) {
        self.context = context
        self.coordinator = coordinator
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension TwitterAuthenticationController {

    @MainActor
    func setup(authorizationContext: Twitter.AuthorizationContext) async throws {
        switch authorizationContext {
        case .oauth(let context):
            let requestToken = try await context.requestToken(session: self.context.apiService.session)

            switch (context, requestToken) {
            // Pin-based OAuth via WebView
            case (.standard(let oauthContext), .standard(let requestToken)):
                setupTwitterPinBasedAuthenticationViewController(
                    oauthContext: oauthContext,
                    requestToken: requestToken
                )
                
            // 3-legged OAuth via system AuthenticationServices
            case (.relay(let oauthContext), .relay(let requestToken)):
                setupAuthenticationSession(
                    oauthContext: oauthContext,
                    requestToken: requestToken
                )
            default:
                assertionFailure()
                throw AppError.implicit(.badRequest)
            }
            
        case .oauth2(let context):
            switch context {
            case .relay(let context):
                let authorization = try await context.authorize(session: self.context.apiService.session)
                setupAuthenticationSession(
                    oauthContext: context,
                    authorization: authorization
                )
            }
        }   // end switch
    }
    
}

extension TwitterAuthenticationController {

    // setup pin code based account authentication & verify publisher
    func setupTwitterPinBasedAuthenticationViewController(
        oauthContext: Twitter.AuthorizationContext.OAuth.Standard.Context,
        requestToken: Twitter.API.OAuth.RequestToken.Standard.Response
    ) {
        let authorizeURL = Twitter.API.OAuth.authorizeURL(requestToken: requestToken.oauthToken)
        let viewModel = TwitterPinBasedAuthenticationViewModel(authorizeURL: authorizeURL)
        let viewController: TwitterPinBasedAuthenticationViewController = {
            let viewController = TwitterPinBasedAuthenticationViewController()
            viewController.context = self.context
            viewController.coordinator = self.coordinator
            viewController.viewModel = viewModel
            return viewController
        }()
        
        viewModel.pinCodePublisher
            .sink(receiveValue: { [weak self] pinCode in
                guard let self = self else { return }
                Task {
                    self.isAuthenticating = true
                    defer {
                        self.isAuthenticating = false
                    }

                    await self.twitterPinBasedAuthenticationViewController?.dismiss(animated: true, completion: nil)
                    self.twitterPinBasedAuthenticationViewController = nil
                    do {
                        let accessTokenResponse = try await self.context.apiService.twitterOAuthAccessToken(
                            query: .init(
                                consumerKey: oauthContext.consumerKey,
                                consumerSecret: oauthContext.consumerKeySecret,
                                requestToken: requestToken.oauthToken,
                                pinCode: pinCode
                            )
                        )

                        let property = TwitterAuthentication.Property(
                            userID: accessTokenResponse.userID,
                            screenName: accessTokenResponse.screenName,
                            consumerKey: oauthContext.consumerKey,
                            consumerSecret: oauthContext.consumerKeySecret,
                            accessToken: accessTokenResponse.oauthToken,
                            accessTokenSecret: accessTokenResponse.oauthTokenSecret,
                            nonce: "",
                            bearerAccessToken: "",
                            bearerRefreshToken: "",
                            updatedAt: Date()
                        )
                        let response = try await TwitterAuthenticationController.verifyAndSaveAuthentication(
                            context: self.context,
                            property: property
                        )

                        let user = response.value
                        self.authenticatedTwitterUser = user

                    } catch {
                        self.error = error
                    }
                }   // end Task
            })
            .store(in: &disposeBag)
        
        self.twitterPinBasedAuthenticationViewController = viewController
    }

}

extension TwitterAuthenticationController {

    func setupAuthenticationSession(
        oauthContext: Twitter.AuthorizationContext.OAuth.Relay.Context,
        requestToken: Twitter.API.OAuth.RequestToken.Relay.Response
    ) {
        let authorizeURL = Twitter.API.OAuth.authorizeURL(requestToken: requestToken.append.requestToken)
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
                        self.isAuthenticating = false
                        return
                    }
                }

                self.isAuthenticating = false
                self.error = error
                return
            }

            guard let callbackURL = callback,
                  let customOAuthCallback = Twitter.API.OAuth.RequestToken.Relay.OAuthCallback(callbackURL: callbackURL),
                  let authentication = try? customOAuthCallback.authentication(privateKey: requestToken.append.clientExchangePrivateKey)
            else {
                let error = AuthenticationError.invalidOAuthCallback(error: nil)
                self.isAuthenticating = false
                self.error = error
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
                    updatedAt: Date()
                )
                do {
                    let response = try await TwitterAuthenticationController.verifyAndSaveAuthentication(
                        context: self.context,
                        property: property
                    )
                    let user = response.value
                    os_log("%{public}s[%{public}ld], %{public}s: user @%s verified", ((#file as NSString).lastPathComponent), #line, #function, user.screenName)
                    self.authenticatedTwitterUser = user
                } catch {
                    self.isAuthenticating = false
                    self.error = error
                }
            }   // end Task
        }
    }

    func setupAuthenticationSession(
        oauthContext: Twitter.AuthorizationContext.OAuth2.Relay.Context,
        authorization: Twitter.AuthorizationContext.OAuth2.Relay.Response
    ) {
        let authorizeURL = Twitter.API.V2.OAuth2.authorizeURL(
            endpoint: oauthContext.endpoint,
            clientID: oauthContext.clientID,
            challenge: authorization.content.challenge,
            state: authorization.content.state
        )

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
                        self.isAuthenticating = false
                        return
                    }
                }

                self.isAuthenticating = false
                self.error = error
                return
            }

            guard let callbackURL = callback,
                  let oauthCallback = Twitter.API.V2.OAuth2.Authorize.Relay.OAuthCallback(callbackURL: callbackURL),
                  let response = try? oauthCallback.authentication(privateKey: authorization.append.clientExchangePrivateKey)
            else {
                let error = AuthenticationError.invalidOAuthCallback(error: nil)
                self.isAuthenticating = false
                self.error = error
                return
            }
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): accessToken: \(response.oauth2AccessToken)")

            Task {
                let property = TwitterAuthentication.Property(
                    userID: response.userID,
                    screenName: response.screenName,
                    consumerKey: response.oauthConsumerKey,
                    consumerSecret: response.oauthConsumerSecret,
                    accessToken: response.oauthAccessToken,
                    accessTokenSecret: response.oauthAccessTokenSecret,
                    nonce: "",
                    bearerAccessToken: response.oauth2AccessToken,
                    bearerRefreshToken: response.oauth2AccessToken,
                    updatedAt: Date()
                )
                do {
                    let response = try await TwitterAuthenticationController.verifyAndSaveAuthentication(
                        context: self.context,
                        property: property
                    )
                    let user = response.value
                    os_log("%{public}s[%{public}ld], %{public}s: user @%s verified", ((#file as NSString).lastPathComponent), #line, #function, user.screenName)
                    self.authenticatedTwitterUser = user
                } catch {
                    self.isAuthenticating = false
                    self.error = error
                }
            }   // end Task
        }
    }

}

extension TwitterAuthenticationController {

    // shared
    static func verifyAndSaveAuthentication(
        context: AppContext,
        property: TwitterAuthentication.Property
    ) async throws -> Twitter.Response.Content<Twitter.Entity.User> {
        let twitterAuthenticationProperty: TwitterAuthentication.Property
        do {
            twitterAuthenticationProperty = try property.sealing(secret: AppSecret.default.secret)
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
