//
//  TimeIntervalPicker.swift
//  
//
//  Created by MainasuK on 2022-5-25.
//

import UIKit
import SwiftUI

struct TimeIntervalPicker: UIViewRepresentable {
    
    @Binding var dateComponents: DateComponents

    func makeUIView(context: Context) -> UIPickerView {
        let pickerView = UIPickerView()
        pickerView.dataSource = context.coordinator
        pickerView.delegate = context.coordinator
        TimeIntervalPicker.configure(pickerView, dateComponents: dateComponents, animated: false)
        return pickerView
    }

    func updateUIView(_ pickerView: UIPickerView, context: Context) {
        TimeIntervalPicker.configure(pickerView, dateComponents: dateComponents, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        private let view: TimeIntervalPicker

        init(_ view: TimeIntervalPicker) {
            self.view = view
        }
    }
    
    static func configure(_ pickerView: UIPickerView, dateComponents: DateComponents, animated: Bool) {
        let day = dateComponents.day ?? 0
        let hour = dateComponents.hour ?? 0
        let minute = dateComponents.minute ?? 0
        
        pickerView.selectRow(day, inComponent: Coordinator.Component.day.rawValue, animated: true)
        pickerView.selectRow(hour, inComponent: Coordinator.Component.hour.rawValue, animated: true)
        pickerView.selectRow(minute, inComponent: Coordinator.Component.minute.rawValue, animated: true)
    }
}

// MARK: - UIPickerViewDataSource
extension TimeIntervalPicker.Coordinator: UIPickerViewDataSource {
    
    enum Component: Int, CaseIterable {
        case day
        case hour
        case minute
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return Component.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch Component.allCases[component] {
        case .day:      return 7 + 1    // 0...7
        case .hour:     return 24       // 0..<24
        case .minute:   return 60       // 0..<60
        }
    }
    
}

// MARK: - UIPickerViewDelegate
extension TimeIntervalPicker.Coordinator: UIPickerViewDelegate {
    
    func pickerView(
        _ pickerView: UIPickerView,
        titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        return "\(row)"
    }
    
    func pickerView(
        _ pickerView: UIPickerView,
        didSelectRow row: Int,
        inComponent component: Int
    ) {
        switch Component.allCases[component] {
        case .day:
            view.dateComponents.day = row
        case .hour:
            view.dateComponents.hour = row
        case .minute:
            view.dateComponents.minute = row
        }
        
        // check invalid condition and reset it
        let day = view.dateComponents.day ?? 0
        let hour = view.dateComponents.hour ?? 0
        let minute = view.dateComponents.minute ?? 0
        if day == .zero, hour == .zero, minute == .zero {
            view.dateComponents.day = 1
            TimeIntervalPicker.configure(pickerView, dateComponents: view.dateComponents, animated: true)
        }
        if day == 7 {
            view.dateComponents.hour = 0
            view.dateComponents.minute = 0
            TimeIntervalPicker.configure(pickerView, dateComponents: view.dateComponents, animated: true)
        }
    }
    
}
