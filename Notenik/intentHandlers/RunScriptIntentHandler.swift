//
//  RunScriptIntentHandler.swift
//  Notenik
//
//  Created by Herb Bowie on 7/29/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikLib

@available(macOS 11.0, *)
class RunScriptIntentHandler: NSObject, RunScriptIntentHandling {

    func handle(intent: RunScriptIntent, completion: @escaping (RunScriptIntentResponse) -> Void) {
        
        guard let scriptFilePath = intent.scriptFilePath else {
            let response = RunScriptIntentResponse(code: .failure, userActivity: nil)
            completion(response)
            return
        }
        
        let player = ScriptPlayer()
        player.playScript(fileName: scriptFilePath)

        let response = RunScriptIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }
    
}
