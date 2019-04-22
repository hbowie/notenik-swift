//
//  FieldDictionary.swift
//  Notenik
//
//  Created by Herb Bowie on 12/3/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// A Dictionary of Field Definitions
class FieldDictionary {
    
    var dict = [:] as [String: FieldDefinition]
    var list: [FieldDefinition] = []
    var insertPositionFromEnd = 1
    var locked = false
    
    /// Default initializer
    init() {
        
    }
    
    /// Return the number of definitions in the dictionary
    var count: Int {
        return dict.count
    }
    
    /// Is this dictionary empty?
    var isEmpty: Bool {
        return (dict.isEmpty)
    }
    
    /// Does this dictionary have any definitions stored in it?
    var hasData: Bool {
        return (dict.count > 0)
    }
    
    /// Lock the dictionary so that no more definitions may be added
    func lock() {
        locked = true
    }
    
    /// Unlock the dictionary so that more definitions may be added
    func unlock() {
        locked = false
    }
    
    /// Does the dictionary contain a definition for this field label?
    func contains (_ def: FieldDefinition) -> Bool {
        let def = dict[def.fieldLabel.commonForm]
        return def != nil
    }
    
    /// Does the dictionary contain a definition for this field label?
    func contains (_ label: FieldLabel) -> Bool {
        let def = dict[label.commonForm]
        return def != nil
    }
    
    /// Does the dictionary contain a definition for this field label?
    func contains (_ label: String) -> Bool {
        let fieldLabel = FieldLabel(label)
        let def = dict[fieldLabel.commonForm]
        return def != nil
    }
    
    /// Return the optional definition for this field label
    func getDef(_ def: FieldDefinition) -> FieldDefinition? {
        return dict[def.fieldLabel.commonForm]
    }
    
    /// Return the optional definition for this field label
    func getDef(_ label: FieldLabel) -> FieldDefinition? {
        return dict[label.commonForm]
    }
    
    /// Return the optional definition for this field label
    func getDef(_ labelStr: String) -> FieldDefinition? {
        let fieldLabel = FieldLabel(labelStr)
        return dict[fieldLabel.commonForm]
    }
    
    /// Get the definition from the dictionary, given its place in the list.
    ///
    /// - Parameter i: An index into the list of definitions in the dictionary.
    /// - Returns: An optional Field Definition, of nil, if the index is out of range.
    func getDef(_ i : Int) -> FieldDefinition? {
        if i < 0 || i >= list.count {
            return nil
        } else {
            return list [i]
        }
    }
    
    /// Add a new field definition to the dictionary, based on the passed field label string
    func addDef (_ label : String) -> FieldDefinition? {
        let def = FieldDefinition(label)
        return addDef(def)
    }
    
    /// Add a new field definition to the dictionary, based on the passed Field Label
    func addDef (_ label : FieldLabel) -> FieldDefinition? {
        let def = FieldDefinition(label: label)
        return addDef(def)
        
    }
    
    /// Add a new field definition to the dictionary.
    ///
    /// - Parameter def: The field definition to be added.
    ///
    /// - Returns: The new definition just added, or the existing definition,
    ///            if the field was already in the dictionary.
    ///
    func addDef(_ def : FieldDefinition) -> FieldDefinition? {
        let common = def.fieldLabel.commonForm
        let existingDef = dict[common]
        if existingDef != nil {
            return existingDef!
        } else if locked {
            return nil
        } else {
            dict [common] = def
            if common == LabelConstants.titleCommon {
                if list.isEmpty {
                    list.append(def)
                } else {
                    list.insert(def, at: 0)
                }
            } else if common == LabelConstants.bodyCommon {
                if insertPositionFromEnd <= 1 {
                    list.append(def)
                } else {
                    list.insert(def, at: list.count - insertPositionFromEnd)
                }
                insertPositionFromEnd += 1
            } else if common == LabelConstants.dateAddedCommon {
                list.append(def)
                insertPositionFromEnd += 1
            } else if insertPositionFromEnd <= 1 {
                list.append(def)
            } else {
                list.insert(def, at: list.count - insertPositionFromEnd)
            }
            return def
        }
    }
    
    /// Remove the given definition from the dictionary and report our success
    func removeDef(_ def: FieldDefinition) -> Bool {
        var removeOK = false
        let common = def.fieldLabel.commonForm
        dict.removeValue(forKey: common)
        var i = 0
        var looking = true
        while looking && i < list.count {
            let listDef = list[i]
            if common == listDef.fieldLabel.commonForm {
                looking = false
                removeOK = true
                list.remove(at: i)
            } else {
                i += 1
            }
        }
        return removeOK
    }
}
