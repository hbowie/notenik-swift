//
//  ScriptViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/26/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class ScriptViewController: NSViewController {
    
    var window: ScriptWindowController!

    @IBOutlet var scriptPath: NSTextField!
    @IBOutlet var scriptLog: NSTextView!
    
    var scriptURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppPrefs.shared.setRegularFont(object: scriptPath)
        AppPrefs.shared.setRegularFont(object: scriptLog)
    }
    
    func setScriptURL(_ scriptURL: URL) {
        self.scriptURL = scriptURL
        scriptPath.stringValue = scriptURL.path
    }
    
    @IBAction func playAction(_ sender: Any) {
        if scriptURL != nil {
            let scripter = ScriptEngine()
            scripter.playScript(fileURL: scriptURL!)
            self.scriptLog.string = scripter.workspace.scriptLog
        }
    }
}
