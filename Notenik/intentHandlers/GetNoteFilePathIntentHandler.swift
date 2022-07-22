//
//  GetNoteFilePathIntentHandler.swift
//  Notenik
//
//  Created by Herb Bowie on 7/20/22.
//  Copyright © 2022 PowerSurge Publishing. All rights reserved.
//

import Cocoa

@available(macOS 11.0, *)
class GetNoteFilePathIntentHandler: NSObject, GetNoteFilePathIntentHandling {

    func handle(intent: GetNoteFilePathIntent, completion: @escaping (GetNoteFilePathIntentResponse) -> Void) {
        let path = CollectionJuggler.shared.getLastSelectedNoteFilePath()
        let response = GetNoteFilePathIntentResponse(code: .success, userActivity: nil)
        response.filePath = path
        completion(response)
    }
}
