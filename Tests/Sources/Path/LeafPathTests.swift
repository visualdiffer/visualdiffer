//
//  LeafPathTests.swift
//  VisualDiffer
//
//  Created by davide ficano on 30/01/14.
//  Copyright (c) 2014 visualdiffer.com
//

import Testing
@testable import VisualDiffer

// swiftlint:disable function_body_length line_length
final class LeafPathTests: BaseTests {
    func findLeafPaths(_ paths: [String]) -> [CompareItem] {
        let arr = paths.map { CompareItem(
            path: $0,
            attrs: nil,
            fileExtraOptions: [],
            parent: nil
        )
        }

        return CompareItem.findLeafPaths(arr)
    }

    @Test
    func findLeafPaths1() {
        let paths = [
            "/Users/dave/trash/test_suite/createDir/l/dir1/dir2/dir3/test_date",
            "/Users/dave/trash/test_suite/createDir/l/dir1/dir2/dir3/test_date copia",
        ]
        let result = findLeafPaths(paths)
        assertArrayCount(result, 2)
        #expect(result[0].path == paths[0], "\(String(describing: result[0].path))")
        #expect(result[1].path == paths[1], "\(String(describing: result[1].path))")
    }

    @Test
    func findLeafPaths2() {
        let paths = [
            "/Users/dave/trash/test_suite/createDir/l/dir1/dir2",
            "/Users/dave/trash/test_suite/createDir/l/dir1/dir2/dir3",
            "/Users/dave/trash/test_suite/createDir/l/dir1/dir2/dir3/test_date",
        ]
        let result = findLeafPaths(paths)
        assertArrayCount(result, 1)
        #expect(result[0].path == paths[2], "\(String(describing: result[0].path))")
    }

    @Test
    func findLeafPaths3() {
        let paths = [
            "/Users/dave/trash/test_suite/createDir/test/10/20/30/40",
            "/Users/dave/trash/test_suite/createDir/test/10/40",
        ]
        let result = findLeafPaths(paths)
        assertArrayCount(result, 2)
        #expect(result[0].path == paths[0], "\(String(describing: result[0].path))")
        #expect(result[1].path == paths[1], "\(String(describing: result[1].path))")
    }

    @Test
    func findLeafPaths4() {
        let paths = [
            "/Users/dave/trash/app/VisualDiffer.xcodeproj",
            "/Users/dave/trash/app/VisualDiffer.xcodeproj/project.xcworkspace",
            "/Users/dave/trash/app/VisualDiffer.xcodeproj/project.xcworkspace/xcuserdata",
            "/Users/dave/trash/app/VisualDiffer.xcodeproj/project.xcworkspace/xcuserdata/dave.xcuserdatad",
            "/Users/dave/trash/app/VisualDiffer.xcodeproj/project.xcworkspace/xcuserdata/dave.xcuserdatad/UserInterfaceState.xcuserstate",
            "/Users/dave/trash/app/VisualDiffer.xcodeproj/xcuserdata",
        ]
        let result = findLeafPaths(paths)
        assertArrayCount(result, 2)
        #expect(result[0].path == paths[4], "\(String(describing: result[0].path))")
        #expect(result[1].path == paths[5], "\(String(describing: result[1].path))")
    }

    @Test
    func closestPath() {
        var arr = [
            "/Users/dave/trash/test_suite/bug244/r.txt",
            "/Users/dave/trash/0latest_stable/app",
            "/opt/devel/0dafiprj/git.github/android/ListViewOverlay",
            "/opt/devel/0dafiprj/osx/visualgrep/app/VisualGrep",
            "/opt/devel/0dafiprj/git.github/android/BatteryChargerNotifier/BatteryChargerNotifier",
            "/Users/dave/trash/photoshelf_all/photoshelf_cached/app",
            "/opt/devel/0dafiprj/osx/visualgrep/app/VisualGrep/en.lproj/MainMenu.xib",
            "/opt/devel/0dafiprj/git.github/android/TestApp",
            "/Users/dave/trash/Crawler/src",
            "/Users/dave/Dropbox/applicazioni/photoshelf/tags (1).csv",
            "/opt/devel/0dafiprj/git.github/dafizilla/slamtracker",
            "/opt/devel/0dafiprj/sourceforge/dafizilla/trunk/webapp/viewsourcewith/update.rdf",
            "/opt/devel/0dafiprj/osx/visualdiffer/website",
            "/Users/dave/trash/photoshelf_all/photoshelf_before_module/app/src/main/res",
            "/opt/devel/0dafiprj/osx/visualgrep/app/VisualGrep/utils/document",
            "/opt/devel/0dafiprj/git.github/android/photoshelf/app/src",
            "/Volumes/Seneca/devel/tests/visualdiffer/immaweb/svn/immaweb",
            "/Users/dave/trash/vd_localized/Localizable.strings",
            "/Users/dave/trash/test_suite/refactor_visibileItem/r",
            "/opt/devel/0dafiprj/osx/visualgrep/app/VisualGrepTests/support/ita-001-input.txt",
            "/Users/dave/trash/photoshelf_all/photoshelf_before_module/app/src/main/java",
            "/opt/devel/0dafiprj/osx/visualdiffer/website/css",
            "/Volumes/Seneca/mm/movies/xxx/app",
            "/Volumes/Seneca/devel/mycocoapod/TOPKit/TOPKit",
            "/Users/dave/trash/test_suite/bug239/r.csv",
            "/Users/dave/trash/test-encoding-word-file.doc",
            "/Users/dave/trash/Crawler",
            "/opt/devel/0dafiprj/git.github/android/photoshelf/app/src/main/java/com",
            "/opt/devel/0dafiprj/osx/visualdiffer/app/common",
            "/Users/dave/trash",
            "/opt/devel/0dafiprj/osx/visualdiffer/visualdiffer.github.com/css",
            "/opt/devel/0dafiprj/sourceforge/dafizilla_old/trunk",
            "/Users/dave/trash/progressbar",
            "/Users/dave/trash/photoshelf_all/photoshelf_gridview2",
            "/opt/devel/0dafiprj/sourceforge/dafizilla",
            "/opt/devel/0dafiprj/git.github/android/photoshelf/app/src/main/java/com/ternaryop",
            "/Users/dave/trash/test_suite/bug255",
            "/opt/devel/0dafiprj/git.github/dafizilla/viewsourcewith/profile/ff/extensions/{eecba28f-b68b-4b3a-b501-6ce12e6b8696}/chrome/plainfiles",
            "/opt/devel/0dafiprj/osx/visualgrep/app/VisualGrep/utils",
            "/Users/dave/trash/test_suite/bug244/l.txt",
            "/opt/devel/0dafiprj/osx/visualdiffer/visualdiffer.github.com/_plugins/tocGenerator.rb",
            "/Users/dave/trash/test_suite/FileSystemUtilsTests/testMoveMatchFileBecomeFiltered/r",
            "/Volumes/Seneca/devel/tests/visualdiffer/immaweb/svn/immaweb/trunk",
            "/opt/devel/0dafiprj/sourceforge/dafizilla_old",
            "/Users/dave/trash/test_suite/bug255/l",
            "/Volumes/Seneca/mm/movies/xxx/Archivio/commonutils-master",
            "/opt/devel/0dafiprj/git.github/android/photoshelf/app/src/main/res",
            "/Users/dave/trash/update.rdf",
            "/Users/dave/trash/photoshelf_all/tags.csv",
            "/Users/dave/trash/test_suite/bug255/r",
            "/Users/dave/trash/hidefiles/sql1.txt",
            "/opt/devel/0dafiprj/osx/visualgrepswift",
            "/Volumes/Seneca/mm/movies/xxx/Archivio/photoshelf",
            "/Users/dave/trash/photoshelf_all/photoshelf_cached",
            "/Users/dave/trash/VisualDiffer/common/VDPathViewController.m",
            "/Volumes/Seneca/devel/examples/android/apk/PhotoShelf-release/AndroidManifest.xml",
            "/Users/dave/trash/test_suite/bug239/l.csv",
            "/Users/dave/trash/visualdi_mant1-141116.sql",
            "/Volumes/Seneca/mm/movies/person.of.interest",
            "/Users/dave/trash/test_suite/FileSystemUtilsTests/testMoveMatchFileBecomeFiltered/l",
            "/Volumes/Seneca/mm/movies/temp/visualdi_mant1.sql",
            "/opt/devel/0dafiprj/git.github/dafizilla/viewsourcewith/dist/bin/viewsourcewith-0.9.4.3",
            "/opt/devel/0dafiprj/osx/visualdiffer/website/new/css",
            "/Users/dave/trash/test_suite/refactor_visibileItem/l",
            "/Users/dave/Dropbox/applicazioni/photoshelf/tags.csv",
            "/opt/devel/0dafiprj/git.github/dafizilla/viewsourcewith/dist/bin/amo",
            "/Users/dave/trash/hidefiles/list-only-files.txt",
            "/opt/devel/0dafiprj/osx/visualdiffer/app/common/VDPathViewController.m",
            "/Users/dave/trash/tocgen_html_site",
            "/opt/devel/0dafiprj/git.github/android/photoshelf",
            "/Users/dave/trash/tocgen_xhtml_site",
            "/Users/dave/trash/ShareActionProvider-main.xml",
            "/Users/dave/trash/0latest_stable/app 2",
            "/Volumes/Seneca/mm/movies/xxx/Archivio/photoshelf-master",
            "/Volumes/Seneca/devel/tests/visualdiffer/immaweb/svn/immaweb/trunk/src",
            "/Users/dave/trash/test_suite/a.txt",
            "/opt/devel/0dafiprj/git.github/android/commonutils/app/src/main/java/com",
            "/opt/devel/0dafiprj/osx/visualdiffer/app/utils/document",
            "/opt/devel/0dafiprj/git.github/jekyll-toc-generator/_plugins/tocGenerator.rb",
            "/opt/devel/0dafiprj/git.github/dafizilla/viewsourcewith/dist/bin/debug",
            "/opt/devel/0dafiprj/osx/visualdiffer/app",
            "/opt/devel/0dafiprj/osx/visualdiffer/visualdiffer.github.com",
            "/Users/dave/Dropbox/Applicazioni/PhotoShelf/birthdays.csv",
            "/opt/devel/0dafiprj/sourceforge/dafizilla/trunk/bespin",
            "/Users/dave/trash/photoshelf_all/photoshelf_toolbar",
            "/Volumes/Seneca/mm/movies/temp",
            "/Volumes/Seneca/devel/examples/android/dropbox-android-sync-sdk-3.0.2/libs",
            "/private/var",
            "/Users/dave/trash/visualgrepswift/VisualGrepSwift",
            "/Users/dave/trash/test_suite/FileSystemUtilsTests/testCopyFollowSymLink/l",
            "/opt/devel/0dafiprj/osx/visualgrep/app/VisualGrep/utils/io",
            "/Users/dave/trash/photoshelf_all/CommonUtilsModule",
            "/opt/devel/0dafiprj/osx/visualdiffer/app/utils",
            "/opt/devel/0dafiprj/git.github/android/commonutils",
            "/Users/dave/trash/VisualDiffer",
            "/Users/dave/.Trash/update.rdf",
            "/Users/dave/trash/test_suite/bug218/l",
            "/opt/devel/0dafiprj/osx/visualgrep/app/VisualGrepTests/support/ita-001-pattern.txt",
            "/Volumes/Seneca/devel/tests/visualdiffer/immaweb/prj/immaweb",
            "/Users/dave/trash/birthdays-150129.csv",
            "/opt/devel/0dafiprj/git.github/android/photoshelf/app",
            "/opt/devel/0dafiprj/git.github/dafizilla/viewsourcewith/dist/bin/amo/viewsourcewith-0.9.4.3",
            "/Users/dave/trash/Project_Default.xml",
            "/Users/dave/trash/VisualDiffer/common",
            "/Users/dave/trash/test_suite/FileSystemUtilsTests/testCopyFollowSymLink/r",
            "/Users/dave/trash/test_suite/bug218/r",
            "/Volumes/Seneca/devel/tests/visualdiffer/immaweb/prj/immaweb/src",
            "/opt/devel/0dafiprj/git.github/android/photoshelf/app/src/main/java",
            "/opt/devel/0dafiprj/osx/visualdiffer/app/English.lproj/Localizable.strings",
            "/Users/dave/trash/test_suite/bug251/l",
            "/opt/devel/0dafiprj/osx/visualgrep/site",
            "/Users/dave/trash/photoshelf_all/photoshelf_added_icons",
            "/opt/devel/0dafiprj/git.github/dafizilla/viewsourcewith/src/main",
            "/opt/devel/0dafiprj/git.github/android/commonutils/app/src/main/java",
            "/opt/devel/0dafiprj/git.github/android/photoshelf/app/libs",
            "/Users/dave/trash/test_suite/bug251/r",
        ]

        var found: String?
        var expectedResult: String?

        expectedResult = "/opt/devel/0dafiprj/git.github/android/BatteryChargerNotifier/BatteryChargerNotifier"
        found = SecureBookmark.shared.findClosestPath(to: URL(filePath: "/opt/devel/0dafiprj/git.github/android/BatteryChargerNotifier/BatteryChargerNotifier/gradle"), searchPaths: arr)
        #expect(found == expectedResult, "found \(String(describing: found)) expected \(String(describing: expectedResult))")

        expectedResult = "/Users/dave/trash/0latest_stable/app 2"
        found = SecureBookmark.shared.findClosestPath(to: URL(filePath: "/Users/dave/trash/0latest_stable/app 2"), searchPaths: arr)
        #expect(found == expectedResult, "found \(String(describing: found)) expected \(String(describing: expectedResult))")

        expectedResult = "/opt/devel/0dafiprj/osx/visualdiffer/app"
        found = SecureBookmark.shared.findClosestPath(to: URL(filePath: "/opt/devel/0dafiprj/osx/visualdiffer/app"), searchPaths: arr)
        #expect(found == expectedResult, "found \(String(describing: found)) expected \(String(describing: expectedResult))")

        arr = ["/Users/app 2 3"]
        expectedResult = nil
        found = SecureBookmark.shared.findClosestPath(to: URL(filePath: "/Users/app 2"), searchPaths: arr)
        #expect(found == expectedResult, "found \(String(describing: found)) expected \(String(describing: expectedResult))")

        arr = ["/Users/app", "/All/aa", "/Zoom/hello"]
        expectedResult = "/Users/app"
        found = SecureBookmark.shared.findClosestPath(to: URL(filePath: "/Users/app/file"), searchPaths: arr)
        #expect(found == expectedResult, "found \(String(describing: found)) expected \(String(describing: expectedResult))")
    }
}

// swiftlint:enable function_body_length line_length
