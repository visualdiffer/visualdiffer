//
//  CommonPrefs.swift
//  VisualDiffer
//
//  Created by davide ficano on 30/08/25.
//  Copyright (c) 2025 visualdiffer.com
//

import os.log

private let darkColorSchemeFileName: String = "colorsDark"
private let lightColorSchemeFileName: String = "colors"

public class CommonPrefs: @unchecked Sendable {
    public static let shared = CommonPrefs()

    private(set) var colorSchemeMap = [String: ColorScheme]()

    private init() {
        loadColors()
    }

    func appearanceChanged(
        postNotification: Bool,
        _ object: Any? = nil
    ) {
        loadColors()
        if postNotification {
            NotificationCenter.default.post(
                name: .appAppearanceDidChange,
                object: object
            )
        }
    }

    // MARK: - Colors

    func loadColors() {
        guard let colorsConfigPath = colorsConfigPath ?? defaultColorsConfigPath else {
            fatalError("No color config file found")
        }
        guard let configColorMap = readColorConfig(colorsConfigPath) else {
            fatalError("Can't read color config")
        }

        colorSchemeMap.removeAll()

        for (schemeName, definitions) in configColorMap {
            if let definitions = definitions as? [String: [String: String]] {
                colorSchemeMap[schemeName] = ColorScheme(name: schemeName, definitions: definitions)
            }
        }
    }

    var colorsConfigPath: String? {
        string(forKey: .colorsConfigPath)
    }

    var defaultColorsConfigPath: String? {
        Bundle.main.path(
            forResource: NSAppearance.isDarkMode ? darkColorSchemeFileName : lightColorSchemeFileName,
            ofType: "json"
        )
    }

    private func readColorConfig(_ configPath: String) -> [String: Any]? {
        do {
            return try readJSON(configPath) as? [String: Any]
        } catch {
            Logger.general.error("Error while loading colors from \(configPath), error \(error.localizedDescription). Try to load default colors config")
            // fallback to defaults
            if let path = defaultColorsConfigPath {
                return try? readJSON(path) as? [String: Any]
            }
        }
        return nil
    }

    func readJSON(_ configPath: String) throws -> Any {
        guard let stream = InputStream(fileAtPath: configPath) else {
            throw FileError.openFile(path: configPath)
        }
        defer {
            stream.close()
        }
        stream.open()

        return try JSONSerialization.jsonObject(with: stream)
    }
}
