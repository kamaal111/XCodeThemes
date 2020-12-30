//
//  main.swift
//
//
//  Created by Kamaal M Farah on 29/12/2020.
//

import Foundation

struct XCodeThemes {
    private let fileManager = FileManager.default

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
        switch xCodeThemes.getFontsZip() {
        case .failure(let failure):
            print(failure.localizedDescription)
            return
        case .success(let data):
            fontsZipData = data
        }
        print("Installing Jet Brains Mono fonts")
        localFontsFolder.createFolder(named: "JetBrainsMono.zip", with: fontsZipData)

        let output: String
        do {
            output = try xCodeThemes.unzipFonts(at: localFontsFolder.path)
        } catch XCodeThemes.Errors.jetBrainsMonoFolderExists {
            print(XCodeThemes.Errors.jetBrainsMonoFolderExists.localizedDescription)
            return
        } catch {
            print(error.localizedDescription)
            return
        }
        print(output)

        let jetBrainsMonoFolder = localFontsFolder.appendingPathComponent("JetBrainsMono")
        let jetBrainsMonoFontsFolder = jetBrainsMonoFolder.appendingPathComponent("fonts").appendingPathComponent("ttf")
        do {
            try xCodeThemes.moveFolderContent(of: jetBrainsMonoFontsFolder, to: localFontsFolder)
        } catch {
            print(error.localizedDescription)
            return
        }

        do {
            try xCodeThemes.deleteFolder(at: jetBrainsMonoFolder.appendingPathExtension("zip"))
            try xCodeThemes.deleteFolder(at: jetBrainsMonoFolder)
        } catch {
            print(error.localizedDescription)
            return
        }

        print("Have fun")
    }

    func getFontsZip() -> Result<Data, Error> {
        let fontZipURL = URL(
            staticString: "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.221/JetBrainsMono-2.221.zip")
        do {
            let data = try Data(contentsOf: fontZipURL)
            return .success(data)
        } catch {
            return .failure(error)
        }
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
        guard !fileManager.fileExists(atPath: "\(path)/JetBrainsMono") else {
            throw XCodeThemes.Errors.jetBrainsMonoFolderExists
        }
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

    enum Errors: Error {
        case libraryFolderNotFound
        case jetBrainsMonoFolderExists
    }
}

extension URL {
    @discardableResult
    func createFolder(named: String, with data: Data, using fileManager: FileManager = FileManager.default) -> Bool {
        fileManager.createFile(atPath: self.appendingPathComponent(named).path, contents: data)
    }

    init(staticString: StaticString) {
        self.init(string: "\(staticString)")!
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
        case .jetBrainsMonoFolderExists:
            return "JetBrainsMono folder allready exists, please delete before you can go on"
        }
    }
}

XCodeThemes.main()
