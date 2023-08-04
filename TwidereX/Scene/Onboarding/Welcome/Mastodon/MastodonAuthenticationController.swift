//
//  MastodonAuthenticationController.swift
//  MastodonAuthenticationController
//
//  Created by Cirno MainasuK on 2021-8-13.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import CoreDataStack
import AuthenticationServices
import WebKit
import MastodonSDK

final class MastodonAuthenticationController: NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()
    
    static let callbackScheme = AppCommon.scheme
    static let callbackURL = "\(callbackScheme)://twidere.com/oauth/callback"
    
    // input
    var context: AppContext!
    var coordinator: SceneCoordinator!
    let appSecret: AppSecret
    let authenticationInfo: MastodonAuthenticationInfo
    var authenticationSession: ASWebAuthenticationSession?
    
    // output
    let isAuthenticating = CurrentValueSubject<Bool, Never>(false)
    let error = CurrentValueSubject<Error?, Never>(nil)
    let pinCodePublisher = PassthroughSubject<String, Never>()
    let authenticated = PassthroughSubject<Mastodon.Entity.Account, Never>()

    init(
        context: AppContext,
        coordinator: SceneCoordinator,
        authenticationInfo: MastodonAuthenticationInfo,
        appSecret: AppSecret
    ) {
        self.context = context
        self.coordinator = coordinator
        self.authenticationInfo = authenticationInfo
        self.appSecret = appSecret
        
        authentication()
        
        pinCodePublisher
            .first()
            .sink(receiveValue: { [weak self] code in
                guard let self = self else { return }
                let authenticationInfo = self.authenticationInfo
                Task {
                    self.isAuthenticating.value = true
                    do {
                        try await self.authenticate(info: authenticationInfo, code: code)
                    } catch {
                        self.error.value = error
                    }
                    self.isAuthenticating.value = false
                }
            })
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MastodonAuthenticationController {
    struct MastodonAuthenticationInfo {
        let domain: String
        let clientID: String
        let clientSecret: String
        let authorizeURL: URL
        let redirectURI: String
        
        init?(
            domain: String,
            application: Mastodon.Entity.Application,
            redirectURI: String
        ) {
            self.domain = domain
            guard let clientID = application.clientID,
                  let clientSecret = application.clientSecret else { return nil }
            self.clientID = clientID
            self.clientSecret = clientSecret
            self.authorizeURL = {
                let query = Mastodon.API.OAuth.AuthorizeQuery(clientID: clientID, redirectURI: redirectURI)
                let url = Mastodon.API.OAuth.authorizeURL(domain: domain, query: query)
                return url
            }()
            self.redirectURI = redirectURI
        }
    }
}

extension MastodonAuthenticationController {
    
    static func parseDomain(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }
        
        let urlString = trimmed.hasPrefix("https://") ? trimmed : "https://" + trimmed
        guard let url = URL(string: urlString),
              let host = url.host else {
                  return nil
              }
        let components = host.components(separatedBy: ".")
        guard !components.contains(where: { $0.isEmpty }) else { return nil }
        guard components.count >= 2 else { return nil }
        
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: input host: %s", ((#file as NSString).lastPathComponent), #line, #function, host)
        
        return host
    }
    
}

extension MastodonAuthenticationController {
    private func authentication() {
        authenticationSession = ASWebAuthenticationSession(
            url: authenticationInfo.authorizeURL,
            callbackURLScheme: MastodonAuthenticationController.callbackScheme
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
            
            guard let url = callback,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let codeQueryItem = components.queryItems?.first(where: { $0.name == "code" }),
                  let code = codeQueryItem.value
            else { return }
            
            self.pinCodePublisher.send(code)
        }
    }
    
    private func authenticate(info: MastodonAuthenticationInfo, code: String) async throws {
        let query = Mastodon.API.OAuth.AccessTokenQuery(
            clientID: info.clientID,
            clientSecret: info.clientSecret,
            redirectURI: info.redirectURI,
            code: code,
            grantType: .authorizationCode
        )
        let userAccessTokenResponse = try await context.apiService.mastodonUserAccessToken(
            domain: info.domain,
            query: query
        )
        
        let token = userAccessTokenResponse.value
        let response = try await MastodonAuthenticationController.verifyAndSaveAuthentication(
            context: context,
            info: info,
            userAccessToken: token
        )
        
        let user = response.value
        self.authenticated.send(user)
    }
    
}

extension MastodonAuthenticationController {
    
    static func verifyAndSaveAuthentication(
        context: AppContext,
        info: MastodonAuthenticationInfo,
        userAccessToken: Mastodon.Entity.Token
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Account> {
        let authorization = Mastodon.API.OAuth.Authorization(accessToken: userAccessToken.accessToken)
        let response = try await context.apiService.verifyMastodonCredentials(
            domain: info.domain,
            authorization: authorization
        )
        
        let domain = info.domain
        let userID = response.value.id
        
        let managedObjectContext = context.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let now = Date()
            
            let mastodonUserRequest = MastodonUser.sortedFetchRequest
            mastodonUserRequest.predicate = MastodonUser.predicate(domain: domain, id: userID)
            mastodonUserRequest.fetchLimit = 1
            
            guard let mastodonUser = try? managedObjectContext.fetch(mastodonUserRequest).first else {
                assertionFailure()
                return
            }
            
            let mastodonAuthenticationProperty = MastodonAuthentication.Property(
                domain: domain,
                userID: userID,
                appAccessToken: userAccessToken.accessToken,  // use user token is OK
                userAccessToken: userAccessToken.accessToken,
                clientID: info.clientID,
                clientSecret: info.clientSecret,
                updatedAt: response.networkDate
            )
            
            if let oldMastodonAuthentication = mastodonUser.mastodonAuthentication {
                // update authentication
                oldMastodonAuthentication.update(property: mastodonAuthenticationProperty)
                // update authentication index
                oldMastodonAuthentication.authenticationIndex.update(activeAt: now)
            } else {
                // insert authentication index
                let authenticationIndexProperty = AuthenticationIndex.Property(platform: .mastodon)
                let authenticationIndex = AuthenticationIndex.insert(
                    into: managedObjectContext,
                    property: authenticationIndexProperty
                )
                // insert authentication
                _ = MastodonAuthentication.insert(
                    into: managedObjectContext,
                    property: mastodonAuthenticationProperty,
                    authenticationIndex: authenticationIndex,
                    mastodonUser: mastodonUser
                )
            }
        }   // end managedObjectContext.perform…
        
        return response
    }
    
}
