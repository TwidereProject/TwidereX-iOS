//
//  ComposeContentViewController.swift
//  
//
//  Created by MainasuK on 2021/11/17.
//

import os.log
import UIKit
import Combine
import MetaTextKit
import PhotosUI

public final class ComposeContentViewController: UIViewController {
    
    let logger = Logger(subsystem: "ComposeContentViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    public var viewModel: ComposeContentViewModel!
        
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        return tableView
    }()
    
    let composeToolbarBackgroundView = UIView()
    let composeToolbarView = ComposeToolbarView()
    
}

extension ComposeContentViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDiffableDataSource(
            tableView: tableView
        )
        
        composeToolbarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(composeToolbarBackgroundView)
        NSLayoutConstraint.activate([
            composeToolbarBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composeToolbarBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composeToolbarBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        composeToolbarView.translatesAutoresizingMaskIntoConstraints = false
        composeToolbarView.preservesSuperviewLayoutMargins = true
        view.addSubview(composeToolbarView)
        NSLayoutConstraint.activate([
            composeToolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composeToolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.keyboardLayoutGuide.topAnchor.constraint(equalTo: composeToolbarView.bottomAnchor),
            composeToolbarBackgroundView.topAnchor.constraint(equalTo: composeToolbarView.topAnchor).priority(.defaultHigh),
        ])
        
        composeToolbarBackgroundView.backgroundColor = .secondarySystemBackground
        composeToolbarView.backgroundColor = .secondarySystemBackground
        
        composeToolbarView.delegate = self
        viewModel.composeInputTableViewCell.metaText.delegate = self
        viewModel.composeAttachmentTableViewCell.delegate = self
        
//        view.keyboardLayoutGuide.setConstraints([
//
//        ], activeWhenAwayFrom: .top)
//        view.keyboardLayoutGuide.setConstraints([
//
//        ], activeWhenNearEdge: .top)
        
        viewModel.$attachmentViewModels
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.makeTableViewUpdate()
            }
            .store(in: &disposeBag)
        
        viewModel.$isMediaToolBarButtonEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMediaToolBarButtonEnabled in
                guard let self = self else { return }
                self.composeToolbarView.mediaButton.isEnabled = isMediaToolBarButtonEnabled
            }
            .store(in: &disposeBag)
    }
    
}

extension ComposeContentViewController {
    private func createPhotoLibraryPicker() -> PHPickerViewController {
        let configuration: PHPickerConfiguration = {
            var configuration = PHPickerConfiguration()
            configuration.filter = .any(of: [.images, .videos])
            configuration.selectionLimit = viewModel.maxMediaAttachmentLimit - viewModel.attachmentViewModels.count
            return configuration
        }()
        let imagePicker = PHPickerViewController(configuration: configuration)
        imagePicker.delegate = self
        return imagePicker
    }
    
    private func makeTableViewUpdate() {
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ComposeContentViewController: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        let newAttachmentViewModels = results.map { result in
            AttachmentViewModel(input: .pickerResult(result))
        }
        viewModel.attachmentViewModels.append(contentsOf: newAttachmentViewModels)
    }
}

// MARK: - UITableViewDelegate
extension ComposeContentViewController: UITableViewDelegate {

}

// MARK: - ComposeToolbarViewDelegate
extension ComposeContentViewController: ComposeToolbarViewDelegate {
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, mediaButtonPressed button: UIButton, mediaSelectionType type: ComposeToolbarView.MediaSelectionType) {
        switch type {
        case .camera:
            break
        case .photoLibrary:
            present(createPhotoLibraryPicker(), animated: true, completion: nil)
        case .browse:
            break
        }
    }

    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, emojiButtonPressed button: UIButton) {
        
    }
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, pollButtonPressed button: UIButton) {
        
    }
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, mentionButtonPressed button: UIButton) {
        
    }
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, hashtagButtonPressed button: UIButton) {
        
    }
    
    public func composeToolBarView(_ composeToolBarView: ComposeToolbarView, localButtonPressed button: UIButton) {
        
    }
}

// MARK: - MetaTextDelegate
extension ComposeContentViewController: MetaTextDelegate {
    public func metaText(_ metaText: MetaText, processEditing textStorage: MetaTextStorage) -> MetaContent? {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        defer {
            DispatchQueue.main.async {
                self.makeTableViewUpdate()
            }
        }
        
        return nil 
    }
}

// MARK: - ComposeAttachmentTableViewCellDelegate
extension ComposeContentViewController: ComposeAttachmentTableViewCellDelegate {
    public func composeAttachmentTableViewCell(_ cell: ComposeAttachmentTableViewCell, contextMenuAction: ComposeAttachmentTableViewCell.ContextMenuAction, for item: ComposeAttachmentTableViewCell.Item) {
        switch contextMenuAction {
        case .remove:
            switch item {
            case .attachment(let attachmentViewModel):
                viewModel.attachmentViewModels.removeAll(where: { $0 === attachmentViewModel })
            }
        }   // end switch contextMenuAction { … }
    }
}
