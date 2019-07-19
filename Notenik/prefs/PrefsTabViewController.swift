//
//  PrefsTabViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 7/17/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

class PrefsTabViewController: NSTabViewController {
    
    var lastTabViewItemLabel = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func tabView(_ tabView: NSTabView,
                 willSelect tabViewItem: NSTabViewItem?) {
        
        super.tabView(tabView, willSelect: tabViewItem)
        
        if tabViewItem != nil {
            for tab in self.tabViewItems {
                if lastTabViewItemLabel == tab.label {
                    let vc = tab.viewController
                    if let conformantVC = vc as? PrefsTabVC {
                        conformantVC.leavingTab()
                    }
                }
            }
            lastTabViewItemLabel = tabViewItem!.label
        }
        
    }
    
}
