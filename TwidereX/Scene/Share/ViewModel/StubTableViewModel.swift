//
//  StubTableViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import UIKit

final class StubTableViewModel: NSObject {
    
}

extension StubTableViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StubTableViewCell.self), for: indexPath) as! StubTableViewCell
        cell.titleLabel.text = "row \(indexPath.row), section: \(indexPath.section)"
        return cell
    }
    
}
