//
//  GetNoteTitleHandler.swift
//  Notenik
//
//  Created by Herb Bowie on 7/19/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

@available(macOS 11.0, *)
class GetNoteTitleIntentHandler: NSObject, GetNoteTitleIntentHandling {
    
    func handle(intent: GetNoteTitleIntent, completion: @escaping (GetNoteTitleIntentResponse) -> Void) {
        let title = CollectionJuggler.shared.getLastSelectedNoteTitle()
        let response = GetNoteTitleIntentResponse(code: .success, userActivity: nil)
        response.noteTitle = title
        completion(response)
    }
    
}
