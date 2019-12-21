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
    let tabDelim  = "Tab-Delimited"
    let bookmarks = "Netscape Bookmark File"
    
    let csv = "csv"
    let tab = "tab"
    let txt = "txt"
    let htm = "htm"
    let html = "html"
    let json = "json"
    
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
        formatPopup.addItem(withTitle: bookmarks)
        formatPopup.selectItem(at: 0)
        
        fileExtCombo.removeAllItems()
        fileExtCombo.addItem(withObjectValue: csv)
        fileExtCombo.addItem(withObjectValue: tab)
        fileExtCombo.addItem(withObjectValue: txt)
        fileExtCombo.addItem(withObjectValue: json)
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
            }
        }
    }
    
    /// The user clicked ok -- let's go ahead and export now. 
    @IBAction func okButtonPressed(_ sender: Any) {
        
        io = window.io
        
        guard let destination = getExportURL(fileExt: fileExtCombo.stringValue) else {
            window.close()
            return
        }
        
        var format = NoteFormat.commaSeparated
        if formatPopup.selectedItem != nil {
            if formatPopup.selectedItem!.title == tabDelim {
                format = .tabDelimited
            } else if formatPopup.selectedItem!.title == jsonTitle {
                format = .json
            } else if formatPopup.selectedItem!.title == bookmarks {
                format = .bookmarks
            }
        }
        
        let exporter = NotesExporter()
        let notesExported = exporter.export(noteIO: io,
                                            format: format,
                                            useTagsExportPrefs: tagsExportPrefsCheckBox.state == .on,
                                            split: splitTagsCheckBox.state == .on,
                                            addWebExtensions: addWebExtensionsCheckBox.state == .on,
                                            destination: destination)
        let ok = notesExported > 0
        informUserOfImportExportResults(operation: "export",
                                        ok: ok,
                                        numberOfNotes: notesExported,
                                        path: destination.path)
        
        window.close()
    }
    
    /// Ask the user where to save the export file
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
