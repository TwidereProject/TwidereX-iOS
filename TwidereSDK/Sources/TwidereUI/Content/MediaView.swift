//
//  MediaView.swift
//  MediaView
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import AVKit
import UIKit
import SwiftUI
import Combine
import TwidereAsset
import Kingfisher

public struct MediaView: View {
    
    @ObservedObject var viewModel: ViewModel
    
    public init(viewModel: MediaView.ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        KFImage(viewModel.previewURL)
            .onSuccess { result in
                viewModel.thumbnail = result.image
            }
            .cancelOnDisappear(true)
            .resizable()
            .placeholder { progress in
                Image(uiImage: Asset.Logo.mediaPlaceholder.image.withRenderingMode(.alwaysTemplate))
            }
            .overlay(alignment: .bottomTrailing) {
                if let durationText = viewModel.durationText {
                    Label {
                        Text(durationText)
                    } icon: {
                        Image(systemName: "play.fill")
                    }
                    .font(.footnote)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(.regularMaterial)
                    .cornerRadius(4)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 11))
                }
            }

//        Color.clear
//            .overlay {
//                KFImage(viewModel.previewURL)
//                    .cancelOnDisappear(true)
//                    .resizable()
//                    .placeholder { progress in
//
//                    }
//            }
//            .aspectRatio(viewModel.aspectRatio, contentMode: .fill)
//            .placeholder {
//                ZStack {
//                    let gradient = Gradient(stops: [
//                        .init(color: Color(uiColor: UIColor(hex: 0x50A85E)), location: 0.0),
//                        .init(color: Color(uiColor: UIColor(hex: 0x567CA6)), location: 0.3490),
//                        .init(color: Color(uiColor: UIColor(hex: 0x765BAE)), location: 0.7031),
//                        .init(color: Color(uiColor: UIColor(hex: 0xAB5886)), location: 1.0),
//                    ])
//                    LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
//                    Image(uiImage: Asset.Image.TimeLine.placeholder.image.withRenderingMode(.alwaysTemplate))
//                }
//            }
//            .sizeFitContainer(shape: Rectangle(), aspectRatio: viewModel._asepctRatio)
//            .accessibilityLabel(viewModel.altText ?? "")
    }
    
}

struct MediaView_Previews: PreviewProvider {
    
    static let viewModels = {
        let models = [
            MediaView.ViewModel(
                mediaKind: .photo,
                aspectRatio: CGSize(width: 2048, height: 1186),
                altText: nil,
                previewURL: URL(string: "https://www.nasa.gov/sites/default/files/thumbnails/image/web_first_images_release.png"),
                assetURL: URL(string: "https://www.nasa.gov/sites/default/files/thumbnails/image/web_first_images_release.png"),
                downloadURL: URL(string: "https://www.nasa.gov/sites/default/files/thumbnails/image/web_first_images_release.png"),
                durationMS: nil
            ),
            MediaView.ViewModel(
                mediaKind: .video,
                aspectRatio: CGSize(width: 1200, height: 675),
                altText: nil,
                previewURL: URL(string: "https://pbs.twimg.com/ext_tw_video_thumb/1630058212258115584/pu/img/slS0fYBeGKp8LXzC.jpg"),
                assetURL: URL(string: "https://pbs.twimg.com/ext_tw_video_thumb/1630058212258115584/pu/img/slS0fYBeGKp8LXzC.jpg"),
                downloadURL: URL(string: "https://video.twimg.com/ext_tw_video/1630058212258115584/pu/vid/1280x720/V-Jq9fMqwxTbZdxD.mp4?tag=12"),
                durationMS: 27375
            ),
        ]
        return models
    }()
    
    static var previews: some View {
        Group {
            ForEach(viewModels, id: \.self) { viewModel in
                MediaView(viewModel: viewModel)
                .frame(width: 300, height: 168)
                .previewLayout(.fixed(width: 300, height: 168))
                .previewDisplayName(String(describing: viewModel.mediaKind))
            }
        }
    }
}

//public final class MediaView: UIView {
//
//    var disposeBag = Set<AnyCancellable>()
//
//    public static let cornerRadius: CGFloat = 8
//    public static let durationFormatter: DateComponentsFormatter = {
//        let formatter = DateComponentsFormatter()
//        formatter.zeroFormattingBehavior = .pad
//        formatter.allowedUnits = [.minute, .second]
//        return formatter
//    }()
//    public static let borderColor: UIColor = UIColor.label.withAlphaComponent(0.05)
//    public static let borderWidth: CGFloat = 1
//
//    public let container = TouchBlockingView()
//
//    public private(set) var configuration: Configuration?
//
//    private(set) lazy var imageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.layer.masksToBounds = true
//        imageView.layer.cornerCurve = .continuous
//        imageView.layer.cornerRadius = MediaView.cornerRadius
//        imageView.layer.borderColor = MediaView.borderColor.cgColor
//        imageView.layer.borderWidth = MediaView.borderWidth
//        imageView.isUserInteractionEnabled = false
//        return imageView
//    }()
//
//    private(set) lazy var playerViewController: AVPlayerViewController = {
//        let playerViewController = AVPlayerViewController()
//        playerViewController.view.layer.masksToBounds = true
//        playerViewController.view.layer.cornerCurve = .continuous
//        playerViewController.view.layer.cornerRadius = MediaView.cornerRadius
//        playerViewController.view.layer.borderColor = MediaView.borderColor.cgColor
//        playerViewController.view.layer.borderWidth = MediaView.borderWidth
//        playerViewController.view.isUserInteractionEnabled = false
//        return playerViewController
//    }()
//    private var playerLooper: AVPlayerLooper?
//
//    private(set) lazy var indicatorBlurEffectView: UIVisualEffectView = {
//        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
//        effectView.layer.masksToBounds = true
//        effectView.layer.cornerCurve = .continuous
//        effectView.layer.cornerRadius = 4
//        return effectView
//    }()
//    private(set) lazy var indicatorVibrancyEffectView = UIVisualEffectView(
//        effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .systemUltraThinMaterial))
//    )
//    private(set) lazy var playerIndicatorLabel: UILabel = {
//        let label = UILabel()
//        label.font = .preferredFont(forTextStyle: .caption1)
//        label.textColor = .secondaryLabel
//        return label
//    }()
//
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//        _init()
//    }
//
//    public required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        _init()
//    }
//
//}
//
//extension MediaView {
//
//    @MainActor
//    public func thumbnail() async -> UIImage? {
//        return imageView.image
//    }
//
//    public func thumbnail() -> UIImage? {
//        return imageView.image
//    }
//
//}
//
//extension MediaView {
//    private func _init() {
//        // lazy load content later
//
//        imageView.isAccessibilityElement = true
//    }
//
//    public func setup(configuration: Configuration) {
//        self.configuration = configuration
//
//        setupContainerViewHierarchy()
//
//        switch configuration {
//        case .image(let info):
//            configure(image: info, containerView: container)
//        case .gif(let info):
//            configure(gif: info)
//        case .video(let info):
//            configure(video: info)
//        }
//    }
//
//    private func configure(
//        image info: Configuration.ImageInfo,
//        containerView: UIView
//    ) {
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        containerView.addSubview(imageView)
//        NSLayoutConstraint.activate([
//            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
//            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
//        ])
//
//        let placeholder = Asset.Logo.mediaPlaceholder.image
//        imageView.contentMode = .center
//        imageView.backgroundColor = .systemGray6
//
//        guard let urlString = info.assetURL,
//              let url = URL(string: urlString) else {
//                  imageView.image = placeholder
//                  return
//              }
//
//        imageView.af.setImage(
//            withURL: url,
//            placeholderImage: placeholder,
//            completion: { [weak imageView] response in
//                assert(Thread.isMainThread)
//                switch response.result {
//                case .success:
//                    imageView?.contentMode = .scaleAspectFill
//                case .failure:
//                    break
//                }
//            })
//    }
//
//    private func configure(gif info: Configuration.VideoInfo) {
//        // use view controller as View here
//        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
//        container.addSubview(playerViewController.view)
//        NSLayoutConstraint.activate([
//            playerViewController.view.topAnchor.constraint(equalTo: container.topAnchor),
//            playerViewController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
//            playerViewController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
//            playerViewController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
//        ])
//
//        assert(playerViewController.contentOverlayView != nil)
//        if let contentOverlayView = playerViewController.contentOverlayView {
//            let imageInfo = Configuration.ImageInfo(
//                aspectRadio: info.aspectRadio,
//                assetURL: info.previewURL,
//                downloadURL: info.previewURL
//            )
//            configure(image: imageInfo, containerView: contentOverlayView)
//
//            indicatorBlurEffectView.translatesAutoresizingMaskIntoConstraints = false
//            contentOverlayView.addSubview(indicatorBlurEffectView)
//            NSLayoutConstraint.activate([
//                contentOverlayView.trailingAnchor.constraint(equalTo: indicatorBlurEffectView.trailingAnchor, constant: 11),
//                contentOverlayView.bottomAnchor.constraint(equalTo: indicatorBlurEffectView.bottomAnchor, constant: 8),
//            ])
//            setupIndicatorViewHierarchy()
//        }
//        playerIndicatorLabel.attributedText = NSAttributedString(AttributedString("GIF"))
//
//        guard let player = setupGIFPlayer(info: info) else {
//            // assertionFailure()
//            return
//        }
//        setupPlayerLooper(player: player)
//        playerViewController.player = player
//        playerViewController.showsPlaybackControls = false
//
//        playerViewController.publisher(for: \.isReadyForDisplay)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] isReadyForDisplay in
//                guard let self = self else { return }
//                self.imageView.isHidden = isReadyForDisplay
//            }
//            .store(in: &disposeBag)
//
//        // auto play for GIF
//        player.play()
//    }
//
//    private func configure(video info: Configuration.VideoInfo) {
//        let imageInfo = Configuration.ImageInfo(
//            aspectRadio: info.aspectRadio,
//            assetURL: info.previewURL,
//            downloadURL: info.previewURL
//        )
//        configure(image: imageInfo, containerView: container)
//
//        indicatorBlurEffectView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.addSubview(indicatorBlurEffectView)
//        NSLayoutConstraint.activate([
//            imageView.trailingAnchor.constraint(equalTo: indicatorBlurEffectView.trailingAnchor, constant: 11),
//            imageView.bottomAnchor.constraint(equalTo: indicatorBlurEffectView.bottomAnchor, constant: 8),
//        ])
//        setupIndicatorViewHierarchy()
//
//        playerIndicatorLabel.attributedText = {
//            let imageAttachment = NSTextAttachment(image: UIImage(systemName: "play.fill")!)
//            let imageAttributedString = AttributedString(NSAttributedString(attachment: imageAttachment))
//            let duration: String = {
//                guard let durationMS = info.durationMS else { return "" }
//                let timeInterval = TimeInterval(durationMS / 1000)
//                guard timeInterval > 0 else { return "" }
//                guard let text = MediaView.durationFormatter.string(from: timeInterval) else { return "" }
//                return " \(text)"
//            }()
//            let textAttributedString = AttributedString("\(duration)")
//            var attributedString = imageAttributedString + textAttributedString
//            attributedString.foregroundColor = .secondaryLabel
//            return NSAttributedString(attributedString)
//        }()
//
//    }
//
//    public func prepareForReuse() {
//        // reset appearance
//        alpha = 1
//
//        // reset image
//        imageView.removeFromSuperview()
//        imageView.removeConstraints(imageView.constraints)
//        imageView.af.cancelImageRequest()
//        imageView.image = nil
//        imageView.isHidden = false
//
//        // reset player
//        playerViewController.view.removeFromSuperview()
//        playerViewController.contentOverlayView.flatMap { view in
//            view.removeConstraints(view.constraints)
//        }
//        playerViewController.player?.pause()
//        playerViewController.player = nil
//        playerLooper = nil
//
//        // reset indicator
//        indicatorBlurEffectView.removeFromSuperview()
//
//        // reset container
//        container.removeFromSuperview()
//        container.removeConstraints(container.constraints)
//
//        // reset configuration
//        configuration = nil
//
//        disposeBag.removeAll()
//    }
//}
//
//extension MediaView {
//    private func setupGIFPlayer(info: Configuration.VideoInfo) -> AVPlayer? {
//        guard let urlString = info.assetURL,
//              let url = URL(string: urlString)
//        else { return nil }
//        let playerItem = AVPlayerItem(url: url)
//        let player = AVQueuePlayer(playerItem: playerItem)
//        player.isMuted = true
//        return player
//    }
//
//    private func setupPlayerLooper(player: AVPlayer) {
//        guard let queuePlayer = player as? AVQueuePlayer else { return }
//        guard let templateItem = queuePlayer.items().first else { return }
//        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: templateItem)
//    }
//
//    private func setupContainerViewHierarchy() {
//        guard container.superview == nil else { return }
//        container.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(container)
//        NSLayoutConstraint.activate([
//            container.topAnchor.constraint(equalTo: topAnchor),
//            container.leadingAnchor.constraint(equalTo: leadingAnchor),
//            container.trailingAnchor.constraint(equalTo: trailingAnchor),
//            container.bottomAnchor.constraint(equalTo: bottomAnchor),
//        ])
//    }
//
//    private func setupIndicatorViewHierarchy() {
//        let blurEffectView = indicatorBlurEffectView
//        let vibrancyEffectView = indicatorVibrancyEffectView
//
//        if vibrancyEffectView.superview == nil {
//            vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false
//            blurEffectView.contentView.addSubview(vibrancyEffectView)
//            NSLayoutConstraint.activate([
//                vibrancyEffectView.topAnchor.constraint(equalTo: blurEffectView.contentView.topAnchor),
//                vibrancyEffectView.leadingAnchor.constraint(equalTo: blurEffectView.contentView.leadingAnchor),
//                vibrancyEffectView.trailingAnchor.constraint(equalTo: blurEffectView.contentView.trailingAnchor),
//                vibrancyEffectView.bottomAnchor.constraint(equalTo: blurEffectView.contentView.bottomAnchor),
//            ])
//        }
//
//        if playerIndicatorLabel.superview == nil {
//            playerIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
//            vibrancyEffectView.contentView.addSubview(playerIndicatorLabel)
//            NSLayoutConstraint.activate([
//                playerIndicatorLabel.topAnchor.constraint(equalTo: vibrancyEffectView.contentView.topAnchor),
//                playerIndicatorLabel.leadingAnchor.constraint(equalTo: vibrancyEffectView.contentView.leadingAnchor, constant: 3),
//                vibrancyEffectView.contentView.trailingAnchor.constraint(equalTo: playerIndicatorLabel.trailingAnchor, constant: 3),
//                playerIndicatorLabel.bottomAnchor.constraint(equalTo: vibrancyEffectView.contentView.bottomAnchor),
//            ])
//        }
//    }
//}
