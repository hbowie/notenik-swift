//
//  OpenSaveDirectory.swift
//  Notenik
//
//  Created by Herb Bowie on 3/26/19.
//  Copyright © 2019 PowerSurge Publishing. All rights reserved.
//

import Foundation

class OpenSaveDirectory {
    
    // Singleton instance
    static let shared = OpenSaveDirectory()
    
    // Shorthand references to System Objects
    private let defaults = UserDefaults.standard
    private let fileMgr = FileManager.default
    
    // Constant values for keys
    private let lastParentFolderKey = "last-parent-folder"
    private let defaultDiskLocationKey = "default-disk-location"
    
    // Instance Variables
    private var home: URL?
    private var lp: URL?
    private var dl: DefaultDiskLocation = .userHome
    
    /// Initialize a new object, retrieving whatever default values are available
    private init() {
        lp = defaults.url(forKey: lastParentFolderKey)
        home = fileMgr.homeDirectoryForCurrentUser
        let defaultLocationInt = defaults.integer(forKey: defaultDiskLocationKey)
        let possibleDefaultLocation = DefaultDiskLocation(rawValue: defaultLocationInt)
        if possibleDefaultLocation != nil {
            dl = possibleDefaultLocation!
        }
        if lp != nil {
            defaultLocation = .lastParent
        }
    }
    
    /// The last parent folder used for an open or save
    var lastParentFolder: URL? {
        get {
            return lp
        }
        set(newParent) {
            if newParent != nil {
                lp = newParent
                defaults.set(newParent!, forKey: lastParentFolderKey)
            }
        }
    }
    
    /// The default location for Notenik folders for this user
    var defaultLocation: DefaultDiskLocation {
        get {
            return dl
        }
        set(newLocation) {
            dl = newLocation
            defaults.set(newLocation.rawValue, forKey: defaultDiskLocationKey)
        }
    }
    
    /// Return a possible directory URL to be passed to an open or save panel
    var directoryURL: URL? {
        switch defaultLocation {
        case .userHome:
            return home
        case .lastParent:
            return lastParentFolder
        default:
            return home
        }
    }
    
}
