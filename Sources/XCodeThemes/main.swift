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
        do {
            try xCodeThemes.getFontsFolder()
        } catch XCodeThemes.Errors.libraryFolderNotFound {
            print(XCodeThemes.Errors.libraryFolderNotFound.localizedDescription)
        } catch {
            print(error.localizedDescription)
        }
//        let getFontsResult = xCodeThemes.getFonts()
//        let fontsData: Data!
//        switch getFontsResult {
//        case .failure(let failure):
//            print(failure)
//            return
//        case .success(let fonts):
//            fontsData = fonts
//        }
//        print(fontsData)
    }

    func getFonts() -> Result<Data, Error> {
        let fontZipURL = URL(
            string: "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.221/JetBrainsMono-2.221.zip")!
        do {
            let data = try Data(contentsOf: fontZipURL)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    func getFontsFolder() throws {
        guard let libraryFolder = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            throw XCodeThemes.Errors.libraryFolderNotFound
        }
        let contentOfLibraryFolder = try fileManager.contentsOfDirectory(at: libraryFolder,
                                                                         includingPropertiesForKeys: nil,
                                                                         options: [])
        let assumedFontsFolder = libraryFolder.appendingPathComponent("Fonts")
        let fontsFolder = contentOfLibraryFolder.first { $0.absoluteString == assumedFontsFolder.absoluteString }
        if let unwrappedFontsFolder = fontsFolder {
            print(unwrappedFontsFolder)
            let output = shell("/bin/zsh", "echo", "\("hello world")")
            print(output)
        } else {
//            try fileManager.createDirectory(at: libraryFolder.appendingPathComponent("Fonts/"), withIntermediateDirectories: true, attributes: nil)
        }
    }

    enum Errors: Error {
        case libraryFolderNotFound
    }
}

func shell(_ launchPath: String, _ arguments: String...) -> String {
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
    let status = task.terminationStatus
    if status == 0 {
        // pass
    } else {
        // error
    }

    return output
}

enum ShellErrors: Error {
    case failed
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
