//
//  ComposeTweetViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-21.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import AlamofireImage

final class ComposeTweetViewController: UIViewController, NeedsDependency {
    
    static let avatarImageViewSize = CGSize(width: 44, height: 44)
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ComposeTweetViewModel!
    
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let lockImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .center
        imageView.image = Asset.ObjectTools.lock.image.withRenderingMode(.alwaysTemplate)
        imageView.backgroundColor = .black
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = TimelinePostView.lockImageViewSize.width * 0.5
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.white.cgColor
        return imageView
    }()
    
    let composeTextView: UITextView = {
        let textView = UITextView()
        textView.font = .preferredFont(forTextStyle: .body)
        return textView
    }()
    
    let cycleCounterView = CycleCounterView()
    let tweetToolbarView = TweetToolbarView()
    var tweetToolbarViewBottomLayoutConstraint: NSLayoutConstraint!
}

extension ComposeTweetViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Asset.Editing.xmark.image.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(ComposeTweetViewController.closeBarButtonItemPressed(_:)))
        navigationItem.leftBarButtonItem?.tintColor = .label
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.ObjectTools.paperplane.image.withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(ComposeTweetViewController.sendBarButtonItemPressed(_:)))
        navigationItem.leftBarButtonItem?.tintColor = Asset.Colors.hightLight.color
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        
        cycleCounterView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cycleCounterView)
        NSLayoutConstraint.activate([
            cycleCounterView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 12),
            cycleCounterView.widthAnchor.constraint(equalToConstant: 18).priority(.defaultHigh),
            cycleCounterView.heightAnchor.constraint(equalToConstant: 18).priority(.defaultHigh),
        ])
        
        tweetToolbarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tweetToolbarView)
        tweetToolbarViewBottomLayoutConstraint = view.bottomAnchor.constraint(equalTo: tweetToolbarView.bottomAnchor)
        NSLayoutConstraint.activate([
            tweetToolbarView.topAnchor.constraint(equalTo: cycleCounterView.bottomAnchor, constant: 16),
            tweetToolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tweetToolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tweetToolbarViewBottomLayoutConstraint,
            tweetToolbarView.heightAnchor.constraint(equalToConstant: 48),
        ])
        
        // user avatar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            avatarImageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: ComposeTweetViewController.avatarImageViewSize.width).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: ComposeTweetViewController.avatarImageViewSize.height).priority(.required - 1),
        ])
        lockImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.addSubview(lockImageView)
        NSLayoutConstraint.activate([
            lockImageView.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            lockImageView.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            lockImageView.widthAnchor.constraint(equalToConstant: 16),
            lockImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        composeTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(composeTextView)
        NSLayoutConstraint.activate([
            composeTextView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            composeTextView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 20),
            composeTextView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            composeTextView.heightAnchor.constraint(equalTo: view.heightAnchor),
        ])
        
        // respond scrollView overlap change
        view.layoutIfNeeded()
        Publishers.CombineLatest3(
            KeyboardResponderService.shared.isShow.eraseToAnyPublisher(),
            KeyboardResponderService.shared.state.eraseToAnyPublisher(),
            KeyboardResponderService.shared.endFrame.eraseToAnyPublisher()
        )
        .sink(receiveValue: { [weak self] isShow, state, endFrame in
            guard let self = self else { return }
            guard isShow, state == .dock else {
                self.composeTextView.contentInset.bottom = 0.0
                self.composeTextView.verticalScrollIndicatorInsets.bottom = 0.0
                UIView.animate(withDuration: 0.3) {
                    self.tweetToolbarViewBottomLayoutConstraint.constant = 0.0
                    self.view.layoutIfNeeded()
                }
                return
            }
            
            // isShow AND dock state
            let scrollViewFrame = self.view.convert(self.scrollView.frame, to: nil)
            let padding = scrollViewFrame.maxY - endFrame.minY
            guard padding > 0 else {
                self.composeTextView.contentInset.bottom = 0.0
                self.composeTextView.verticalScrollIndicatorInsets.bottom = 0.0
                UIView.animate(withDuration: 0.3) {
                    self.tweetToolbarViewBottomLayoutConstraint.constant = 0.0
                    self.view.layoutIfNeeded()
                }
                return
            }
            
            self.scrollView.contentInset.bottom = padding + self.tweetToolbarView.frame.height + self.view.safeAreaInsets.bottom
            self.scrollView.verticalScrollIndicatorInsets.bottom = padding + self.tweetToolbarView.frame.height + self.view.safeAreaInsets.bottom
            UIView.animate(withDuration: 0.3) {
                self.tweetToolbarViewBottomLayoutConstraint.constant = padding
                self.view.layoutIfNeeded()
            }
        })
        .store(in: &disposeBag)
        
        // set avatar
        viewModel.avatarImageURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                guard let self = self else { return }
                let placeholderImage = UIImage
                    .placeholder(size: TimelinePostView.avatarImageViewSize, color: .systemFill)
                    .af.imageRoundedIntoCircle()
                guard let url = url else {
                    self.avatarImageView.image = UIImage.placeholder(color: .systemFill)
                    return
                }
                let filter = ScaledToSizeCircleFilter(size: ComposeTweetViewController.avatarImageViewSize)
                self.avatarImageView.af.setImage(
                    withURL: url,
                    placeholderImage: placeholderImage,
                    filter: filter,
                    imageTransition: .crossDissolve(0.2)
                )
            }
            .store(in: &disposeBag)
        viewModel.isAvatarLockHidden.receive(on: DispatchQueue.main).assign(to: \.isHidden, on: lockImageView).store(in: &disposeBag)
        
        // set cycle counter
        viewModel.twitterTextparseResults
            .receive(on: DispatchQueue.main)
            .sink { [weak self] parseResult in
                guard let self = self else { return }
                let progress = CGFloat(parseResult.weightedLength) / CGFloat(self.viewModel.twitterTextParser.configuration.maxWeightedTweetLength)
                UIView.animate(withDuration: 0.1) {
                    self.cycleCounterView.progress.value = progress
                }
            }
            .store(in: &disposeBag)
        
        // bind viewModel
        context.authenticationService.currentActiveTwitterAutentication
            .assign(to: \.value, on: viewModel.currentTwitterAuthentication)
            .store(in: &disposeBag)
        context.authenticationService.currentTwitterUser
            .sink { [weak self] user in
                guard let self = self else { return }
                self.viewModel.avatarImageURL.value = user?.avatarImageURL(size: .reasonablySmall)
                self.viewModel.isAvatarLockHidden.value = user.flatMap { !$0.protected } ?? true
            }
            .store(in: &disposeBag)
        
        composeTextView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        composeTextView.becomeFirstResponder()
    }
    
}

extension ComposeTweetViewController {
    
    @objc private func closeBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendBarButtonItemPressed(_ sender: UIBarButtonItem) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
    }
    
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension ComposeTweetViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            return .fullScreen
        default:
            return .formSheet
        }
    }
    
}

// MARK: - UITextViewDelegate
extension ComposeTweetViewController: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        guard textView === composeTextView else { return }
        viewModel.composeContent.value = composeTextView.text ?? ""
    }
}
