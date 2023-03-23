//
//  PollOptionView+ViewModel.swift
//  
//
//  Created by MainasuK on 2021-12-8.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import TwidereAsset
import TwitterMeta
import MastodonMeta
import TwidereCore

//extension PollOptionView {
//    
//    static let percentageFormatter: NumberFormatter = {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .percent
//        formatter.maximumFractionDigits = 1
//        formatter.minimumIntegerDigits = 1
//        formatter.roundingMode = .down
//        return formatter
//    }()
//    
//    public final class ViewModel: ObservableObject {
//        var disposeBag = Set<AnyCancellable>()
//        var observations = Set<NSKeyValueObservation>()
//        var objects = Set<NSManagedObject>()
//        
//        @Published var authenticationContext: AuthenticationContext?
//        
//        @Published var style: PollOptionView.Style?
//        
//        @Published public var content: String = ""          // for edit style
//        
//        @Published public var metaContent: MetaContent?     // for plain style
//        @Published public var percentage: Double?
//        
//        @Published public var isExpire: Bool = false
//        @Published public var isMultiple: Bool = false
//        @Published public var isSelect: Bool? = false       // nil for server not return selection array
//        @Published public var isPollVoted: Bool = false
//        @Published public var isMyPoll: Bool = false
//        
//        // output
//        @Published public var corner: Corner = .none
//        @Published public var stripProgressTinitColor: UIColor = .clear
//        @Published public var selectImageTintColor: UIColor = Asset.Colors.hightLight.color
//        @Published public var isReveal: Bool = false
//        
//        @Published public var groupedAccessibilityLabel = ""
//
//        init() {
//            // corner
//            $isMultiple
//                .map { $0 ? .radius(8) : .circle }
//                .assign(to: &$corner)
//            // stripProgressTinitColor
//            Publishers.CombineLatest3(
//                $style,
//                $isSelect,
//                $isReveal
//            )
//            .map { style, isSelect, isReveal -> UIColor in
//                guard case .plain = style else { return .clear }
//                guard isReveal else {
//                    return .clear
//                }
//                
//                if isSelect == true {
//                    return Asset.Colors.hightLight.color.withAlphaComponent(0.75)
//                } else {
//                    return Asset.Colors.hightLight.color.withAlphaComponent(0.20)
//                }
//            }
//            .assign(to: &$stripProgressTinitColor)
//            // selectImageTintColor
//            Publishers.CombineLatest(
//                $isSelect,
//                $isReveal
//            )
//            .map { isSelect, isReveal in
//                guard let isSelect = isSelect else {
//                    return .clear       // none selection state
//                }
//                
//                if isReveal {
//                    return isSelect ? .white : .clear
//                } else {
//                    return Asset.Colors.hightLight.color
//                }
//            }
//            .assign(to: &$selectImageTintColor)
//            // isReveal
//            Publishers.CombineLatest3(
//                $isExpire,
//                $isPollVoted,
//                $isMyPoll
//            )
//            .map { isExpire, isPollVoted, isMyPoll in
//                return isExpire || isPollVoted || isMyPoll
//            }
//            .assign(to: &$isReveal)
//            // groupedAccessibilityLabel
//
//            Publishers.CombineLatest3(
//                $metaContent,
//                $percentage,
//                $isReveal
//            )
//            .map { metaContent, percentage, isReveal -> String in
//                var strings: [String?] = []
//                
//                metaContent.flatMap { strings.append($0.string) }
//                
//                if isReveal,
//                    let percentage = percentage,
//                    let string = PollOptionView.percentageFormatter.string(from: NSNumber(value: percentage))
//                {
//                    strings.append(string)
//                }
//                
//                return strings.compactMap { $0 }.joined(separator: ", ")
//            }
//            .assign(to: &$groupedAccessibilityLabel)
//        }
//        
//        public enum Corner: Hashable {
//            case none
//            case circle
//            case radius(CGFloat)
//        }
//    }
//}
//
//extension PollOptionView.ViewModel {
//    public func bind(view: PollOptionView) {
//        // content
//        NotificationCenter.default
//            .publisher(for: UITextField.textDidChangeNotification, object: view.textField)
//            .receive(on: DispatchQueue.main)
//            .map { _ in view.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
//            .assign(to: &$content)
//        // metaContent
//        $metaContent
//            .sink { metaContent in
//                guard let metaContent = metaContent else {
//                    view.titleMetaLabel.reset()
//                    return
//                }
//                view.titleMetaLabel.configure(content: metaContent)
//            }
//            .store(in: &disposeBag)
//        // percentage
//        Publishers.CombineLatest(
//            $isReveal,
//            $percentage
//        )
//        .sink { isReveal, percentage in
//            guard isReveal else {
//                view.percentageMetaLabel.configure(content: PlaintextMetaContent(string: ""))
//                return
//            }
//            
//            let oldPercentage = self.percentage
//            
//            let animated = oldPercentage != nil && percentage != nil
//            view.stripProgressView.setProgress(percentage ?? 0, animated: animated)
//            
//            guard let percentage = percentage,
//                  let string = PollOptionView.percentageFormatter.string(from: NSNumber(value: percentage))
//            else {
//                view.percentageMetaLabel.configure(content: PlaintextMetaContent(string: ""))
//                return
//            }
//            
//            view.percentageMetaLabel.configure(content: PlaintextMetaContent(string: string))
//        }
//        .store(in: &disposeBag)
//        // corner
//        $corner
//            .removeDuplicates()
//            .sink { _ in
//                view.setNeedsLayout()
//            }
//            .store(in: &disposeBag)
//        // backgroundColor
//        $stripProgressTinitColor
//            .map { $0 as UIColor? }
//            .assign(to: \.tintColor, on: view.stripProgressView)
//            .store(in: &disposeBag)
//        // selectionImageView
//        Publishers.CombineLatest4(
//            $style,
//            $isMultiple,
//            $isSelect,
//            $isReveal
//        )
//        .map { style, isMultiple, isSelect, isReveal -> UIImage? in
//            guard case .plain = style else { return nil }
//            
//            func circle(isSelect: Bool) -> UIImage {
//                let image = isSelect ? Asset.Indices.checkmarkCircleFill.image : Asset.Indices.circle.image
//                return image.withRenderingMode(.alwaysTemplate)
//            }
//            
//            func square(isSelect: Bool) -> UIImage {
//                let image = isSelect ? Asset.Indices.checkmarkSquareFill.image : Asset.Indices.square.image
//                return image.withRenderingMode(.alwaysTemplate)
//            }
//            
//            func image(isMultiple: Bool, isSelect: Bool) -> UIImage {
//                return isMultiple ? square(isSelect: isSelect) : circle(isSelect: isSelect)
//            }
//            
//            if isReveal {
//                guard isSelect == true else {
//                    // not display image when isReveal:
//                    // - the server not return selection state
//                    // - the user not select
//                    return nil
//                }
//                return image(isMultiple: isMultiple, isSelect: true)
//            } else {
//                return image(isMultiple: isMultiple, isSelect: isSelect == true)
//            }
//        }
//        .sink { image in
//            view.selectionImageView.image = image
//        }
//        .store(in: &disposeBag)
//        // selectImageTintColor
//        $selectImageTintColor
//            .assign(to: \.tintColor, on: view.selectionImageView)
//            .store(in: &disposeBag)
//        // accessibility
//        $isSelect
//            .sink { isSelect in
//                if isSelect == true {
//                    view.accessibilityTraits.insert(.selected)
//                } else {
//                    view.accessibilityTraits.remove(.selected)
//                }
//            }
//            .store(in: &disposeBag)
//        $groupedAccessibilityLabel
//            .sink { groupedAccessibilityLabel in
//                view.accessibilityLabel = groupedAccessibilityLabel
//            }
//            .store(in: &disposeBag)
//    }
//}
