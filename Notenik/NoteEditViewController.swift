//
//  NoteEditViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 1/28/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class NoteEditViewController: NSViewController {
    
    var collectionWindowController: CollectionWindowController?
    var notenikIO: NotenikIO?
    
    @IBOutlet var editView: NSView!
    
    var initialViewLoaded    = false
    var gridViewBuilt = false
    var grid: [[NSView]] = []
    
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
            gridViewBuilt = false
            guard notenikIO != nil && notenikIO!.collection != nil else { return }
            makeEditView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewLoaded = true
        makeEditView()
    }
    
    func makeEditView() {
        
        guard let collection = io?.collection else { return }
        guard io!.collectionOpen else { return }
        guard initialViewLoaded && !gridViewBuilt else { return }
        
        let dict = collection.dict
        let defs = dict.list
        grid = []
        for def in defs {
            let label = def.fieldLabel
            let type = def.fieldType
            let labelView = makeLabelView(with: label)
            let valueView = makeValueView(for: type)
            let row = [labelView, valueView]
            grid.append(row)
        }
        let gridView = NSGridView(views: grid)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        editView.addSubview(gridView)
        
        // Pin the grid to the edges of our main view
        gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        gridView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        gridViewBuilt = true
    }
    
    func makeLabelView(with label: FieldLabel) -> NSView {
        let vw = NSTextField(labelWithString: label.properForm + ": ")
        vw.translatesAutoresizingMaskIntoConstraints = false
        vw.isEditable = false
        vw.isSelectable = false
        vw.alignment = .left
        return vw
    
    }
    
    func makeValueView(for type: FieldType) -> NSView {
        let vw = NSTextField(string: "")
        vw.translatesAutoresizingMaskIntoConstraints = false
        vw.isEditable = true
        vw.isSelectable = true
        vw.alignment = .left
        return vw
    }
    
    func select(note: Note) {
        
        guard let collection = io?.collection else { return }
        guard io!.collectionOpen else { return }
        guard initialViewLoaded && gridViewBuilt else { return }
        
        let dict = collection.dict
        let defs = dict.list
        var i = 0
        for def in defs {
            let field = note.getField(def: def)
            let fieldView = grid[i][1]
            guard let tf = fieldView as? NSTextField else { break }
            if field == nil {
                tf.stringValue = ""
            } else {
                tf.stringValue = String(describing: field!.value)
            }
            i += 1
        }
    }
    
}
