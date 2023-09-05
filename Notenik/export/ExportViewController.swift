//
//  ExportViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/18/19.
//
//  Copyright © 2019-2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils
import NotenikLib

class ExportViewController: NSViewController {
    
    var window: ExportWindowController!
    
    let commaSep  = "Comma-Separated"
    let jsonTitle = "JSON"
    let notenik   = "Notenik"
    let yaml      = "YAML Metadata"
    let outline   = "OPML"
    let tabDelim  = "Tab-Delimited"
    let bookmarks = "Netscape Bookmark File"
    let concatHtml = "Concatenated HTML"
    let outlineHtml = "HTML Outline"
    let concatMd  = "Concatenated Markdown"
    let webBookEPUBFolder = "Web Book as EPUB Folder"
    let webBookSite = "Web Book as Site"
    let webBookEPUB = "Web Book as EPUB"
    
    let osdir     = OpenSaveDirectory.shared
    
    let csv     = "csv"
    let htm     = "htm"
    let html    = "html"
    let json    = "json"
    let md      = "md"
    let opml    = "opml"
    let tab     = "tab"
    let txt     = "txt"
    let xhtml   = "xhtml"
    
    @IBOutlet var formatPopup: NSPopUpButton!
    
    var startOfExportScripts = -1
    
    @IBOutlet var fileExtCombo: NSComboBox!
    @IBOutlet var tagsExportPrefsCheckBox: NSButton!
    @IBOutlet var splitTagsCheckBox: NSButton!
    @IBOutlet var addWebExtensionsCheckBox: NSButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadFormatPopup()
        
        fileExtCombo.removeAllItems()
        fileExtCombo.addItem(withObjectValue: csv)
        fileExtCombo.addItem(withObjectValue: tab)
        fileExtCombo.addItem(withObjectValue: txt)
        fileExtCombo.addItem(withObjectValue: json)
        fileExtCombo.addItem(withObjectValue: md)
        fileExtCombo.addItem(withObjectValue: htm)
        fileExtCombo.addItem(withObjectValue: html)
        fileExtCombo.addItem(withObjectValue: opml)
        fileExtCombo.addItem(withObjectValue: xhtml)
        fileExtCombo.selectItem(at: 0)
    }
    
    var io: NotenikIO? {
        get {
            return _io
        }
        set {
            _io = newValue
            loadFormatPopup()
        }
    }
    var _io: NotenikIO?
    
    func loadFormatPopup() {
        formatPopup.removeAllItems()
        
        formatPopup.addItem(withTitle: commaSep)
        formatPopup.addItem(withTitle: tabDelim)
        formatPopup.addItem(withTitle: jsonTitle)
        formatPopup.addItem(withTitle: notenik)
        formatPopup.addItem(withTitle: yaml)
        formatPopup.addItem(withTitle: bookmarks)
        formatPopup.addItem(withTitle: outline)
        formatPopup.addItem(withTitle: concatHtml)
        formatPopup.addItem(withTitle: outlineHtml)
        formatPopup.addItem(withTitle: concatMd)
        formatPopup.addItem(withTitle: webBookEPUBFolder)
        formatPopup.addItem(withTitle: webBookSite)
        formatPopup.addItem(withTitle: webBookEPUB)
        startOfExportScripts = formatPopup.numberOfItems
        formatPopup.selectItem(at: 0)
        
        guard let noteIO = io else { return }
        for script in noteIO.exportScripts {
            formatPopup.addItem(withTitle: script.scriptName)
        }
        
    }
    
    @IBAction func formatAction(_ sender: Any) {
        if let selectedFormat = formatPopup.selectedItem {
            switch selectedFormat.title {
            case commaSep:
                fileExtCombo.selectItem(withObjectValue: csv)
            case  tabDelim:
                fileExtCombo.selectItem(withObjectValue: txt)
            case jsonTitle:
                fileExtCombo.selectItem(withObjectValue: json)
            case bookmarks:
                fileExtCombo.selectItem(withObjectValue: htm)
                splitTagsCheckBox.state = .on
            case notenik:
                fileExtCombo.selectItem(withObjectValue: txt)
                splitTagsCheckBox.state = .off
            case yaml:
                fileExtCombo.selectItem(withObjectValue: md)
                splitTagsCheckBox.state = .off
            case outline:
                fileExtCombo.selectItem(withObjectValue: opml)
                splitTagsCheckBox.state = .off
            case concatHtml:
                fileExtCombo.selectItem(withObjectValue: html)
                splitTagsCheckBox.state = .off
            case outlineHtml:
                fileExtCombo.selectItem(withObjectValue: html)
                splitTagsCheckBox.state = .off
            case concatMd:
                fileExtCombo.selectItem(withObjectValue: md)
                splitTagsCheckBox.state = .off
            case webBookEPUB:
                fileExtCombo.selectItem(withObjectValue: xhtml)
                splitTagsCheckBox.state = .off
            case webBookEPUBFolder:
                fileExtCombo.selectItem(withObjectValue: html)
                splitTagsCheckBox.state = .off
            case webBookSite:
                fileExtCombo.selectItem(withObjectValue: html)
                splitTagsCheckBox.state = .off
            default:
                break
            }
        }
    }
    
    /// The user clicked ok -- let's go ahead and export now. 
    @IBAction func okButtonPressed(_ sender: Any) {
        
        // Figure out the desired output format.
        var formatTitle = commaSep
        var format = ExportFormat.commaSeparated
        if formatPopup.selectedItem != nil {
            formatTitle = formatPopup.selectedItem!.title
        }
        if formatPopup.indexOfSelectedItem >= startOfExportScripts {
            format = .exportScript
        } else {
            switch formatTitle {
            case tabDelim:
                format = .tabDelimited
            case jsonTitle:
                format = .json
            case bookmarks:
                format = .bookmarks
            case notenik:
                format = .notenik
            case yaml:
                format = .yaml
            case outline:
                format = .opml
            case concatHtml:
                format = .concatHtml
            case outlineHtml:
                format = .outlineHtml
            case concatMd:
                format = .concatMarkdown
            case webBookEPUB:
                format = .webBookEPUB
                generateWebBook(exportFormat: format)
                window.close()
                return
            case webBookSite:
                format = .webBookSite
                publishWebBookAsSite()
                window.close()
                return
            case webBookEPUBFolder:
                format = .webBookEPUBFolder
                generateWebBook(exportFormat: format)
                window.close()
                return
            default:
                format = .commaSeparated
            }
        }
        
        // See where the user wants to save it.
        var url: URL?
        switch format {
        case .notenik, .yaml, .webBookSite, .webBookEPUB, .exportScript:
            url = getFolderExportURL(format: format)
        default:
            url = getExportURL(fileExt: fileExtCombo.stringValue)
        }
        guard let destination = url else {
            window.close()
            return
        }
        
        // Now let's export.
        if format == .exportScript {
            runExportScript(scriptName: formatTitle, exportPath: url!.path)
        } else {
            let exporter = NotesExporter()
            let notesExported = exporter.export(noteIO: io!,
                                                format: format,
                                                useTagsExportPrefs: tagsExportPrefsCheckBox.state == .on,
                                                split: splitTagsCheckBox.state == .on,
                                                addWebExtensions: addWebExtensionsCheckBox.state == .on,
                                                destination: destination,
                                                ext: fileExtCombo.stringValue)
            let ok = notesExported > 0
            informUserOfImportExportResults(operation: "export",
                                            ok: ok,
                                            numberOfNotes: notesExported,
                                            path: destination.path)
        }
        
        window.close()
    }
    
    /// Ask the user where to save the export file.
    func getExportURL(fileExt: String, fileName: String = "export") -> URL? {
        
        let savePanel = NSSavePanel();
        
        savePanel.title = "Specify an output file"
        let parent = io!.collection!.fullPathURL
        if parent != nil {
            savePanel.directoryURL = parent
        }
        savePanel.showsResizeIndicator = true
        savePanel.showsHiddenFiles = false
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = fileName + "." + fileExt
        savePanel.prompt = "Export"
        let userChoice = savePanel.runModal()
        if userChoice == .OK {
            return savePanel.url
        } else {
            return nil
        }
    }
    
    /// Ask the user where to save the export folder.
    func getFolderExportURL(format: ExportFormat) -> URL? {
        let openPanel = NSOpenPanel();
        openPanel.title = "Select Folder for Export"
        let parent = osdir.directoryURL
        if parent != nil {
            openPanel.directoryURL = parent!
        }
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Export"
        let response = openPanel.runModal()
        if response == .OK {
            if format == .notenik {
                MultiFileIO.shared.registerBookmark(url: openPanel.url!)
            }
            return openPanel.url
        } else {
            return nil
        }
    }
    
    func runExportScript(scriptName: String, exportPath: String) {
        guard let lib = io?.collection?.lib else { return }
        guard lib.hasAvailable(type: .exportFolder) else { return }
        guard let exportFolderURL = lib.getURL(type: .exportFolder) else { return }
        let scriptURL = exportFolderURL.appendingPathComponent(scriptName).appendingPathExtension("tcz")
        let scriptPath = scriptURL.path
        let player = ScriptPlayer()
        player.playScript(fileName: scriptPath, exportPath: exportPath, templateOutputConsumer: nil)
    }
    
    /// Generate a Web Book of CSS and HTML pages, containing the entire Collection.
    func generateWebBook(exportFormat: ExportFormat) {
        
        var webBookType: WebBookType = .epub
        if exportFormat == .webBookEPUBFolder {
            webBookType = .epubsite
        }
        guard let collection = io?.collection else { return }
        
        let dialog = NSOpenPanel()
        
        if !collection.webBookPath.isEmpty {
            let webBookURL = URL(fileURLWithPath: collection.webBookPath)
            let parent = webBookURL.deletingLastPathComponent()
            dialog.directoryURL = parent
        }
        
        dialog.title                   = "Choose an Output Folder for your Web Book"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories    = true
        dialog.canChooseFiles          = false
        dialog.canCreateDirectories    = true
        
        let response = dialog.runModal()
         
        if response == .OK {
            let bookURL = dialog.url!
            let maker = WebBookMaker(input: collection.fullPathURL!, output: bookURL, webBookType: webBookType)
            if maker != nil {
                collection.webBookPath = bookURL.path
                collection.webBookAsEPUB = true
                let filesWritten = maker!.generate()
                informUserOfImportExportResults(operation: "Generate Web Book", ok: true, numberOfNotes: filesWritten, path: bookURL.path)
            }
        }
        
    }
    
    func publishWebBookAsSite() {
        
        guard let collection = io?.collection else { return }
        
        let dialog = NSOpenPanel()
        
        if !collection.webBookPath.isEmpty {
            let webBookURL = URL(fileURLWithPath: collection.webBookPath)
            let parent = webBookURL.deletingLastPathComponent()
            dialog.directoryURL = parent
        }
        
        dialog.title                   = "Choose an Output Folder for your Web Book"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories    = true
        dialog.canChooseFiles          = false
        dialog.canCreateDirectories    = true
        
        let response = dialog.runModal()
         
        if response == .OK {
            let bookURL = dialog.url!
            let maker = WebBookMaker(input: collection.fullPathURL!, output: bookURL, webBookType: .website)
            if maker != nil {
                collection.webBookPath = bookURL.path
                collection.webBookAsEPUB = false
                let filesWritten = maker!.generate()
                informUserOfImportExportResults(operation: "Generate Web Book", ok: true, numberOfNotes: filesWritten, path: bookURL.path)
            }
        }
        
    }
    
    /// Let the user know the results of an import/export operation
    ///
    /// - Parameters:
    ///   - operation: Either "import" or "export"
    ///   - ok: Was the operation successful?
    ///   - numberOfNotes: Number of notes imported or exported.
    ///   - path: The path to the export destination or the import source.
    func informUserOfImportExportResults(operation: String, ok: Bool, numberOfNotes: Int, path: String) {
        let alert = NSAlert()
        if ok {
            alert.alertStyle = .informational
            alert.messageText = "\(StringUtils.toUpperFirstChar(operation)) operation was performed on \(numberOfNotes) Notes"
            if operation == "import" {
                alert.informativeText = "Notes imported from '\(path)'"
            } else {
                alert.informativeText = "Notes exported to \(path)"
            }
        } else {
            alert.alertStyle = .critical
            if operation == "import" {
                alert.messageText = "Problems importing from \(path)"
            } else {
                alert.messageText = "Problems exporting to \(path)"
            }
            alert.informativeText = "Check Log Window for possible details"
        }
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        window.close()
    }
    
}
