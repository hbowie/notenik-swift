//
//  MastodonInfo.swift
//  Notenik
//
//  Created by Herb Bowie on 12/3/22.
//
//  Copyright © 2022 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import MastodonKit

import NotenikLib    

public class MastodonInfo {
    
    /// Provide a standard shared singleton instance
    public static let shared = MastodonInfo()
    
    public let clientName = "Notenik"
    public let appWebsite = "https://notenik.app"
    public var username = ""
    public var domain = ""
    public var appID = ""
    public var redirect = ""
    public var clientID = ""
    public var clientSecret = ""
    public var accessToken = ""
    public var note: Note?
    public var client: Client?
    
    init() {
        
    }
    
}
