//
//  FoldersWindowController+MenuDelegate.swift
//  VisualDiffer
//
//  Created by davide ficano on 11/07/25.
//  Copyright (c) 2025 visualdiffer.com
//

import Quartz

extension FoldersWindowController: NSMenuDelegate,
    NSMenuItemValidation,
    TableViewContextMenuDelegate {
    // swiftlint:disable:next function_body_length
    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if running {
            return false
        }
        if isPathControlMenu(menuItem.tag) {
            return true
        }
        let action = menuItem.action
        let fsi = lastUsedView.selectionInfo

        if action == #selector(toggleFilteredFiles) {
            if showFilteredFiles {
                menuItem.title = NSLocalizedString("Hide Filtered Files", comment: "")
            } else {
                menuItem.title = NSLocalizedString("Show Filtered Files", comment: "")
            }
            return true
        } else if action == #selector(setLeftReadOnly) {
            menuItem.state = sessionDiff.leftReadOnly ? .on : .off
            return true
        } else if action == #selector(setRightReadOnly) {
            menuItem.state = sessionDiff.rightReadOnly ? .on : .off
            return true
        } else if action == #selector(expandSelectedSubfolders) {
            return fsi.validateExpandSelectedSubfolders()
        } else if action == #selector(showInFinder) {
            return fsi.validateShowInFinder()
        } else if action == #selector(copyFiles) {
            switch fsi.view.side {
            case .left:
                menuItem.title = NSLocalizedString("Copy to Right...", comment: "")
            case .right:
                menuItem.title = NSLocalizedString("Copy to Left...", comment: "")
            }
            return fsi.validateCopyFiles(sessionDiff)
        } else if action == #selector(deleteFiles) {
            return fsi.validateDeleteFiles(sessionDiff)
        } else if action == #selector(copyFullPaths) || action == #selector(copyFileNames) || action == #selector(copy(_:)) || action == #selector(copyUrls) {
            return fsi.validateClipboardCopy()
        } else if action == #selector(setAsBaseFolder) {
            return fsi.validateSetAsBaseFolder()
        } else if action == #selector(setAsBaseFolderOtherSide) {
            return fsi.validateSetAsBaseFolderOtherSide()
        } else if action == #selector(setAsBaseFoldersBothSides) {
            return fsi.validateSetAsBaseFoldersBothSides()
        } else if action == #selector(compareFiles) {
            return fsi.validateCompareFiles()
        } else if action == #selector(excludeByName) {
            var fileName: String? = ""
            if !fsi.validateExclude(byName: &fileName) {
                return false
            }
            if let fileName {
                menuItem.title = String(format: NSLocalizedString("Exclude '%@'", comment: ""), fileName)
            }
            return true
        } else if action == #selector(excludeByExt) {
            var excludedExt: String? = ""
            let isValid = fsi.validateExclude(byExt: &excludedExt)
            if isValid,
               let excludedExt {
                menuItem.title = String(format: NSLocalizedString("Exclude all '*.%@'", comment: ""), excludedExt)
            }
            return isValid
        } else if action == #selector(syncFiles) {
            switch fsi.view.side {
            case .left:
                menuItem.title = NSLocalizedString("Sync to Right...", comment: "")
            case .right:
                menuItem.title = NSLocalizedString("Sync to Left...", comment: "")
            }
            return fsi.validateSyncFiles(sessionDiff)
        } else if action == #selector(showEmptyFolders) {
            if hideEmptyFolders {
                menuItem.title = NSLocalizedString("Show Empty Folders", comment: "")
            } else {
                menuItem.title = NSLocalizedString("Hide Empty Folders", comment: "")
            }
            return true
        } else if action == #selector(popupOpenWithApp) {
            var selectedPath: String? = ""
            let isValid = fsi.validateOpen(withApp: &selectedPath)

            if isValid {
                let url: URL? = if let selectedPath {
                    URL(filePath: selectedPath)
                } else {
                    nil
                }
                menuItem.menu?.setSubmenu(
                    NSMenu.appsMenuForFile(
                        url,
                        openAppAction: #selector(openWithApp),
                        openOtherAppAction: #selector(openWithOther)
                    ),
                    for: menuItem
                )
            }
            return isValid
        } else if action == #selector(findNext) {
            return scopeBar.findView.hasMatches
        } else if action == #selector(findPrevious) {
            return scopeBar.findView.hasMatches
        } else if action == #selector(compareFolders) {
            return fsi.validateCompareFolders()
        } else if action == #selector(moveFiles) {
            switch fsi.view.side {
            case .left:
                menuItem.title = NSLocalizedString("Move to Right...", comment: "")
            case .right:
                menuItem.title = NSLocalizedString("Move to Left...", comment: "")
            }
            return fsi.validateMoveFiles(sessionDiff)
        } else if action == #selector(setModificationDate) {
            return fsi.validateFileTouch(sessionDiff)
        } else if action == #selector(toggleLogConsole) {
            if consoleSplitter.hasSubviewCollapsed {
                menuItem.title = NSLocalizedString("Show Log Console", comment: "")
            } else {
                menuItem.title = NSLocalizedString("Hide Log Console", comment: "")
            }
            return true
        } else if action == #selector(togglePreviewPanel) {
            if QLPreviewPanel.sharedPreviewPanelExists(), QLPreviewPanel.shared().isVisible {
                menuItem.title = NSLocalizedString("Close Quick Look", comment: "")
            } else {
                menuItem.title = NSLocalizedString("Quick Look", comment: "")
            }
            return fsi.validatePreviewPanel()
        }
        return true
    }

    // MARK: - Menu Delegate

    public func menuNeedsUpdate(_ menu: NSMenu) {
        if menu.identifier == .Folders.openWithToolbarMenu {
            // preserve root item
            let root = menu.item(at: 0)
            menu.removeAllItems()
            if let root {
                menu.addItem(root)
            }
            let row = lastUsedView.selectedRow
            if row >= 0,
               let vi = lastUsedView.item(atRow: row) as? VisibleItem {
                menu.addMenuItemsForFile(
                    vi.item.toUrl(),
                    openAppAction: #selector(openWithApp),
                    openOtherAppAction: #selector(openWithOther)
                )
            }
        }
    }

    // MARK: - TableViewContextMenuDelegate

    func tableView(_ tableView: NSTableView, menuItem: NSMenuItem, hideMenuItem hide: inout Bool) -> Bool {
        if running {
            return false
        }
        guard let folderView = tableView as? FoldersOutlineView else {
            return false
        }
        let action = menuItem.action

        hide = true

        let isValid = validateMenuItem(menuItem)
        if action == #selector(copyFiles) {
            // make menu visible but disabled only if it's readonly
            if !isValid {
                let isReadOnly = switch folderView.side {
                case .left:
                    sessionDiff.rightReadOnly
                case .right:
                    sessionDiff.leftReadOnly
                }
                if isReadOnly {
                    hide = false
                }
            }
        } else if action == #selector(deleteFiles) {
            // make menu visible but disabled only if it's readonly
            if !isValid {
                let isReadOnly = switch folderView.side {
                case .left:
                    sessionDiff.leftReadOnly
                case .right:
                    sessionDiff.rightReadOnly
                }
                if isReadOnly {
                    hide = false
                }
            }
        } else if action == #selector(moveFiles) {
            // make menu visible but disabled only if it's readonly
            if !isValid {
                let isReadOnly = switch folderView.side {
                case .left:
                    sessionDiff.rightReadOnly
                case .right:
                    sessionDiff.leftReadOnly
                }
                if isReadOnly {
                    hide = false
                }
            }
        }

        return isValid
    }
}
