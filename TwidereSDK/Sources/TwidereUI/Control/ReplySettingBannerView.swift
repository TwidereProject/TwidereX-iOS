//
//  ReplySettingBannerView.swift
//  
//
//  Created by MainasuK on 2022-6-16.
//

import UIKit
import SwiftUI
import TwitterSDK
import TwidereAsset
import TwidereLocalization

public struct ReplySettingBannerView: View {
    
    public let viewModel: ViewModel

    @ScaledMetric(relativeTo: .callout) private var imageDimension: CGFloat = 16

    
    public var body: some View {
        HStack(spacing: 4) {
            Image(uiImage: viewModel.icon)
                .resizable()
                .frame(width: imageDimension, height: imageDimension)
            Text(viewModel.title)
        }
        .font(.callout)
        .foregroundColor(.white)
        .padding(.vertical, 8)
    }
    
}

extension ReplySettingBannerView {
    public class ViewModel: ObservableObject {
        // input
        public let replaySettings: Twitter.Entity.V2.Tweet.ReplySettings
        public let authorUsername: String
        
        // output
        public let icon: UIImage
        public let title: String
        public let shouldHidden: Bool
        
        public init(
            replaySettings: Twitter.Entity.V2.Tweet.ReplySettings,
            authorUsername: String
        ) {
            self.replaySettings = replaySettings
            self.authorUsername = authorUsername
            self.icon = {
                switch replaySettings {
                case .everyone:
                    fallthrough
                case .following:
                    return Asset.Communication.at.image.withRenderingMode(.alwaysTemplate)
                case .mentionedUsers:
                    return Asset.Human.personCheckMini.image.withRenderingMode(.alwaysTemplate)
                }
            }()
            self.title = {
                switch replaySettings {
                case .everyone:
                    return ""
                case .following:
                    return L10n.Common.Controls.Status.ReplySettings.peopleUserFollowsOrMentionedCanReply("@\(authorUsername)")
                case .mentionedUsers:
                    return L10n.Common.Controls.Status.ReplySettings.peopleUserMentionedCanReply("@\(authorUsername)")
                }
            }()
            self.shouldHidden = replaySettings == .everyone
            // end init
        }
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct ReplySettingBannerView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            ReplySettingBannerView(viewModel: .init(
                replaySettings: .following,
                authorUsername: "alice"
            ))
            ReplySettingBannerView(viewModel: .init(
                replaySettings: .mentionedUsers,
                authorUsername: "alice"
            ))
        }
        .background(Color.black)
    }
    
}

#endif

