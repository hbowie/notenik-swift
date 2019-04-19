//
//  CalendarWindowController.swift
//  Notenik
//
//  Created by Herb Bowie on 4/17/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class CalendarWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        guard let vc = contentViewController as? CalendarViewController else { return }
        vc.window = self
    }

}
