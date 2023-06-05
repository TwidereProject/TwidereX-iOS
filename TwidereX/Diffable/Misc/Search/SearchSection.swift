//
//  SearchSection.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-22.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import SwiftUI
import Meta
import TwidereCore
import TwidereUI

enum SearchSection: Hashable, CaseIterable {
    case history
    case trend
}

extension SearchSection {
    
    struct Configuration {
        let viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<SearchSection, SearchItem> {
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(TableViewPlainCell.self, forCellReuseIdentifier: String(describing: TableViewPlainCell.self))
        tableView.register(TrendTableViewCell.self, forCellReuseIdentifier: String(describing: TrendTableViewCell.self))
        tableView.register(CenterFootnoteLabelTableViewCell.self, forCellReuseIdentifier: String(describing: CenterFootnoteLabelTableViewCell.self))
        tableView.register(ButtonTableViewCell.self, forCellReuseIdentifier: String(describing: ButtonTableViewCell.self))
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .history(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TableViewPlainCell.self), for: indexPath) as! TableViewPlainCell
                context.managedObjectContext.performAndWait {
                    guard let object = record.object(in: context.managedObjectContext) else { return }
                    configure(cell: cell, object: object)
                }
                return cell
            case .trend(let object):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TrendTableViewCell.self), for: indexPath) as! TrendTableViewCell
                let trendViewModel = TrendView.ViewModel(
                    object: object,
                    viewLayoutFramePublisher: configuration.viewLayoutFramePublisher
                )
                cell.contentConfiguration = UIHostingConfiguration {
                    TrendView(viewModel: trendViewModel)
                }
                return cell
            case .loader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                return cell
            case .noResults:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CenterFootnoteLabelTableViewCell.self), for: indexPath) as! CenterFootnoteLabelTableViewCell
                cell.selectionStyle = .none
                cell.label.text = L10n.Common.Controls.List.noResults
                return cell
            case .showMore:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ButtonTableViewCell.self), for: indexPath) as! ButtonTableViewCell
                var configuration = UIButton.Configuration.plain()
                configuration.baseForegroundColor = Asset.Colors.hightLight.color
                configuration.contentInsets = .zero
                configuration.attributedTitle = {
                    var attributedString = AttributedString(L10n.Scene.Search.showMore)
                    attributedString.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .preferredFont(forTextStyle: .body))
                    return attributedString
                }()
                cell.button.configuration = configuration
                cell.button.contentHorizontalAlignment = .leading
                return cell
            }   // end switch
        }
    }
}

extension SearchSection {
    private static func configure(
        cell: TableViewPlainCell,
        object: SavedSearchObject
    ) {
        switch object {
        case .twitter(let history):
            let metaContent = Meta.convert(document: .plaintext(string: history.name))
            cell.primaryTextLabel.configure(content: metaContent)
        case .mastodon(let history):
            let metaContent = Meta.convert(document: .plaintext(string: history.query))
            cell.primaryTextLabel.configure(content: metaContent)
        }
    }
    
//    private static func configure(
//        cell: TrendTableViewCell,
//        object: TrendObject
//    ) {
//        switch object {
//        case .twitter(let trend):
//            let metaContent = Meta.convert(document: .plaintext(string: trend.name))
//            cell.primaryLabel.configure(content: metaContent)
//            cell.accessoryType = .disclosureIndicator
//        case .mastodon(let tag):
//            let metaContent = Meta.convert(document: .plaintext(string: "#" + tag.name))
//
//            cell.primaryLabel.configure(content: metaContent)
//            cell.secondaryLabel.text = L10n.Scene.Trends.accounts(tag.talkingPeopleCount ?? 0)
//            cell.setSecondaryLabelDisplay()
//
//            cell.supplementaryLabel.text = tag.history?.first?.uses ?? " "
//            cell.setSupplementaryLabelDisplay()
//
//            cell.lineChartView.data = (tag.history ?? [])
//                .sorted(by: { $0.day < $1.day })        // latest last
//                .map { entry in
//                    guard let point = Int(entry.accounts) else {
//                        return .zero
//                    }
//                    return CGFloat(point)
//                }
//            cell.setLineChartViewDisplay()
//        }
//    }
}
