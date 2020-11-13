//
//  AuthenticationViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import os
import UIKit
import AuthenticationServices
import Combine
import TwitterAPI
import CoreDataStack

final class AuthenticationViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    var disposeBag = Set<AnyCancellable>()
    
    let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.Logo.twidere.image
        return imageView
    }()
    
    let logoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24)
        label.text = "Twidere X"
        label.textColor = .secondaryLabel
        return label
    }()
    
    let signInButton: UIButton = {
        let button = UIButton()
        button.setInsets(forContentPadding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16), imageTitlePadding: 0)
        button.setTitle("Sign in with Twitter", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setBackgroundImage(.placeholder(color: Asset.Colors.hightLight.color), for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 48 * 0.5
        return button
    }()
    
    let signInActivityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.startAnimating()
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.color = .white
        return activityIndicatorView
    }()
    
    var isSigning = CurrentValueSubject<Bool, Never>(false)
    private var twitterAuthenticationController: TwitterAuthenticationController?
    
}

extension AuthenticationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Authentication"
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        let quarterHeightPadding = UIView()
        quarterHeightPadding.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(quarterHeightPadding)
        NSLayoutConstraint.activate([
            quarterHeightPadding.topAnchor.constraint(equalTo: view.topAnchor),
            quarterHeightPadding.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            quarterHeightPadding.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            quarterHeightPadding.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25),
        ])
        quarterHeightPadding.isHidden = true
        
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: quarterHeightPadding.bottomAnchor),
        ])
        
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoLabel)
        NSLayoutConstraint.activate([
            logoLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor),
            logoLabel.centerXAnchor.constraint(equalTo: logoImageView.centerXAnchor),
        ])
        
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signInButton)
        NSLayoutConstraint.activate([
            signInButton.centerXAnchor.constraint(equalTo: logoImageView.centerXAnchor),
            view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 80),
            signInButton.heightAnchor.constraint(equalToConstant: 48).priority(.defaultHigh),
        ])
        signInButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        signInActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signInActivityIndicatorView)
        NSLayoutConstraint.activate([
            signInActivityIndicatorView.centerXAnchor.constraint(equalTo: signInButton.centerXAnchor),
            signInActivityIndicatorView.centerYAnchor.constraint(equalTo: signInButton.centerYAnchor),
        ])
        
        isSigning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRequestToken in
                guard let self = self else { return }
                self.signInButton.setTitleColor(isRequestToken ? .clear : .white, for: .normal)
                self.signInButton.isUserInteractionEnabled = !isRequestToken
                isRequestToken ? self.signInActivityIndicatorView.startAnimating() : self.signInActivityIndicatorView.stopAnimating()
            }
            .store(in: &disposeBag)
        
        signInButton.addTarget(self, action: #selector(AuthenticationViewController.signInWithTwitterButtonPressed(_:)), for: .touchUpInside)
    }
}

extension AuthenticationViewController {
    @objc private func signInWithTwitterButtonPressed(_ sender: UIButton) {
        context.apiService.twitterRequestToken()
            .handleEvents(receiveSubscription: { [weak self] _ in
                sender.isEnabled = false
                self?.isSigning.value = true
            }, receiveCompletion: { completion in
                sender.isEnabled = true
            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    os_log("%{public}s[%{public}ld], %{public}s: request token error: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)

                    let alertController = UIAlertController.standardAlert(of: error)
                    self.present(alertController, animated: true) { [weak self] in
                        self?.isSigning.value = false
                    }
                case .finished:
                    break
                }
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
        
        let authenticateURL = Twitter.API.OAuth.autenticateURL(requestToken: requestToken)
        
        twitterAuthenticationController = TwitterAuthenticationController(
            context: context,
            authenticateURL: authenticateURL,
            requestTokenExchange: requestTokenExchange
        )
        
        twitterAuthenticationController?.isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isAuthenticating in
                guard let self = self else { return }
                self.isSigning.value = isAuthenticating
            })
            .store(in: &disposeBag)
        
        twitterAuthenticationController?.error
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] error in
                guard let self = self else { return }
                guard let error = error else { return }
                let alertController = UIAlertController.standardAlert(of: error)
                self.present(alertController, animated: true)
            })
            .store(in: &disposeBag)
        
        twitterAuthenticationController?.authenticated
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .store(in: &disposeBag)
        
        twitterAuthenticationController?.authenticationSession?.prefersEphemeralWebBrowserSession = true
        twitterAuthenticationController?.authenticationSession?.presentationContextProvider = self
        twitterAuthenticationController?.authenticationSession?.start()
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


