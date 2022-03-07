//
//  ListSection.swift
//  TwidereX
//
//  Created by MainasuK on 2022-2-28.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import Meta
import TwidereCore

enum ListSection: Hashable {
    case twitter(kind: TwitterListKind)
    case mastodon
    
    enum TwitterListKind: Hashable {
        case owned
        case subscribed
        case listed
    }
}

extension ListSection {
    
    struct Configuration { }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<ListSection, ListItem> {
        tableView.register(ListTableViewCell.self, forCellReuseIdentifier: String(describing: ListTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(CenterFootnoteLabelTableViewCell.self, forCellReuseIdentifier: String(describing: CenterFootnoteLabelTableViewCell.self))
        tableView.register(ButtonTableViewCell.self, forCellReuseIdentifier: String(describing: ButtonTableViewCell.self))
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .list(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ListTableViewCell.self), for: indexPath) as! ListTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let object = record.object(in: context.managedObjectContext) else { return }
                    configure(
                        tableView: tableView,
                        cell: cell,
                        list: object,
                        configuration: configuration
                    )
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
        }   // end UITableViewDiffableDataSource(tableView:)
    }   // end func
    
}

extension ListSection {
    
    static func configure(
        tableView: UITableView,
        cell: ListTableViewCell,
        list: ListObject,
        configuration: Configuration
    ) {
        switch list {
        case .twitter(let object):
            let metaContent = Meta.convert(from: .plaintext(string: object.name))
            cell.primaryTextLabel.configure(content: metaContent)
            cell.accessoryType = .disclosureIndicator
        case .mastodon(let object):
            let metaContent = Meta.convert(from: .plaintext(string: object.title))
            cell.primaryTextLabel.configure(content: metaContent)
            cell.accessoryType = .disclosureIndicator
        }
    }

}
