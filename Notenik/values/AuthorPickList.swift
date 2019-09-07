//
//  AuthorPickList.swift
//  Notenik
//
//  Created by Herb Bowie on 9/6/19.
//  Copyright © 2019 Herb Bowie (https://powersurgepub.com)
//
//  This programming code is published as open source software under the
//  terms of the MIT License (https://opensource.org/licenses/MIT).
//

import Foundation

class AuthorPickList: PickList {
    
    func registerAuthor(_ author: AuthorValue) {
        registerValue(author.firstNameFirst)
    } // end register tags
    
}
