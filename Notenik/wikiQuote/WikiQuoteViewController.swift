//
//  WikiQuoteViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 9/23/24.
//
//  Copyright © 2024 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class WikiQuoteViewController: NSViewController {
    
    let application = NSApplication.shared
    
    var window: WikiQuoteWindowController!
    
    @IBOutlet var languageComboBox: NSComboBox!
    
    @IBOutlet var authorNameTextField: NSTextField!
    
    @IBOutlet var searchTextField: NSTextField!
    
    @IBOutlet var quoteTextView: NSTextView!
    
    var authorPage = ""
    
    var quoteParser: WikiQuoteParser?
    
    var io: NotenikIO? {
        get {
            return _io
        }
        set {
            _io = newValue
            // loadFormatPopup()
        }
    }
    var _io: NotenikIO?
    
    var cwc: CollectionWindowController?

    override func viewDidLoad() {
        super.viewDidLoad()
        AppPrefsCocoa.shared.setTextEditingFont(object: languageComboBox)
        AppPrefsCocoa.shared.setTextEditingFont(object: authorNameTextField)
        AppPrefsCocoa.shared.setTextEditingFont(object: searchTextField)
        AppPrefsCocoa.shared.setTextEditingFont(object: quoteTextView)
        languageComboBox.stringValue = "en"
    }
    
    @IBAction func authorNameEntered(_ sender: Any) {
        authorPage = ""
        guard !authorNameTextField.stringValue.isEmpty else { return }
        var wikified = ""
        for char in authorNameTextField.stringValue {
            if char == " " {
                wikified.append("_")
            } else {
                wikified.append(char)
            }
        }
        var language = "en"
        if !languageComboBox.stringValue.isEmpty {
            language = languageComboBox.stringValue
        }
        let authorURL = "https://\(language).wikiquote.org/wiki/\(wikified)"
        if let url = URL(string: authorURL) {
            do {
                let authorPage = try String(contentsOf: url)
                if authorPage.isEmpty {
                    communicateError(msg: "URL of \(authorURL) could not be loaded")
                } else {
                    quoteParser = WikiQuoteParser(author: authorNameTextField.stringValue,
                                                  link: authorURL,
                                                  html: authorPage)
                    if quoteParser != nil && !quoteParser!.quotes.isEmpty {
                        quoteTextView.string = quoteParser!.quotes[0].text
                        quoteIndex = 0
                        quote = quoteParser!.quotes[0]
                    }
                }
            } catch {
                communicateError(msg: "URL of \(authorURL) could not be loaded")
            }
        } else {
            communicateError(msg: "URL of \(authorURL) could not be loaded")
        }
    }
    
    @IBAction func searchTextEntered(_ sender: Any) {

        scanForMatch()
    }
    
    @IBAction func cancel(_ sender: Any) {
        window.close()
    }
    
    @IBAction func nextQuote(_ sender: Any) {
        scanForMatch()
    }
    
    var searchText = ""
    var lastSearch = ""
    var quoteIndex = -1
    var found = false
    var quote = Quote()
    
    func scanForMatch() {
        
        quoteTextView.string = ""
        guard !authorNameTextField.stringValue.isEmpty else {
            print("    - author name text field is empty!")
            return
        }
        guard let parser = quoteParser else {
            print("    - no quote parser found!")
            return
        }
        
        searchText = searchTextField.stringValue.lowercased()
        
        var noMatchMsg = "No matching quotations found"
        
        if searchText != lastSearch || quoteIndex >= parser.count {
            quoteIndex = 0
        } else {
            quoteIndex += 1
        }
        if quoteIndex > 0 {
            noMatchMsg = "No further matches found"
        }
        
        found = false
        if searchText.isEmpty {
            found = true
        }
        if quoteIndex < parser.count {
            quote = parser.quotes[quoteIndex]
        } else {
            quote = Quote()
        }
        
        while quoteIndex < parser.count && !found {
            quote = parser.quotes[quoteIndex]
            if searchText.isEmpty || quote.text.lowercased().contains(searchText) {
                found = true
            } else {
                quoteIndex += 1
            }
        }
        
        if found {
            quoteTextView.string = quote.text
        } else {
            quoteTextView.string = "*** \(noMatchMsg) ***"
        }
        lastSearch = searchText
    }
    
    @IBAction func okToImport(_ sender: Any) {
        guard cwc != nil else { return }
        cwc!.newNote(quote: quote)

        application.stopModal(withCode: .OK)
        window!.close()
    }
    
    func communicateError(msg: String) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = msg
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

}
