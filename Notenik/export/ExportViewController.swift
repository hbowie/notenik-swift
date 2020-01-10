//
//  ExportViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/18/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class ExportViewController: NSViewController {
    
    var window: ExportWindowController!
    var io: NotenikIO!
    
    let commaSep  = "Comma-Separated"
    let jsonTitle = "JSON"
    let notenik   = "Notenik"
    let tabDelim  = "Tab-Delimited"
    let bookmarks = "Netscape Bookmark File"
    let osdir     = OpenSaveDirectory.shared
    
    let csv     = "csv"
    let htm     = "htm"
    let html    = "html"
    let json    = "json"
    let md      = "md"
    let tab     = "tab"
    let txt     = "txt"
    
    @IBOutlet var formatPopup: NSPopUpButton!
    @IBOutlet var fileExtCombo: NSComboBox!
    @IBOutlet var tagsExportPrefsCheckBox: NSButton!
    @IBOutlet var splitTagsCheckBox: NSButton!
    @IBOutlet var addWebExtensionsCheckBox: NSButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatPopup.removeAllItems()
        formatPopup.addItem(withTitle: commaSep)
        formatPopup.addItem(withTitle: tabDelim)
        formatPopup.addItem(withTitle: jsonTitle)
        formatPopup.addItem(withTitle: notenik)
        formatPopup.addItem(withTitle: bookmarks)
        formatPopup.selectItem(at: 0)
        
        fileExtCombo.removeAllItems()
        fileExtCombo.addItem(withObjectValue: csv)
        fileExtCombo.addItem(withObjectValue: tab)
        fileExtCombo.addItem(withObjectValue: txt)
        fileExtCombo.addItem(withObjectValue: json)
        fileExtCombo.addItem(withObjectValue: md)
        fileExtCombo.addItem(withObjectValue: htm)
        fileExtCombo.addItem(withObjectValue: html)
        fileExtCombo.selectItem(at: 0)
    }
    
    @IBAction func formatAction(_ sender: Any) {
        if let selectedFormat = formatPopup.selectedItem {
            if selectedFormat.title == commaSep {
                fileExtCombo.selectItem(withObjectValue: csv)
            } else if selectedFormat.title == tabDelim {
                fileExtCombo.selectItem(withObjectValue: txt)
            } else if selectedFormat.title == jsonTitle {
                fileExtCombo.selectItem(withObjectValue: json)
            } else if selectedFormat.title == bookmarks {
                fileExtCombo.selectItem(withObjectValue: htm)
                splitTagsCheckBox.state = .on
            } else if selectedFormat.title == notenik {
                fileExtCombo.selectItem(withObjectValue: txt)
                splitTagsCheckBox.state = .off
            }
        }
    }
    
    /// The user clicked ok -- let's go ahead and export now. 
    @IBAction func okButtonPressed(_ sender: Any) {
        
        io = window.io
        
        // Figure out the desired output format.
        var formatTitle = commaSep
        var format = ExportFormat.commaSeparated
        if formatPopup.selectedItem != nil {
            formatTitle = formatPopup.selectedItem!.title
        }
        switch formatTitle {
        case tabDelim:
            format = .tabDelimited
        case jsonTitle:
            format = .json
        case bookmarks:
            format = .bookmarks
        case notenik:
            format = .notenik
        default:
            format = .commaSeparated
        }
        
        // See where the user wants to save it.
        var url: URL?
        if format == .notenik {
            url = getNotenikExportURL()
        } else {
            url = getExportURL(fileExt: fileExtCombo.stringValue)
        }
        guard let destination = url else {
            window.close()
            return
        }
        
        // Now let's export. 
        let exporter = NotesExporter()
        let notesExported = exporter.export(noteIO: io,
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
        
        window.close()
    }
    
    /// Ask the user where to save the export file.
    func getExportURL(fileExt: String, fileName: String = "export") -> URL? {
        
        let savePanel = NSSavePanel();
        savePanel.title = "Specify an output file"
        let parent = io!.collection!.collectionFullPathURL
        if parent != nil {
            savePanel.directoryURL = parent!
        }
        savePanel.showsResizeIndicator = true
        savePanel.showsHiddenFiles = false
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = fileName + "." + fileExt
        let userChoice = savePanel.runModal()
        if userChoice == .OK {
            return savePanel.url
        } else {
            return nil
        }
    }
    
    /// Ask the user where to save the export folder.
    func getNotenikExportURL() -> URL? {
        let openPanel = NSOpenPanel();
        openPanel.title = "Create a New Notenik Folder"
        let parent = osdir.directoryURL
        if parent != nil {
            openPanel.directoryURL = parent!
        }
        // openPanel.directoryURL = home
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        let response = openPanel.runModal()
        if response == .OK {
            return openPanel.url
        } else {
            return nil
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
