//
//  CountsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 5/28/20.
//  Copyright © 2020 - 2022 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikMkdown
import NotenikLib

class CountsViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet var tableView: NSTableView!
    
    var counts = MkdownCounts()
    var minutesToRead: MinutesToReadValue!
    
    let fixedPitchFont = NSFont.userFixedPitchFont(ofSize: 13.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func updateCounts(_ counts: MkdownCounts) {
        self.counts = counts
        minutesToRead = MinutesToReadValue(with: self.counts)
        if self.isViewLoaded {
            tableView.reloadData()
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let vw = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
        
        var str = ""
        
        if tableColumn!.identifier.rawValue == "label" {
            switch row {
            case 0: str = "Total Markdown Size......... "
            case 1: str = "Number of Markdown Lines.... "
            case 2: str = "Number of Words............. "
            case 3: str = "Number of Text Characters... "
            case 4: str = "Average Word Length......... "
            case 5: str = "Minutes to Read............. "
            default: str = ""
            }
        } else {
            switch row {
            case 0: str = "\(counts.size)"
            case 1: str = "\(counts.lines)"
            case 2: str = "\(counts.words)"
            case 3: str = "\(counts.text)"
            case 4: str = "\(Double(round(100*counts.averageWordLength)/100))"
            case 5: str = "\(minutesToRead.value)"
            default: str = ""
            }
        }
        
        if vw.textField != nil {
            vw.textField!.stringValue = str
            vw.textField!.font = fixedPitchFont
        }

        return vw
    }
    
}
