//
//  WorkTitleValue.swift
//  Notenik
//
//  Created by Herb Bowie on 9/6/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class WorkTitleValue: StringValue {
    
    var author = ""
    var date = ""
    var type = ""
    var link = ""
    var id = ""
    var rights = ""
    var holder = ""
    var publisher = ""
    var city = ""
    
    override init() {
        super.init()
    }
    
    /// Initialize with a String value
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    func setAuthor(_ newAuthor: AuthorValue) {
        if newAuthor.hasData && author.count == 0 {
            author = newAuthor.value
        }
    }
    
    func setDate(_ newDate: DateValue) {
        if newDate.hasData && date.count == 0 {
            date = newDate.value
        }
    }
    
    func setType(_ newType: WorkTypeValue) {
        if newType.hasData && type.count == 0 {
            type = newType.value
        }
    }
    
    func setLink(_ newLink: LinkValue) {
        if newLink.hasData && link.count == 0 {
            link = newLink.value
        }
    }
    
    func setID(_ newID: StringValue) {
        if newID.hasData &&  id.count == 0 {
            id = newID.value
        }
    }
    
    func setRights(_ newRights: StringValue) {
        if newRights.hasData && rights.count == 0 {
            rights = newRights.value
        }
    }
    
    func setHolder(_ newHolder: StringValue) {
        if newHolder.hasData && holder.count == 0 {
            holder = newHolder.value
        }
    }
    
    func setPublisher(_ newPublisher: StringValue) {
        if newPublisher.hasData && publisher.count == 0 {
            publisher = newPublisher.value
        }
    }
    
    func setCity(_ newCity: StringValue) {
        if newCity.hasData && city.count == 0 {
            city = newCity.value
        }
    }
    
}
