//
//  main.swift
//
//
//  Created by Kamaal M Farah on 29/12/2020.
//

import Foundation
import KamaalUtils
import KamaalExtensions

@main
struct XCodeThemes {
    private static let fileManager = FileManager.default
    private static let themes = [
        "KamaalLight.xccolortheme",
        "KamaalDark.xccolortheme"
    ]

    private static let fontDownloadSource = URL(
        staticString: "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip"
    )

    static func main() throws {
        let localFontsFolder = try getLocalFontsFolder()
        print("Dowloading Jet Brains Mono fonts")
        let fontsZipData = try getFontsZip()
        print("Installing Jet Brains Mono fonts")
        let jetBrainsMonoFolder = localFontsFolder.appending(path: "JetBrainsMono")
        FileClerk.createFile(with: fontsZipData, at: jetBrainsMonoFolder.appendingPathExtension("zip"))
        let output = try unzipFonts(zip: "JetBrainsMono.zip", at: localFontsFolder.path)
        print(output)

        let jetBrainsMonoFontsFolder = jetBrainsMonoFolder.appending(path: "fonts").appending(path: "ttf")
        try FileClerk.moveFolderContent(from: jetBrainsMonoFontsFolder, to: localFontsFolder)

        print("Deleting \(jetBrainsMonoFolder.appendingPathExtension("zip").path)")
        try FileClerk.deleteItem(at: jetBrainsMonoFolder.appendingPathExtension("zip"))
        print("Deleting \(jetBrainsMonoFolder.path)")
        try FileClerk.deleteItem(at: jetBrainsMonoFolder)

        let rootURL = URL(staticString: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        for theme in themes {
            try addThemeToXCodeThemes(with: rootURL.appendingPathComponent(theme))
        }
        print("Have fun")
    }

    private static func getFontsZip() throws -> Data {
        try Data(contentsOf: fontDownloadSource)
    }

    @discardableResult
    private static func addThemeToXCodeThemes(with file: URL) throws -> Bool {
        guard let libraryFolder = FileClerk.libraryDirectory else {
            throw XCodeThemes.Errors.libraryFolderNotFound
        }

        let subFolderPaths = ["Developer", "Xcode", "UserData", "FontAndColorThemes"]
        let fontAndColorThemesFolder = try FileClerk
            .getOrCreateSubfolder(atBase: libraryFolder, subFolderPaths: subFolderPaths)
        let urlToPlaceFile = fontAndColorThemesFolder.appending(path: file.lastPathComponent)
        let dataFromFile = try Data(contentsOf: URL(fileURLWithPath: file.path), options: .mappedIfSafe)
        return fileManager.createFile(atPath: urlToPlaceFile.path, contents: dataFromFile, attributes: nil)
    }

    private static func getLocalFontsFolder() throws -> URL {
        guard let libraryFolder = FileClerk.libraryDirectory else { throw XCodeThemes.Errors.libraryFolderNotFound }

        return try FileClerk.getOrCreateSubfolder(atBase: libraryFolder, subFolderPaths: ["Fonts"])
    }

    private static func unzipFonts(zip: String, at path: String) throws -> String {
        print("unzipping")
        return try Shell.zsh("unzip \(zip) -d \(zip.split(separator: ".zip").first!)", at: path).get()
    }

    enum Errors: Error {
        case libraryFolderNotFound
    }
}

extension XCodeThemes.Errors {
    var localizedDescription: String {
        switch self {
        case .libraryFolderNotFound: "Library folder could not be found"
        }
    }
}
