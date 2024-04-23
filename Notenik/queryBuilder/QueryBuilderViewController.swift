//
//  QueryBuilderViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/15/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

class QueryBuilderViewController: NSViewController {
    
    let cocoaPrefs = AppPrefsCocoa.shared
    let displayPrefs = DisplayPrefs.shared
    
    var collectionWC: CollectionWindowController!
    var windowController: QueryBuilderWindowController?
    
    @IBOutlet weak var queryNameTextField: NSTextField!
    
    @IBOutlet weak var parentView: NSView!
    
    var subView: NSView?
    
    var collection: NoteCollection!
    var fields: [FieldDefinition] = []
    
    var grid:      [[NSView]] = []
    var gridView:  NSGridView!
    
    var templateWriter = Markedup(format: .htmlDoc)
    var scriptWriter: DelimitedWriter!
    
    var reportRunner: ReportRunner?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public var io: NotenikIO? {
        get {
            return _nio
        }
        set {
            _nio = newValue
            buildView()
        }
    }
    var _nio: NotenikIO?
    
    func buildView() {
        guard io != nil && io!.collection != nil else { return }
        collection = io!.collection!
        queryNameTextField.stringValue = "query"
        fields = collection.dict.list
        
        let column1Header = NSTextField(labelWithString: "Field")
        cocoaPrefs.setLabelFont(object: column1Header)
        let column2Header = NSTextField(labelWithString: "Order")
        cocoaPrefs.setLabelFont(object: column2Header)
        let column3Header = NSTextField(labelWithString: "Filter")
        cocoaPrefs.setLabelFont(object: column3Header)
        let column4Header = NSTextField(labelWithString: "Literal")
        cocoaPrefs.setLabelFont(object: column4Header)
        let headerRow = [column1Header, column2Header, column3Header, column4Header]
        grid.append(headerRow)
        
        for def in fields {
            
            let label = def.fieldLabel
            let str = AppPrefsCocoa.shared.makeUserAttributedString(text: label.properForm, usage: .labels)
            let labelView = NSTextField(labelWithAttributedString: str)
            
            let sel = NSPopUpButton()
            sel.addItems(withTitles: [" ", "1", "2", "3", "4", "5", "X"])
            cocoaPrefs.setTextEditingFont(object: sel)
            
            let op = NSPopUpButton()
            op.addItems(withTitles: ["  ", "eq", "gt", "ge", "lt", "le", "ne", "co", "nc", "st", "ns", "fi", "nf"])
            cocoaPrefs.setTextEditingFont(object: op)
            
            let text = NSTextField(string: "")
            cocoaPrefs.setTextEditingFont(object: text)
            
            let row = [labelView, sel, op, text]
            grid.append(row)
        }
        
        switch collection.sortParm {
        case .title:
            setSelector(labelOrType: NotenikConstants.title, sortSeq: 1)
        case .seqPlusTitle:
            setSelector(labelOrType: NotenikConstants.seq, sortSeq: 1)
            setSelector(labelOrType: NotenikConstants.title, sortSeq: 2)
        case .tasksByDate:
            setSelector(labelOrType: NotenikConstants.date, sortSeq: 1)
        case .tasksBySeq:
            setSelector(labelOrType: NotenikConstants.seq, sortSeq: 1)
        case .author:
            setSelector(labelOrType: NotenikConstants.author, sortSeq: 1)
            setSelector(labelOrType: NotenikConstants.title, sortSeq: 2)
        case .tagsPlusTitle:
            setSelector(labelOrType: NotenikConstants.tags, sortSeq: 1)
            setSelector(labelOrType: NotenikConstants.title, sortSeq: 2)
        case .tagsPlusSeq:
            setSelector(labelOrType: NotenikConstants.tags, sortSeq: 1)
            setSelector(labelOrType: NotenikConstants.seq, sortSeq: 2)
        case .custom:
            setSelector(labelOrType: NotenikConstants.title, sortSeq: 1)
        case .dateAdded:
            setSelector(labelOrType: NotenikConstants.dateAdded, sortSeq: 1)
        case .dateModified:
            setSelector(labelOrType: NotenikConstants.dateModified, sortSeq: 1)
        case .datePlusSeq:
            setSelector(labelOrType: NotenikConstants.date, sortSeq: 1)
            setSelector(labelOrType: NotenikConstants.seq,  sortSeq: 2)
        case .rankSeqTitle:
            setSelector(labelOrType: NotenikConstants.rank, sortSeq: 1)
            setSelector(labelOrType: NotenikConstants.seq,  sortSeq: 2)
            setSelector(labelOrType: NotenikConstants.title, sortSeq: 3)
        case .klassTitle:
            setSelector(labelOrType: NotenikConstants.klass, sortSeq: 1)
            setSelector(labelOrType: NotenikConstants.title, sortSeq: 2)
        case .klassDateTitle:
            setSelector(labelOrType: NotenikConstants.klass, sortSeq: 1)
            setSelector(labelOrType: NotenikConstants.date,  sortSeq: 2)
            setSelector(labelOrType: NotenikConstants.title, sortSeq: 3)
        case .folderTitle:
            setSelector(labelOrType: NotenikConstants.folder, sortSeq: 1)
            setSelector(labelOrType: NotenikConstants.title, sortSeq: 2)
        case .folderDateTitle:
            setSelector(labelOrType: NotenikConstants.folder, sortSeq: 1)
            setSelector(labelOrType: NotenikConstants.date,  sortSeq: 2)
            setSelector(labelOrType: NotenikConstants.title, sortSeq: 3)
        case .folderSeqTitle:
            setSelector(labelOrType: NotenikConstants.folder, sortSeq: 1)
            setSelector(labelOrType: NotenikConstants.seq, sortSeq: 2)
            setSelector(labelOrType: NotenikConstants.title, sortSeq: 3)
        case .lastNameFirst:
            if collection.personDef != nil {
                setSelector(labelOrType: NotenikConstants.person, sortSeq: 1)
            } else if collection.authorDef != nil {
                setSelector(labelOrType: NotenikConstants.author, sortSeq: 1)
            } else {
                setSelector(labelOrType: NotenikConstants.title, sortSeq: 1)
            }
        }
        
        gridView = NSGridView(views: grid)
        
        gridView.translatesAutoresizingMaskIntoConstraints = false
        
        if subView == nil {
            parentView.addSubview(gridView)
        } else {
            parentView.replaceSubview(subView!, with: gridView!)
        }

        subView = gridView
        
        // Pin the grid to the edges of our main view
        gridView!.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 8).isActive = true
        gridView!.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -8).isActive = true
        gridView!.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 8).isActive = true
        gridView!.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -8).isActive = true

    }
    
    func setSelector(labelOrType: String, sortSeq: Int) {
        let id = StringUtils.toCommon(labelOrType)
        var rowIndex = 0
        while rowIndex < fields.count {
            let def = fields[rowIndex]
            if id == def.fieldLabel.commonForm || id == def.fieldType.typeString {
                let row = grid[rowIndex + 1]
                let cell = row[1]
                if let sel = cell as? NSPopUpButton {
                    sel.selectItem(at: sortSeq)
                }
            }
            rowIndex += 1
        }
    }
    
    @IBAction func okButtonClicked(_ sender: Any) {
        buildAndRunQuery()
        closeWindow()
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        closeWindow()
    }
    
    func closeWindow() {
        guard windowController != nil else { return }
        windowController!.close()
    }
    
    /// Now build and run the requested query.
    func buildAndRunQuery() {
        
        guard io != nil && io!.collection != nil else { return }
        
        var qName = StringUtils.trim(queryNameTextField.stringValue)
        if qName.isEmpty {
            qName = "query"
        }
        
        // Build the Merge Template
        let columnIndices = determineColumns()
        templateWriter = Markedup(format: .htmlDoc)
        templateWriter.templateOutput(filename: "\(qName).html")
        templateWriter.startDoc(withTitle: "Notenik Query",
                        withCSS: displayPrefs.displayCSS,
                        linkToFile: false,
                        withJS: nil)
        templateWriter.heading(level: 1, text: collection.title)
        templateWriter.heading(level: 2, text: qName)
        templateWriter.startParagraph()
        templateWriter.startEmphasis()
        templateWriter.write("Generated on =$today&EEEE, MMMM d, yyyy$=")
        templateWriter.finishEmphasis()
        templateWriter.finishParagraph()
        templateWriter.startTable()
        templateWriter.startTableRow()
        for columnIndex in columnIndices {
            templateWriter.startTableHeader()
            let def = fields[columnIndex]
            templateWriter.write(def.fieldLabel.properForm)
            templateWriter.finishTableHeader()
        }
        templateWriter.finishTableRow()
        templateWriter.templateNextRec()
        templateWriter.startTableRow()
        for columnIndex in columnIndices {
            genColumn(rowIndex: columnIndex)
        }
        templateWriter.finishTableRow()
        templateWriter.templateLoop()
        templateWriter.finishTable()
        templateWriter.finishDoc()
        
        let reportsResource = collection.lib.getResource(type: .reports)
        guard reportsResource.ensureExistence() else { return }
        guard let reportsFolderURL = reportsResource.url else { return }
        let templateURL = reportsFolderURL.appendingPathComponent("\(qName)_template.html")
        
        do {
          try templateWriter.code.write(to: templateURL, atomically: false, encoding: .utf8)
        } catch {
            communicateError("Error saving query merge template to \(templateURL)")
            return
        }
        
        // Now build the Script file.
        let scriptURL = reportsFolderURL.appendingPathComponent("\(qName)_script.tcz")
        scriptWriter = DelimitedWriter(destination: scriptURL, format: .tabDelimited)
        scriptWriter.open()
        
        scriptWriter.write(value: "module")
        scriptWriter.write(value: "action")
        scriptWriter.write(value: "modifier")
        scriptWriter.write(value: "object")
        scriptWriter.write(value: "value")
        scriptWriter.endLine()
        
        scriptWriter.write(value: "input")
        scriptWriter.write(value: "set")
        scriptWriter.write(value: "")
        scriptWriter.write(value: "xpltags")
        scriptWriter.write(value: "false")
        scriptWriter.endLine()
        
        scriptWriter.write(value: "input")
        scriptWriter.write(value: "set")
        scriptWriter.write(value: "")
        scriptWriter.write(value: "dirdepth")
        scriptWriter.write(value: "1")
        scriptWriter.endLine()
        
        scriptWriter.write(value: "input")
        scriptWriter.write(value: "open")
        scriptWriter.write(value: "notenik-defined")
        scriptWriter.write(value: "")
        scriptWriter.write(value: "\(collection.fullPath)")
        scriptWriter.endLine()
        
        scriptWriter.write(value: "filter")
        scriptWriter.write(value: "clear")
        scriptWriter.write(value: "")
        scriptWriter.write(value: "")
        scriptWriter.write(value: "")
        scriptWriter.endLine()
        
        var rowIndex = 0
        while rowIndex < fields.count {
            let row = grid[rowIndex + 1]
            let cell3 = row[2]
            let cell4 = row[3]
            var literal = ""
            if let litField = cell4 as? NSTextField {
                literal = litField.stringValue
            }
            if let opButton = cell3 as? NSPopUpButton {
                if let opTitle = opButton.titleOfSelectedItem {
                    let trimmed = StringUtils.trim(opTitle)
                    if !trimmed.isEmpty  {
                        scriptWriter.write(value: "filter")
                        scriptWriter.write(value: "add")
                        scriptWriter.write(value: trimmed)
                        scriptWriter.write(value: fields[rowIndex].fieldLabel.commonForm)
                        scriptWriter.write(value: literal)
                        scriptWriter.endLine()
                    }
                }
            }
            rowIndex += 1
        }
        
        scriptWriter.write(value: "filter")
        scriptWriter.write(value: "set")
        scriptWriter.write(value: "")
        scriptWriter.write(value: "params")
        scriptWriter.write(value: "")
        scriptWriter.endLine()
        
        scriptWriter.write(value: "sort")
        scriptWriter.write(value: "clear")
        scriptWriter.write(value: "")
        scriptWriter.write(value: "")
        scriptWriter.write(value: "")
        scriptWriter.endLine()
        
        for columnIndex in columnIndices {
            let def = fields[columnIndex]
            let row = grid[columnIndex + 1]
            let selCell = row[1]
            if let selField = selCell as? NSPopUpButton {
                if let selTitle = selField.titleOfSelectedItem {
                    if !selTitle.isEmpty && selTitle != "X" && selTitle != " " {
                        scriptWriter.write(value: "sort")
                        scriptWriter.write(value: "add")
                        scriptWriter.write(value: "ascending")
                        scriptWriter.write(value: def.fieldLabel.commonForm)
                        scriptWriter.write(value: "")
                        scriptWriter.endLine()
                    }
                }
            }
        }
        
        scriptWriter.write(value: "sort")
        scriptWriter.write(value: "set")
        scriptWriter.write(value: "")
        scriptWriter.write(value: "params")
        scriptWriter.write(value: "")
        scriptWriter.endLine()
        
        scriptWriter.write(value: "template")
        scriptWriter.write(value: "open")
        scriptWriter.write(value: "")
        scriptWriter.write(value: "")
        scriptWriter.write(value: templateURL.path)
        scriptWriter.endLine()
        
        scriptWriter.write(value: "template")
        scriptWriter.write(value: "generate")
        scriptWriter.write(value: "")
        scriptWriter.write(value: "")
        scriptWriter.write(value: "")
        scriptWriter.endLine()
        
        let ok = scriptWriter.close()
        if !ok { return }
        
        io!.loadReports()
        collectionWC.buildReportsActionMenu()
        
        // Now run the script.
        reportRunner = ReportRunner(io: io!)
        let report = MergeReport(reportName: "\(qName)_script", reportType: "tcz")
        _ = reportRunner!.runReport(report)
        
        // let player = ScriptPlayer()
        // let scriptPath = scriptURL.path
        // let qol = QueryOutputLauncher(windowTitle: "Script Output")
        // player.playScript(fileName: scriptPath, templateOutputConsumer: qol)
    }
    
    func determineColumns() -> [Int] {
        var columnIndices: [Int] = []
        addToColumns(sel: "1", columnIndices: &columnIndices)
        addToColumns(sel: "2", columnIndices: &columnIndices)
        addToColumns(sel: "3", columnIndices: &columnIndices)
        addToColumns(sel: "4", columnIndices: &columnIndices)
        addToColumns(sel: "5", columnIndices: &columnIndices)
        var xIndex = nextFieldWith(sel: "X")
        while xIndex >= 0 && xIndex < fields.count {
            columnIndices.append(xIndex)
            xIndex = nextFieldWith(sel: "X", startingRow: xIndex + 1)
        }
        return columnIndices
    }
    
    func addToColumns(sel: String, columnIndices: inout [Int]) {
        let index = nextFieldWith(sel: sel)
        if index >= 0 && index < fields.count {
            columnIndices.append(index)
        }
    }
    
    func nextFieldWith(sel: String, startingRow: Int = 0) -> Int {
        var rowIndex = startingRow
        while rowIndex < fields.count {
            let row = grid[rowIndex + 1]
            let cell = row[1]
            if let rowSel = cell as? NSPopUpButton {
                if let title = rowSel.titleOfSelectedItem {
                    if title == sel {
                        return rowIndex
                    }
                }
            }
            rowIndex += 1
        }
        return NSNotFound
    }
    
    func genColumn(rowIndex: Int) {
        guard rowIndex >= 0 else { return }
        guard rowIndex < fields.count else { return }
        templateWriter.startTableData()
        let def = fields[rowIndex]
        var mods: String = ""
        switch def.fieldType.typeString {
        case NotenikConstants.bodyCommon, NotenikConstants.teaserCommon, NotenikConstants.longTextType:
            mods = "&o"
        default:
            break
        }
        if def.fieldLabel.commonForm == NotenikConstants.titleCommon || def.fieldType.typeString == NotenikConstants.titleCommon {
            let str = CustomURLFormatter().openWithUniqueID(collection: collection)
            templateWriter.link(text: "=$\(def.fieldLabel.commonForm)\(mods)$=", path: str)
        } else {
            templateWriter.templateVariable(name: fields[rowIndex].fieldLabel.commonForm, mods: mods)
        }
        templateWriter.finishTableData()
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                          category: "QueryBuilderViewController",
                          level: .error,
                          message: msg)
        
        if alert {
            let dialog = NSAlert()
            dialog.alertStyle = .warning
            dialog.messageText = msg
            dialog.addButton(withTitle: "OK")
            let _ = dialog.runModal()
        }
    }
}
