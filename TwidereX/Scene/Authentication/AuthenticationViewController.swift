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
                // TODO: handle error
            } receiveValue: { [weak self] requestToken in
                guard let self = self else { return }
                guard requestToken.oauthCallbackConfirmed else { return }
                self.twitterAuthenticate(requestToken: requestToken)
            }
            .store(in: &disposeBag)

    }
}

extension AuthenticationViewController {
    func twitterAuthenticate(requestToken: Twitter.API.OAuth.RequestToken) {
        authenticationSession = ASWebAuthenticationSession(url: Twitter.API.OAuth.autenticateURL(requestToken: requestToken), callbackURLScheme: "twidere") { [weak self] callback, error in
            guard let self = self else { return }
            os_log("%{public}s[%{public}ld], %{public}s: callback: %s, error: %s", ((#file as NSString).lastPathComponent), #line, #function, callback?.debugDescription ?? "<nil>", error.debugDescription)

            if let error = error {
                // TODO: handle error
                assertionFailure(error.localizedDescription)
                return
            }
            guard let callbackURL = callback, let accessToken = Twitter.API.OAuth.Authentication(callbackURL: callbackURL) else {
                // TODO: handle error
                assertionFailure()
                return
            }
            
            let property = TwitterAuthentication.Property(userID: accessToken.userID, screenName: accessToken.screenName, consumerKey: accessToken.consumerKey, consumerSecret: accessToken.consumerSecret, accessToken: accessToken.oauthToken, accessTokenSecret: accessToken.oauthTokenSecret)
            
            // TODO: check duplicate
            let managedObjectContext = self.context.managedObjectContext
            managedObjectContext.performChanges {
                TwitterAuthentication.insert(into: managedObjectContext, property: property)
            }
            .sink { result in
                switch result {
                case .success:
                    os_log("%{public}s[%{public}ld], %{public}s: insert Authentication for %s, userID: %s", ((#file as NSString).lastPathComponent), #line, #function, property.screenName, property.userID)
                    self.dismiss(animated: true, completion: nil)
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: insert Authentication failed. %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    // TODO: handle error
                }
            }
            .store(in: &self.disposeBag)
            
            os_log("%{public}s[%{public}ld], %{public}s: accessToken: %s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: accessToken))
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
