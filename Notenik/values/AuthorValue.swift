//
//  AuthorValue.swift
//  Notenik
//
//  Created by Herb Bowie on 12/5/18.
//  Copyright © 2018 PowerSurge Publishing. All rights reserved.
//

import Foundation

/// An object representing an author, or authoring team, for one or more works
class AuthorValue : StringValue {
    
    var lastName = ""
    var firstName = ""
    var suffix = ""
    var authors : [AuthorValue] = []
    
    /// Default initialization
    override init() {
        super.init()
    }
    
    /// Set an initial value with a last name and a first name
    convenience init (lastName: String, firstName: String) {
        self.init()
        set(lastName: lastName, firstName: firstName)
    }
    
    /// Set an initial value with a last name and a first name and a suffix
    convenience init (lastName : String, firstName : String, suffix : String) {
        self.init()
        set(lastName: lastName, firstName: firstName, suffix: suffix)
    }
    
    /// Set an initial value with a complete name
    convenience init (_ value: String) {
        self.init()
        set(value)
    }
    
    /// Use a last name first arrangement for the sort key
    override var sortKey: String {
        return lastNameFirst
    }
    
    /// Return the last name followed by a comma, then the first name and suffix
    var lastNameFirst : String {
        var lnf = ""
        var i = 0
        if authors.count > 0 {
            for author in authors {
                lnf.append(author.lastNameFirst)
                if i < (authors.count - 2) {
                    lnf.append(", ")
                } else if i == (authors.count - 2) {
                    lnf.append(" and ")
                }
                i += 1
            }
        } else {
            lnf.append(lastName)
            if lnf.count > 0 && firstName.count > 0 {
                lnf.append(", ")
            }
            lnf.append(firstName)
            if lnf.count > 0 && suffix.count > 0 {
                lnf.append(" ")
            }
            lnf.append(suffix)
        }
        return lnf
    }
    
    /// Return the number of authors
    var authorCount : Int {
        if authors.count > 1 {
            return authors.count
        } else if count > 0 {
            return 1
        } else {
            return 0
        }
    }
    
    /// Get the complete name(s), as originally input by the user
    func getCompleteName() -> String {
        return self.value
    }
    
    /// Get the first name of the first or only author
    func getFirstName() -> String {
        if authors.count > 0 {
            return authors[0].firstName
        } else {
            return self.firstName
        }
    }
    
    /// Get the last name of the first or only author
    func getLastName() -> String {
        if authors.count > 0 {
            return authors[0].lastName
        } else {
            return self.lastName
        }
    }
    
    /// Get the suffix of the first or only author
    func getSuffix() -> String {
        if authors.count > 0 {
            return authors[0].suffix
        } else {
            return self.suffix
        }
    }
    
    /// Get author number i from a list of authors, where the first is numbered zero
    func getSubAuthor(_ i : Int) -> AuthorValue? {
        if i == 0 && authors.count == 0 {
            return self
        } else if i < 0 || i >= authors.count {
            return nil
        } else {
            return authors[i]
        }
    }
    
    /// Set the Author's name from a first name and last name
    func set (lastName : String, firstName : String) {
        authors = []
        self.lastName  = lastName
        self.firstName = firstName
        self.suffix    = ""
        self.value = lastName
        if lastName.count > 0 && firstName.count > 0 {
            self.value.append(", ")
        }
        self.value.append(firstName)
    }
    
    /// Set the Author's name from a first name and last name and suffix
    func set (lastName : String, firstName : String, suffix : String) {
        authors = []
        self.lastName  = lastName
        self.firstName = firstName
        self.suffix    = suffix
        self.value = lastName
        if lastName.count > 0 && firstName.count > 0 {
            self.value.append(", ")
        }
        self.value.append(firstName)
        if self.value.count > 0 && suffix.count > 0 {
            self.value.append(" ")
        }
        self.value.append(suffix)
    }
    
    /// Set the author name from a complete name
    ///
    /// Set the content of the Author object from a single String containing the
    /// complete name(s) of one or more author(s). If the string names multiple
    /// authors, then it is expected to be in the form "John Doe, Jane Smith and
    /// Joe Riley": in other words, with an "and" (or an ampersand) before the last
    /// name and with other names separated by commas.
    override func set (_ value : String) {
        self.value = value
        self.lastName  = ""
        self.firstName = ""
        self.suffix    = ""
        authors = []
        
        // Scan the input string and break it down into words
        var words : [AuthorWord] = []
        var word = AuthorWord()
        var andFound = false
        var commaCount = 0
        for c in value {
            if c == " " || c == "\t" || c == "\n" || c == "\r" || c == "~" || c == "_" {
                if word.count > 0 {
                    word.setDelim(" ")
                    words.append(word)
                    word = AuthorWord()
                    if word.isAnd {
                        andFound = true
                    }
                }
            } else if c == "," {
                if word.count > 0 {
                    word.setDelim(c)
                    words.append(word)
                    commaCount += 1
                    word = AuthorWord()
                }
            } else {
                word.append(c)
            }
        }
        if word.count > 0 {
            words.append(word)
        }
        
        // Now let's go through the list of words and create one or more names
        var wordNumber = 0
        let multipleAuthors = commaCount > 1 || andFound
        var temp = TempName()
        for word in words {
            wordNumber += 1
            var endName = false
            if multipleAuthors && word.isAnd {
                endName = true
            } else {
                temp.append(word: word, multipleAuthors: multipleAuthors)
                if multipleAuthors && word.delim == "," {
                    endName = true
                }
                if wordNumber == words.count {
                    endName = true
                }
            }
            if endName && temp.count > 0 {
                if multipleAuthors {
                    authors.append(temp.buildAuthorValue())
                    temp = TempName()
                } else {
                    self.lastName = temp.lastName
                    self.firstName = temp.firstName
                    self.suffix = temp.suffix
                }
            }
        }
    }
    
    /// A temporary inner class for building a single name
    class TempName {
        var completeName = ""
        var firstName = ""
        var lastName = ""
        var suffix = ""
        var lastNameFirst = false
        
        init() {
            
        }
        
        var count : Int {
            return completeName.count + firstName.count + lastName.count
        }
        
        /// Generate a valid Author Value from this temporary object
        func buildAuthorValue() -> AuthorValue {
            if lastName.count > 0 {
                return AuthorValue(lastName: lastName, firstName: firstName, suffix: suffix)
            } else {
                return AuthorValue(completeName)
            }
        }
        
        /// Figure out where to put the next word making up this temporary name
        func append (word : AuthorWord, multipleAuthors : Bool) {
            let lower = word.word.lowercased()
            if suffix.count == 0 && count > 0 && (lower == "jr" || lower == "jr."
                    || lower == "sr" || lower == "sr." || lower == "iii") {
                // We have a name suffix
                suffix = word.word
                appendToCompleteName(word.word)
            } else if word.delim == "," {
                if multipleAuthors {
                    // Let's treat this as a last name (until another one comes along)
                    appendToCompleteName(word.word)
                    newLastName(word.word)
                } else {
                    // Delimiter is a comma indicating end of last name
                    lastNameFirst = true
                    appendToLastName(word.word)
                    appendToCompleteName(word.word)
                    if completeName.count > 0 {
                        completeName.append(", ")
                    }
                }
            } else {
                appendToCompleteName(word.word)
                if lastNameFirst {
                    appendToFirstName(word.word)
                } else {
                    newLastName(word.word)
                }
            }
        }
        
        /// Append the string to the complete name
        func appendToCompleteName(_ word : String) {
            if completeName.count > 0 {
                completeName.append(" ")
            }
            completeName.append(word)
        }
        
        /// Use this word as the new last name
        func newLastName(_ word : String) {
            appendToFirstName(lastName)
            lastName = word
        }
        
        /// Append the string to the last name
        func appendToLastName(_ word : String) {
            if lastName.count > 0 {
                lastName.append(" ")
            }
            lastName.append(word)
        }
        
        /// Append the string to the first name
        func appendToFirstName(_ word : String) {
            if firstName.count > 0 {
                firstName.append(" ")
            }
            firstName.append(word)
        }
        
    }
    
    /// An inner class for defining one word in an author's name
    class AuthorWord {
        var word = ""
        var delim = " "
        
        init() {
            
        }
        
        var count : Int {
            return word.count
        }
        
        var isAnd : Bool {
            return word == "and" || word == "&" || word == "&amp;"
        }
        
        func append(_ c : Character) {
            word.append(String(c))
        }
        
        func setDelim(_ delim : Character) {
            self.delim = String(delim)
        }
        
        
    }
}
