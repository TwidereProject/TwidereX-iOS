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

// Note:
// use given request token to authenticate user
// now we are supports two styles OAuth
// - PIN-based: for user who use customize consumer key OR custom build with "oob" OAuth endpoint
// - custom: App Store default build OR custom build with our internal OAuth relay server endpoint
final class TwitterAuthenticationController: NeedsDependency {
    
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
        authenticateURL: URL,
        requestTokenExchange: Twitter.API.OAuth.OAuthRequestTokenResponseExchange
    ) {
        self.context = context
        self.coordinator = coordinator
        self.appSecret = appSecret
        
        switch requestTokenExchange {
        // use PIN-based OAuth via WKWebView (when set callback as "oob")
        case .pin(let response):
            let twitterPinBasedAuthenticationViewModel = TwitterPinBasedAuthenticationViewModel(authenticateURL: authenticateURL)
            setupPINAuthenticate(requestTokenResponse: response, appSecret: appSecret, pinCodePublisher: twitterPinBasedAuthenticationViewModel.pinCodePublisher)
            twitterPinBasedAuthenticationViewController = coordinator.present(scene: .twitterPinBasedAuthentication(viewModel: twitterPinBasedAuthenticationViewModel), from: nil, transition: .modal(animated: true, completion: nil))
        // use standard OAuth via system AuthenticationServices
        case .custom(_, let append):
            setupCustomAuthenticate(authenticateURL: authenticateURL, append: append)
        }
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension TwitterAuthenticationController {
    
    // create authenticationSession and setup callback account authenticate & verify publisher
    func setupCustomAuthenticate(
        authenticateURL: URL,
        append: Twitter.API.OAuth.CustomRequestTokenResponseAppend
    ) {
        authenticationSession = ASWebAuthenticationSession(url: authenticateURL, callbackURLScheme: AppCommon.scheme) { [weak self] callback, error in
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

            Task {
                let property = TwitterAuthentication.Property(
                    userID: authentication.userID,
                    screenName: authentication.screenName,
                    consumerKey: authentication.consumerKey,
                    consumerSecret: authentication.consumerSecret,
                    accessToken: authentication.accessToken,
                    accessTokenSecret: authentication.accessTokenSecret
                )
                do {
                    let response = try await TwitterAuthenticationController.verifyAndSaveAuthentication(context: self.context, property: property, appSecret: .default)
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
}

extension TwitterAuthenticationController {

    // setup pin code based account authentication & verify publisher
    func setupPINAuthenticate(
        requestTokenResponse: Twitter.API.OAuth.RequestTokenResponse,
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
                        let accessTokenResponse = try await context.apiService.twitterAccessToken(
                            requestToken: requestTokenResponse.oauthToken,
                            pinCode: pinCode,
                            oauthSecret: oauthSecret
                        )
                        
                        let property = TwitterAuthentication.Property(
                            userID: accessTokenResponse.userID,
                            screenName: accessTokenResponse.screenName,
                            consumerKey: oauthSecret.consumerKey,
                            consumerSecret: oauthSecret.consumerKeySecret,
                            accessToken: accessTokenResponse.oauthToken,
                            accessTokenSecret: accessTokenResponse.oauthTokenSecret
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
                }
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
            twitterAuthenticationProperty = try property.seal(appSecret: appSecret)
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
            twitterUserRequest.predicate = TwitterUser.predicate(idStr: userID)
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
                oldTwitterAuthentication.update(nonce: twitterAuthenticationProperty.nonce ?? "")
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
                    authenticationIndex: authenticationIndex,
                    twitterUser: twitterUser
                )
            }
        }   // end managedObjectContext.perform…

        return response
    }
    
}

extension TwitterAuthenticationController {
    enum AuthenticationError: Error {
        case invalidOAuthCallback(error: Error?)
        case verifyCredentialsFail(error: Error?)
    }
}
