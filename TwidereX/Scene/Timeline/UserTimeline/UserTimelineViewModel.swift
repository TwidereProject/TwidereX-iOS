//
//  UserTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import UIKit

class UserTimelineViewModel {
    
    // input
    var diffableDataSource: UITableViewDiffableDataSource<TimelineSection, TimelineItem>?
    
    init() { }
    
}

extension UserTimelineViewModel {
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource<TimelineSection, TimelineItem>(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .userTimelineItem(let tweet):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
                
                // configure cell
//                let managedObjectContext = self.fetchedResultsController.managedObjectContext
//                managedObjectContext.performAndWait {
//                    let timelineIndex = managedObjectContext.object(with: objectID) as! TimelineIndex
//                    HomeTimelineViewModel.configure(cell: cell, timelineIndex: timelineIndex, attribute: expandStatus)
//                }
//                cell.delegate = self.timelinePostTableViewCellDelegate
                return cell
            default:
                return nil
            }
        }
    }
}
