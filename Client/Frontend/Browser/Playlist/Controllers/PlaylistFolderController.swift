// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveUI
import CoreData
import Data
import SwiftUI
import Shared

private let log = Logger.browserLogger

private enum Section: Int, CaseIterable {
    case savedItems
    case folders
}

class PlaylistFolderController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let savedFolder = PlaylistFolder.getFolder(uuid: PlaylistFolder.savedFolderUUID)
    private let othersFRC = PlaylistFolder.frc(savedFolder: false)
    
    var onFolderSelected: ((_ playlistFolder: PlaylistFolder?) -> Void)?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        title = Strings.PlayList.playListSectionTitle
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .dark
        
        do {
            try othersFRC.performFetch()
        } catch {
            print("Error: \(error)")
        }
        
        let toolbar = UIToolbar().then {
            $0.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(title: "New Folder", style: .done, target: self, action: #selector(onNewFolder(_:)))
            ]
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDonePressed(_:)))
        
        view.addSubview(tableView)
        view.addSubview(toolbar)
        tableView.snp.makeConstraints {
            $0.leading.trailing.top.equalTo(view.safeAreaLayoutGuide)
        }
        
        toolbar.snp.makeConstraints {
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.top.equalTo(tableView.snp.bottom)
        }
        
        tableView.do {
            $0.register(PlaylistFolderCell.self)
            $0.dataSource = self
            $0.delegate = self
            $0.dragDelegate = self
            $0.dropDelegate = self
            $0.dragInteractionEnabled = true
        }
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reload the table when visible
        othersFRC.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Avoid reloading the table while in the background
        othersFRC.delegate = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Reload the table only when completely visible
        tableView.reloadData()
    }
    
    @objc
    private func onDonePressed(_ button: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
}

extension PlaylistFolderController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            return 0
        }
        
        switch section {
        case .savedItems: return 1
        case .folders: return othersFRC.fetchedObjects?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as PlaylistFolderCell
        guard let section = Section(rawValue: indexPath.section) else {
            return cell
        }
        
        switch section {
        case .savedItems:
            cell.titleLabel.text = "Saved"
            cell.subtitleLabel.text = "\(savedFolder?.playlistItems?.count ?? 0) Items"
        case .folders:
            guard let folder = othersFRC.fetchedObjects?[safe: indexPath.row] else {
                return cell
            }
            
            cell.titleLabel.text = folder.title
            cell.subtitleLabel.text = "\(folder.playlistItems?.count ?? 0) Items"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        52
    }
}

extension PlaylistFolderController: UITableViewDelegate {
    @objc
    func onNewFolder(_ button: UIBarButtonItem) {
        var playlistFolder = PlaylistNewFolderView()
        playlistFolder.onCancelButtonPressed = { [weak self] in
            self?.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        
        playlistFolder.onCreateFolder = { [weak self] folderTitle, selectedItems in
            guard let self = self else { return }
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            
            PlaylistFolder.addFolder(title: folderTitle) { uuid in
                PlaylistItem.moveItems(items: selectedItems, to: uuid)
                
                DispatchQueue.main.async {
                    do {
                        try self.othersFRC.performFetch()
                    } catch {
                        log.error("Error Reloading Table: \(error)")
                    }
                    
                    self.tableView.reloadData()
                }
            }
        }

        present(UIHostingController(rootView: playlistFolder.environment(\.managedObjectContext, DataController.swiftUIContext)),
                animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let section = Section(rawValue: indexPath.section) else {
            return nil
        }
        
        switch section {
        case .savedItems:
            return savedFolder?.playlistItems?.count == 0 ? nil : indexPath
        case .folders:
            let folder = othersFRC.fetchedObjects?[safe: indexPath.row]
            return folder?.playlistItems?.count != 0 ? indexPath : nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else {
            return
        }
        
        switch section {
        case .savedItems:
            onFolderSelected?(savedFolder)
        case .folders:
            onFolderSelected?(othersFRC.fetchedObjects?[safe: indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard let section = Section(rawValue: indexPath.section) else {
            return nil
        }
        
        let deleteAction = UIContextualAction(style: .normal, title: nil, handler: { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            switch section {
            case .savedItems:
                break
            case .folders:
                guard let folder = self.othersFRC.fetchedObjects?[safe: indexPath.row] else {
                    completionHandler(false)
                    return
                }
                
                if PlaylistManager.shared.currentFolder?.objectID == folder.objectID {
                    PlaylistManager.shared.currentFolder = nil
                }
                
                PlaylistFolder.removeFolder(folder)
                
                do {
                    try self.othersFRC.performFetch()
                } catch {
                    print("Error: \(error)")
                }
                
                if PlaylistManager.shared.currentFolder?.isDeleted == true {
                    PlaylistManager.shared.currentFolder = nil
                }
                
                tableView.reloadData()
            }
            
            completionHandler(true)
        })
        
        deleteAction.image = #imageLiteral(resourceName: "playlist_delete_item")
        deleteAction.backgroundColor = UIColor.braveErrorLabel
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension PlaylistFolderController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if parent != nil, tableView.hasActiveDrag || tableView.hasActiveDrop { return }
        
        var indexPath = indexPath
        var newIndexPath = newIndexPath
        
        indexPath?.section = Section.folders.rawValue
        newIndexPath?.section = Section.folders.rawValue
        
        switch type {
            case .insert:
                guard let newIndexPath = newIndexPath else { break }
                tableView.insertRows(at: [newIndexPath], with: .fade)
            case .delete:
                guard let indexPath = indexPath else { break }
                tableView.deleteRows(at: [indexPath], with: .fade)
            case .update:
                guard let indexPath = indexPath else { break }
                tableView.reloadRows(at: [indexPath], with: .fade)
            case .move:
                guard let indexPath = indexPath,
                      let newIndexPath = newIndexPath else { break }
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.insertRows(at: [newIndexPath], with: .fade)
            default:
                break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if parent != nil, tableView.hasActiveDrag || tableView.hasActiveDrop { return }
        tableView.endUpdates()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if parent != nil, tableView.hasActiveDrag || tableView.hasActiveDrop { return }
        tableView.beginUpdates()
    }
}

// MARK: - Reordering of cells

extension PlaylistFolderController: UITableViewDragDelegate, UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let section = Section(rawValue: indexPath.section) else {
            return false
        }
        return section == .folders
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        if sourceIndexPath.section != destinationIndexPath.section {
            return
        }
        
        var sourceIndexPath = sourceIndexPath
        var destinationIndexPath = destinationIndexPath
        sourceIndexPath.section = 0
        destinationIndexPath.section = 0
        
        reorderItems(from: sourceIndexPath, to: destinationIndexPath) { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.othersFRC.performFetch()
            } catch {
                log.error("Error Reloading Data: \(error)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        if indexPath.section != Section.folders.rawValue {
            return []
        }
        
        let item = othersFRC.fetchedObjects?[safe: indexPath.row]
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = item
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {

        var dropProposal = UITableViewDropProposal(operation: .cancel)
        guard session.items.count == 1 else { return dropProposal }
        
        if destinationIndexPath?.section != Section.folders.rawValue {
            return dropProposal
        }
        
        if tableView.hasActiveDrag {
            dropProposal = UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return dropProposal
    }
        
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let sourceIndexPath = coordinator.items.first?.sourceIndexPath else {
            return
        }
        
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        guard let section = Section(rawValue: destinationIndexPath.section),
              section == .folders else {
            return
        }
        
        if coordinator.proposal.operation == .move {
            guard let item = coordinator.items.first else { return }
            _ = coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
            tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistFolderCell else { return nil }
        
        let preview = UIDragPreviewParameters()
        preview.visiblePath = UIBezierPath(roundedRect: cell.contentView.frame, cornerRadius: 12.0)
        preview.backgroundColor = UIColor.braveBackground.slightlyLighterColor
        return preview
    }

    func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistFolderCell else { return nil }
        
        let preview = UIDragPreviewParameters()
        preview.visiblePath = UIBezierPath(roundedRect: cell.contentView.frame, cornerRadius: 12.0)
        preview.backgroundColor = UIColor.braveBackground.slightlyLighterColor
        return preview
    }
    
    func tableView(_ tableView: UITableView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        true
    }
    
    func reorderItems(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath, completion: (() -> Void)?) {
        guard var objects = othersFRC.fetchedObjects else {
            ensureMainThread {
                completion?()
            }
            return
        }

        othersFRC.managedObjectContext.perform { [weak self] in
            defer {
                ensureMainThread {
                    completion?()
                }
            }
            
            guard let self = self else { return }
            
            let src = self.othersFRC.object(at: sourceIndexPath)
            objects.remove(at: sourceIndexPath.row)
            objects.insert(src, at: destinationIndexPath.row)
            
            for (order, item) in objects.enumerated().reversed() {
                item.order = Int32(order)
            }
            
            do {
                try self.othersFRC.managedObjectContext.save()
            } catch {
                log.error(error)
            }
        }
    }
}
