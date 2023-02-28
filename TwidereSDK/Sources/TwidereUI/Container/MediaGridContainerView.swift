//
//  MediaGridContainerView.swift
//  MediaGridContainerView
//
//  Created by Cirno MainasuK on 2021-8-23.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI

public struct MediaGridContainerView: View {
    
    static public var spacing: CGFloat { 8 }
    static public var cornerRadius: CGFloat { 8 }
    
    public let viewModels: [MediaView.ViewModel]
    
    public let idealWidth: CGFloat?
    public let idealHeight: CGFloat     // ideal height for grid exclude single media
    
    public let previewAction: (MediaView.ViewModel) -> Void

    public var body: some View {
        VStack {
            switch viewModels.count {
            case 1:
                mediaView(at: 0, width: idealWidth, height: idealHeight)
            case 2:
                let height = height(for: 1)
                HStack(spacing: MediaGridContainerView.spacing) {
                    mediaView(at: 0, width: nil, height: height)
                    mediaView(at: 1, width: nil, height: height)
                }
            case 3:
                HStack(alignment: .top, spacing: MediaGridContainerView.spacing) {
                    let height = height(for: 2)
                    mediaView(at: 0, width: nil, height: 2 * height + MediaGridContainerView.spacing)
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 1, width: nil, height: height)
                        mediaView(at: 2, width: nil, height: height)
                    }
                }
            case 4:
                HStack(alignment: .top, spacing: MediaGridContainerView.spacing) {
                    let height = height(for: 2)
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 0, width: nil, height: height)
                        mediaView(at: 2, width: nil, height: height)
                    }
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 1, width: nil, height: height)
                        mediaView(at: 3, width: nil, height: height)
                    }
                }
            case 5:
                HStack(alignment: .top, spacing: MediaGridContainerView.spacing) {
                    let height = height(for: 3)
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 0, width: nil, height: height)
                        mediaView(at: 3, width: nil, height: height)
                    }
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 1, width: nil, height: height)
                        mediaView(at: 4, width: nil, height: height)
                    }
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 2, width: nil, height: height)
                    }
                }
            case 6:
                HStack(alignment: .top, spacing: MediaGridContainerView.spacing) {
                    let height = height(for: 3)
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 0, width: nil, height: height)
                        mediaView(at: 3, width: nil, height: height)
                    }
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 1, width: nil, height: height)
                        mediaView(at: 4, width: nil, height: height)
                    }
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 2, width: nil, height: height)
                        mediaView(at: 5, width: nil, height: height)
                    }
                }
            case 7:
                HStack(alignment: .top, spacing: MediaGridContainerView.spacing) {
                    let height = height(for: 3)
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 0, width: nil, height: height)
                        mediaView(at: 3, width: nil, height: height)
                        mediaView(at: 6, width: nil, height: height)
                    }
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 1, width: nil, height: height)
                        mediaView(at: 4, width: nil, height: height)
                    }
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 2, width: nil, height: height)
                        mediaView(at: 5, width: nil, height: height)
                    }
                }
            case 8:
                HStack(alignment: .top, spacing: MediaGridContainerView.spacing) {
                    let height = height(for: 3)
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 0, width: nil, height: height)
                        mediaView(at: 3, width: nil, height: height)
                        mediaView(at: 6, width: nil, height: height)
                    }
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 1, width: nil, height: height)
                        mediaView(at: 4, width: nil, height: height)
                        mediaView(at: 7, width: nil, height: height)
                    }
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 2, width: nil, height: height)
                        mediaView(at: 5, width: nil, height: height)
                    }
                }
            case 9...:
                HStack(alignment: .top, spacing: MediaGridContainerView.spacing) {
                    let height = height(for: 3)
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 0, width: nil, height: height)
                        mediaView(at: 3, width: nil, height: height)
                        mediaView(at: 6, width: nil, height: height)
                    }
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 1, width: nil, height: height)
                        mediaView(at: 4, width: nil, height: height)
                        mediaView(at: 7, width: nil, height: height)
                    }
                    VStack(spacing: MediaGridContainerView.spacing) {
                        mediaView(at: 2, width: nil, height: height)
                        mediaView(at: 5, width: nil, height: height)
                        mediaView(at: 8, width: nil, height: height)
                            .overlay() {
                                let remains = viewModels.count - 9
                                if remains > 0 {
                                    Color.black.opacity(0.3)
                                        .overlay {
                                            Text("+\(remains)")
                                                .font(.system(size: 27, weight: .semibold, design: .default))
                                                .foregroundColor(.white)
                                        }
                                }   // end if
                            }
                    }
                }
            default:
                EmptyView()
            }
        }   // end Group
    }   // end body
}

extension MediaGridContainerView {
    public func contextMenuItems(for viewModel: MediaView.ViewModel) -> some View {
        Button {
            
        } label: {
            Label(L10n.Common.Controls.Actions.save, systemImage: "square.and.arrow.down")
        }
    }
}

extension MediaGridContainerView {
    
    private func mediaView(at index: Int, width: CGFloat?, height: CGFloat?) -> some View {
        Group {
            let viewModel = viewModels[index]
            switch viewModels.count {
            case 1:
                MediaView(viewModel: viewModel)
                    .modifier(MediaViewFrameModifer(
                        asepctRatio: viewModel.aspectRatio.width / viewModel.aspectRatio.height,
                        idealWidth: idealWidth,
                        idealHeight: viewModel.mediaKind == .video ? idealHeight : 2 * idealHeight)
                    )
            default:
                Rectangle()
                    .fill(Color(uiColor: .placeholderText))
                    .frame(width: width, height: height)
                    .overlay(
                        MediaView(viewModel: viewModel)
                            .aspectRatio(contentMode: .fill)
                    )
            }
        }
        .cornerRadius(MediaGridContainerView.cornerRadius)
        .clipped()
        .background(GeometryReader { proxy in
            Color.clear.preference(
                key: ViewFrameKey.self,
                value: proxy.frame(in: .global)
            )
            .onPreferenceChange(ViewFrameKey.self) { frame in
                viewModels[index].frameInWindow = frame
            }
        })
        .overlay(alignment: .bottom) {
            HStack {
                let viewModel = viewModels[index]
                Spacer()
                Group {
                    if viewModel.mediaKind == .animatedGIF {
                        Text("GIF")
                    } else if let durationText = viewModel.durationText {
                        Text("\(Image(systemName: "play.fill")) \(durationText)")
                    }
                }
                .foregroundColor(Color(uiColor: .label))
                .font(.system(.footnote, design: .default, weight: .medium))
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(.thinMaterial)
                .cornerRadius(4)
            }
            .padding(EdgeInsets(top: 0, leading: 11, bottom: 8, trailing: 11))
            .allowsHitTesting(false)
        }
        .overlay(
            RoundedRectangle(cornerRadius: MediaGridContainerView.cornerRadius)
                .stroke(Color(uiColor: .placeholderText).opacity(0.5), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            previewAction(viewModels[index])
        }
        .contextMenu(contextMenuContentPreviewProvider: {
            let viewModel = viewModels[index]
            guard let thumbnail = viewModel.thumbnail else { return nil }
            let contextMenuImagePreviewViewModel = ContextMenuImagePreviewViewModel(aspectRatio: thumbnail.size, thumbnail: thumbnail)
            let previewProvider = ContextMenuImagePreviewViewController()
            previewProvider.viewModel = contextMenuImagePreviewViewModel
            return previewProvider
            
        }, contextMenuActionProvider: { _ in
            let children: [UIAction] = [
                UIAction(
                    title: L10n.Common.Controls.Actions.copy,
                    image: UIImage(systemName: "doc.on.doc"),
                    attributes: [],
                    state: .off
                ) { _ in
                    print("Hi copy")
                }
            ]
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: children)
        }, previewAction: {
            previewAction(viewModels[index])
        })
    }   // end func
    
    private func height(for rows: Int) -> CGFloat {
        guard let idealWidth = self.idealWidth else {
            // fix grid height
            let margins = CGFloat(rows - 1) * MediaGridContainerView.spacing
            let height = (idealHeight - margins) / CGFloat(rows)
            return height
        }
        
        // make tiem square
        let cols = rows < 3 ? 2 : 3
        let margins = CGFloat(cols - 1) * MediaGridContainerView.spacing
        let width = (idealWidth - margins) / CGFloat(cols)
        return width
    }
    
}

public struct MediaViewFrameModifer: ViewModifier {
    
    let asepctRatio: CGFloat?
    let idealWidth: CGFloat?
    let idealHeight: CGFloat
    
    public init(
        asepctRatio: CGFloat?,
        idealWidth: CGFloat?,
        idealHeight: CGFloat
    ) {
        self.asepctRatio = asepctRatio
        self.idealWidth = idealWidth
        self.idealHeight = idealHeight
    }
    
    public func body(content: Content) -> some View {
        if let idealWidth = idealWidth {
            content
                .frame(width: idealWidth, height: idealWidth / (asepctRatio ?? 1.0))
        } else {
            content
                .frame(maxHeight: idealHeight)
        }
    }
}

struct MediaGridContainerView_Previews: PreviewProvider {
    
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
                mediaKind: .photo,
                aspectRatio: CGSize(width: 6096, height: 5173),
                altText: nil,
                previewURL: URL(string: "https://www.nasa.gov/sites/default/files/thumbnails/image/chandra_ixpe_v3magentahires.jpg"),
                assetURL: URL(string: "https://www.nasa.gov/sites/default/files/thumbnails/image/chandra_ixpe_v3magentahires.jpg"),
                downloadURL: URL(string: "https://www.nasa.gov/sites/default/files/thumbnails/image/chandra_ixpe_v3magentahires.jpg"),
                durationMS: nil
            ),
            MediaView.ViewModel(
                mediaKind: .animatedGIF,
                aspectRatio: CGSize(width: 1200, height: 720),
                altText: nil,
                previewURL: URL(string: "https://media.mstdn.jp/cache/media_attachments/files/109/936/306/341/672/302/small/19d1c52c1a1713b2.png"),
                assetURL: URL(string: "https://media.mstdn.jp/cache/media_attachments/files/109/936/306/341/672/302/small/19d1c52c1a1713b2.png"),
                downloadURL: URL(string: "https://media.mstdn.jp/cache/media_attachments/files/109/936/306/341/672/302/original/19d1c52c1a1713b2.mp4"),
                durationMS: 11084
            ),
            MediaView.ViewModel(
                mediaKind: .video,
                aspectRatio: CGSize(width: 1200, height: 675),
                altText: nil,
                previewURL: URL(string: "https://pbs.twimg.com/ext_tw_video_thumb/1629081362555899904/pu/img/em5qGBhoV0R1aGfv.jpg"),
                assetURL: URL(string: "https://pbs.twimg.com/ext_tw_video_thumb/1629081362555899904/pu/img/em5qGBhoV0R1aGfv.jpg"),
                downloadURL: URL(string: "https://video.twimg.com/ext_tw_video/1629081362555899904/pu/vid/1280x720/4OGsKDg67adqojtX.mp4?tag=12"),
                durationMS: 10555
            ),
            MediaView.ViewModel(
                mediaKind: .photo,
                aspectRatio: CGSize(width: 2016, height: 2016),
                altText: nil,
                previewURL: URL(string: "https://www.nasa.gov/sites/default/files/images/671506main_PIA15628_full.jpg"),
                assetURL: URL(string: "https://www.nasa.gov/sites/default/files/images/671506main_PIA15628_full.jpg"),
                downloadURL: URL(string: "https://www.nasa.gov/sites/default/files/images/671506main_PIA15628_full.jpg"),
                durationMS: nil
            ),
            MediaView.ViewModel(
                mediaKind: .photo,
                aspectRatio: CGSize(width: 3482, height: 1959),
                altText: nil,
                previewURL: URL(string: "https://www.nasa.gov/sites/default/files/thumbnails/image/pia20027_updated.jpg"),
                assetURL: URL(string: "https://www.nasa.gov/sites/default/files/thumbnails/image/pia20027_updated.jpg"),
                downloadURL: URL(string: "https://www.nasa.gov/sites/default/files/thumbnails/image/pia20027_updated.jpg"),
                durationMS: nil
            ),
        ]
        return Array(repeating: models, count: 3).flatMap { $0 }
    }()
    
    static var previews: some View {
        Group {
            ForEach(0..<viewModels.count, id: \.self) { i in
                MediaGridContainerView(
                    viewModels: Array(viewModels.prefix(i + 1)),
                    idealWidth: 300,
                    idealHeight: 280,
                    previewAction: { _ in
                        // do nothing
                    }
                )
                .frame(width: 300)
                .previewLayout(.fixed(width: 300, height: 280))
                .previewDisplayName("\(i + 1)")
                .border(Color.red)
            }
        }
    }
}

extension View {
    func contextMenu(
        contextMenuContentPreviewProvider: @escaping UIContextMenuContentPreviewProvider,
        contextMenuActionProvider: @escaping UIContextMenuActionProvider,
        previewAction: @escaping () -> Void
    ) -> some View {
        modifier(ContextMenuViewModifier(
            contextMenuContentPreviewProvider: contextMenuContentPreviewProvider,
            contextMenuActionProvider: contextMenuActionProvider,
            previewAction: previewAction
        ))
    }
}

struct ContextMenuViewModifier: ViewModifier {
    let contextMenuContentPreviewProvider: UIContextMenuContentPreviewProvider
    let contextMenuActionProvider: UIContextMenuActionProvider
    let previewAction: () -> Void
    
    func body(content: Content) -> some View {
        ContextMenuInteractionRepresentable(
            contextMenuContentPreviewProvider: contextMenuContentPreviewProvider,
            contextMenuActionProvider: contextMenuActionProvider
        ) {
            content
        } previewAction: {
            previewAction()
        }
    }
}



//public final class MediaGridContainerView: UIView {
//    
//    public static let maxCount = 9
//    
//    let logger = Logger(subsystem: "MediaGridContainerView", category: "UI")
//    
//    public weak var delegate: MediaGridContainerViewDelegate?
//    public private(set) lazy var viewModel: ViewModel = {
//        let viewModel = ViewModel()
//        viewModel.bind(view: self)
//        return viewModel
//    }()
//    
//    // lazy var is required here to setup gesture recognizer target-action
//    // Swift not doesn't emit compiler error if without `lazy` here
//    private(set) lazy var _mediaViews: [MediaView] = {
//        var mediaViews: [MediaView] = []
//        for i in 0..<MediaGridContainerView.maxCount {
//            // init media view
//            let mediaView = MediaView()
//            mediaView.tag = i
//            mediaViews.append(mediaView)
//            
//            // add gesture recognizer
//            let tapGesture = UITapGestureRecognizer.singleTapGestureRecognizer
//            tapGesture.addTarget(self, action: #selector(MediaGridContainerView.mediaViewTapGestureRecognizerHandler(_:)))
//            mediaView.container.addGestureRecognizer(tapGesture)
//            mediaView.container.isUserInteractionEnabled = true
//        }
//        return mediaViews
//    }()
//    
//    let sensitiveToggleButtonBlurVisualEffectView: UIVisualEffectView = {
//        let visualEffectView = UIVisualEffectView(effect: ContentWarningOverlayView.blurVisualEffect)
//        visualEffectView.layer.masksToBounds = true
//        visualEffectView.layer.cornerRadius = 6
//        visualEffectView.layer.cornerCurve = .continuous
//        return visualEffectView
//    }()
//    let sensitiveToggleButtonVibrancyVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: ContentWarningOverlayView.blurVisualEffect))
//    let sensitiveToggleButton: HitTestExpandedButton = {
//        let button = HitTestExpandedButton(type: .system)
//        button.setImage(Asset.Human.eyeSlashMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
//        button.isAccessibilityElement = true
//        button.accessibilityLabel = L10n.Accessibility.Common.Status.Actions.hideMedia
//        button.accessibilityTraits = .button
//        return button
//    }()
//    
//    public let contentWarningOverlayView: ContentWarningOverlayView = {
//        let overlay = ContentWarningOverlayView()
//        overlay.layer.masksToBounds = true
//        overlay.layer.cornerRadius = MediaView.cornerRadius
//        overlay.layer.cornerCurve = .continuous
//        overlay.isAccessibilityElement = true
//        overlay.accessibilityLabel = L10n.Accessibility.Common.Status.Actions.revealMedia
//        overlay.accessibilityTraits = .button
//        return overlay
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
//extension MediaGridContainerView {
//    private func _init() {
//        sensitiveToggleButton.addTarget(self, action: #selector(MediaGridContainerView.sensitiveToggleButtonDidPressed(_:)), for: .touchUpInside)
//        contentWarningOverlayView.delegate = self
//    }
//}
//
//extension MediaGridContainerView {
//    @objc private func mediaViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
//        guard let index = _mediaViews.firstIndex(where: { $0.container === sender.view }) else { return }
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(index)")
//        let mediaView = _mediaViews[index]
//        delegate?.mediaGridContainerView(self, didTapMediaView: mediaView, at: index)
//    }
//
//    @objc private func sensitiveToggleButtonDidPressed(_ sender: UIButton) {
//        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        delegate?.mediaGridContainerView(self, toggleContentWarningOverlayViewDisplay: contentWarningOverlayView)
//    }
//}
//
//extension MediaGridContainerView {
//
//    public func dequeueMediaView(adaptiveLayout layout: AdaptiveLayout) -> MediaView {
//        prepareForReuse()
//        
//        let mediaView = _mediaViews[0]
//        layout.layout(in: self, mediaView: mediaView)
//        
//        layoutSensitiveToggleButton()
//        bringSubviewToFront(sensitiveToggleButtonBlurVisualEffectView)
//
//        layoutContentOverlayView(on: mediaView)
//        bringSubviewToFront(contentWarningOverlayView)
//        
//        return mediaView
//    }
//    
//    public func dequeueMediaView(gridLayout layout: GridLayout) -> [MediaView] {
//        prepareForReuse()
//        
//        let mediaViews = Array(_mediaViews[0..<layout.count])
//        layout.layout(in: self, mediaViews: mediaViews)
//        
//        layoutSensitiveToggleButton()
//        bringSubviewToFront(sensitiveToggleButtonBlurVisualEffectView)
//
//        layoutContentOverlayView(on: self)
//        bringSubviewToFront(contentWarningOverlayView)
//        
//        return mediaViews
//    }
//    
//    public func prepareForReuse() {
//        _mediaViews.forEach { view in
//            view.removeFromSuperview()
//            view.removeConstraints(view.constraints)
//            view.prepareForReuse()
//        }
//        
//        subviews.forEach { view in
//            view.removeFromSuperview()
//        }
//        
//        removeConstraints(constraints)
//    }
//
//}
//
//extension MediaGridContainerView {
//    private func layoutSensitiveToggleButton() {
//        sensitiveToggleButtonBlurVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(sensitiveToggleButtonBlurVisualEffectView)
//        NSLayoutConstraint.activate([
//            sensitiveToggleButtonBlurVisualEffectView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
//            sensitiveToggleButtonBlurVisualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
//        ])
//        
//        sensitiveToggleButtonVibrancyVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
//        sensitiveToggleButtonBlurVisualEffectView.contentView.addSubview(sensitiveToggleButtonVibrancyVisualEffectView)
//        NSLayoutConstraint.activate([
//            sensitiveToggleButtonVibrancyVisualEffectView.topAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.contentView.topAnchor),
//            sensitiveToggleButtonVibrancyVisualEffectView.leadingAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.contentView.leadingAnchor),
//            sensitiveToggleButtonVibrancyVisualEffectView.trailingAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.contentView.trailingAnchor),
//            sensitiveToggleButtonVibrancyVisualEffectView.bottomAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.contentView.bottomAnchor),
//        ])
//        
//        sensitiveToggleButton.translatesAutoresizingMaskIntoConstraints = false
//        sensitiveToggleButtonVibrancyVisualEffectView.contentView.addSubview(sensitiveToggleButton)
//        NSLayoutConstraint.activate([
//            sensitiveToggleButton.topAnchor.constraint(equalTo: sensitiveToggleButtonVibrancyVisualEffectView.contentView.topAnchor, constant: 4),
//            sensitiveToggleButton.leadingAnchor.constraint(equalTo: sensitiveToggleButtonVibrancyVisualEffectView.contentView.leadingAnchor, constant: 4),
//            sensitiveToggleButtonVibrancyVisualEffectView.contentView.trailingAnchor.constraint(equalTo: sensitiveToggleButton.trailingAnchor, constant: 4),
//            sensitiveToggleButtonVibrancyVisualEffectView.contentView.bottomAnchor.constraint(equalTo: sensitiveToggleButton.bottomAnchor, constant: 4),
//        ])
//    }
//    
//    private func layoutContentOverlayView(on view: UIView) {
//        contentWarningOverlayView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(contentWarningOverlayView)       // should add to container
//        NSLayoutConstraint.activate([
//            contentWarningOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
//            contentWarningOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            contentWarningOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            contentWarningOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ])
//    }
//    
//}
//
//extension MediaGridContainerView {
//    
//    public var mediaViews: [MediaView] {
//        _mediaViews.filter { $0.superview != nil }
//    }
//    
//    public func setAlpha(_ alpha: CGFloat) {
//        _mediaViews.forEach { $0.alpha = alpha }
//    }
//    
//    public func setAlpha(_ alpha: CGFloat, index: Int) {
//        if index < _mediaViews.count {
//            _mediaViews[index].alpha = alpha
//        }
//    }
//    
//}
//
//extension MediaGridContainerView {
//    public struct AdaptiveLayout {
//        let aspectRatio: CGSize
//        let maxSize: CGSize
//        
//        func layout(in view: UIView, mediaView: MediaView) {
//            let imageViewSize = AVMakeRect(aspectRatio: aspectRatio, insideRect: CGRect(origin: .zero, size: maxSize)).size
//            mediaView.translatesAutoresizingMaskIntoConstraints = false
//            view.addSubview(mediaView)
//            NSLayoutConstraint.activate([
//                mediaView.topAnchor.constraint(equalTo: view.topAnchor),
//                mediaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//                mediaView.trailingAnchor.constraint(equalTo: view.trailingAnchor).priority(.defaultLow),
//                mediaView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//                mediaView.widthAnchor.constraint(equalToConstant: imageViewSize.width).priority(.required - 1),
//                mediaView.heightAnchor.constraint(equalToConstant: imageViewSize.height).priority(.required - 1),
//            ])
//        }
//    }
//    
//    public struct GridLayout {
//        static let spacing: CGFloat = 8
//        
//        let count: Int
//        let maxSize: CGSize
//        
//        init(count: Int, maxSize: CGSize) {
//            self.count = min(count, 9)
//            self.maxSize = maxSize
//        
//        }
//        
//        private func createStackView(axis: NSLayoutConstraint.Axis) -> UIStackView {
//            let stackView = UIStackView()
//            stackView.axis = axis
//            stackView.semanticContentAttribute = .forceLeftToRight
//            stackView.spacing = GridLayout.spacing
//            stackView.distribution = .fillEqually
//            return stackView
//        }
//        
//        public func layout(in view: UIView, mediaViews: [MediaView]) {
//            let containerVerticalStackView = createStackView(axis: .vertical)
//            containerVerticalStackView.translatesAutoresizingMaskIntoConstraints = false
//            view.addSubview(containerVerticalStackView)
//            NSLayoutConstraint.activate([
//                containerVerticalStackView.topAnchor.constraint(equalTo: view.topAnchor),
//                containerVerticalStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//                containerVerticalStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//                containerVerticalStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            ])
//            
//            let count = mediaViews.count
//            switch count {
//            case 1:
//                assertionFailure("should use Adaptive Layout")
//                containerVerticalStackView.addArrangedSubview(mediaViews[0])
//            case 2:
//                let horizontalStackView = createStackView(axis: .horizontal)
//                containerVerticalStackView.addArrangedSubview(horizontalStackView)
//                horizontalStackView.addArrangedSubview(mediaViews[0])
//                horizontalStackView.addArrangedSubview(mediaViews[1])
//            case 3:
//                let horizontalStackView = createStackView(axis: .horizontal)
//                containerVerticalStackView.addArrangedSubview(horizontalStackView)
//                horizontalStackView.addArrangedSubview(mediaViews[0])
//                
//                let verticalStackView = createStackView(axis: .vertical)
//                horizontalStackView.addArrangedSubview(verticalStackView)
//                verticalStackView.addArrangedSubview(mediaViews[1])
//                verticalStackView.addArrangedSubview(mediaViews[2])
//            case 4:
//                let topHorizontalStackView = createStackView(axis: .horizontal)
//                containerVerticalStackView.addArrangedSubview(topHorizontalStackView)
//                topHorizontalStackView.addArrangedSubview(mediaViews[0])
//                topHorizontalStackView.addArrangedSubview(mediaViews[1])
//                
//                let bottomHorizontalStackView = createStackView(axis: .horizontal)
//                containerVerticalStackView.addArrangedSubview(bottomHorizontalStackView)
//                bottomHorizontalStackView.addArrangedSubview(mediaViews[2])
//                bottomHorizontalStackView.addArrangedSubview(mediaViews[3])
//            case 5...9:
//                let topHorizontalStackView = createStackView(axis: .horizontal)
//                containerVerticalStackView.addArrangedSubview(topHorizontalStackView)
//                topHorizontalStackView.addArrangedSubview(mediaViews[0])
//                topHorizontalStackView.addArrangedSubview(mediaViews[1])
//                topHorizontalStackView.addArrangedSubview(mediaViews[2])
//                
//                func mediaViewOrPlaceholderView(at index: Int) -> UIView {
//                    return index < mediaViews.count ? mediaViews[index] : UIView()
//                }
//                let middleHorizontalStackView = createStackView(axis: .horizontal)
//                containerVerticalStackView.addArrangedSubview(middleHorizontalStackView)
//                middleHorizontalStackView.addArrangedSubview(mediaViews[3])
//                middleHorizontalStackView.addArrangedSubview(mediaViews[4])
//                middleHorizontalStackView.addArrangedSubview(mediaViewOrPlaceholderView(at: 5))
//                
//                if count > 6 {
//                    let bottomHorizontalStackView = createStackView(axis: .horizontal)
//                    containerVerticalStackView.addArrangedSubview(bottomHorizontalStackView)
//                    bottomHorizontalStackView.addArrangedSubview(mediaViewOrPlaceholderView(at: 6))
//                    bottomHorizontalStackView.addArrangedSubview(mediaViewOrPlaceholderView(at: 7))
//                    bottomHorizontalStackView.addArrangedSubview(mediaViewOrPlaceholderView(at: 8))
//                }
//            default:
//                assertionFailure()
//                return
//            }
//            
//            let containerWidth = maxSize.width
//            let containerHeight = count > 6 ? containerWidth : containerWidth * 2 / 3
//            NSLayoutConstraint.activate([
//                view.widthAnchor.constraint(equalToConstant: containerWidth).priority(.required - 1),
//                view.heightAnchor.constraint(equalToConstant: containerHeight).priority(.required - 1),
//            ])
//        }
//    }
//}
//
//// MARK: - ContentWarningOverlayViewDelegate
//extension MediaGridContainerView: ContentWarningOverlayViewDelegate {
//    public func contentWarningOverlayViewDidPressed(_ contentWarningOverlayView: ContentWarningOverlayView) {
//        delegate?.mediaGridContainerView(self, toggleContentWarningOverlayViewDisplay: contentWarningOverlayView)
//    }
//}
//
//extension MediaGridContainerView {
//    public override var accessibilityElements: [Any]? {
//        get {
//            if viewModel.isContentWarningOverlayDisplay == true {
//                return [contentWarningOverlayView]
//            } else {
//                return [sensitiveToggleButton] + mediaViews
//            }
//            
//        }
//        set { }
//    }
//}
