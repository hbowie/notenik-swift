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

class AllTypes {
    
    /// A catalog of all available field types. One of these should be created for each Collection.
    var fieldTypes: [AnyType] = []
    
    init() {
        
        let artistType = ArtistType()
        fieldTypes.append(artistType)
        
        let authorType = AuthorType()
        fieldTypes.append(authorType)
        
        let booleanType = BooleanType()
        fieldTypes.append(booleanType)
        
        let dateType = DateType()
        fieldTypes.append(dateType)
        
        let indexType = IndexType()
        fieldTypes.append(indexType)
        
        let intType = IntType()
        fieldTypes.append(intType)
        
        let linkType = LinkType()
        fieldTypes.append(linkType)
        
        let longTextType = LongTextType()
        fieldTypes.append(longTextType)
        
        let ratingType = RatingType()
        fieldTypes.append(ratingType)
        
        let recursType = RecursType()
        fieldTypes.append(recursType)
        
        let seqType = SeqType()
        fieldTypes.append(seqType)
        
        let statusType = StatusType()
        fieldTypes.append(statusType)
        
        let tagsType = TagsType()
        fieldTypes.append(tagsType)
        
        let titleType = TitleType()
        fieldTypes.append(titleType)
        
        let workTitleType = WorkTitleType()
        fieldTypes.append(workTitleType)
        
        let workTypeType = WorkTypeType()
        fieldTypes.append(workTypeType)
        
        // String Type is the default, so it should always be last. 
        let stringType = StringType()
        fieldTypes.append(stringType)
    }
    
    /// Assign a field type based ona field label and, optionally, a type string. 
    func assignType(label: FieldLabel, type: String?) -> AnyType {
        
        for fieldType in fieldTypes {
            if fieldType.appliesTo(label: label, type: type) {
                return fieldType
            }
        }
        return fieldTypes[fieldTypes.count - 1]
    }
    
}
