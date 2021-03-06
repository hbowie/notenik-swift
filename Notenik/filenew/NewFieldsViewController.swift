//
//  NewFieldsViewController.swift
//  Notenik
//
//  Created by Herb Bowie on 2/8/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Cocoa

import NotenikUtils

/// Third tab: let the user select a type of collection.
class NewFieldsViewController: NSViewController {
    
    let modelsPath = "/models"
    var fullPath = ""
    
    var tabsVC: NewCollectionViewController?

    @IBOutlet var listOfModels: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listOfModels.removeAllItems()
        fullPath = Bundle.main.resourcePath! + modelsPath
        do {
            var models = try FileManager.default.contentsOfDirectory(atPath: fullPath)
            models.sort()
            for model in models {
                listOfModels.addItem(withTitle: model)
                let menuItem = listOfModels.item(withTitle: model)
                if menuItem != nil {
                    switch model {
                    case "1 - Basic Notes":
                        menuItem!.toolTip = "Each Note will have a Title, Tags & Body"
                    case "2 - Web Links":
                        menuItem!.toolTip = "Each Note will have a Link field, as well as Title, Tags & Body"
                    case "3 - To Do":
                        menuItem!.toolTip = "Each Note will represent a task, with a Date, a Status, and optional Recurs rule, in addition to the more common fields."
                    case "4 - Sequenced List":
                        menuItem!.toolTip = "Each Note gets a sequence number, and you can sort the entire list by those numbers."
                    case "5 - Zettelkasten":
                        menuItem!.toolTip = "Zettelkasten is a fancy term for a collection of thoughts that can link to one another."
                    case "6 - Blog":
                        menuItem!.toolTip = "Each Note becomes a Blog Post"
                    case "7 - Commonplace book":
                        menuItem!.toolTip = "Each Note contains a notable quotation"
                    default:
                        break
                    }
                }
            }
        } catch {
            tabsVC!.communicateError("Could not read the contents of the models directory", alert: true)
        }
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        tabsVC!.selectTab(index: 1)
    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        let selectedItem = listOfModels.selectedItem
        guard selectedItem != nil else {
            tabsVC!.communicateError("You must first make a selection from the list of Collection types", alert: true)
            return
        }
        let selection = selectedItem!.title
        let modelPath = FileUtils.joinPaths(path1: fullPath, path2: selection)
        let modelURL = URL(fileURLWithPath: modelPath)
        
        tabsVC!.setFields(selection, modelURL: modelURL)
        
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        guard tabsVC != nil else { return }
        tabsVC!.closeWindow()
    }
    
}
