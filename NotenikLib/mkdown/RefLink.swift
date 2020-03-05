//
//  RefLink.swift
//  Notenik
//
//  Created by Herb Bowie on 3/4/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

class RefLink {
    var label = ""
    var link  = ""
    var title = ""
    
    var isValid: Bool {
        return label.count > 0 && link.count > 0
    }
    
    func display() {
        print(" ")
        print("Reference Link Definition")
        print("Label: \(label)")
        print("Link:  \(link)")
        print("Title: \(title)")
    }
}
