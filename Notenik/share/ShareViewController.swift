//
//  ShareViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/15/19.
//  Copyright © 2019 - 2023 Herb Bowie (https://powersurgepub.com)
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
    let markdownQuoteFromValue = "mdquotefrom"
    let notenikValue = "notenik"
    let jsonValue = "json"
    let microValue = "micro"
    let templateValue = "template"
    
    let clipboardValue = "clipboard"
    let fileValue = "file"
    let browserValue = "browser"
    
    var window: ShareWindowController?
    var io: NotenikIO?
    var note: Note?
    var searchPhrase: String?
    var stringToShare = "No data available"

    @IBOutlet var contentBodyOnlyButton: NSButton!
    @IBOutlet var contentEntireNoteButton: NSButton!
    @IBOutlet var contentTeaserOnlyButton: NSButton!
    
    @IBOutlet var formatHTMLDocButton: NSButton!
    @IBOutlet var formatHTMLFragmentButton: NSButton!
    @IBOutlet var formatHTMLBlockquoteButton: NSButton!
    @IBOutlet var formatMarkdownButton: NSButton!
    @IBOutlet var formatMarkdownQuoteButton: NSButton!
    @IBOutlet var formatMarkdownQuoteFrom: NSButton!
    @IBOutlet var formatNotenikButton: NSButton!
    @IBOutlet var formatJSONButton: NSButton!
    @IBOutlet var formatMicroButton: NSButton!
    @IBOutlet var formatTemplateButton: NSButton!
    
    @IBOutlet var destinationClipboardButton: NSButton!
    @IBOutlet var destinationFileButton: NSButton!
    @IBOutlet var destinationBrowserButton: NSButton!
    
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
        } else if formatSelector == markdownQuoteFromValue {
            formatMarkdownQuoteFrom.state = .on
        } else if formatSelector == jsonValue {
            formatJSONButton.state = .on
        } else if formatSelector == microValue {
            formatMicroButton.state = .on
        } else if formatSelector == templateValue {
            formatTemplateButton.state = .on
        } else {
            formatNotenikButton.state = .on
        }
        
        let destinationSelector = defaults.string(forKey: destinationKey)
        if destinationSelector == clipboardValue {
            destinationClipboardButton.state = .on
        } else if destinationSelector == fileValue {
            destinationFileButton.state = .on
        } else {
            destinationBrowserButton.state = .on
        }
    }
    
    func contentSelection() {
        
    }
    
    func formatSelection() {
        
    }
    
    func destinationSelection() {
        if destinationBrowserButton.state == .on {
            formatHTMLDocButton.state = .on
        }
    }
    
    /// User said OK -- Let's do the Sharing now
    @IBAction func okButtonPressed(_ sender: Any) {
        
        guard note != nil && window != nil && io != nil else {
            return
        }
        
        let displayParms = DisplayParms()
        displayParms.setFrom(note: note!)
        let mkdownOptions = displayParms.genMkdownOptions()
        mkdownOptions.shortID = note!.shortID.value
        
        // Set desired output format
        var format: MarkedupFormat = .htmlDoc
        if formatHTMLFragmentButton.state == .on
            || formatHTMLBlockquoteButton.state == .on {
            format = .htmlFragment
        } else if formatMarkdownButton.state == .on {
            format = .markdown
        }
        
        // Perform selected transformation
        
        // Format Markdown quote.
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
                    let workTypeField = FieldGrabber.getField(note: note!, label: note!.collection.workTypeFieldDef.fieldLabel.commonForm)
                    var workType = ""
                    if workTypeField != nil {
                        workType = workTypeField!.value.value
                    }
                    if workType.lowercased() == "unknown" {
                        workType = ""
                    }
                    var theType = ""
                    var delim = "*"
                    if !workType.isEmpty {
                        if let typeValue = workTypeField?.value as? WorkTypeValue? {
                            theType = typeValue!.theType
                            if !typeValue!.isMajor {
                                delim = "\""
                            }
                        } else {
                            theType = "the \(workType)"
                        }
                    }
                    var workTitle = note!.workTitle.value
                    if workTitle.lowercased() == "unknown" {
                        workTitle = ""
                    }
                    if workType.count > 0 && workTitle.count > 0 {
                        authorLine.append(", from \(theType) titled \(delim)\(workTitle)\(delim)")
                    }
                    markedUp.writeLine(authorLine)
                }
            }
            stringToShare = markedUp.code
            
            // Format Markdown with quote-from command
        } else if formatMarkdownQuoteFrom.state == .on {
            let markedUp = Markedup(format: .markdown)
            if note!.hasBody() {
                markedUp.startBlockQuote()
                markedUp.writeBlockOfLines(note!.body.value)
                markedUp.finishBlockQuote()
            }
            if contentEntireNoteButton.state == .on {
                markedUp.newLine()
                let workTypeField = FieldGrabber.getField(note: note!, label: note!.collection.workTypeFieldDef.fieldLabel.commonForm)
                var workType = ""
                if workTypeField != nil {
                    workType = workTypeField!.value.value
                }
                if workType.lowercased() == "unknown" {
                    workType = ""
                }
                var workTitle = note!.workTitle.value
                if workTitle.lowercased() == "unknown" {
                    workTitle = ""
                }
                let authorLinkField = FieldGrabber.getField(note: note!, label: NotenikConstants.authorLinkCommon)
                var authorLink = ""
                if authorLinkField != nil {
                    authorLink = authorLinkField!.value.value
                }
                let workLinkField = FieldGrabber.getField(note: note!, label: note!.collection.workLinkFieldDef.fieldLabel.commonForm)
                var workLink = ""
                if workLinkField != nil {
                    workLink = workLinkField!.value.value
                }
                markedUp.writeLine("{:quote-from:\(note!.creatorValue)|\(note!.date.value)|\(workType)|\(workTitle)|\(authorLink)|\(workLink)}")
            }
            stringToShare = markedUp.code
            
        // Format Markdown body only.
        } else if contentBodyOnlyButton.state == .on && formatMarkdownButton.state == .on {
            // No conversion required
            if note!.hasBody() {
                stringToShare = note!.body.value
            }
            
            // Format teaser.
        } else if contentTeaserOnlyButton.state == .on {
            if note!.hasTeaser() {
                if format == .htmlDoc || format == .htmlFragment {
                    let markdown = Markdown()
                    markdown.md = note!.teaser.value
                    let context = NotesMkdownContext(io: io!)
                    let html = markdown.parse(markdown: note!.teaser.value,
                                              options: mkdownOptions,
                                              context: context)
                    stringToShare = html
                } else {
                    stringToShare = note!.teaser.value
                }
            }
        // Format as Notenik.
        } else if formatNotenikButton.state == .on {
            // Share in Notenik format
            let writer = BigStringWriter()
            let noteLineMaker = NoteLineMaker(writer)
            if contentBodyOnlyButton.state == .on {
                noteLineMaker.putField(note!.getBodyAsField(),
                                       format: note!.noteID.getNoteFileFormat())
            } else {
                _ = noteLineMaker.putNote(note!)
            }
            if noteLineMaker.fieldsWritten > 0 {
                stringToShare = writer.bigString
            }
            
        // Format as JSON.
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
            
        // Format Body to HTML.
        } else if contentBodyOnlyButton.state == .on {
            let markdown = Markdown()
            markdown.md = note!.body.value
            let context = NotesMkdownContext(io: io!)
            let html = markdown.parse(markdown: note!.body.value,
                                      options: mkdownOptions,
                                      context: context)
            if format == .htmlDoc {
                let markedup = Markedup(format: .htmlDoc)
                markedup.startDoc(withTitle: note!.title.value, withCSS: nil)
                markedup.append(html)
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
            
        // Format for Micro Blog post.
        } else if formatMicroButton.state == .on {
            stringToShare = note!.body.value
            newLine()
            if note!.hasLink() {
                appendLine(" ")
                appendLine(note!.link.value)
            }
            if contentEntireNoteButton.state == .on {
                if note!.hasTags() {
                    appendLine(" ")
                    let tagsField = note!.getTagsAsField()
                    if let tagsValue = tagsField?.value as? TagsValue {
                        appendLine(tagsValue.microTags)
                    }
                }
            }
            
        // Format with Merge Template.
        } else if formatTemplateButton.state == .on {
            let openPanel = NSOpenPanel()
            openPanel.title = "Select a Merge Template"
            openPanel.prompt = "Use This Template"
            var parent = note!.collection.lib.getURL(type: .reports)
            if parent == nil {
                parent = note!.collection.lib.getURL(type: .notes)
            }
            if parent != nil {
                openPanel.directoryURL = parent!
            }
            openPanel.showsResizeIndicator = true
            openPanel.showsHiddenFiles = false
            openPanel.canChooseDirectories = false
            openPanel.canCreateDirectories = false
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            let userChoice = openPanel.runModal()
            if userChoice == .OK {
                let template = Template()
                var ok = template.openTemplate(templateURL: openPanel.url!)
                if ok {
                    let notesList = NotesList()
                    notesList.append(note!)
                    template.supplyData(note!,
                                        dataSource: note!.collection.title,
                                        io: io)
                    ok = template.generateOutput()
                    if ok {
                        stringToShare = template.util.linesToOutput
                    }
                }
                if !ok {
                    stringToShare = "Template Generation Failed"
                    Logger.shared.log(subsystem: "NotenikLib",
                                      category: "ShareViewController",
                                      level: .error,
                                      message: "Template generation failed")
                }
            }
        } else {
            // Format the entire Note as HTML. 
            let noteDisplay = NoteDisplay()
            // let collection = note!.collection
            // displayParms.mathJax = collection.mathJax
            displayParms.localMj = false
            displayParms.format = format
            displayParms.curlyApostrophes = note!.collection.curlyApostrophes
            displayParms.extLinksOpenInNewWindows = note!.collection.extLinksOpenInNewWindows
            displayParms.checkBoxMessageHandlerName = NotenikConstants.checkBoxMessageHandlerName
            let mdResults = TransformMdResults()
            let displayString = noteDisplay.display(note!, io: io!, parms: displayParms, mdResults: mdResults)
            if format == .htmlDoc && searchPhrase != nil && searchPhrase!.count > 0 {
                stringToShare = StringUtils.highlightPhraseInHTML(phrase: searchPhrase!,
                                                                  html: displayString,
                                                                  klass: "search-results")
            } else {
                stringToShare = displayString
            }
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
        
        if destinationBrowserButton.state == .on {
            if let notesFolder = note?.collection.lib.getURL(type: .notes) {
                let browseFolder = notesFolder.appendingPathComponent("browse", isDirectory: true)
                _ = FileUtils.makeDirectory(at: browseFolder)
                let fn = StringUtils.toCommonFileName(note!.title.value)
                let url = browseFolder.appendingPathComponent(fn).appendingPathExtension("html")
                do {
                    try stringToShare.write(to: url, atomically: true, encoding: .utf8)
                    NSWorkspace.shared.open(url)
                } catch {
                    Logger.shared.log(subsystem: "com.powersurgepub.notenik.macos",
                                      category: "ShareViewController",
                                      level: .fault,
                                      message: "Problems writing shared text to disk")
                }
            }
        }
        
        /// Open Mastodon domain, when appropriate.
        if destinationClipboardButton.state == .on && formatMicroButton.state == .on {
            let domain = AppPrefs.shared.mastodonDomain
            if !domain.isEmpty {
                var urlStr = domain
                if !domain.starts(with: "http") {
                    urlStr = "https://\(domain)"
                }
                if let url = URL(string: urlStr) {
                    NSWorkspace.shared.open(url)
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
        } else if formatMarkdownQuoteFrom.state == .on {
            formatSelector = markdownQuoteFromValue
        } else if formatJSONButton.state == .on {
            formatSelector = jsonValue
        } else if formatMicroButton.state == .on {
            formatSelector = microValue
        } else if formatTemplateButton.state == .on {
            formatSelector = templateValue
        }
        defaults.set(formatSelector, forKey: formatKey)
        
        var destinationSelector = clipboardValue
        if destinationFileButton.state == .on {
            destinationSelector = fileValue
        } else if destinationBrowserButton.state == .on {
            destinationSelector = browserValue
        }
        defaults.set(destinationSelector, forKey: destinationKey)
        
        window!.close()
    }
    
    func appendLine(_ str: String) {
        stringToShare.append(str)
        newLine()
    }
    
    func newLine() {
        stringToShare.append("\n")
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        window!.close()
    }
}
