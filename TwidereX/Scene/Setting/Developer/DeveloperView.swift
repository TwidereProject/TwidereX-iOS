//
//  DeveloperView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-7.
//  Copyright © 2020 Twidere. All rights reserved.
//

#if DEBUG

import SwiftUI
import Combine

struct RateLimitStatusRow: View {
    
    let name: String
    let limit: Int
    let remaining: Int
    
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Text("\(limit-remaining)/\(limit)")
        }
    }
}

struct DeveloperView: View {
    
    @EnvironmentObject var context: AppContext
    @ObservedObject var viewModel: DeveloperViewModel
    
    var body: some View {
        List {
            if viewModel.fetching {
                Section() {
                    VStack(alignment: .center) {
                        if #available(iOS 14.0, *) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Loading…")
                        }
                    }
                }
            }
            if !viewModel.sections.isEmpty {
                Section() {
                    Picker("", selection: $viewModel.resourceFilterOption) {
                        ForEach(DeveloperViewModel.ResourceFilterOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                ForEach(viewModel.sections.sorted(by: { $0.resource.lowercased() < $1.resource.lowercased() })) { section in
                    Section(header: Text(section.resource)) {
                        ForEach(section.statuses, id: \.0) { name, status in
                            RateLimitStatusRow(name: name, limit: status.limit, remaining: status.remaining)
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
    
}

struct DeveloperView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeveloperView(viewModel: DeveloperViewModel())
            DeveloperView(viewModel: DeveloperViewModel())
                .preferredColorScheme(.dark)
        }
    }
}

#endif
