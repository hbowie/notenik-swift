//
//  FavoritesToHTML.swift
//  Notenik
//
//  Created by Herb Bowie on 7/2/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

/// Write out an HTML page listing all of the user's favorite bookmarks.
class FavoritesToHTML {
    
    let prefs = AppPrefs.shared
    
    var maxColumns = 4
    var maxLines = 32
    var columnWidth = "250px"
    
    var lineCount = 0
    var columnCount = 0
    var rowCount = 0
    
    var noteIO: NotenikIO?
    var outURL: URL?
    
    var css = ""
    var markedup = Markedup(format: .htmlDoc)
    
    let htmlConverter = StringConverter()
    
    var favoritesWord = "favorites"
    var favoritesCap = "Favorites"
    
    init() {
        htmlConverter.addHTML()
        maxColumns = prefs.favoritesColumns
        maxLines = prefs.favoritesRows
        columnWidth = prefs.favoritesColumnWidth
        if !AppPrefs.shared.americanEnglish {
            favoritesWord = "favourites"
            favoritesCap = "Favourites"
        }
    }
    
    convenience init (noteIO: NotenikIO, outURL: URL) {
        self.init()
        self.noteIO = noteIO
        self.outURL = outURL
    }
    
    /// Generate the web page.
    func generate() -> Bool {
        
        guard let io = noteIO else { return false }
        guard let url = outURL else { return false }
        
        buildCSS()
        markedup.startDoc(withTitle: "Bookmark \(favoritesCap)", withCSS: css)
        markedup.startDiv(klass: "container")
        let iterator = io.makeTagsNodeIterator()
        var tagsNode = iterator.next()
        var favorites = false
        var favoritesDepth = -1
        lineCount = maxLines + 1
        columnCount = maxColumns + 1
        rowCount = -1
        var favoritesCount = 0
        while tagsNode != nil {
            if tagsNode!.type == .tag {
                if tagsNode!.tag!.lowercased() == "favorites" || tagsNode!.tag!.lowercased() == "favourites" {
                    favorites = true
                    favoritesDepth = iterator.depth
                } else if iterator.depth <= favoritesDepth {
                    favorites = false
                } else if favorites {
                    if tagsNode!.children.count > 0 {
                        if lineCount + 2 + tagsNode!.countChildren >= maxLines {
                            newColumn()
                        }
                        let text = htmlConverter.convert(from: tagsNode!.tag!)
                        markedup.heading(level: 2, text: text)
                        lineCount += 2
                    }
                }
            } else if tagsNode!.type == .note && favorites {
                guard let note = tagsNode!.note else { break }
                if lineCount + 1 >= maxLines {
                    newColumn()
                }
                markedup.startParagraph()
                let text = htmlConverter.convert(from: note.title.value)
                markedup.link(text: text, path: note.link.value)
                markedup.finishParagraph()
                lineCount += 1
                favoritesCount += 1
            }
            tagsNode = iterator.next()
        }
        markedup.finishDiv() // End column
        markedup.finishDiv() // End row
        markedup.finishDiv() // End container
        markedup.finishDoc()
        do {
            try markedup.code.write(to: url, atomically: true, encoding: String.Encoding.utf8)
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FavoritesToHTML",
                              level: .info,
                              message: "\(favoritesCount) favorites written to \(url.path)")
        } catch {
            Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                              category: "FavoritesToHTML",
                              level: .error,
                              message: "Problems writing favorites to \(url.path)")
            return false
        }
        return true
    }
    
    func buildCSS() {
        css = ""
        let displayCSS = DisplayPrefs.shared.bodyCSS
        if displayCSS != nil {
            writeLineToCSS(displayCSS!)
        }
        writeLineToCSS("body { margin-left: 20px; } ")
        writeLineToCSS(".column { display:inline-block; width: \(columnWidth); vertical-align: top; }")
        writeLineToCSS("h2 { font-weight: 700; margin-top: 10pt; margin-bottom: 4pt; font-size: \(DisplayPrefs.shared.sizePlusUnit!); line-height: normal; }")
        writeLineToCSS("p { font-size: \(DisplayPrefs.shared.sizePlusUnit!); margin-top: 0pt; margin-bottom: 4pt; font-weight: 500; }")
        writeLineToCSS("a:link { text-decoration: none; color: #004080; }")
        writeLineToCSS("a:visited { text-decoration: none; color: #400080; }")
        writeLineToCSS("a:hover { text-decoration: underline; }")
        writeLineToCSS("a:active { text-decoration: underline; }")
    }
    
    func writeLineToCSS(_ line: String) {
        css.append(line)
        css.append("\n")
    }
    
    /// Start a new column.
    func newColumn() {
        if rowCount >= 0 {
            markedup.finishDiv()
        }
        columnCount += 1
        if columnCount >= maxColumns {
            startRow()
        }
        markedup.startDiv(klass: "column")
        lineCount = -1
    }
    
    /// Start a new row.
    func startRow() {
        if rowCount >= 0 {
            markedup.finishDiv()
        }
        rowCount += 1
        markedup.startDiv(klass: "row")
        columnCount = 0
    }
    
}
