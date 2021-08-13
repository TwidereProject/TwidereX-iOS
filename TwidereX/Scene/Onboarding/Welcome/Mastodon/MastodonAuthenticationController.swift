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
import AppShared
import MastodonSDK

final class MastodonAuthenticationController: NeedsDependency {
    
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
    // let authenticated = PassthroughSubject<Twitter.Entity.User, Never>()
    
    init(
        context: AppContext,
        coordinator: SceneCoordinator,
        appSecret: AppSecret
        // requestTokenExchange: Twitter.API.OAuth.OAuthRequestTokenResponseExchange
    ) {
        self.context = context
        self.coordinator = coordinator
        self.appSecret = appSecret
        
    }
}
