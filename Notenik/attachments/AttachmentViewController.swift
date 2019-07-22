//
//  AttachmentViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/21/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

class AttachmentViewController: NSViewController {
    
    var master: AttachmentMasterController!
    var window: AttachmentWindowController!

    @IBOutlet var fileToCopy: NSTextField!
    @IBOutlet var storageFolder: NSTextField!
    @IBOutlet var attachmentPrefix: NSTextField!
    @IBOutlet var attachmentSuffix: NSTextField!
    
    var fileToCopyURL: URL!
    var note: Note!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func setFileToCopy(_ fileURL: URL) {
        fileToCopyURL = fileURL
        fileToCopy.stringValue = fileURL.path
        fileToCopy.isEditable = false
    }
    
    func setStorageFolder(_ folderPath: String) {
        storageFolder.stringValue = folderPath
        storageFolder.isEditable = false
    }
    
    func setNote(_ note: Note) {
        self.note = note
        attachmentPrefix.stringValue = note.fileNameBase!
        attachmentPrefix.isEditable = false
    }
    
    @IBAction func okAction(_ sender: Any) {
        master.okToAddAttachment(note: note, file: fileToCopyURL, suffix: attachmentSuffix.stringValue)
        window.close()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        window.close()
    }
}
