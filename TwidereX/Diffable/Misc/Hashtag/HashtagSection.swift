//
//  HashtagSection.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-11-5.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

enum HashtagSection: Hashable {
    case main
}

extension HashtagSection {
    
    struct Configuration {
        
    }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<HashtagSection, HashtagItem> {
        return UITableViewDiffableDataSource<HashtagSection, HashtagItem>(tableView: tableView) { tableView, indexPath, item in
            // data source should dispatch in main thread
            assert(Thread.isMainThread)
            
            switch item {
            case .hashtag(let data):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HashtagTableViewCell.self), for: indexPath) as! HashtagTableViewCell
                configure(
                    cell: cell,
                    data: data,
                    configuration: configuration
                )
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }
        }
    }
    
}

extension HashtagSection {
    static func configure(
        cell: HashtagTableViewCell,
        data: HashtagData,
        configuration: Configuration
    ) {
        cell.configure(hashtagData: data)
    }
}
