//
//  SwiftUIView.swift
//  
//
//  Created by MainasuK on 2023/5/15.
//

import SwiftUI
import Combine
import Meta
import MetaTextKit
import TwitterSDK
import MastodonSDK

public struct TrendView: View {
    
    @ObservedObject public var viewModel: ViewModel
    
    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: .zero) {
                titleLabel
                descriptionLabel
            }
            Spacer()
            HStack {
                chartDescriptionLabel
                chartView
            }
        }
    }
}

extension TrendView {
    var titleLabel: some View {
        LabelRepresentable(
            metaContent: viewModel.title,
            textStyle: .searchTrendTitle,
            setupLabel: { label in
                label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            }
        )
        .fixedSize(horizontal: false, vertical: true)
    }
    
    var descriptionLabel: some View {
        LabelRepresentable(
            metaContent: viewModel.description,
            textStyle: .searchTrendSubtitle,
            setupLabel: { label in
                label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            }
        )
        .fixedSize(horizontal: false, vertical: true)
    }
    
    var chartDescriptionLabel: some View {
        Text(viewModel.chartDescription)
            .font(.footnote)
            .foregroundColor(.secondary)
    }
    
    var chartView: some View {
        EmptyView()
//        Chart {
//
//        }
    }
}

extension TrendView {
    public class ViewModel: ObservableObject {
        
        @Published public var viewLayoutFrame = ViewLayoutFrame()

        // input
        public let kind: Kind
        public let title: MetaContent
        public let description: MetaContent
        public let chartDescription: String
        
        // output
        @Published var historyData: [Mastodon.Entity.History]?
        
        public init(
            kind: Kind,
            title: MetaContent,
            description: MetaContent,
            chartDescription: String,
            viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
        ) {
            self.kind = kind
            self.title = title
            self.description = description
            self.chartDescription = chartDescription
            // end init
            
            viewLayoutFramePublisher?.assign(to: &$viewLayoutFrame)
        }

    }
}

extension TrendView.ViewModel {
    public enum Kind: Hashable {
        case twitter
        case mastodon
    }
}

extension TrendView.ViewModel {
    public convenience init(
        object: TrendObject,
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) {
        switch object {
        case .twitter(let trend):
            self.init(trend: trend, viewLayoutFramePublisher: viewLayoutFramePublisher)
        case .mastodon(let tag):
            self.init(tag: tag, viewLayoutFramePublisher: viewLayoutFramePublisher)
        }
    }
    
    public convenience init(
        trend: Twitter.Entity.Trend,
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) {
        self.init(
            kind: .twitter,
            title: PlaintextMetaContent(string: "\(trend.name)"),
            description: PlaintextMetaContent(string: ""),
            chartDescription: "",
            viewLayoutFramePublisher: viewLayoutFramePublisher
        )
    }
    
    public convenience init(
        tag: Mastodon.Entity.Tag,
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) {
        self.init(
            kind: .mastodon,
            title: Meta.convert(document: .plaintext(string: "#" + tag.name)),
            description: PlaintextMetaContent(string: L10n.Scene.Trends.accounts(tag.talkingPeopleCount ?? 0)),
            chartDescription: tag.history?.first?.uses ?? " ",
            viewLayoutFramePublisher: viewLayoutFramePublisher
        )
        
        self.historyData = tag.history
    }
}


#if DEBUG
extension TrendView.ViewModel {
    convenience init(kind: Kind) {
        self.init(
            kind: kind,
            title: PlaintextMetaContent(string: "#Name"),
            description: PlaintextMetaContent(string: "500 people talking"),
            chartDescription: "123",
            viewLayoutFramePublisher: nil
        )
        
        historyData = [
            Mastodon.Entity.History(day: Date(year: 2020, month: 5, day: 1), uses: "123", accounts: "123"),
            Mastodon.Entity.History(day: Date(year: 2020, month: 5, day: 2), uses: "123", accounts: "123"),
            Mastodon.Entity.History(day: Date(year: 2020, month: 5, day: 3), uses: "123", accounts: "123"),
            Mastodon.Entity.History(day: Date(year: 2020, month: 5, day: 4), uses: "123", accounts: "123"),
            Mastodon.Entity.History(day: Date(year: 2020, month: 5, day: 5), uses: "123", accounts: "123"),
            Mastodon.Entity.History(day: Date(year: 2020, month: 5, day: 6), uses: "123", accounts: "123"),
            Mastodon.Entity.History(day: Date(year: 2020, month: 5, day: 7), uses: "123", accounts: "123"),
        ]
    }
}
#endif

#if canImport(SwiftUI) && DEBUG
struct TrendView_Previews: PreviewProvider {
    static var previews: some View {
        TrendView(viewModel: .init(kind: .twitter))
        TrendView(viewModel: .init(kind: .mastodon))
    }
}
#endif

