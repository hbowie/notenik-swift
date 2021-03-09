//
//  CollectionsViewController.swift
//  Notenik-iOS
//
//  Created by Herb Bowie on 2/20/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import UIKit

import NotenikLib
import NotenikUtils

/// Control the list of all available Collections.
class CollectionsViewController: UITableViewController {
    
    let cellIdentifier = "CollectionCell"
    let showCollectionID = "ShowCollection"
    
    let collections = NotenikFolderList.shared
    
    var rootNode = NotenikFolderNode()

    override func viewDidLoad() {
        super.viewDidLoad()
        rootNode = collections.root
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        self.clearsSelectionOnViewWillAppear = false
        
        if collections.iCloudContainerAvailable {
            collections.downloadFolders()
        } else {
            communicateError("Notenik iCloud container is not available", alert: true)
        }

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    /// Return the total number of sections to be included in the table.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return rootNode.countChildren
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return rootNode.children[section].desc
    }

    /// Return the number of rows in the given section.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rootNode.children[section].countChildren
    }

    /// Return a cell to be displayed within the table.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let sectionNode = rootNode.children[indexPath.section]
        cell.textLabel!.text = sectionNode.children[indexPath.row].desc
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionNode = rootNode.children[indexPath.section]
        let collectionNode = sectionNode.children[indexPath.row]
        performSegue(withIdentifier: showCollectionID, sender: collectionNode)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showCollectionID {
            let target = segue.destination as! NotesListViewController
            let node = sender as? NotenikFolderNode
            if node != nil {
                target.folderLink = node!.folder
            }
        }
    }
    
    /// Log an informational message.
    func logInfo(_ msg: String) {
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.ios",
                          category: "NotesListViewController",
                          level: .info,
                          message: msg)
    }
    
    /// Log an error message and optionally display an alert message.
    func communicateError(_ msg: String, alert: Bool=false) {
        
        Logger.shared.log(subsystem: "com.powersurgepub.notenik.ios",
                          category: "NotesListViewController",
                          level: .error,
                          message: msg)
        
        if alert {
            let alert = UIAlertController(title: "Error Encountered",
                                          message: msg,
                                          preferredStyle: .alert)
            
            let action = UIAlertAction(title: "OK",
                                       style: .default,
                                       handler: nil)
            
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
