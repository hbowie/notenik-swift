//
//  NotesListViewController.swift
//  Notenik-iOS
//
//  Created by Herb Bowie on 2/23/21.
//
//  Copyright © 2021 Herb Bowie (https://hbowie.net)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import UIKit

import NotenikLib
import NotenikUtils

/// Display a list of Notes within one Collection. 
class NotesListViewController: UITableViewController {
    
    let cellIdentifier = "NoteCell"
    let displayNoteID  = "DisplayNote"
    
    var _fLink: NotenikLink?
    var io: NotenikIO = FileIO()
    var collection: NoteCollection?
    
    var folderLink: NotenikLink? {
        get {
            return _fLink
        }
        set {
            _fLink = newValue
            if newValue != nil {
                openCollection(notenikLink: newValue!)
            }
        }
    }
        
    func openCollection(notenikLink: NotenikLink) {
        io = FileIO()
        let realm = io.getDefaultRealm()
        realm.path = ""
        let readOnly = (notenikLink.location == .appBundle)
        collection = io.openCollection(realm: realm, collectionPath: notenikLink.path, readOnly: readOnly)
        if collection == nil {
            communicateError("Problems opening the collection at " + notenikLink.path,
                             alert: true)
        } else {
            logInfo("Collection successfully opened: \(collection!.title)")
            collection!.readOnly = (notenikLink.location == .appBundle)
            if isViewLoaded {
                title = collection!.title
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        if collection != nil {
            title = collection!.title
        }

        self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return io.notesCount
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let note = io.getNote(at: indexPath.row)
        if note == nil {
            cell.textLabel!.text = "???"
        } else {
            cell.textLabel!.text = note!.title.value
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let note = io.getNote(at: indexPath.row) else { return }
        performSegue(withIdentifier: displayNoteID, sender: note)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard sender != nil else { return }
        if segue.identifier == displayNoteID {
            let target = segue.destination as! DisplayNoteViewController
            let note = sender as! Note
            target.note = note
            target.notenikIO = io
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

}
