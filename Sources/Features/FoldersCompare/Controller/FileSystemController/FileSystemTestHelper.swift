//
//  FileSystemTestHelper.swift
//  VisualDiffer
//
//  Created by davide ficano on 25/12/25.
//  Copyright (c) 2025 visualdiffer.com
//

// swiftlint:disable identifier_name force_unwrapping force_try file_length line_length
#if DEBUG

    private let fakeFile = "12345678901234567890"

    private let headerPattern =
        """
        let comparatorDelegate = MockItemComparatorDelegate()
        let comparator = ItemComparator(
            options: %@,
            delegate: comparatorDelegate,
            bufferSize: 8192,
            isLeftCaseSensitive: %@,
            isRightCaseSensitive: %@
        )
        let filterConfig = FilterConfig(
            showFilteredFiles: %@,
            hideEmptyFolders: %@,
            followSymLinks: %@,
            skipPackages: %@,
            traverseFilteredFolders: %@,
            predicate: defaultPredicate,
            fileExtraOptions: [],
            displayOptions: %@
        )
        let folderReaderDelegate = MockFolderReaderDelegate(isRunning: true)
        let folderReader = FolderReader(
            with: folderReaderDelegate,
            comparator: comparator,
            filterConfig: filterConfig,
            refreshInfo: RefreshInfo(initState: true)
        )

        try removeItem("l")
        try removeItem("r")

        """

    private let readFolderPattern =
        """
                folderReader.start(
                    withLeftRoot: nil,
                    rightRoot: nil,
                    leftPath: appendFolder("l"),
                    rightPath: appendFolder("r")
                )

                let rootL = folderReader.leftRoot!
                let rootR = folderReader.rightRoot!
                let vi = rootL.visibleItem!
        """

    class FileSystemTestHelper {
        var strFolders = "// create folders\n"
        var strFiles = "// create files\n"
        var strAssert = ""
        var strAssertVisibleItems = "// VisibleItems\n"
        var leftPos = 0
        var rightPos = 0
        var childNum = 1

        var header = ""

        private static let comparatorStrings = [
            ComparatorOptions.timestamp.rawValue: ".timestamp",
            ComparatorOptions.size.rawValue: ".size",
            ComparatorOptions.content.rawValue: ".content",
            ComparatorOptions.contentTimestamp.rawValue: ".contentTimestamp",
            ComparatorOptions.asText.rawValue: ".asText",
            ComparatorOptions.finderLabel.rawValue: ".finderLabel",
            ComparatorOptions.finderTags.rawValue: ".finderTags",
            ComparatorOptions.filename.rawValue: ".filename",
            ComparatorOptions.alignFileSystemCase.rawValue: ".alignFileSystemCase",
            ComparatorOptions.alignMatchCase.rawValue: ".alignMatchCase",
            ComparatorOptions.alignIgnoreCase.rawValue: ".alignIgnoreCase",
        ]
        private static let displayFiltersStrings = [
            DisplayOptions.onlyMatches.rawValue: ".onlyMatches",
            DisplayOptions.onlyLeftSideNewer.rawValue: ".onlyLeftSideNewer",
            DisplayOptions.onlyLeftSideOrphans.rawValue: ".onlyLeftSideOrphans",
            DisplayOptions.onlyRightSideNewer.rawValue: ".onlyRightSideNewer",
            DisplayOptions.onlyRightSideOrphans.rawValue: ".onlyRightSideOrphans",
            DisplayOptions.mismatchesButNoOrphans.rawValue: ".mismatchesButNoOrphans",
            DisplayOptions.leftNewerAndLeftOrphans.rawValue: ".leftNewerAndLeftOrphans",
            DisplayOptions.rightNewerAndRightOrphans.rawValue: ".rightNewerAndRightOrphans",
            DisplayOptions.onlyMismatches.rawValue: ".onlyMismatches",
            DisplayOptions.noOrphan.rawValue: ".noOrphan",
            DisplayOptions.onlyOrphans.rawValue: ".onlyOrphans",
            DisplayOptions.showAll.rawValue: ".showAll",
            DisplayOptions.dontFollowSymlinks.rawValue: ".dontFollowSymlinks",
        ]

        private var comparatorFlags: ComparatorOptions = []

        init(sessionDiff: SessionDiff) {
            comparatorFlags = sessionDiff.comparatorOptions

            leftPos = URL(filePath: sessionDiff.leftPath!).deletingLastPathComponent().osPath.count + 1
            rightPos = URL(filePath: sessionDiff.rightPath!).deletingLastPathComponent().osPath.count + 1
            header = Self.formatHeader(sessionDiff)
        }

        private static func formatHeader(_ sessionDiff: SessionDiff) -> String {
            let leftURL = URL(filePath: sessionDiff.leftPath!)
            let rightURL = URL(filePath: sessionDiff.rightPath!)

            return String(
                format: headerPattern,
                Self.stringify(flag: sessionDiff.comparatorOptions.rawValue, stringNumberDictionary: Self.comparatorStrings),
                Self.bool2String(try! leftURL.volumeSupportsCaseSensitive()),
                Self.bool2String(try! rightURL.volumeSupportsCaseSensitive()),
                Self.bool2String(false),
                Self.bool2String(true),
                Self.bool2String(sessionDiff.followSymLinks),
                Self.bool2String(sessionDiff.skipPackages),
                Self.bool2String(sessionDiff.traverseFilteredFolders),
                Self.stringify(flag: sessionDiff.displayOptions.rawValue, stringNumberDictionary: Self.displayFiltersStrings)
            )
        }

        private static func bool2String(_ value: Bool) -> String {
            value ? "true" : "false"
        }

        private static func stringify(
            flag: Int,
            stringNumberDictionary: [Int: String]
        ) -> String {
            var orFlags = [String]()

            if let str = stringNumberDictionary[flag] {
                orFlags.append(str)
            } else {
                var currentFlag = 1
                var flag = flag

                while flag != 0 {
                    if (currentFlag & flag) != 0, let value = stringNumberDictionary[currentFlag] {
                        orFlags.append(value)
                        flag &= ~currentFlag
                    }
                    currentFlag <<= 1
                }
            }
            let stringFlags = orFlags.joined(separator: ", ")

            if orFlags.count > 1 {
                return "[\(stringFlags)]"
            }
            return stringFlags
        }

        @MainActor
        static func createTestCode(
            _ view: FoldersOutlineView,
            sessionDiff: SessionDiff
        ) {
            guard let vi = view.dataSource?.outlineView?(view, child: 0, ofItem: nil) as? VisibleItem,
                  let fs = vi.item.parent else {
                return
            }
            let testHelper = FileSystemTestHelper(sessionDiff: sessionDiff)
            testHelper.generateTest(fs)
            testHelper.generateTest(fs.visibleItem!)
            testHelper.copyTestToClipboard()
        }

        // MARK: - CompareItem generators

        private func generateTest(_ root: CompareItem) {
            childNum = 1
            generateTest(root, parentVarName: "rootL", index: 0)
        }

        private func generateTest(
            _ root: CompareItem,
            parentVarName: String,
            index: Int
        ) {
            createFolders(root)
            createAssert(root, parentVarName: parentVarName, outString: &strAssert, index: index)

            let parentName = String(format: "child%ld", childNum)
            for (index, fs) in root.children.enumerated() {
                childNum += 1

                if fs.isFolder {
                    generateTest(fs, parentVarName: parentName, index: index)
                } else {
                    createFolders(fs)
                    createAssert(fs, parentVarName: parentName, outString: &strAssert, index: index)
                }
            }
        }

        // MARK: - VisibleItem generators

        private func generateTest(_ root: VisibleItem) {
            childNum = 1

            generateTest(root, parentVarName: "vi", index: 0)
        }

        private func generateTest(
            _ root: VisibleItem,
            parentVarName: String,
            index: Int
        ) {
            let childVarName = String(format: "childVI%ld", childNum)

            // root element for simplicity is assigned to child and printed out
            if parentVarName == "vi" {
                strAssertVisibleItems.append(String(
                    format: "let %@ = vi // %@ <--> %@\n",
                    childVarName,
                    root.item.fileName!,
                    root.item.linkedItem!.fileName!
                ))
            } else {
                strAssertVisibleItems.append(String(
                    format: "let %@ = %@.children[%ld] // %@ <--> %@\n",
                    childVarName,
                    parentVarName,
                    index,
                    root.item.parent!.fileName!,
                    root.item.linkedItem!.parent!.fileName!
                ))
            }
            strAssertVisibleItems.append(String(format: "assertArrayCount(%@.children, %ld)\n", childVarName, root.children.count))
            createAssert(root, parentVarName: childVarName, outString: &strAssertVisibleItems, index: index)

            for (index, vi) in root.children.enumerated() {
                childNum += 1

                generateTest(vi, parentVarName: childVarName, index: index)
            }
        }

        // MARK: - Assert generator methods

        private func createAssert(
            _ fsOrVi: AnyObject,
            parentVarName: String,
            outString: inout String,
            index: Int
        ) {
            var fs: CompareItem
            var stringFormat = ""

            if let vi = fsOrVi as? VisibleItem {
                fs = vi.item
                stringFormat = "let child%ld = %@.item // %@ <-> %@\n"
                outString.append(String(
                    format: stringFormat,
                    childNum,
                    parentVarName,
                    fs.parent?.fileName ?? "nil",
                    fs.parent?.linkedItem?.fileName ?? "nil"
                ))
            } else if let fsOrVi = fsOrVi as? CompareItem {
                fs = fsOrVi
                if parentVarName == "rootL" {
                    stringFormat = "let child%ld = %@ // %@ <-> %@\n"
                    outString.append(String(
                        format: stringFormat,
                        childNum,
                        parentVarName,
                        fs.fileName ?? "nil",
                        fs.linkedItem?.fileName ?? "nil"
                    ))
                } else {
                    stringFormat = "let child%ld = %@.children[%ld] // %@ <-> %@\n"
                    outString.append(String(
                        format: stringFormat,
                        childNum,
                        parentVarName,
                        index,
                        fs.parent?.fileName ?? "nil",
                        fs.parent?.linkedItem?.fileName ?? "nil"
                    ))
                }
            } else {
                return
            }

            createAssert(fs, outString: &outString, linked: false)
            createAssert(fs.linkedItem!, outString: &outString, linked: true)

            outString.append("\n")
        }

        private func createAssert(
            _ fs: CompareItem,
            outString: inout String,
            linked: Bool
        ) {
            let fileName: String? = if let fileName = fs.fileName {
                String(format: "\"%@\"", fileName)
            } else {
                nil
            }

            let linkedString = linked ? ".linkedItem" : ""

            outString.append(String(
                format: "assertItem(child%ld%@, %ld, %ld, %ld, %ld, %ld, %@, .%@, %lld)\n",
                childNum,
                linkedString,
                fs.olderFiles,
                fs.changedFiles,
                fs.orphanFiles,
                fs.matchedFiles,
                fs.children.count,
                fileName ?? "nil",
                fs.type.description,
                fs.isFolder ? fs.subfoldersSize : fs.fileSize
            ))
            if fs.isValidFile, fs.isFolder {
                let linkedStringForceUnwrapping = linked ? ".linkedItem!" : ""
                outString.append(String(
                    format: "#expect(child%ld%@.orphanFolders == %ld, \"OrphanFolder: Expected count %ld found \\(child%ld%@.orphanFolders)\")\n",
                    childNum,
                    linkedStringForceUnwrapping,
                    fs.orphanFolders,
                    fs.orphanFolders,
                    childNum,
                    linkedStringForceUnwrapping
                ))
            }

            if let fileName, comparatorFlags.contains(.finderTags) {
                outString.append(String(format: "assertFolderTags(child%ld%@, %@, %@)\n", childNum, linkedString, Self.bool2String(fs.summary.hasMetadataTags), fileName))
                outString.append(String(format: "assertMismatchingTags(child%ld%@, %ld, %@)\n", childNum, linkedString, fs.mismatchingTags, fileName))
            }
            if let fileName, comparatorFlags.contains(.finderLabel) {
                outString.append(String(format: "assertFolderLabels(child%ld%@, %@, %@)\n", childNum, linkedString, Self.bool2String(fs.summary.hasMetadataLabels), fileName))
                outString.append(String(format: "assertMismatchingLabels(child%ld%@, %ld, %@)\n", childNum, linkedString, fs.mismatchingLabels, fileName))
                addAssertLabelsOnDisk(&outString, fs: fs, linked: linked, index: childNum)
            }
        }

        private func addAssertLabelsOnDisk(
            _ outString: inout String,
            fs: CompareItem,
            linked: Bool,
            index: Int
        ) {
            guard fs.isValidFile else {
                return
            }
            let path = fs.path!
            if let labelNumber = URL(filePath: path).labelNumber() {
                let linkedString = linked ? ".linkedItem" : ""
                let startIndex = path.index(path.startIndex, offsetBy: linked ? rightPos : leftPos)
                let subPath = String(path[startIndex ..< path.endIndex])
                outString.append(String(
                    format: "assertResourceFileLabels(child%ld%@, %ld, appendFolder(\"%@\"))\n",
                    index,
                    linkedString,
                    labelNumber,
                    subPath
                ))
            }
        }

        // MARK: - Folder, size, metadata

        private func createFolders(_ fs: CompareItem) {
            appendCreateFoldersExpressions(fs, pathIndex: leftPos)
            appendCreateFoldersExpressions(fs.linkedItem!, pathIndex: rightPos)
        }

        private func appendCreateFoldersExpressions(
            _ fs: CompareItem,
            pathIndex: Int
        ) {
            guard fs.isValidFile,
                  let path = fs.path else {
                return
            }
            let startIndex = path.index(path.startIndex, offsetBy: pathIndex)
            let subPath = String(path[startIndex ..< path.endIndex])
            if fs.isFolder {
                strFolders.append(String(format: "try createFolder(\"%@\")\n", subPath))
            } else {
                if fs.olderFiles > 0 {
                    strFiles.append(String(format: "try createFile(\"%@\", \"%@\")\n", subPath, fakeFileBySize(fs.fileSize, subPath)))
                    strFiles.append(String(format: "try setFileTimestamp(\"%@\", \"2001-03-24 10:45:32 +0600\")\n", subPath))
                } else {
                    strFiles.append(String(format: "try createFile(\"%@\", \"%@\")\n", subPath, fakeFileBySize(fs.fileSize, subPath)))
                }
            }
            if comparatorFlags.contains(.finderTags) {
                addTags(fs, subPath: subPath)
            }
            if comparatorFlags.contains(.finderLabel) {
                addLabels(fs, subPath: subPath)
            }
        }

        private func fakeFileBySize(_ size: Int64, _ path: String) -> String {
            assert(size < fakeFile.count, "File size (\(size)) is greater then fakeFile length (\(fakeFile.count)) for \(path)")

            return String(fakeFile[..<fakeFile.index(fakeFile.startIndex, offsetBy: Int(size))])
        }

        private func addTags(_ fs: CompareItem, subPath: String) {
            let url = URL(filePath: fs.path!)
            guard let tags = url.tagNames(sorted: false)?.map({ "\"\($0)\"" }),
                  !tags.isEmpty else {
                return
            }
            strFiles.append(String(
                format: "try add(tags: [%@], fullPath: appendFolder(\"%@\"))\n",
                tags.joined(separator: ","),
                subPath
            ))
        }

        private func addLabels(_ fs: CompareItem, subPath: String) {
            let url = URL(filePath: fs.path!)
            guard let labelNumber = url.labelNumber(),
                  labelNumber != 0 else {
                return
            }
            strFiles.append(String(format: "try add(labelNumber: %ld, fullPath: appendFolder(\"%@\"))\n", labelNumber, subPath))
        }

        // MARK: - clipboard

        private func copyTestToClipboard() {
            NSPasteboard.general.copy(lines: [
                header,
                strFolders, strFiles,
                readFolderPattern,
                "",
                "do {", strAssert, "}",
                "do {", strAssertVisibleItems, "}\n",
            ])
        }
    }

#endif

// swiftlint:enable identifier_name force_unwrapping force_try file_length line_length
