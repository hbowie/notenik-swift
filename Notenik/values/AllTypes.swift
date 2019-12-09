//
//  AllTypes.swift
//  Notenik
//
//  Created by Herb Bowie on 10/25/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

/// A catalog of all available field types. One of these should be created for each Collection.
class AllTypes {
    
    let artistType  = ArtistType()
    let authorType  = AuthorType()
    let bodyType    = LongTextType()
    let booleanType = BooleanType()
    let codeType    = LongTextType()
    let dateAddedType = DateAddedType()
    let dateType    = DateType()
    let indexType   = IndexType()
    let intType     = IntType()
    let labelType   = StringType()
    let linkType    = LinkType()
    let longTextType = LongTextType()
    let ratingType  = RatingType()
    let recursType  = RecursType()
    let seqType     = SeqType()
    let statusType  = StatusType()
    let stringType  = StringType()
    let tagsType    = TagsType()
    let titleType   = TitleType()
    let timestampType = TimestampType()
    let workTitleType = WorkTitleType()
    let workTypeType = WorkTypeType()
    
    var fieldTypes: [AnyType] = []
    
    var statusValueConfig: StatusValueConfig {
        get {
            return statusType.statusValueConfig
        }
        set {
            statusType.statusValueConfig = newValue
        }
    }
    
    /// Initialize with all of the standard types. 
    init() {
        
        // picklist type???
        
        fieldTypes.append(artistType)
        
        fieldTypes.append(authorType)
        
        fieldTypes.append(booleanType)
        
        fieldTypes.append(dateAddedType)
        
        fieldTypes.append(dateType)
        
        fieldTypes.append(indexType)
        
        fieldTypes.append(intType)
        
        labelType.typeString = "label"
        fieldTypes.append(labelType)
        
        fieldTypes.append(linkType)
        
        fieldTypes.append(longTextType)
        
        bodyType.typeString = "body"
        bodyType.properLabel = "Body"
        bodyType.commonLabel = "body"
        fieldTypes.append(bodyType)
        
        codeType.typeString = "code"
        codeType.properLabel = "Code"
        codeType.commonLabel = "code"
        fieldTypes.append(codeType)
        
        fieldTypes.append(ratingType)
        
        fieldTypes.append(recursType)
        
        fieldTypes.append(seqType)
        
        fieldTypes.append(statusType)
        
        fieldTypes.append(stringType)
        
        fieldTypes.append(tagsType)
        
        fieldTypes.append(timestampType)
        
        fieldTypes.append(titleType)
        
        fieldTypes.append(workTitleType)
        
        fieldTypes.append(workTypeType)
        
    }
    
    /// Assign a field type based on a field label and, optionally, a type string. 
    func assignType(label: FieldLabel, type: String?) -> AnyType {
        
        for fieldType in fieldTypes {
            if fieldType.appliesTo(label: label, type: type) {
                return fieldType
            }
        }
        return stringType
    }
    
    /// Given just a data value, return value type that is the best fit.
    func assignType(value: String) -> AnyType {
        if value.count == 0 {
            return stringType
        } else {
            let possibleInt = Int(value)
            if possibleInt != nil {
                return intType
            } else {
                return stringType
            }
        }
    }
    
}
