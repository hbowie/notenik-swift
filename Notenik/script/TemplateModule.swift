//
//  TemplateModule.swift
//  Notenik
//
//  Created by Herb Bowie on 7/28/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class TemplateModule {
    
    var workspace = ScriptWorkspace()
    var command = ScriptCommand()
    
    init() {
        
    }
    
    func playCommand(workspace: ScriptWorkspace, command: ScriptCommand) {
        self.workspace = workspace
        self.command = command
        switch command.action {
        case .generate:
            generate()
        case .open:
            open()
        case .webroot:
            webroot()
        default:
            break
        }
    }
    
    func open() {
        workspace.template = Template()
        workspace.template.setWebRoot(filePath: workspace.webRootPath)
        workspace.template.setWorkspace(workspace)
        let templateURL = URL(fileURLWithPath: command.valueWithPathResolved)
        workspace.template.openTemplate(templateURL: templateURL)
    }
    
    func generate() {
        workspace.template.supplyData(notesList: workspace.list, dataSource: workspace.inputURL!.path)
        workspace.template.generateOutput()
    }
    
    func webroot() {
        workspace.webRootPath = command.valueWithPathResolved
    }
}
