//
//  NoteEditViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/28/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

/// Controls the view shown to allow the user to edit a note.
class NoteEditViewController: NSViewController {
    
    @IBOutlet var parentView: NSView!
    
    var collectionWindowController: CollectionWindowController?
    var notenikIO: NotenikIO?
    var modWhenChanged: ModWhenChanged?
    
    var selectedNote: Note?
    
    var initialViewLoaded  = false
    var containerViewBuilt = false
    
    var editViews: [CocoaEditView] = []
    var grid:      [[NSView]] = []
    var gridView:  NSGridView!
    
    var bodyView:    NSTextView!
    var bodyStorage: NSTextStorage!
    
    var dateView:   DateView?
    var recursView: CocoaEditView?
    var statusView: StatusView?
    
    var window: CollectionWindowController? {
        get {
            return collectionWindowController
        }
        set {
            collectionWindowController = newValue
        }
    }
    
    var io: NotenikIO? {
        get {
            return notenikIO
        }
        set {
            notenikIO = newValue
            containerViewBuilt = false
            guard notenikIO != nil && notenikIO!.collection != nil else { return }
            makeEditView()
            modWhenChanged = ModWhenChanged(io: notenikIO!)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewLoaded = true
        makeEditView()
    }
    
    /// Let's build the grid view to be used for editing the contents of a note
    func makeEditView() {
        
        // Make sure we have everything we need
        guard let collection = io?.collection else { return }
        guard io!.collectionOpen else { return }
        guard initialViewLoaded && !containerViewBuilt else { return }
        
        let dict = collection.dict
        let defs = dict.list
        
        // Let's build a two-dimensional array of views to be displayed in the grid

        editViews = []
        grid = []
        dateView = nil
        recursView = nil
        statusView = nil
        
        // Build the label and value views for each field in the dictionary
        for def in defs {
            makeEditRow(collection: collection, def: def)
        }
        
        if dateView != nil && recursView != nil {
            dateView!.recursView = recursView
        }
        
        makeGridView()
        
        containerViewBuilt = true
    }
    
    func makeEditRow(collection: NoteCollection, def: FieldDefinition) {
        let label = def.fieldLabel
        let labelView = makeLabelView(with: label)
        
        let editView = ViewFactory.getEditView(collection: collection, def: def)
        let valueView = editView.view
        
        editViews.append(editView)
        
        // Add the next row to the Grid View
        let row = [labelView, valueView]
        grid.append(row)
        
        if label.commonForm == LabelConstants.dateCommon {
            dateView = editView as? DateView
        } else if label.commonForm == LabelConstants.recursCommon {
            recursView = editView
        } else if label.commonForm == LabelConstants.statusCommon {
            statusView = editView as? StatusView
        }
    }
    
    /// Create a Grid View to hold the field labels and values to be edited
    func makeGridView() {
        gridView = NSGridView(views: grid)
        
        gridView.translatesAutoresizingMaskIntoConstraints = false

        parentView.addSubview(gridView!)
        
        // Pin the grid to the edges of our main view
        gridView!.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 8).isActive = true
        gridView!.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -8).isActive = true
        gridView!.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 8).isActive = true
        gridView!.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -8).isActive = true
    }
    
    /// Make a View to contain a field label
    func makeLabelView(with label: FieldLabel) -> NSView {
        let vw = NSTextField(labelWithString: label.properForm + ": ")
        return vw
    
    }
    
    /// Update appropriate stuff when a new note has been selected
    func select(note: Note) {
        
        guard let collection = io?.collection else { return }
        guard io!.collectionOpen else { return }
        guard initialViewLoaded && containerViewBuilt else { return }
        
        selectedNote = note
        
        populateFields(with: note)
    }
    
    /// Populate the Edit View fields with values from the given Note
    func populateFields(with note: Note) {
        let dict = note.collection.dict
        let defs = dict.list
        var i = 0
        for def in defs {
            let field = note.getField(def: def)
            var fieldView = editViews[i]
            if field == nil {
                fieldView.text = ""
            } else {
                let strVal = String(describing: field!.value)
                fieldView.text = strVal
            }
            i += 1
        }
        collectionWindowController!.pendingEdits = true
    }
    
    /// Close the note, either by applying the recurs rule, or changing the status to 9
    func closeNote() {
        if dateView != nil && recursView != nil && dateView!.text.count > 0 && recursView!.text.count > 0 {
            dateView!.applyRecursRule()
        } else if statusView != nil {
            statusView!.close()
        }
    }
    
    /// Modify the Note if the user has changed anything
    ///
    /// - Parameters:
    ///   - newNoteRequested: Are we trying to add a new note, rather than modify an existing one?
    ///   - newNote: A possible new note to start with
    func modIfChanged(newNoteRequested: Bool, newNote: Note?) -> (modIfChangedOutcome, Note?) {
        
        // print("NoteEditViewController.modIfChanged")
        var outcome: modIfChangedOutcome = .notReady
        
        // See if we're ready for this
        guard initialViewLoaded && containerViewBuilt else { return (outcome, nil) }
        guard window != nil else { return (outcome, nil) }
        guard modWhenChanged != nil else { return (outcome, nil) }
        guard selectedNote != nil || newNoteRequested else { return (outcome, nil) }
        
        // Let's run through the modIfChanged logic
        var inNote = selectedNote
        if newNoteRequested {
            inNote = newNote
        }
        var outNote: Note?
        (outcome, outNote) = modWhenChanged!.modIfChanged(newNoteRequested: newNoteRequested,
                                                          startingNote: inNote!,
                                                          modViews: editViews,
                                                          statusConfig: inNote!.collection.statusConfig)
        
        // If we tried to add a note but it had a key that already exists, then ask the user for help
        if outcome == .idAlreadyExists {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Note titled '\(outNote!.title)' already has the same ID"
            alert.informativeText = "Each Note in a Collection must have a unique ID"
            alert.addButton(withTitle: "Fix It")
            alert.addButton(withTitle: "Discard")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                outcome = .tryAgain
            } else {
                outcome = .discard
            }
        }
        
        // See if a new note needs to be selected.
        if (outcome == .add || outcome == .deleteAndAdd) && outNote != nil {
            selectedNote = outNote
        }

        return (outcome, outNote)
    } // end modIfChanged method
}
