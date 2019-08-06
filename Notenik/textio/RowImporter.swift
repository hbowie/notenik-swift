//
//  RowImporter.swift
//  Notenik
//
//  Created by Herb Bowie on 8/5/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

protocol RowImporter {
    
    /// Initialize the class with a Row Consumer and an optional
    /// Script Workspace. 
    func setContext(consumer: RowConsumer, workspace: ScriptWorkspace?)
    
    /// Read the file and break it down into fields and rows, returning each
    /// to the consumer, one at a time.
    ///
    /// - Parameter fileURL: The URL of the file to be read.
    /// - Returns: The number of rows returned.
    func read(fileURL: URL) -> Int
}
