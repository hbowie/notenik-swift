//
//  OpenQuickActionIntentHandler.swift
//  Notenik
//
//  Created by Herb Bowie on 1/9/23.
//
//  Copyright © 2023 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

@available(macOS 11.0, *)
class OpenQuickActionIntentHandler: NSObject, OpenQuickActionIntentHandling {
    
    func handle(intent: OpenQuickActionIntent, completion: @escaping (OpenQuickActionIntentResponse) -> Void) {
        
        CollectionJuggler.shared.quickAction()
        
        let response = OpenQuickActionIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }

}

