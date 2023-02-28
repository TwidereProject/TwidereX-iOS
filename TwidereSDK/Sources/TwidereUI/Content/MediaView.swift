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
            .overlay {
                switch viewModel.mediaKind {
                case .animatedGIF:
                    if let assetURL = viewModel.downloadURL {
                        GIFVideoPlayerRepresentable(assetURL: assetURL)
                    } else {
                        EmptyView()
                    }
                default:
                    EmptyView()
                }
            }
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
            MediaView.ViewModel(
                mediaKind: .animatedGIF,
                aspectRatio: CGSize(width: 1200, height: 720),
                altText: nil,
                previewURL: URL(string: "https://media.mstdn.jp/cache/media_attachments/files/109/936/306/341/672/302/small/19d1c52c1a1713b2.png"),
                assetURL: URL(string: "https://media.mstdn.jp/cache/media_attachments/files/109/936/306/341/672/302/small/19d1c52c1a1713b2.png"),
                downloadURL: URL(string: "https://media.mstdn.jp/cache/media_attachments/files/109/936/306/341/672/302/original/19d1c52c1a1713b2.mp4"),
                durationMS: 11084
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
