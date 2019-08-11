//
//  MergeReport.swift
//  Notenik
//
//  Created by Herb Bowie on 6/4/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class MergeReport: CustomStringConvertible {
    
    var reportName = ""
    var reportType = ""
    
    var description: String {
        var desc = "Report: "
        if reportType.lowercased() == "tcz" {
            desc.append(reportName)
        } else {
            if reportName.lowercased().contains("template") {
                desc.append(reportName.replacingOccurrences(of: "template", with: ""))
                desc.append(" => " + reportType)
            }
        }
        return desc
    }
    
    var fileName: String {
        return reportName + "." + reportType
    }
    
    func getURL(folderPath: String) -> URL? {
        let reportPath = FileUtils.joinPaths(path1: folderPath,
                                              path2: fileName)
        let reportURL = URL(fileURLWithPath: reportPath)
        return reportURL
    }
    
}
