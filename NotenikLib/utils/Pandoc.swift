//
//  Pandoc.swift
//  Notenik
//
//  Created by Herb Bowie on 1/24/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A class that can run the pandoc utility to perform file conversions.
class Pandoc {
    
    let fileManager = FileManager.default
    let appPrefs = AppPrefs.shared
    
    init() {
       
    }
    
    /// Use Pandoc to convert markdown to HTML.
    func convertMarkdownToHTML(_ textIn: String) -> String {
        let textOut = convert(textIn: textIn, fromFormat: "markdown", toFormat: "html")
        if textOut == nil {
            return ""
        } else {
            return textOut!
        }
    }
    
    /// Use Pandoc to convert an input string to an output string.
    func convert(textIn: String,
                 fromFormat: String,
                 toFormat: String) -> String? {
        
        // Let's try to write the input string to a temporary file.
        let tempInput = appPrefs.nextTempFile(ext: "txt")

        do {
            try textIn.write(to: tempInput, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            logError("Could not write input string to temporary directory")
            return nil
        }
        
        // Let's get a good temp output file to use.
        let tempOutput = appPrefs.nextTempFile(ext: "txt")
        
        // Now let's run pandoc.
        let converted = convert(inputPath: tempInput.path,
                               fromFormat: fromFormat,
                               outputPath: tempOutput.path,
                                 toFormat: toFormat)
        guard converted else { return nil }
        
        // Now let's read the output string and return it.
        var textOut: String?
        do {
            textOut = try String(contentsOf: tempOutput)
        } catch {
            logError("Could not read the output string from the temporary directory")
            return nil
        }
        
        // Now let's clean up the temp files. 
        do {
            try fileManager.removeItem(at: tempInput)
        } catch {
            // Don't worry about it
            print("Couldn't delete temp input file")
        }
        do {
            try fileManager.removeItem(at: tempOutput)
        } catch {
            // Don't worry about it.
            print("Couldn't delete temp output file")
        }
        return textOut
    }
    
    /// Use Pandoc to convert an input file to an output file. 
    func convert(inputPath: String,
                fromFormat: String,
                outputPath: String,
                  toFormat: String) -> Bool {
        var ok = true
        let task = Process()
        let bundle = Bundle.main
        let execURL = bundle.url(forResource: "pandoc", withExtension: nil)
        guard execURL != nil else {
            logError("Pandoc executable could not be found in the application bundle")
            return false
        }
        // print("Pandoc.convert")
        // print("  From \(inputPath)")
        // print("    in \(fromFormat) format")
        // print("  To \(outputPath)")
        // print("    in \(toFormat) format")
        task.executableURL = execURL!
        var args: [String] = []
        args.append(inputPath)
        args.append("-f")
        args.append(fromFormat)
        args.append("-t")
        args.append(toFormat)
        args.append("-o")
        args.append(outputPath)
        task.arguments = args
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        do {
            try task.run()
            // print("Pandoc executed successfully!")
            _ = outputPipe.fileHandleForReading.readDataToEndOfFile()
            // let output = String(decoding: outputData, as: UTF8.self)
            // print(output)
            _ = errorPipe.fileHandleForReading.readDataToEndOfFile()
            // let error = String(decoding: errorData, as: UTF8.self)
            // print(error)
        } catch {
            logError("Error running Pandoc: \(error)")
            ok = false
        }
        return ok
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "Pandoc",
                          level: .error,
                          message: msg)
    }
}
