//
//  AuthenticationViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import os
import UIKit
import Combine
import AuthenticationServices
import TwitterAPI
import CoreDataStack

final class AuthenticationViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    
    let signInButton: UIButton = {
        let button = UIButton()
        button.setTitle("Sign in with Twitter", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitleColor(.secondaryLabel, for: .disabled)
        return button
    }()
    
    private var authenticationSession: ASWebAuthenticationSession?
}

extension AuthenticationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Authentication"
        view.backgroundColor = .systemBackground
        
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signInButton)
        NSLayoutConstraint.activate([
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        signInButton.addTarget(self, action: #selector(AuthenticationViewController.signInWithTwitterButtonPressed(_:)), for: .touchUpInside)
    }
}

extension AuthenticationViewController {
    @objc private func signInWithTwitterButtonPressed(_ sender: UIButton) {
        context.apiService.twitterRequestToken()
            .handleEvents(receiveSubscription: { _ in
                sender.isEnabled = false
            }, receiveCompletion: { completion in
                sender.isEnabled = true
            })
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: request token error: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                case .finished:
                    break
                }
                // TODO: handle error
            } receiveValue: { [weak self] requestTokenExchange in
                guard let self = self else { return }
                self.twitterAuthenticate(requestTokenExchange: requestTokenExchange)
            }
            .store(in: &disposeBag)
    }
}

extension AuthenticationViewController {
    func twitterAuthenticate(requestTokenExchange: Twitter.API.OAuth.OAuthRequestTokenExchange) {
        let requestToken: String = {
            switch requestTokenExchange {
            case .requestTokenResponse(let response):           return response.oauthToken
            case .customRequestTokenResponse(_, let append):    return append.requestToken
            }
        }()
        
        authenticationSession = ASWebAuthenticationSession(url: Twitter.API.OAuth.autenticateURL(requestToken: requestToken), callbackURLScheme: "twidere") { [weak self] callback, error in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: callback: %s, error: %s", ((#file as NSString).lastPathComponent), #line, #function, callback?.debugDescription ?? "<nil>", error.debugDescription)

            if let error = error {
                if let error = error as? ASWebAuthenticationSessionError {
                    if error.errorCode == ASWebAuthenticationSessionError.canceledLogin.rawValue { return }
                }
                
                // TODO: handle error
                assertionFailure(error.localizedDescription)
                return
            }
            
            let authenticationProperty: TwitterAuthentication.Property
            switch requestTokenExchange {
            case .requestTokenResponse(let response):
                fatalError("not implement yet")
            case .customRequestTokenResponse(_, let append):
                guard let callbackURL = callback,
                      let oauthCallbackResponse = Twitter.API.OAuth.OAuthCallbackResponse(callbackURL: callbackURL),
                      let authentication = try? oauthCallbackResponse.authentication(privateKey: append.clientExchangePrivateKey) else {
                    // handle error
                    return
                }
                os_log("%{public}s[%{public}ld], %{public}s: authentication: %s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: authentication))
                
                let rawProperty = TwitterAuthentication.Property(userID: authentication.userID, screenName: authentication.screenName, consumerKey: authentication.consumerKey, consumerSecret: authentication.consumerSecret, accessToken: authentication.accessToken, accessTokenSecret: authentication.accessTokenSecret)
                do {
                    authenticationProperty = try rawProperty.seal(appSecret: AppSecret.shared)
                } catch {
                    // handle error
                    return
                }
            }
            
            // save authentication
            let managedObjectContext = self.context.managedObjectContext
            managedObjectContext.performChanges {
                let twitterAuthentication = TwitterAuthentication.insert(into: managedObjectContext, property: authenticationProperty)
            }
            .sink { result in
                switch result {
                case .success:
                    os_log("%{public}s[%{public}ld], %{public}s: insert Authentication for %s, userID: %s", ((#file as NSString).lastPathComponent), #line, #function, authenticationProperty.screenName, authenticationProperty.userID)
                    self.dismiss(animated: true, completion: nil)
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: insert Authentication failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    // TODO: handle error
                }
            }
            .store(in: &self.disposeBag)
        }
        authenticationSession?.presentationContextProvider = self
        authenticationSession?.start()
    }

}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension AuthenticationViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}

extension AuthenticationViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
}


