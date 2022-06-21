//
//  TrendPlaceView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-21.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import SwiftUI
import TwidereLocalization
import TwitterSDK

struct TrendPlaceView: View {
    
    @ObservedObject var viewModel: TrendViewModel
    
    var activePlaceID: Twitter.Entity.Trend.Place.ID? {
        switch viewModel.trendGroupIndex {
        case .twitter(let placeID):
            return placeID
        default:
            return nil
        }
    }
    
    var searchResults: [Twitter.Entity.Trend.Place] {
        if viewModel.searchText.isEmpty {
            return viewModel.twitterTrendPlaces
        } else {
            return viewModel.twitterTrendPlaces.filter { place in
                place.name.lowercased().contains(viewModel.searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                TrendPlaceViewRow(
                    title: L10n.Scene.Trends.worldWideWithoutPrefix,
                    isSelected: 1 == activePlaceID,
                    action: {
                        viewModel.resetTrendGroupIndex()
                    }
                )
            } header: {
                Color.clear.frame(height: 16)
            }
            Section {
                if viewModel.twitterTrendPlaces.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    if searchResults.isEmpty {
                        HStack {
                            Spacer()
                            Text(L10n.Common.Controls.List.noResults)
                                .font(.callout)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                ForEach(searchResults) { place in
                    TrendPlaceViewRow(
                        title: place.name,
                        isSelected: place.id == activePlaceID,
                        action: {
                            viewModel.updateTrendGroupIndex(place: place)
                        }
                    )
                }
            }
        }   // end List
    }
    
}

struct TrendPlaceViewRow: View {
    
    let title: String
    let isSelected: Bool
    let action: () -> ()
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
    
}
