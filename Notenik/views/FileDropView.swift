//
//  FileDropView.swift
//  Notenik
//
//  Created by Herb Bowie on 11/17/20.
//  Copyright © 2020 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class FileDropView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("FileDropView.draggingEntered")
        displayDraggingInfo(sender)
        let returnOp = sender.draggingSourceOperationMask.intersection([.copy])
        print("return operation = \(returnOp)")
        return returnOp
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("FileDropView.performDragOperation")
        return true
    }
    
    func displayDraggingInfo(_ sender: NSDraggingInfo) {
        let pb = sender.draggingPasteboard
        print("source operation mask = \(sender.draggingSourceOperationMask)")
        print("number of valid items = \(sender.numberOfValidItemsForDrop)")
        let items = pb.pasteboardItems
        if items != nil {
            for item in items! {
                print("Another item...")
                for type in item.types {
                    print("  Another type: \(type)")
                }
            }
        }
    }
    
}
