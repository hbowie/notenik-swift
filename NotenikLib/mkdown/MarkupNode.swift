//
//  MarkupNode.swift
//  Notenik
//
//  Created by Herb Bowie on 2/25/20.
//  Copyright © 2020 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class MarkupNode {
    
    var type: MarkupNodeType = .html
    
    var attributes: [String: String] = [:]
    
    var contents: [MarkupNode] = []
    
    var text = ""
}
