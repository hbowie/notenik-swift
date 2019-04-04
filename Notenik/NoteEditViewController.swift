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
    
    var selectedNote: Note?
    
    var initialViewLoaded  = false
    var containerViewBuilt = false
    
    var editViews: [EditView] = []
    var grid:      [[NSView]] = []
    var gridView:  NSGridView!
    
    var bodyView:    NSTextView!
    var bodyStorage: NSTextStorage!
    
    var vStack = NSStackView()
    
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
        
        // Create a Vertical Stack View to contain the rows of fields to be edited.
        vStack = NSStackView()
        vStack.orientation = .vertical
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Let's build a two-dimensional array of views to be displayed in the grid

        editViews = []
        grid = []
        
        // Build the label and value views for each field in the dictionary
        for def in defs {
            
            let label = def.fieldLabel
            let labelView = makeLabelView(with: label)
            
            let editView = ViewFactory.getEditView(def: def)
            let valueView = editView.view
            
            editViews.append(editView)
            
            // Build a horizontal stack for this field and add it to our vertical stack
            let hStack = NSStackView()
            hStack.orientation = .horizontal
            // hStack.translatesAutoresizingMaskIntoConstraints = false
            // hStack.alignment = .top
            hStack.addArrangedSubview(labelView)
            hStack.addArrangedSubview(editView.view)
            vStack.addArrangedSubview(hStack)
            
            // Add the next row to the Grid View
            let row = [labelView, valueView]
            grid.append(row)
        }
        
        makeGridView()
        // makeStackView()
        
        containerViewBuilt = true
    }
    
    func makeStackView() {
        print ("Making Stack View")
        parentView.addSubview(vStack)
        vStack.leadingAnchor.constraint(equalTo: parentView.leadingAnchor).isActive = true
        vStack.trailingAnchor.constraint(equalTo: parentView.trailingAnchor).isActive = true
        vStack.topAnchor.constraint(equalTo: parentView.topAnchor).isActive = true
        vStack.bottomAnchor.constraint(equalTo: parentView.bottomAnchor).isActive = true
    }
    
    func makeGridView() {
        print ("Making Grid View")
        gridView = NSGridView(views: grid)
        // gridView = NSGridView(numberOfColumns: 2, rows: 0)
        // for row in grid {
        //     gridView!.addRow(with: row)
        // }
        // gridView!.setContentHuggingPriority(600, for: .horizontal)
        // gridView!.setContentHuggingPriority(600, for: .vertical)
        
        gridView.translatesAutoresizingMaskIntoConstraints = false
        // gridView.column(at: 0).width = 100
        // gridView.column(at: 0).xPlacement = .trailing
        // gridView.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 600), for: .horizontal)
        // gridView.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 600), for: .vertical)
        // gridView.column(at: 1).width = 200
        // scrollView.documentView = gridView
        parentView.addSubview(gridView!)
        // scrollView.contentView.scroll(to: .zero)
        
        // Pin the grid to the edges of our main view
        gridView!.leadingAnchor.constraint(equalTo: parentView.leadingAnchor).isActive = true
        gridView!.trailingAnchor.constraint(equalTo: parentView.trailingAnchor).isActive = true
        gridView!.topAnchor.constraint(equalTo: parentView.topAnchor).isActive = true
        gridView!.bottomAnchor.constraint(equalTo: parentView.bottomAnchor).isActive = true
    }
    
    func makeLabelView(with label: FieldLabel) -> NSView {
        let vw = NSTextField(labelWithString: label.properForm + ": ")
        // vw.translatesAutoresizingMaskIntoConstraints = false
        // vw.isEditable = false
        // vw.isSelectable = false
        // vw.alignment = .left
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
    }
    
    /// Modify the Note if the user has changed anything
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - newNoteRequested: Are we trying to add a new note, rather than modify an existing one?
    ///   - newNote: A possible new note to start with
    func modIfChanged(newNoteRequested: Bool, newNote: Note?) -> (modIfChangedOutcome, Note?) {
        
        var outcome: modIfChangedOutcome = .notReady
        
        // See if we're ready for this
        guard let collection = io?.collection else { return (outcome, nil) }
        guard io!.collectionOpen else { return (outcome, nil) }
        guard initialViewLoaded && containerViewBuilt else { return (outcome, nil) }
        guard window != nil else { return (outcome, nil) }
        guard selectedNote != nil || newNoteRequested else { return (outcome, nil) }
        
        outcome = .noChange
        
        // Let's get a Note ready for comparison and possible modifications
        var modNote: Note
        if newNoteRequested {
            modNote = newNote!
        } else {
            modNote = selectedNote!.copy() as! Note
        }
        
        // See if any fields were modified by the user, and update corresponding Note fields
        var modified = false
        let dict = collection.dict
        let defs = dict.list
        var i = 0
        for def in defs {
            let field = modNote.getField(def: def)
            var fieldView = editViews[i]
            var noteValue = ""
            if field != nil {
                noteValue = field!.value.value
            }
            let userValue = fieldView.text
            if userValue != noteValue {
                print("\(def.fieldLabel.properForm) changed!")
                if field == nil {
                    modNote.addField(def: def, strValue: userValue)
                } else {
                    field!.value.set(userValue)
                }
                modified = true
            }
            i += 1
        }
        
        // Were any fields modified?
        if modified {
            outcome = .modify
            let modID = modNote.noteID
            
            // If we have a new Note ID, make sure it's unique
            var newID = newNoteRequested
            if newNoteRequested {
                outcome = .add
            }
            if !newNoteRequested {
                newID = (selectedNote!.noteID != modID)
                if newID {
                    outcome = .deleteAndAdd
                }
            }
            if newID {
                let existingNote = io!.getNote(forID: modID)
                if existingNote != nil {
                    let alert = NSAlert()
                    alert.alertStyle = .warning
                    alert.messageText = "Note titled '\(existingNote!.title)' already has the same ID"
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
            }
            if outcome == .modify {
                if selectedNote!.sortKey != modNote.sortKey {
                    outcome = .deleteAndAdd
                }
            }
        }
        // Figure out what we need to do
        switch outcome {
        case .notReady:
            return (outcome, nil)
        case .noChange:
            return (outcome, nil)
        case .tryAgain:
            return (outcome, nil)
        case .discard:
            return (outcome, nil)
        case .add:
            let (addedNote, addedPosition) = io!.addNote(newNote: modNote)
            if addedNote != nil {
                selectedNote = addedNote
                return (outcome, modNote)
            } else {
                print ("Problems adding note titled \(modNote.title)")
                return (.tryAgain, nil)
            }
        case .deleteAndAdd:
            return (outcome, nil)
        case .modify:
            return (outcome, nil)
        }
        window!.noteModified(updatedNote: selectedNote!)
    } // end modIfChanged method
}
