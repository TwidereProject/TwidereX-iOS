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
import TwidereUI

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
        tableView.register(TableViewPlainCell.self, forCellReuseIdentifier: String(describing: TableViewPlainCell.self))
        tableView.register(ListUserStyleTableViewCell.self, forCellReuseIdentifier: String(describing: ListUserStyleTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(CenterFootnoteLabelTableViewCell.self, forCellReuseIdentifier: String(describing: CenterFootnoteLabelTableViewCell.self))
        tableView.register(ButtonTableViewCell.self, forCellReuseIdentifier: String(describing: ButtonTableViewCell.self))
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .list(let record, let style):
                let cell = dequeueConfiguredReusableCell(
                    context: context,
                    tableView: tableView,
                    indexPath: indexPath,
                    configuration: ListCellRegistrationConfiguration(
                        list: record,
                        style: style,
                        configuration: configuration
                    )
                )
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
    
    struct ListCellRegistrationConfiguration {
        let list: ListRecord
        let style: ListItem.ListStyle
        let configuration: Configuration
    }
    
    static func dequeueConfiguredReusableCell(
        context: AppContext,
        tableView: UITableView,
        indexPath: IndexPath,
        configuration: ListCellRegistrationConfiguration
    ) -> UITableViewCell {
        let managedObjectContext = context.managedObjectContext
        
        switch configuration.style {
        case .plain:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TableViewPlainCell.self), for: indexPath) as! TableViewPlainCell
            managedObjectContext.performAndWait {
                guard let object = configuration.list.object(in: managedObjectContext) else { return }
                configure(
                    tableView: tableView,
                    cell: cell,
                    list: object,
                    configuration: configuration.configuration
                )
            }
            return cell
        case .user:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ListUserStyleTableViewCell.self), for: indexPath) as! ListUserStyleTableViewCell
            managedObjectContext.performAndWait {
                guard let object = configuration.list.object(in: managedObjectContext) else { return }
                configure(
                    tableView: tableView,
                    cell: cell,
                    list: object,
                    configuration: configuration.configuration
                )
            }
            return cell
        }
    }
    
    static func configure(
        tableView: UITableView,
        cell: TableViewPlainCell,
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
    
    static func configure(
        tableView: UITableView,
        cell: ListUserStyleTableViewCell,
        list: ListObject,
        configuration: Configuration
    ) {
        switch list {
        case .twitter(let object):
            cell.avatarButton.avatarImageView.configure(configuration: .init(url: object.owner.avatarImageURL()))
            cell.usernameLabel.text = "@" + object.owner.username
            cell.listNameLabel.text = object.name
        case .mastodon(let object):
            assertionFailure("should not enter here this entry for Mastodon")
            let avatarImageURL = object.owner.avatar.flatMap { URL(string: $0) }
            cell.avatarButton.avatarImageView.configure(configuration: .init(url: avatarImageURL))
            cell.usernameLabel.text = "@" + object.owner.acctWithDomain
            cell.listNameLabel.text = object.title
        }
        
        cell.accessoryType = .disclosureIndicator

        // a11y
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = [
            cell.listNameLabel.text,
            cell.usernameLabel.text,
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }

}
