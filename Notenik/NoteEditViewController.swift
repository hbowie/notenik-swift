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

import NotenikLib
import NotenikUtils

/// Controls the view shown to allow the user to edit a note.
class NoteEditViewController: NSViewController {
    
    @IBOutlet var parentView: NSView!
    
    var subView: NSView?
    
    var collectionWindowController: CollectionWindowController?
    var notenikIO: NotenikIO?
    var modWhenChanged: ModWhenChanged?
    
    var selectedNote: Note?
    
    var initialViewLoaded  = false
    var containerViewBuilt = false
    
    var editDefs:  [FieldDefinition] = []
    var editViews: [MacEditView] = []
    var grid:      [[NSView]] = []
    var gridView:  NSGridView!
    
    var bodyView:    NSTextView!
    var bodyStorage: NSTextStorage!
    
    var titleView:  MacEditView?
    var dateView:   DateView?
    var recursView: MacEditView?
    var statusView: StatusView?
    var levelView:  LevelView?
    var linkView:   LinkView?
    var imageNameView: ImageNameView?
    
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
            configureEditView(noteIO: notenikIO!, klassName: nil)
            modWhenChanged = ModWhenChanged(io: notenikIO!)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewLoaded = true
        guard notenikIO != nil && notenikIO!.collection != nil else { return }
        configureEditView(noteIO: notenikIO!, klassName: nil)
    }
    
    func configureEditView(noteIO: NotenikIO, klassName: String? = nil) {
        guard initialViewLoaded else { return }
        guard let collection = noteIO.collection else { return }
        containerViewBuilt = false
        var fieldDefs = collection.dict.list
        if collection.klassFieldDef != nil && klassName != nil && !klassName!.isEmpty {
            for klass in collection.klassDefs {
                if klass.name == klassName! {
                    fieldDefs = klass.fieldDefs
                    break
                }
            }
        }
        editDefs = []
        for def in fieldDefs {
            if def.fieldType.userEditable {
                editDefs.append(def)
            }
        }
        
        noteIO.pickLists.statusConfig = collection.statusConfig
        noteIO.pickLists.levelConfig = collection.levelConfig
        
        // Let's build a two-dimensional array of views to be displayed in the grid

        editViews = []
        grid = []
        dateView = nil
        recursView = nil
        statusView = nil
        levelView = nil
        linkView = nil
        imageNameView = nil
        
        // Build the label and value views for each field in the dictionary
        for def in editDefs {
            makeEditRow(collection: collection, def: def)
        }
        
        if dateView != nil && recursView != nil {
            dateView!.recursView = recursView
        }
        
        makeGridView()
        
        containerViewBuilt = true
    }
    
    func makeEditRow(collection: NoteCollection, def: FieldDefinition) {
        
        guard def.fieldType.typeString != NotenikConstants.backlinksCommon else { return }
        guard def.fieldType.typeString != NotenikConstants.wikilinksCommon else { return }
        
        let label = def.fieldLabel
        let labelView = makeLabelView(with: label)
        
        let editView = ViewFactory.getEditView(pickLists: notenikIO!.pickLists, def: def)
        let valueView = editView.view
        
        editViews.append(editView)
        
        // Add the next row to the Grid View
        let row = [labelView, valueView]
        grid.append(row)
        
        if label.commonForm == NotenikConstants.titleCommon {
            titleView = editView
        } else if def.fieldType.typeString == NotenikConstants.titleCommon {
            titleView = editView
        } else if label.commonForm == NotenikConstants.dateCommon {
            dateView = editView as? DateView
        } else if label.commonForm == NotenikConstants.recursCommon {
            recursView = editView
        } else if label.commonForm == NotenikConstants.statusCommon {
            statusView = editView as? StatusView
        } else if label.commonForm == NotenikConstants.levelCommon {
            levelView = editView as? LevelView
        } else if label.commonForm == NotenikConstants.linkCommon {
            linkView = editView as? LinkView
        } else if def.fieldType.typeString == NotenikConstants.linkCommon {
            linkView = editView as? LinkView
        }
    }
    
    /// Create a Grid View to hold the field labels and values to be edited
    func makeGridView() {
        gridView = NSGridView(views: grid)
        
        gridView.translatesAutoresizingMaskIntoConstraints = false

        if subView == nil {
            parentView.addSubview(gridView)
        } else {
            parentView.replaceSubview(subView!, with: gridView)
        }
        subView = gridView
        
        // Pin the grid to the edges of our main view
        gridView!.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 8).isActive = true
        gridView!.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -8).isActive = true
        gridView!.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 8).isActive = true
        gridView!.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -8).isActive = true
    }
    
    /// Make a View to contain a field label
    func makeLabelView(with label: FieldLabel) -> NSView {
        let str = AppPrefsCocoa.shared.makeUserAttributedString(text: label.properForm + ": ")
        let vw = NSTextField(labelWithAttributedString: str)
        return vw
    
    }
    
    /// Update appropriate stuff when a new note has been selected
    func select(note: Note) {
        
        guard io != nil else { return }
        guard io!.collection != nil else { return }
        guard io!.collectionOpen else { return }
        guard initialViewLoaded && containerViewBuilt else { return }
        
        selectedNote = note
        if io!.collection!.klassFieldDef != nil {
            let klassName = note.klass.value
            if !klassName.isEmpty {
                configureEditView(noteIO: io!, klassName: klassName)
            }
        }
        populateFieldsWithSelectedNote()
    }
    
    /// Populate the Edit View's fields with data from the currently selected Note.
    func populateFieldsWithSelectedNote() {
        if selectedNote != nil {
            populateFields(with: selectedNote!)
        }
    }
    
    /// Populate the Edit View fields with values from the given Note
    func populateFields(with note: Note) {
        var i = 0
        for def in editDefs {
            let field = note.getField(def: def)
            guard i < editViews.count else {
                continue
            }
            var fieldView = editViews[i]
            if fieldView is ImageNameView {
                let imageNameView = fieldView as! ImageNameView
                imageNameView.customizeForNote(note)
            }
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
    
    /// Set the link field on the edit screen
    func setLink(_ localLink: String) {
        if linkView != nil {
            linkView!.text = localLink
        }
    }
    
    /// Close the note, either by applying the recurs rule, or changing the status to 9
    func closeNote() {
        if dateView != nil && recursView != nil && dateView!.text.count > 0 && recursView!.text.count > 0 {
            dateView!.applyRecursRule()
        } else if statusView != nil {
            statusView!.close()
        }
    }
    
    func wikipediaLink() {
        guard titleView != nil else {
            return
        }
        let title = titleView!.text
        guard !title.isEmpty else { return }
        guard linkView != nil else {
            return
        }
        linkView!.text = StringUtils.wikify(title)
    }
    
    /// Modify the Note if the user has changed anything
    ///
    /// - Parameters:
    ///   - newNoteRequested: Are we trying to add a new note, rather than modify an existing one?
    ///   - newNote: A possible new note to start with
    func modIfChanged(newNoteRequested: Bool, newNote: Note?) -> (modIfChangedOutcome, Note?) {
        
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
                                                          editDefs: editDefs,
                                                          modViews: editViews,
                                                          statusConfig: inNote!.collection.statusConfig,
                                                          levelConfig: inNote!.collection.levelConfig)
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
