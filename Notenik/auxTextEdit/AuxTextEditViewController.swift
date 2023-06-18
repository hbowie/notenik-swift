//
//  AuxTextEditViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 6/14/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class AuxTextEditViewController: NSViewController {

    @IBOutlet var textView: NSTextView!
    
    var auxTextView: AuxTextView?
    
    var window: AuxTextEditWindowController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.isRichText = false
        textView.usesFontPanel = false
        textView.allowsUndo = true
        if textView.isAutomaticDashSubstitutionEnabled {
            textView.toggleAutomaticDashSubstitution(nil)
        }
        if textView.isAutomaticQuoteSubstitutionEnabled {
            textView.toggleAutomaticQuoteSubstitution(nil)
        }
        if #available(OSX 10.12.2, *) {
            if textView.isAutomaticTextCompletionEnabled {
                textView.toggleAutomaticTextCompletion(nil)
            }
        }
        if textView.isAutomaticSpellingCorrectionEnabled {
            textView.toggleAutomaticSpellingCorrection(nil)
        }
        AppPrefsCocoa.shared.setCodeEditingFont(view: textView)
    }
    
    func tailorViewFor(properLabel: String, typeString: String) {
        guard textView != nil else {
            return
        }
        if let win = window?.window {
            win.title = "Edit the \(properLabel) field"
        }
        switch typeString {
        case NotenikConstants.linkCommon, NotenikConstants.workLinkCommon:
            textView.isFieldEditor = true
        default:
            break
        }
    }
    
    func setText(_ str: String) {
        textView.string = str
    }
    
    func getText() -> String {
        return textView.string
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if let atv = auxTextView {
            atv.auxEditComplete()
        }
        if let wc = window {
            wc.close()
        }
    }
    
    @IBAction func OKtoProceed(_ sender: Any) {
        if let atv = auxTextView {
            atv.setText(textView.string)
            atv.auxEditComplete()
        }
        if let wc = window {
            wc.close()
        }
    }
}
