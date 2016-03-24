//
//  RNUnifiedContacts.swift
//  RNUnifiedContacts
//
//  Created by Joshua Pinter on 2016-03-23.
//  Copyright © 2016 Joshua Pinter. All rights reserved.
//

import Contacts
import Foundation

@objc(RNUnifiedContacts)
class RNUnifiedContacts: NSObject {
    
    @objc func myTestFunction() {
        NSLog("In myTestFunction in RNUnifiedContacts in Swift!")
        
        let contactStore = CNContactStore()
        
        let defaultContainerIdentifier = contactStore.defaultContainerIdentifier()
        
        let predicate = CNContact.predicateForContactsInContainerWithIdentifier(defaultContainerIdentifier)
        
        let keysToFetch = [ CNContactFormatter.descriptorForRequiredKeysForStyle(CNContactFormatterStyle.FullName) ]
        
        do {
            let contacts = try contactStore.unifiedContactsMatchingPredicate(predicate, keysToFetch: keysToFetch)
            
            for contact in contacts {
                NSLog( CNContactFormatter.stringFromContact(contact, style: .FullName)! )
            }
        }
        catch {
            print("Problem getting unified Contacts")
        }
        
    }
    
}

