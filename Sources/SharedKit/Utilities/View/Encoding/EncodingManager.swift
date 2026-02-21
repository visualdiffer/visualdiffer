//
//  EncodingManager.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/11/12.
//  Copyright (c) 2012 visualdiffer.com
//

import Foundation
import CoreFoundation

private let encodingsPrefName = "userEncodings"
private let encodingSeparator = String.Encoding(rawValue: UInt.max)

let defaultStringsEncodings: [String.Encoding] = [
    .utf8,
    .utf16,
    encodingSeparator,
    .utf16BigEndian,
    .utf16LittleEndian,
    encodingSeparator,
    .macOSRoman,
    .windowsCP1252,
    .isoLatin1,
    CFStringEncodings.isoLatin9.stringEncoding,
    CFStringEncodings.dosLatinUS.stringEncoding,
    encodingSeparator,
    CFStringEncodings.macJapanese.stringEncoding,
    CFStringEncodings.shiftJIS.stringEncoding,
    CFStringEncodings.macChineseTrad.stringEncoding,
    CFStringEncodings.macKorean.stringEncoding,
    CFStringEncodings.macChineseSimp.stringEncoding,
].compactMap(\.self)

@MainActor
class EncodingManager: NSObject, @unchecked Sendable {
    static let listNotification = Notification.Name("EncodingsListChanged")

    static let shared = EncodingManager()

    override private init() {}

    private lazy var stickyStringEncodings: [String.Encoding] = createStickyEncodings()
    private lazy var allEncodings: [String.Encoding] = allAvailableStringEncodings()
    private var popupEncodingsList: [String.Encoding]?

    private var encodingPanel: SelectEncodingsPanel?

    func setupPopUpCell(
        _ popup: EncodingPopUpButtonCell,
        selectedEncoding: String.Encoding,
        withDefaultEntry _: Bool
    ) {
        var itemToSelect = 0

        // Put the encodings in the popup
        popup.removeAllItems()

        for encoding in enabledEncodingsGroups() {
            if encoding == encodingSeparator {
                popup.menu?.addItem(NSMenuItem.separator())
            } else {
                popup.addItem(withTitle: String.localizedName(of: encoding))

                popup.lastItem?.representedObject = NSNumber(value: encoding.rawValue)
                popup.lastItem?.isEnabled = true
                if encoding == selectedEncoding {
                    itemToSelect = popup.numberOfItems - 1
                }
            }
        }

        // Add an optional separator and "customize" item at end
        if popup.numberOfItems > 0 {
            popup.menu?.addItem(NSMenuItem.separator())
        }
        popup.addItem(withTitle: NSLocalizedString("Other...", comment: ""))
        popup.lastItem?.action = #selector(showPanel)
        popup.lastItem?.target = self

        popup.selectItem(at: itemToSelect)
    }

    @objc
    func showPanel(_ sender: AnyObject) {
        if encodingPanel == nil {
            encodingPanel = SelectEncodingsPanel.createSheet()
            encodingPanel?.onClose = onClose

            // Initialize the list (only need to do this once)
            setupEncodingsList()
        }
        guard let encodingPanel else {
            return
        }
        if encodingPanel.isVisible {
            encodingPanel.makeKeyAndOrderFront(sender)
            return
        }
        NSApp.keyWindow?.beginSheet(encodingPanel)
    }

    func onClose(_ response: NSApplication.ModalResponse, _ selectedEncodings: [String.Encoding]) {
        if response == .OK {
            noteEncodingListChange(selectedEncodings, updateList: false, postNotification: true)
        }
    }

    private func enabledEncodingsGroups() -> [String.Encoding] {
        if let popupEncodingsList {
            return popupEncodingsList
        }
        let list = createPopupEncodingList()
        popupEncodingsList = list

        return list
    }

    /**
     * Return a sorted list of all available string encodings.
     **/
    func allAvailableStringEncodings() -> [String.Encoding] {
        var nameEncodings = [[String.Encoding: String]]()
        guard let cfEncodings = CFStringGetListOfAvailableEncodings() else {
            return []
        }
        var index = 0

        while true {
            let enc = cfEncodings[index]

            if enc == kCFStringEncodingInvalidId {
                break
            }
            if let nsEncoding = (enc as CFStringEncoding).stringEncoding {
                nameEncodings.append([nsEncoding: String.localizedName(of: nsEncoding)])
            }

            index += 1
        }

        nameEncodings.sort {
            if let name1 = $0.values.first,
               let name2 = $1.values.first {
                return name1 < name2
            }
            return false
        }

        var allEncodings = [String.Encoding]()
        allEncodings.reserveCapacity(nameEncodings.count)
        for dict in nameEncodings {
            if let key = dict.keys.first {
                allEncodings.append(key)
            }
        }

        return allEncodings
    }

    func setupEncodingsList() {
        var all = allEncodings

        // remove encodings present on sticky list
        for encoding in stickyStringEncodings.reversed() {
            if let index = all.firstIndex(of: encoding) {
                all.remove(at: index)
            }
        }
        encodingPanel?.encodingsList = all

        noteEncodingListChange(nil, updateList: true, postNotification: false)
    }

    func noteEncodingListChange(
        _ listToWrite: [String.Encoding]?,
        updateList: Bool,
        postNotification post: Bool
    ) {
        if let listToWrite {
            saveEncodings(listToWrite)
            popupEncodingsList = nil
        }

        if updateList, let encodingPanel {
            if let otherEncs = readEncodings() {
                var selected = IndexSet()
                for encoding in otherEncs {
                    if let index = encodingPanel.encodingsList.firstIndex(of: encoding) {
                        selected.insert(index)
                    }
                }
                encodingPanel.select(encodings: selected)
            }
        }

        if post {
            NotificationCenter.default.post(name: Self.listNotification, object: nil)
        }
    }

    private func createStickyEncodings() -> [String.Encoding] {
        let defaultEncoding = String.defaultCStringEncoding
        var hasDefault = false

        var encs = [String.Encoding]()

        for encSupported in defaultStringsEncodings {
            if encSupported == encodingSeparator {
                encs.append(encodingSeparator)
            } else {
                encs.append(encSupported)
                if encSupported == defaultEncoding {
                    hasDefault = true
                }
            }
        }

        if !hasDefault {
            encs.append(defaultEncoding)
        }

        return encs
    }

    private func createPopupEncodingList() -> [String.Encoding] {
        var enabledEncs = stickyStringEncodings

        if let userList = readEncodings(),
           !userList.isEmpty {
            enabledEncs.append(encodingSeparator)
            enabledEncs.append(contentsOf: userList)
        }
        return enabledEncs
    }

    private func saveEncodings(_ list: [String.Encoding]) {
        let nsNumbers = list.map {
            NSNumber(value: $0.rawValue)
        }
        UserDefaults.standard.set(nsNumbers, forKey: encodingsPrefName)
    }

    private func readEncodings() -> [String.Encoding]? {
        guard let encs = UserDefaults.standard.array(forKey: encodingsPrefName) as? [NSNumber] else {
            return nil
        }
        return encs.map {
            String.Encoding(rawValue: $0.uintValue)
        }
    }
}
