//
//  NoteEditViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/28/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

/// Controls the view shown to allow the user to edit a note.
class NoteEditViewController: NSViewController {
    
    @IBOutlet var parentView: NSView!
    
    var collectionWindowController: CollectionWindowController?
    var notenikIO: NotenikIO?
    
    var initialViewLoaded  = false
    var containerViewBuilt = false
    
    var editViews: [EditView] = []
    var grid:  [[NSView]] = []
    var gridView: NSGridView!
    
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
        
        print("NoteEditViewController makeEditView starting")
        // Make sure we have everything we need
        guard let collection = io?.collection else { return }
        guard io!.collectionOpen else { return }
        guard initialViewLoaded && !containerViewBuilt else { return }
        
        vStack = NSStackView()
        vStack.orientation = .vertical
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Let's build a two-dimensional array of views to be displayed in the grid
        let dict = collection.dict
        let defs = dict.list
        editViews = []
        grid = []
        for def in defs {
            
            let editView = ViewFactory.getEditView(def: def)
            editViews.append(editView)
            
            let label = def.fieldLabel
            let labelView = makeLabelView(with: label)
            
            let valueView = editView.view
            
            var hStack = NSStackView()
            hStack.orientation = .horizontal
            // hStack.translatesAutoresizingMaskIntoConstraints = false
            // hStack.alignment = .top
            hStack.addArrangedSubview(labelView)
            hStack.addArrangedSubview(editView.view)
            
            vStack.addArrangedSubview(hStack)
            
            let row = [labelView, valueView]
            grid.append(row)
        }
        print("\(grid.count) rows built")
        
        // makeGridView()
        makeStackView()
        
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
        gridView = NSGridView(views: grid)
        // gridView = NSGridView(numberOfColumns: 2, rows: 0)
        // for row in grid {
        //     gridView!.addRow(with: row)
        // }
        // gridView!.setContentHuggingPriority(600, for: .horizontal)
        // gridView!.setContentHuggingPriority(600, for: .vertical)
        
        print ("Making Grid View")
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.column(at: 0).width = 100
        gridView.column(at: 0).xPlacement = .trailing
        gridView.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 600), for: .horizontal)
        gridView.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 600), for: .vertical)
        gridView.column(at: 1).width = 200
        // scrollView.documentView = gridView
        parentView.addSubview(gridView!)
        print ("Grid View added to Edit View")
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
        
        let dict = collection.dict
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
    
}
