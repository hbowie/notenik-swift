//
//  PrefsTabVC.swift
//  Notenik
//
//  Created by Herb Bowie on 7/17/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

protocol PrefsTabVC {
    
    /// Called when the user is leaving this tab for another one. 
    func leavingTab()
}
