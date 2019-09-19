//
//  WorkTitlePickList.swift
//  Notenik
//
//  Created by Herb Bowie on 9/6/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class WorkTitlePickList: PickList {
    
    override init() {
        super.init()
    }
    
    func registerWork(_ note: Note) {

        let value = registerValue(note.workTitle)
        guard let work = value as? WorkTitleValue else { return }
        
        let author = note.author
        work.setAuthor(author)
        
        let date = note.date
        work.setDate(date)
        
        let type = note.workType
        work.setType(type)
        
        let link = note.workLink
        work.setLink(link)
        
        let id = note.getFieldAsValue(label: LabelConstants.workIDcommon)
        work.setID(id)
        
        let rights = note.getFieldAsValue(label: LabelConstants.workRightsCommon)
        work.setRights(rights)
        
        let holder = note.getFieldAsValue(label: LabelConstants.workRightsHolderCommon)
        work.setHolder(holder)
        
        let publisher = note.getFieldAsValue(label: LabelConstants.publisherCommon)
        work.setPublisher(publisher)
        
        let city = note.getFieldAsValue(label: LabelConstants.pubCityCommon)
        work.setCity(city)
    } // end register tags
    
}
