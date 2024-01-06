//
//  main.swift
//
//
//  Created by Kamaal M Farah on 29/12/2020.
//

import Foundation

@main
struct XCodeThemes {
    private let fileManager = FileManager.default

    static let themes = [
        "KamaalLight.xccolortheme",
        "KamaalDark.xccolortheme"
    ]

    let fontDownloadSource = URL(
        staticString: "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.221/JetBrainsMono-2.221.zip")

    static func main() {
        let xCodeThemes = XCodeThemes()
        var localFontsFolder: URL
        do {
            localFontsFolder = try xCodeThemes.getLocalFontsFolder()
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
            fontsZipData = try xCodeThemes.getFontsZip()
        } catch {
            print(error.localizedDescription)
            return
        }
        print("Installing Jet Brains Mono fonts")

        let jetBrainsMonoFolder = localFontsFolder.appendingPathComponent("JetBrainsMono")

        xCodeThemes.createZip(at: jetBrainsMonoFolder.appendingPathExtension("zip"), with: fontsZipData)

        let output: String
        do {
            output = try xCodeThemes.unzipFonts(at: localFontsFolder.path)
        } catch ShellErrors.failed {
            print(ShellErrors.failed.localizedDescription)
            return
        } catch {
            print(error.localizedDescription)
            return
        }
        print(output)

        let jetBrainsMonoFontsFolder = jetBrainsMonoFolder.appendingPathComponent("fonts").appendingPathComponent("ttf")
        do {
            try xCodeThemes.moveFolderContent(of: jetBrainsMonoFontsFolder, to: localFontsFolder)
        } catch {
            print(error.localizedDescription)
            return
        }

        do {
            print("Deleting \(jetBrainsMonoFolder.appendingPathExtension("zip").path)")
            try xCodeThemes.deleteFolder(at: jetBrainsMonoFolder.appendingPathExtension("zip"))
            print("Deleting \(jetBrainsMonoFolder.path)")
            try xCodeThemes.deleteFolder(at: jetBrainsMonoFolder)
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
                try xCodeThemes.addThemeToXCodeThemes(with: rootURL.appendingPathComponent(theme))
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

    func getFontsZip() throws -> Data {
        let data = try Data(contentsOf: fontDownloadSource)
        return data
    }

    @discardableResult
    func addThemeToXCodeThemes(with file: URL) throws -> Bool {
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

    func getLocalFontsFolder() throws -> URL {
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

    func unzipFonts(at path: String) throws -> String {
        print("unzipping")
        let output = try zShell("unzip JetBrainsMono.zip -d JetBrainsMono", at: path)
        return output
    }

    func moveFolderContent(of contentFolder: URL, to destination: URL) throws {
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

    func deleteFolder(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    func createZip(at destination: URL, with content: Data) {
        fileManager.createFile(atPath: destination.path, contents: content)
    }

    enum Errors: Error {
        case libraryFolderNotFound
    }
}

extension URL {
    init(staticString: StaticString) {
        self.init(string: "\(staticString)")!
    }

    func createSubFolderIfNeeded(of path: String) throws -> URL {
        let proposedURL = self.appendingPathComponent(path)
        guard !FileManager.default.fileExists(atPath: proposedURL.path) else { return proposedURL }
        try FileManager.default.createDirectory(at: proposedURL, withIntermediateDirectories: true, attributes: nil)
        return proposedURL
    }
}

func shell(_ launchPath: String, _ command: String, at executionLocation: String? = nil) throws -> String {
    let task = Process()
    var commandToUse: String
    if let executionLocation = executionLocation {
        commandToUse = "cd \(executionLocation) && \(command)"
    } else {
        commandToUse = command
    }
    task.arguments = ["-c", commandToUse]
    task.launchPath = launchPath

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!

    task.waitUntilExit()

    if task.terminationStatus != 0 {
        throw ShellErrors.failed
    }
    return output
}

@discardableResult
func zShell(_ command: String, at executionLocation: String? = nil) throws -> String {
    try shell("/bin/zsh", command, at: executionLocation)
}

enum ShellErrors: Error {
    case failed
}

extension ShellErrors {
    var localizedDescription: String {
        switch self {
        case .failed:
            return "Shell command failed to execute"
        }
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
