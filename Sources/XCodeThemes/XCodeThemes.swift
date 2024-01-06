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

    static func main() {
        var localFontsFolder: URL
        do {
            localFontsFolder = try getLocalFontsFolder()
        } catch XCodeThemes.Errors.libraryFolderNotFound {
            print(XCodeThemes.Errors.libraryFolderNotFound.localizedDescription)
            return
        } catch {
            print(error.localizedDescription)
            return
        }

        var fontsZipData: Data
        print("Dowloading Jet Brains Mono fonts")
        do {
            fontsZipData = try getFontsZip()
        } catch {
            print(error.localizedDescription)
            return
        }
        print("Installing Jet Brains Mono fonts")

        let jetBrainsMonoFolder = localFontsFolder.appendingPathComponent("JetBrainsMono")

        createZip(at: jetBrainsMonoFolder.appendingPathExtension("zip"), with: fontsZipData)

        let output: String
        do {
            output = try unzipFonts(at: localFontsFolder.path)
        } catch {
            print(error.localizedDescription)
            return
        }
        print(output)

        let jetBrainsMonoFontsFolder = jetBrainsMonoFolder.appendingPathComponent("fonts").appendingPathComponent("ttf")
        do {
            try moveFolderContent(of: jetBrainsMonoFontsFolder, to: localFontsFolder)
        } catch {
            print(error.localizedDescription)
            return
        }

        do {
            print("Deleting \(jetBrainsMonoFolder.appendingPathExtension("zip").path)")
            try deleteFolder(at: jetBrainsMonoFolder.appendingPathExtension("zip"))
            print("Deleting \(jetBrainsMonoFolder.path)")
            try deleteFolder(at: jetBrainsMonoFolder)
        } catch {
            print(error.localizedDescription)
            return
        }

        let rootURL = URL(staticString: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        for theme in themes {
            do {
                try addThemeToXCodeThemes(with: rootURL.appendingPathComponent(theme))
            } catch XCodeThemes.Errors.libraryFolderNotFound {
                print(XCodeThemes.Errors.libraryFolderNotFound.localizedDescription)
                return
            } catch {
                print(error.localizedDescription)
                return
            }
        }

        print("Have fun")
    }

    private static func getFontsZip() throws -> Data {
        try Data(contentsOf: fontDownloadSource)
    }

    @discardableResult
    private static func addThemeToXCodeThemes(with file: URL) throws -> Bool {
        guard let libraryFolder = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            throw XCodeThemes.Errors.libraryFolderNotFound
        }
        let developerFolder = try libraryFolder.createSubFolderIfNeeded(of: "Developer")
        let xCodeFolder = try developerFolder.createSubFolderIfNeeded(of: "Xcode")
        let userDataFolder = try xCodeFolder.createSubFolderIfNeeded(of: "UserData")
        let fontAndColorThemesFolder = try userDataFolder.createSubFolderIfNeeded(of: "FontAndColorThemes")
        let urlToPlaceFile = fontAndColorThemesFolder.appendingPathComponent(file.lastPathComponent)
        let dataFromFile = try Data(contentsOf: URL(fileURLWithPath: file.path), options: .mappedIfSafe)
        return fileManager.createFile(atPath: urlToPlaceFile.path, contents: dataFromFile, attributes: nil)
    }

    private static func getLocalFontsFolder() throws -> URL {
        guard let libraryFolder = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            throw XCodeThemes.Errors.libraryFolderNotFound
        }
        var contentOfLibraryFolder: [URL]!
        contentOfLibraryFolder = try fileManager.contentsOfDirectory(at: libraryFolder,
                                                                     includingPropertiesForKeys: nil,
                                                                     options: [])
        let assumedFontsFolder = libraryFolder.appendingPathComponent("Fonts")
        let fontsFolder = contentOfLibraryFolder.first { $0.absoluteString == assumedFontsFolder.absoluteString }
        if fontsFolder == nil {
            try fileManager.createDirectory(at: assumedFontsFolder, withIntermediateDirectories: true, attributes: nil)
        }
        return assumedFontsFolder
    }

    private static func unzipFonts(at path: String) throws -> String {
        print("unzipping")
        return try Shell.zsh("unzip JetBrainsMono.zip -d JetBrainsMono", at: path).get()
    }

    private static func moveFolderContent(of contentFolder: URL, to destination: URL) throws {
        let contentOfJetBrainsMonoFontsFolder = try fileManager.contentsOfDirectory(at: contentFolder,
                                                                                    includingPropertiesForKeys: nil,
                                                                                    options: [])
        try contentOfJetBrainsMonoFontsFolder.forEach {
            guard !fileManager.fileExists(atPath: destination.appendingPathComponent($0.lastPathComponent).path) else {
                print("\($0.lastPathComponent) allready exists in \(destination.path)")
                return
            }
            print("Moving \($0.lastPathComponent) to \(destination.path)")
            try fileManager.moveItem(at: $0, to: destination.appendingPathComponent($0.lastPathComponent))
        }
    }

    private static func deleteFolder(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    private static func createZip(at destination: URL, with content: Data) {
        fileManager.createFile(atPath: destination.path, contents: content)
    }

    enum Errors: Error {
        case libraryFolderNotFound
    }
}

extension URL {
    func createSubFolderIfNeeded(of path: String) throws -> URL {
        let proposedURL = self.appendingPathComponent(path)
        guard !FileManager.default.fileExists(atPath: proposedURL.path) else { return proposedURL }
        try FileManager.default.createDirectory(at: proposedURL, withIntermediateDirectories: true, attributes: nil)
        return proposedURL
    }
}

extension XCodeThemes.Errors {
    var localizedDescription: String {
        switch self {
        case .libraryFolderNotFound:
            return "Library folder could not be found"
        }
    }
}
