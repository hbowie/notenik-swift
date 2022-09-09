//
//  NoteLinkResolverCocoa.swift
//  Notenik
//
//  Created by Herb Bowie on 9/7/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

class NoteLinkResolverCocoa {
    
    static func link(wc: CollectionWindowController, resolution: NoteLinkResolution) {

        if resolution.resolvedPath.isEmpty {
            wc.select(note: resolution.resolvedNote, position: nil, source: .action, andScroll: true)
        } else {
            let folders = NotenikFolderList.shared
            let juggler = CollectionJuggler.shared
            let multi   = MultiFileIO.shared
            let shortcut = resolution.resolvedPath
            var link: NotenikLink?
            let multiEntry = multi.entries[shortcut]
            if multiEntry == nil {
                link = folders.getFolderFor(shortcut: shortcut)
            } else {
                link = multiEntry!.link
            }
            guard let collectionLink = link else { return }
            guard let controller = juggler.open(link: collectionLink) else { return }
            controller.select(note: resolution.resolvedNote!, position: nil, source: .action, andScroll: true)
        }
    }
}
