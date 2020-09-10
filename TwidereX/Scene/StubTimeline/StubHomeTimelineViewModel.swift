//
//  StubHomeTimelineViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-9.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import AlamofireImage
import DateToolsSwift

final class StubTimelineViewModel: NSObject {
    
    // input
    let context: AppContext
    weak var tableView: UITableView?
    var stubItems: [String] = [
        StubTimelineViewModel.createStub()
    ]
    
    // output
    
    
    init(context: AppContext) {
        self.context  = context

        super.init()
        
    }
    
}

extension StubTimelineViewModel {
    static func createStub() -> String {
        let letter = "ABCDEFG".randomElement()!
        let number = Int.random(in: 0..<100000)
        return "\(letter)\(number)"
    }
    
    static func createStubs(count: Int) -> [String] {
        return (0..<count).map { _ in createStub() }
    }
}

extension StubTimelineViewModel: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stubItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HomeTimelineTableViewCell.self), for: indexPath) as! HomeTimelineTableViewCell
        cell.nameLabel.text = stubItems[indexPath.row]
        return cell
    }
    
    
}
