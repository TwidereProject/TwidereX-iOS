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

    var viewModel: AuthenticationViewModel!
    var disposeBag = Set<AnyCancellable>()
    
    static let logoImageSize = CGSize(width: 48, height: 48)
    static let signInButtonHeight: CGFloat = 48.0
    
    private(set) lazy var closeBarButtonItem = UIBarButtonItem.closeBarButtonItem(target: self, action: #selector(AuthenticationViewController.closeBarButtonItemPressed(_:)))
    
    let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.Logo.twidere.image.af.imageAspectScaled(toFit: AuthenticationViewController.logoImageSize)
        return imageView
    }()
    
    let logoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .medium)
        label.textColor = UIColor.label.withAlphaComponent(0.68)
        label.text = "Twidere X"
        return label
    }()
    
    let welcomeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = Asset.Colors.hightLight.color
        label.text = L10n.Scene.SignIn.helloSignInToGetStarted
        label.numberOfLines = 0
        return label
    }()
    
    let twitterAuthenticateButton: AuthenticateButton = {
        let button = AuthenticateButton()
        button.style = .trailingOption
        button.backgroundColor = .white     // make same appearance when set alpha under the Dark Mode
        button.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.twitterBlue.color), for: .normal)
        button.setBackgroundImage(UIImage.placeholder(color: Asset.Colors.twitterBlue.color.withAlphaComponent(0.8)), for: .highlighted)
        button.setLeadingImage(Asset.Logo.twitterMedium.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTrailingBackgroundImage(UIImage.placeholder(color: UIColor.white.withAlphaComponent(0.2)), for: .highlighted)
        button.setTrailingImage(Asset.Editing.ellipsis.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle("Sign in with Twitter", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.layer.masksToBounds = true
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = 10
        return button
    }()
    
    let signInActivityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.startAnimating()
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.color = .white
        return activityIndicatorView
    }()
    
    let isSigning = CurrentValueSubject<Bool, Never>(false)
    private var twitterAuthenticationController: TwitterAuthenticationController?
    
}

extension AuthenticationViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "" // L10n.Scene.Authentication.title
        view.backgroundColor = .systemBackground
        if !viewModel.isCloseBarButtonItemHidden {
            navigationItem.leftBarButtonItem = closeBarButtonItem
        }
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = navigationBarAppearance
        navigationItem.scrollEdgeAppearance = navigationBarAppearance
        navigationItem.compactAppearance = navigationBarAppearance
        
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
            logoImageView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 8),
            logoImageView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
        ])
        
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoLabel)
        NSLayoutConstraint.activate([
            logoLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 24),
            logoLabel.centerYAnchor.constraint(equalTo: logoImageView.centerYAnchor),
        ])
        
        let welcomLabelTopPadding = UIView()
        welcomLabelTopPadding.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(welcomLabelTopPadding)
        NSLayoutConstraint.activate([
            welcomLabelTopPadding.topAnchor.constraint(equalTo: logoImageView.bottomAnchor),
            welcomLabelTopPadding.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            welcomLabelTopPadding.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(welcomeLabel)
        NSLayoutConstraint.activate([
            welcomeLabel.topAnchor.constraint(equalTo: welcomLabelTopPadding.bottomAnchor),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            welcomeLabel.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
        ])
        
        let welcomLabelBottomPadding = UIView()
        welcomLabelBottomPadding.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(welcomLabelBottomPadding)
        NSLayoutConstraint.activate([
            welcomLabelBottomPadding.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor),
            welcomLabelBottomPadding.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            welcomLabelBottomPadding.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            welcomLabelBottomPadding.heightAnchor.constraint(equalTo: welcomLabelTopPadding.heightAnchor, multiplier: 3)
        ])
        
        twitterAuthenticateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(twitterAuthenticateButton)
        NSLayoutConstraint.activate([
            twitterAuthenticateButton.topAnchor.constraint(equalTo: welcomLabelBottomPadding.bottomAnchor),
            twitterAuthenticateButton.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            twitterAuthenticateButton.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            view.bottomAnchor.constraint(greaterThanOrEqualTo: twitterAuthenticateButton.bottomAnchor, constant: 44),
            view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: twitterAuthenticateButton.bottomAnchor).priority(.defaultLow),
            twitterAuthenticateButton.heightAnchor.constraint(equalToConstant: 48).priority(.defaultHigh),
        ])
        twitterAuthenticateButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        signInActivityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signInActivityIndicatorView)
        NSLayoutConstraint.activate([
            signInActivityIndicatorView.centerXAnchor.constraint(equalTo: twitterAuthenticateButton.centerXAnchor),
            signInActivityIndicatorView.centerYAnchor.constraint(equalTo: twitterAuthenticateButton.centerYAnchor),
        ])
        
        isSigning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSigning in
                guard let self = self else { return }
                self.twitterAuthenticateButton.setTitleColor(isSigning ? .clear : .white, for: .normal)
                self.twitterAuthenticateButton.isUserInteractionEnabled = !isSigning
                self.twitterAuthenticateButton.isEnabled = !isSigning
                isSigning ? self.signInActivityIndicatorView.startAnimating() : self.signInActivityIndicatorView.stopAnimating()
            }
            .store(in: &disposeBag)
        
        twitterAuthenticateButton.addTarget(self, action: #selector(AuthenticationViewController.twitterAuthenticatePrimaryActionHandler(_:)), for: AuthenticateButton.primaryAction)
        twitterAuthenticateButton.addTarget(self, action: #selector(AuthenticationViewController.twitterAuthenticateSecondaryActionHandler(_:)), for: AuthenticateButton.secondaryAction)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Update if Dark Mode change
        logoImageView.image = Asset.Logo.twidere.image.af.imageAspectScaled(toFit: AuthenticationViewController.logoImageSize)
        
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = .systemBackground
        }
    }
    
}

extension AuthenticationViewController {
    
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func twitterAuthenticatePrimaryActionHandler(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        context.apiService.twitterRequestToken()
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.isSigning.value = true
            }, receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: request token fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                case .finished:
                    break
                }
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
    
    @objc private func twitterAuthenticateSecondaryActionHandler(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let twitterAuthenticationOptionViewModel = TwitterAuthenticationOptionViewModel(context: context)
        coordinator.present(scene: .twitterAuthenticationOption(viewModel: twitterAuthenticationOptionViewModel), from: self, transition: .modal(animated: true, completion: nil))
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
            coordinator: coordinator,
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
            .sink(receiveValue: { [weak self] _ in
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


#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct AuthenticationViewControllerRepresentable: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = UINavigationController
    
    func makeUIViewController(context: Context) -> UINavigationController {
        return UINavigationController(rootViewController: AuthenticationViewController())
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        
    }
    
}

@available(iOS 13.0, *)
struct AuthenticationViewController_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            AuthenticationViewControllerRepresentable()
            AuthenticationViewControllerRepresentable()
                .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
            AuthenticationViewControllerRepresentable()
                .previewDevice(PreviewDevice(rawValue: "iPad mini 4"))
            AuthenticationViewControllerRepresentable()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (3rd generation)"))
        }
    }
    
}

#endif

