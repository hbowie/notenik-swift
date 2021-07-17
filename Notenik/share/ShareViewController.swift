//
//  ShareViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/15/19.
//  Copyright © 2019-2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils
import NotenikLib

class ShareViewController: NSViewController {
    
    // Get the User Defaults Singleton
    let defaults = UserDefaults.standard
    let contentKey = "share-content"
    let formatKey  = "share-format"
    let destinationKey = "share-destination"
    
    let bodyOnlyValue = "body-only"
    let entireNoteValue = "entire-note"
    
    let htmlDocValue = "html-doc"
    let htmlFragmentValue = "html-fragment"
    let htmlBlockquoteValue = "html-blockquote"
    let markkdownValue = "markdown"
    let markdownQuoteValue = "mdquote"
    let notenikValue = "notenik"
    let jsonValue = "json"
    
    let clipboardValue = "clipboard"
    let fileValue = "file"
    
    var window: ShareWindowController?
    var io: NotenikIO?
    var note: Note?
    var stringToShare = "No data available"

    @IBOutlet var contentBodyOnlyButton: NSButton!
    @IBOutlet var contentEntireNoteButton: NSButton!
    
    @IBOutlet var formatHTMLDocButton: NSButton!
    @IBOutlet var formatHTMLFragmentButton: NSButton!
    @IBOutlet var formatHTMLBlockquoteButton: NSButton!
    @IBOutlet var formatMarkdownButton: NSButton!
    @IBOutlet var formatMarkdownQuoteButton: NSButton!
    @IBOutlet var formatNotenikButton: NSButton!
    @IBOutlet var formatJSONButton: NSButton!
    
    @IBOutlet var destinationClipboardButton: NSButton!
    @IBOutlet var destinationFileButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Let's set the default values to the last ones used
        let contentSelector = defaults.string(forKey: contentKey)
        if contentSelector == bodyOnlyValue {
            contentBodyOnlyButton.state = .on
        } else {
            contentEntireNoteButton.state = .on
        }
        
        let formatSelector = defaults.string(forKey: formatKey)
        if formatSelector == htmlDocValue {
            formatHTMLDocButton.state = .on
        } else if formatSelector == htmlFragmentValue {
            formatHTMLFragmentButton.state = .on
        } else if formatSelector == htmlBlockquoteValue {
            formatHTMLBlockquoteButton.state = .on
        } else if formatSelector == markkdownValue {
            formatMarkdownButton.state = .on
        } else if formatSelector == markdownQuoteValue {
            formatMarkdownQuoteButton.state = .on
        } else if formatSelector == jsonValue {
            formatJSONButton.state = .on
        } else {
            formatNotenikButton.state = .on
        }
        
        let destinationSelector = defaults.string(forKey: destinationKey)
        if destinationSelector == clipboardValue {
            destinationClipboardButton.state = .on
        } else {
            destinationFileButton.state = .on
        }
    }
    
    /// User said OK -- Let's do the Sharing now
    @IBAction func okButtonPressed(_ sender: Any) {
        
        guard note != nil && window != nil && io != nil else { return }
        
        // Set desired output format
        var format: MarkedupFormat = .htmlDoc
        if formatHTMLFragmentButton.state == .on
            || formatHTMLBlockquoteButton.state == .on {
            format = .htmlFragment
        } else if formatMarkdownButton.state == .on {
            format = .markdown
        }
        
        // Perform selected transformation
        if formatMarkdownQuoteButton.state == .on {
            let markedUp = Markedup(format: .markdown)
            if note!.hasBody() {
                markedUp.startBlockQuote()
                markedUp.writeBlockOfLines(note!.body.value)
                markedUp.finishBlockQuote()
            }
            if contentEntireNoteButton.state == .on {
                let author = note!.creatorValue
                if author.count > 0 {
                    markedUp.newLine()
                    var authorLine = "-- "
                    authorLine.append(author)
                    let date = note!.date.value
                    if date.count > 0 {
                        authorLine.append(", \(date)")
                    }
                    let workType = note!.workType.value
                    let workTitle = note!.workTitle.value
                    if workType.count > 0 && workTitle.count > 0 {
                        authorLine.append(", from the \(workType) titled *\(workTitle)*")
                    }
                    markedUp.writeLine(authorLine)
                }
            }
            stringToShare = markedUp.code
        } else if contentBodyOnlyButton.state == .on && formatMarkdownButton.state == .on {
            // No conversion required
            if note!.hasBody() {
                stringToShare = note!.body.value
            }
        } else if formatNotenikButton.state == .on {
            // Share in Notenik format
            let writer = BigStringWriter()
            let noteLineMaker = NoteLineMaker(writer)
            if contentBodyOnlyButton.state == .on {
                noteLineMaker.putField(note!.getBodyAsField(),
                                       format: note!.fileInfo.format)
            } else {
                _ = noteLineMaker.putNote(note!)
            }
            if noteLineMaker.fieldsWritten > 0 {
                stringToShare = writer.bigString
            }
        } else if formatJSONButton.state == .on {
            let jWriter = JSONWriter()
            jWriter.open()
            if contentBodyOnlyButton.state == .on {
                jWriter.writeBodyAsObject(note!)
            } else {
                jWriter.writeNoteAsObject(note!)
            }
            jWriter.close()
            stringToShare = jWriter.outputString
        } else if contentBodyOnlyButton.state == .on {
            let markdown = Markdown()
            markdown.md = note!.body.value
            markdown.parse()
            if format == .htmlDoc {
                let markedup = Markedup(format: .htmlDoc)
                markedup.startDoc(withTitle: note!.title.value, withCSS: nil)
                markedup.append(markdown.html)
                markedup.finishDoc()
                stringToShare = markedup.code
            } else if formatHTMLBlockquoteButton.state == .on {
                let markedup = Markedup(format: .htmlFragment)
                markedup.startBlockQuote()
                markedup.append(markdown.html)
                markedup.finishBlockQuote()
                stringToShare = markedup.code
            } else {
                stringToShare = markdown.html
            }
        } else {
            let noteDisplay = NoteDisplay()
            let parms = DisplayParms()
            let collection = note!.collection
            parms.mathJax = collection.mathJax
            parms.localMj = false
            parms.format = format
            stringToShare = noteDisplay.display(note!, io: io!, parms: parms)
        }
        
        // Write the string to an output destination
        if destinationClipboardButton.state == .on {
            let pb = NSPasteboard.general
            pb.clearContents()
            _ = pb.setString(stringToShare, forType: .string)
        }
        
        if destinationFileButton.state == .on {
            let savePanel = NSSavePanel();
            savePanel.title = "Specify an output file"
            let parent = note?.collection.fullPathURL
            if parent != nil {
                savePanel.directoryURL = parent!
            }
            savePanel.showsResizeIndicator = true
            savePanel.showsHiddenFiles = false
            savePanel.canCreateDirectories = true
            let defaultFileName = StringUtils.toReadableFilename(note!.title.value)
            var defaultExt = ".md"
            if formatHTMLFragmentButton.state == .on || formatHTMLDocButton.state == .on {
                defaultExt = ".html"
            }
            savePanel.nameFieldStringValue = defaultFileName + defaultExt
            let userChoice = savePanel.runModal()
            if userChoice == .OK {
                let url = savePanel.url
                do {
                    try stringToShare.write(to: url!, atomically: true, encoding: .utf8)
                } catch {
                    Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                      category: "ShareViewController",
                                      level: .fault,
                                      message: "Problems writing shared text to disk")
                }
            }
        }
        
        // Save the user's choices so we can default to them later
        var contentSelector = entireNoteValue
        if contentBodyOnlyButton.state == .on {
            contentSelector = bodyOnlyValue
        }
        defaults.set(contentSelector, forKey: contentKey)
        
        var formatSelector = htmlDocValue
        if formatNotenikButton.state == .on {
            formatSelector = notenikValue
        } else if formatHTMLFragmentButton.state == .on {
            formatSelector = htmlFragmentValue
        } else if formatHTMLBlockquoteButton.state == .on {
            formatSelector = htmlBlockquoteValue
        } else if formatMarkdownButton.state == .on {
            formatSelector = markkdownValue
        } else if formatMarkdownQuoteButton.state == .on {
            formatSelector = markdownQuoteValue
        } else if formatJSONButton.state == .on {
            formatSelector = jsonValue
        }
        defaults.set(formatSelector, forKey: formatKey)
        
        var destinationSelector = clipboardValue
        if destinationFileButton.state == .on {
            destinationSelector = fileValue
        }
        defaults.set(destinationSelector, forKey: destinationKey)
        
        window!.close()
    }
    
    func appendLine(_ str: String) {
        stringToShare.append(str)
        stringToShare.append("\n")
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        window!.close()
    }
}
