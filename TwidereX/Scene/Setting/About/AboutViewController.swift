//
//  AboutViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import SafariServices

final class AboutViewController: UIViewController, NeedsDependency {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: AboutViewModel!
    
}

extension AboutViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Settings.About.title
        
        let hostingViewController = UIHostingController(
            rootView: AboutView(viewModel: viewModel).environmentObject(context)
        )
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        viewModel.entryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entry in
                guard let self = self else { return }
                
                switch entry {
                case .github:
                    let url = URL(string: "https://github.com/TwidereProject/TwidereX-iOS")!
                    self.coordinator.present(scene: .safari(url: url.absoluteString), from: nil, transition: .safariPresent(animated: true, completion: nil))
                case .twitter:
                    switch self.context.authenticationService.activeAuthenticationContext {
                    case .twitter:
                        let profileViewModel = RemoteProfileViewModel(
                            context: self.context,
                            authContext: self.viewModel.authContext,
                            profileContext: .twitter(.username("TwidereProject"))
                        )
                        self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
                    case .mastodon:
                        fallthrough
                    case .none:
                        let url = URL(string: "https://twitter.com/twidereproject")!
                        self.coordinator.present(scene: .safari(url: url.absoluteString), from: nil, transition: .safariPresent(animated: true, completion: nil))
                    }
                case .telegram:
                    let url = URL(string: "https://t.me/twidere_x")!
                    UIApplication.shared.open(url)
                case .discord:
                    let url = URL(string: "https://discord.gg/hfzTV6P2AJ")!
                    UIApplication.shared.open(url)
                case .license:
                    let url = URL(string: "https://github.com/TwidereProject/TwidereX-iOS/blob/master/LICENSE")!
                    self.coordinator.present(scene: .safari(url: url.absoluteString), from: nil, transition: .safariPresent(animated: true, completion: nil))
                case .privacyPolicy:
                    let url = URL(string: "https://github.com/TwidereProject/TwidereX-iOS/wiki/Privacy-Policy")!
                    self.coordinator.present(scene: .safari(url: url.absoluteString), from: nil, transition: .safariPresent(animated: true, completion: nil))
                }
            }
            .store(in: &disposeBag)
    }
    
}
