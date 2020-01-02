//
//  XLSXReader.swift
//  Notenik
//
//  Created by Herb Bowie on 8/5/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

import CoreXLSX

class XLSXReader: RowImporter {
    
    var consumer:           RowConsumer?
    var workspace:          ScriptWorkspace?
    
    var excelFile:          XLSXFile?
    var worksheetPath       = ""
    var worksheet:          Worksheet?
    var sharedStrings:      SharedStrings?
    
    var rowCount            = 0
    var columns:            [String] = []
    var labels:             [String] = []
    var fields:             [String] = []
    
    init() {
        
    }
    
    /// Initialize the class with a Row Consumer
    func setContext(consumer: RowConsumer, workspace: ScriptWorkspace? = nil) {
        self.consumer = consumer
        self.workspace = workspace
    }
    
    /// Read the file and break it down into fields and rows, returning each
    /// to the consumer, one at a time.
    ///
    /// - Parameter fileURL: The URL of the file to be read.
    /// - Returns: The number of rows returned. 
    func read(fileURL: URL) {
        guard consumer != nil else { return }
        rowCount = 0
        labels = []
        columns = []
        
        excelFile = XLSXFile(filepath: fileURL.path)
        if excelFile == nil {
            logError("XLSX file corrupted or does not exist")
            return
        }
        
        do {
            let paths = try excelFile!.parseWorksheetPaths()
            if paths.count < 1 {
                logError("XLSX file contains no worksheets")
                return
            }
            worksheetPath = paths[0]
        } catch {
            logError("Could not obtain worksheet paths")
            return
        }
        
        do {
            worksheet = try excelFile?.parseWorksheet(at: worksheetPath)
        } catch {
            logError("Error parsing worksheet at path \(worksheetPath)")
            return
        }
        
        if worksheet!.data == nil {
            logError("No data in worksheet at path \(worksheetPath)")
            return
        }
        
        do {
            sharedStrings = try excelFile!.parseSharedStrings()
        } catch {
            logError("Error parsing shared strings in XSLX file")
        }
        
        for row in worksheet!.data!.rows {
            var fieldCount = 0
            fields = []
            for c in row.cells {
                var value = ""
                let reference = c.reference
                let column = String(describing: reference.column)
                if c.type != nil && c.type! == "s" && c.value != nil {
                    let ssi = Int(c.value!)
                    if ssi != nil && sharedStrings != nil {
                        let s = sharedStrings!.items[ssi!]
                        if s.text != nil {
                            value = s.text!
                        }
                    }
                } else if c.value != nil {
                    value = c.value!
                }
                if rowCount == 0 {
                    columns.append(column)
                    labels.append(value)
                } else {
                    while fieldCount < labels.count && column != columns[fieldCount] {
                        let label = labels[fieldCount]
                        consumer!.consumeField(label: label, value: "")
                        fields.append("")
                        fieldCount += 1
                    }
                    if fieldCount < labels.count {
                        let label = labels[fieldCount]
                        consumer!.consumeField(label: label, value: value)
                        fields.append(value)
                    }
                }
                fieldCount += 1
            }
            if rowCount > 0 {
                consumer!.consumeRow(labels: labels, fields: fields)
            }
            rowCount += 1
        }
    }
    
    /// Send an error message to the log.
    func logError(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik",
                          category: "XLSXReader",
                          level: .error,
                          message: msg)
        if workspace != nil {
            workspace!.writeErrorToLog(msg)
        }
    }
    
}
