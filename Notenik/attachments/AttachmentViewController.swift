//
//  AttachmentViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/21/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Cocoa

import NotenikLib

class AttachmentViewController: NSViewController {
    
    let moveKey = "move-attachments"
    
    var master: AttachmentMasterController!
    var window: AttachmentWindowController!

    @IBOutlet var fileToCopy: NSTextField!
    @IBOutlet var storageFolder: NSTextField!
    @IBOutlet var attachmentPrefix: NSTextField!
    @IBOutlet var attachmentSuffix: NSTextField!
    @IBOutlet weak var copyButton: NSButton!
    @IBOutlet weak var moveButton: NSButton!
    
    var fileToCopyURL: URL!
    var note: Note!
    var clearLink: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let move = UserDefaults.standard.bool(forKey: moveKey)
        if move {
            moveButton.state = .on
        } else {
            copyButton.state = .on
        }
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
        attachmentPrefix.stringValue = note.noteID.getBaseFilename()!
        attachmentPrefix.isEditable = false
    }
    
    func setClearLinkOption(_ clearLink: Bool) {
        self.clearLink = clearLink
    }
    
    @IBAction func opSelected(_ sender: Any) {
        // No need to actually do anything here... we just need to assign
        // both radio buttons to this action so that they will act
        // like radio buttons, allowing only one to be selected at a time.
    }
    
    @IBAction func okAction(_ sender: Any) {
        let move = (moveButton.state == .on)
        master.okToAddAttachment(note: note,
                                 file: fileToCopyURL,
                                 suffix: attachmentSuffix.stringValue,
                                 move: move,
                                 clearLink: clearLink)
        UserDefaults.standard.set(move, forKey: moveKey)
        window.close()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        window.close()
    }
}
