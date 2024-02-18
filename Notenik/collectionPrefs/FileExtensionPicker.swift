//
//  FileExtensionPicker.swift
//  Notenik
//
//  Created by Herb Bowie on 2/5/21.
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class FileExtensionPicker {
    
    var fileExtComboBox:      NSComboBox
    
    init(fileExtComboBox: NSComboBox) {
        self.fileExtComboBox = fileExtComboBox
        loadValues()
    }
    
    func loadValues() {
        fileExtComboBox.removeAllItems()
        fileExtComboBox.addItem(withObjectValue: "txt")
        fileExtComboBox.addItem(withObjectValue: "md")
        fileExtComboBox.addItem(withObjectValue: "text")
        fileExtComboBox.addItem(withObjectValue: "markdown")
        fileExtComboBox.addItem(withObjectValue: "mdown")
        fileExtComboBox.addItem(withObjectValue: "mdtext")
        fileExtComboBox.addItem(withObjectValue: "mkdown")
        fileExtComboBox.addItem(withObjectValue: "mktext")
        fileExtComboBox.addItem(withObjectValue: "nnk")
        fileExtComboBox.addItem(withObjectValue: "notenik")
    }
    
    func setFileExt(_ ext: String?) {
        guard ext != nil && ext != "" else { return }
        var i = 0
        var found = false
        while i < fileExtComboBox.numberOfItems && !found {
            let validExt = fileExtComboBox.objectValues[i] as! String
            if ext == validExt {
                found = true
                fileExtComboBox.selectItem(at: i)
            } else {
                i += 1
            }
        }
        if !found {
            fileExtComboBox.addItem(withObjectValue: ext!)
            fileExtComboBox.selectItem(at: i)
        }
    }
}
