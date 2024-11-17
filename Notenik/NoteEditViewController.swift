//
//  NoteEditViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/28/19.
//
//  Copyright © 2019 - 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib
import NotenikUtils

/// Controls the view shown to allow the user to edit a note.
class NoteEditViewController: NSViewController, CollectionView {
    
    /// This is the view defined in the Main storyboard, set within a bordered scroll view.
    @IBOutlet var parentView: NSView!
    
    var clipView: NSClipView?
    var scrollView: NSScrollView?
    
    /// This is the grid view that will be set inside the parent view.
    var gridView:  NSGridView!
    
    var subView: NSView?
    
    var collectionWindowController: CollectionWindowController?
    var notenikIO: NotenikIO?
    var modWhenChanged: ModWhenChanged?
    
    var selectedNote: Note?
    
    var initialViewLoaded  = false
    var containerViewBuilt = false
    
    var editDefs:  [FieldDefinition] = []
    var editViews: [MacEditView] = []
    var lookupViews: [LookupView] = []
    var grid:      [[NSView]] = []
    
    var titleView:  MacEditView?
    var dateView:   DateView?
    var recursView: MacEditView?
    var statusView: StatusView?
    var levelView:  LevelView?
    var linkView:   AuxTextView?
    var imageNameView: ImageNameView?
    var bodyView:   BodyView?
    var bodyRow = -1
    
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
        if parentView != nil {
            if parentView!.superview != nil {
                clipView = parentView?.superview as? NSClipView
                if clipView!.superview != nil {
                    scrollView = clipView?.superview as? NSScrollView
                }
            }
        }
        
        guard notenikIO != nil && notenikIO!.collection != nil else { return }
        configureEditView(noteIO: notenikIO!, klassName: nil)
    }
    
    func scrollToBottom() {
        guard io != nil else { return }
        guard io!.collection != nil else { return }
        guard io!.collectionOpen else { return }
        guard initialViewLoaded && containerViewBuilt else { return }
        if clipView == nil {
            print("Clip View Not Available!")
        } else if clipView!.documentView == nil {
            print("Document View Not Available!")
        } else if scrollView == nil {
            print("Scroll View Not Available!")
        } else {
            // print("\(scrollView!.documentView!.size)")
            // let docBounds = clipView!.documentView!.bounds
            // let scrollPoint = CGPoint(x: docBounds.width, y: (docBounds.height * -1.00))
            //  clipView!.scroll(to: scrollPoint)
        }
    }
    /// Save any important info prior to the view's disappearance.
    override func viewWillDisappear() {
        super.viewWillDisappear()
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
            if def.fieldType.userEditable && !def.parentField {
                editDefs.append(def)
            }
        }
        
        noteIO.pickLists.statusConfig = collection.statusConfig
        noteIO.pickLists.levelConfig = collection.levelConfig
        
        // Let's build a two-dimensional array of views to be displayed in the grid

        editViews = []
        lookupViews = []
        grid = []
        
        dateView = nil
        recursView = nil
        statusView = nil
        levelView = nil
        linkView = nil
        imageNameView = nil
        bodyView = nil
        
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
        
        let editView = ViewFactory.getEditView(collection: collection,
                                               pickLists: notenikIO!.pickLists,
                                               def: def,
                                               auxLongText: AppPrefs.shared.auxLongText)
        let valueView = editView.view
        
        editViews.append(editView)
        if let lookupView = editView as? LookupView {
            lookupViews.append(lookupView)
        }
        
        bodyRow = -1
        
        // Add the next row to the Grid View
        if def.fieldType.typeString == NotenikConstants.bodyCommon {
            if collection.bodyLabel {
                let row = [labelView]
                appendToGrid(row)
            }
            bodyRow = grid.count
            let row = [valueView]
            appendToGrid(row)
        } else {
            let row = [labelView, valueView]
            appendToGrid(row)
        }
        
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
        } else if label.commonForm == NotenikConstants.linkCommon && linkView == nil {
            linkView = editView as? AuxTextView
        } else if def.fieldType.typeString == NotenikConstants.linkCommon && linkView == nil {
            linkView = editView as? AuxTextView
        } else if def.fieldType.typeString == NotenikConstants.bodyCommon {
            bodyView = editView as? BodyView
        }
    }
    
    func appendToGrid(_ row: [NSView]) {
        grid.append(row)
    }
    
    /// Create a Grid View to hold the field labels and values to be edited
    func makeGridView() {
        gridView = NSGridView(views: grid)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        
        if bodyRow >= 0 {
            let hRange = NSRange(location: 0,length: 2)
            let vRange = NSRange(location: bodyRow, length: 1)
            gridView.mergeCells(inHorizontalRange: hRange, verticalRange: vRange)
        }
        
        finishGridSubView()
    }
    
    func finishGridSubView() {
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
        let str = AppPrefsCocoa.shared.makeUserAttributedString(text: label.properWithParent + ": ", usage: .labels)
        let vw = NSTextField(labelWithAttributedString: str)
        return vw
    }
    
    // -----------------------------------------------------------
    //
    // MARK: Conformace to OutlineView protocol
    //
    // -----------------------------------------------------------
    
    var viewID: String = "note-edit"
    
    var coordinator: CollectionViewCoordinator?
    
    func setCoordinator(coordinator: CollectionViewCoordinator) {
        self.coordinator = coordinator
    }
    
    func focusOn(initViewID: String, 
                 note: NotenikLib.Note?,
                 position: NotenikLib.NotePosition?,
                 io: any NotenikLib.NotenikIO,
                 searchPhrase: String?,
                 withUpdates: Bool = false) {
        
        guard viewID != initViewID else { return }
        guard initialViewLoaded && containerViewBuilt else { return }
        guard io.collectionOpen else { return }
        guard let collection = io.collection else { return }
        guard let focusNote = note else { return }
        
        selectedNote = focusNote
        if collection.klassFieldDef != nil {
            let klassName = focusNote.klass.value
            configureEditView(noteIO: io, klassName: klassName)
        }
        refreshLookupData()
        populateFieldsWithSelectedNote()
        
        if let scroller = collectionWindowController?.scroller {
            if let sv = bodyView?.scrollView {
                scroller.editStart(scrollView: sv)
            }
        }
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
            configureEditView(noteIO: io!, klassName: klassName)
        }
        refreshLookupData()
        populateFieldsWithSelectedNote()
        
        if let scroller = collectionWindowController?.scroller {
            if let sv = bodyView?.scrollView {
                scroller.editStart(scrollView: sv)
            }
        } 
    }
    
    func refreshLookupData() {
        for lookupView in lookupViews {
            lookupView.refreshData()
        }
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
            if fieldView is KlassView && (field == nil || field!.value.isEmpty) {
                let klassView = fieldView as! KlassView
                klassView.setToDefaultValue()
            } else if fieldView is StatusView && (field == nil || field!.value.isEmpty) {
                let statusView = fieldView as! StatusView
                statusView.setToDefaultValue()
            } else if field == nil {
                fieldView.text = ""
            } else {
                let strVal = String(describing: field!.value)
                fieldView.text = strVal
            }
            i += 1
        }
        collectionWindowController!.pendingEdits = true
    }
    
    func getLink() -> String {
        if linkView != nil {
            return linkView!.text
        }
        return ""
    }
    
    /// Set the link field on the edit screen
    func setLink(_ newLink: String) -> Bool {
        if linkView != nil {
            linkView!.text = newLink
            return true
        } else {
            return false
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
        if (outcome == .add || outcome == .modWithKeyChanges) && outNote != nil {
            selectedNote = outNote
        }
        
        if let scrollView = bodyView?.scrollView {
            if let scroller = collectionWindowController?.scroller {
                scroller.editEnd(scrollView: scrollView)
            }
        }

        return (outcome, outNote)
    } // end modIfChanged method
    
}

