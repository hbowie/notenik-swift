//
//  GetNoteSharingLinkIntentHandler.swift
//  Notenik
//
//  Created by Herb Bowie on 7/20/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

@available(macOS 11.0, *)
class GetNoteSharingLinkIntentHandler: NSObject, GetNoteSharingLinkIntentHandling {
    
    func handle(intent: GetNoteSharingLinkIntent, completion: @escaping (GetNoteSharingLinkIntentResponse) -> Void) {
        let urlStr = CollectionJuggler.shared.getLastSelectedNoteCustomURL()
        let url = URL(string: urlStr)
        let response = GetNoteSharingLinkIntentResponse(code: .success, userActivity: nil)
        response.noteSharingLink = url
        completion(response)
    }

}
