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
        switch xCodeThemes.getLocalFontsFolder() {
        case .failure(let failure):
            print(failure.localizedDescription)
            return
        case .success(let url):
            localFontsFolder = url
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
        print("Have fun")
    }

    func getFontsZip() -> Result<Data, Error> {
        let fontZipURL = URL(
            string: "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.221/JetBrainsMono-2.221.zip")!
        do {
            let data = try Data(contentsOf: fontZipURL)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    func getLocalFontsFolder() -> Result<URL, Error> {
        guard let libraryFolder = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return .failure(XCodeThemes.Errors.libraryFolderNotFound)
        }
        var contentOfLibraryFolder: [URL]!
        do {
            contentOfLibraryFolder = try fileManager.contentsOfDirectory(at: libraryFolder,
                                                                         includingPropertiesForKeys: nil,
                                                                         options: [])
        } catch {
            return .failure(error)
        }
        let assumedFontsFolder = libraryFolder.appendingPathComponent("Fonts")
        let fontsFolder = contentOfLibraryFolder.first { $0.absoluteString == assumedFontsFolder.absoluteString }
        if fontsFolder == nil {
            do {
                try fileManager.createDirectory(at: assumedFontsFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return .failure(error)
            }
        }
        return .success(assumedFontsFolder)
    }

    enum Errors: Error {
        case libraryFolderNotFound
    }
}

extension URL {
    @discardableResult
    func createFolder(named: String, with data: Data, using fileManager: FileManager = FileManager.default) -> Bool {
        fileManager.createFile(atPath: self.appendingPathComponent(named).path, contents: data)
    }
}

func shell(_ launchPath: String, _ arguments: String...) throws -> String {
    let task = Process()
    task.arguments = ["-c", arguments.joined(separator: " ")]
    task.launchPath = launchPath

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe

    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!

    task.waitUntilExit()

    if task.terminationStatus != 0 {
        throw ShellError.failed
    }
    return output
}

enum ShellError: Error {
    case failed
}

extension ShellError {
    var errorDescription: String? {
        switch self {
        case .failed:
            return "Shell command failed to execute"
        }
    }
}

extension XCodeThemes.Errors {
    var errorDescription: String? {
        switch self {
        case .libraryFolderNotFound:
            return "Library folder could not be found"
        }
    }
}

XCodeThemes.main()
