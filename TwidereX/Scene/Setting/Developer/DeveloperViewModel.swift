//
//  DeveloperViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-7.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import SwiftyJSON
import TwitterAPI

final class DeveloperViewModel: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // Input
    let rateLimitStatusResources = CurrentValueSubject<JSON?, Never>(nil)
    @Published var resourceFilterOption: DeveloperViewModel.ResourceFilterOption = .used

    // output
    @Published var fetching = false
    @Published var sections: [Section] = []
    
    init() {
        Publishers.CombineLatest(
            $resourceFilterOption.eraseToAnyPublisher(),
            rateLimitStatusResources
        )
        .compactMap { option, resources -> [Section]? in
            guard let resources = resources else { return nil }
            
            var sections: [Section] = []
            for (key, value) in resources.dictionaryValue {
                let resource = key
                
                let statusDict = value.dictionaryValue
                var statuses: [(name: String, status: Twitter.Entity.RateLimitStatus.Status)] = []
                for (key, value) in statusDict {
                    guard let data = try? value.rawData() else { continue }
                    guard let status = try? JSONDecoder().decode(Twitter.Entity.RateLimitStatus.Status.self, from: data) else { continue }
                    if option == .used, status.remaining == status.limit { continue }
                    statuses.append((key, status))
                }
                
                guard !statuses.isEmpty else { continue }
                let section = Section(resource: resource, statuses: statuses)
                sections.append(section)
            }
            
            return sections
        }
        .assign(to: \.sections, on: self)
        .store(in: &disposeBag)
    }
    
}

extension DeveloperViewModel {
    enum ResourceFilterOption: String, Equatable, CaseIterable {
        case used = "Used"
        case all = "All"
    }
    
    struct Section: Identifiable {
        let resource: String
        let statuses: [(name: String, status: Twitter.Entity.RateLimitStatus.Status)]
        
        var id: String {
            return resource
        }
    }
}

